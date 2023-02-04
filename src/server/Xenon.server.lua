--[[

		Xenon Streaming Engine
	 Copyright (c) 2023 iiPython

]]

-- Services
local Players = game:GetService("Players")
local Storage = game:GetService("ServerStorage")

-- Configuration
local C = {
	RenderDistance	= 50,	-- Stud radius (xy, where x and y are both this number)
	Delay			= 0.1,	-- Delay between player updates
	WalkTrigger		= 10,	-- Magnitude difference to trigger update
	IgnoreLocked	= true,	-- Ignore locked parts (baseplates, etc.)
	ExternalConfig	= true, -- Allow config changing via Value objects
}
if C.ExternalConfig then
	local CfgObj = Instance.new("Configuration", script)
	CfgObj.ChildAdded:Connect(function(c)
		if c:IsA("IntValue") or c:IsA("BoolValue") then
			local function upd(v) C[c.Name] = v end  -- Configuration update
			c:GetPropertyChangedSignal("Value"):Connect(function() upd(c.Value) end)
			upd(c.Value)
		end
	end)
else
	table.freeze(C)
end

-- Initialization
local Parts = Instance.new("Folder")
Parts.Name = "XenonParts"
Parts.Parent = Storage

local function XeL(m) print("[Xe]", m) end

-- Version info
local V = Instance.new("StringValue")
V.Value = "1.1.2"
V.Name = "Version"
V.Parent = script

XeL("Xenon version " .. V.Value .. " loaded.")

-- Position handlers
local function createPartStructure(x: number, y: number, z: number, p: Instance)
	if p == nil then p = Parts end
	local function cpf(n, pt)
		local a = Instance.new("Folder")
		a.Name = n
		a.Parent = pt
		return a
	end
	local x1 = p:FindFirstChild(x)
	if x1 == nil then x1 = cpf(x, p) end
	local y1 = x1:FindFirstChild(y)
	if y1 == nil then y1 = cpf(y, x1) end
	local z1 = y1:FindFirstChild(z)
	if z1 == nil then cpf(z, y1) end
end
local function registerPart(part: Instance)
	local x, y, z = math.floor(part.Position.X), math.floor(part.Position.Y), math.floor(part.Position.Z)
	createPartStructure(x, y, z)
	part.Parent = Parts[x][y][z]
end
local function findPartsInRange(v1: Vector3, v2: Vector3, p: Instance)
	if p == nil then p = Parts end
	local pts = {}
	local x, oy, oz = math.floor(v1.X), math.floor(v1.Y), math.floor(v1.Z)
	local x1, y1, z1 = math.floor(v2.X), math.floor(v2.Y), math.floor(v2.Z)
	while x <= x1 do
		if not p:FindFirstChild(x) then x += 1; continue end
		local y = oy
		while y <= y1 do
			if not p[x]:FindFirstChild(y) then y += 1; continue end
			local z = oz
			while z <= z1 do
				if not p[x][y]:FindFirstChild(z) then z += 1; continue end
				local t = p[x][y][z]:GetChildren()
				for _, t1 in pairs(t) do table.insert(pts, t1) end
				z += 1
			end
			y += 1
		end
		x += 1
	end
	return pts
end

-- Begin registering parts
local Xe = game.Workspace:FindFirstChild("Xenon")
if not Xe then return XeL("No 'Xenon' folder to stream from.") end
for _, p in pairs(Xe:GetDescendants()) do
	if p:IsA("BasePart") then
		if p.Locked and C.IgnoreLocked then continue end
		registerPart(p)
	end
end

-- Handle leaving
local lastPos, lastParts = {}, {}
Players.PlayerRemoving:Connect(function(p)
	local lp = lastParts[p.UserId]
	if lp == nil then return end  -- They must of NOPED out insanely fast for this to be nil

	-- Clear all signs that they ever existed
	lp:Destroy()
	lastPos[p.UserId] = nil
end)

-- Handle respawning
Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function(c)	
		c:WaitForChild("Humanoid").Died:Connect(function()

			-- Force update
			lastPos[p.UserId] = Vector3.new(0, lastPos[p.UserId].Y + (C.WalkTrigger + 1), 0)
		end)
	end)
end)

-- Start watching movement
while task.wait(C.Delay) do
	local up = {}
	for _, p in pairs(Players:GetPlayers()) do
		local c = p.Character
		if c == nil then continue end
		local h = c:FindFirstChild("Head")
		if h == nil then continue end

		-- Position tracking
		local ps = h.Position
		if not lastPos[p.UserId] then
			lastPos[p.UserId] = ps
			local f = Instance.new("Folder")
			f.Name = p.Name
			f.Parent = game.Workspace.Xenon
			lastParts[p.UserId] = f
		elseif (lastPos[p.UserId] - ps).magnitude < C.WalkTrigger then continue end
		
		-- Create range
		local v1 = Vector3.new(
			ps.X - C.RenderDistance,
			ps.Y - C.RenderDistance,
			ps.Z - C.RenderDistance
		)
		local v2 = Vector3.new(
			ps.X + C.RenderDistance,
			ps.Y + C.RenderDistance,
			ps.Z + C.RenderDistance
		)
		
		-- Stream parts
		for _, pt in pairs(findPartsInRange(v1, v2)) do
			local ps = pt.Position
			local rp = findPartsInRange(ps, ps, lastParts[p.UserId])
			if #rp > 0 then
				for _, _p in pairs(rp) do _p:SetAttribute("_XN", 1) end
				continue
			end
			local px, py, pz = math.floor(ps.X), math.floor(ps.Y), math.floor(ps.Z)
			local pc = pt:Clone()
			createPartStructure(px, py, pz, lastParts[p.UserId])
			pc:SetAttribute("_XN", 1)
			pc.Parent = lastParts[p.UserId][px][py][pz]
		end
		table.insert(up, p.UserId)
	end

	-- Remove old parts (reuse parts)
	for _, pl in pairs(up) do
		for _, _p in pairs(lastParts[pl]:GetDescendants()) do
			if not _p:IsA("BasePart") then continue end
			if _p:GetAttribute("_XN") == 1 then _p:SetAttribute("_XN", 0)
			else
				if (#_p.Parent:GetChildren() - 1) == 0 then
					_p.Parent:Destroy()  -- Remove empty folders
					continue
				end
				_p:Destroy()
			end
		end
	end
end

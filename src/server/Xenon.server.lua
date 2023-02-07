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
local Parts = Instance.new("WorldModel")
Parts.Name = "XenonParts"
Parts.Parent = Storage

local function XeL(m) print("[Xe]", m) end

-- Version info
local V = Instance.new("StringValue")
V.Value = "1.1.4"
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

-- Begin registering parts
local Xe = workspace:FindFirstChild("Xenon")
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
			f.Parent = workspace.Xenon
			lastParts[p.UserId] = f
		elseif (lastPos[p.UserId] - ps).magnitude < C.WalkTrigger then continue end
	
		-- Stream parts
		local cr = C.RenderDistance
		local pn = Instance.new("Folder", workspace.Xenon)
		pn.Name = p.Name .. "_n"
		for _, pt in pairs(Parts:GetPartBoundsInBox(h.CFrame, Vector3.new(cr, cr, cr))) do
			local ps = pt.Position
			local px, py, pz = math.floor(ps.X), math.floor(ps.Y), math.floor(ps.Z)
			local rpobj = lastParts[p.UserId]
			if rpobj:FindFirstChild(px) and rpobj[px]:FindFirstChild(py) and rpobj[px][py]:FindFirstChild(pz) then
				local rp = rpobj[px][py][pz]:GetChildren()
				for _, _p in pairs(rp) do _p.Parent = pn end
			end
			local pc = pt:Clone()
			createPartStructure(px, py, pz, pn)
			pc.Parent = pn[px][py][pz]
		end
		table.insert(up, p.UserId)

		-- Remove old parts (reuse parts)
		lastParts[p.UserId]:Destroy()
		pn.Name = p.Name
		lastParts[p.UserId] = pn
	end	
end

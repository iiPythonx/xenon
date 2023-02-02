--[[

		Xenon Streaming Engine
	 Copyright (c) 2023 iiPython

]]

-- Services
local Players = game:GetService("Players")
local Storage = game:GetService("ServerStorage")

-- Configuration
local C = {
	RenderDistance = 50
}

-- Version info
local V = Instance.new("StringValue")
V.Value = "1.0.8"
V.Name = "Version"
V.Parent = script

print("[Xe] Xenon version " .. V.Value .. " loaded.")

-- Initialization
local Parts = Instance.new("Folder")
Parts.Name = "XenonParts"
Parts.Parent = Storage

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

-- Begin Xenonifying parts
for _, p in pairs(game.Workspace.Xenon:GetDescendants()) do registerPart(p) end

-- Start watching movement
local lastPos, lastParts = {}, {}
while task.wait(.1) do
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
		elseif (lastPos[p.UserId] - ps).magnitude < 2 then continue end
		
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
		
	end

	-- Remove old parts (reuse parts)
	for _, _p in pairs(game.Workspace.Xenon:GetDescendants()) do
		if _p:IsA("Folder") then continue end
		if _p:GetAttribute("_XN") == 1 then _p:SetAttribute("_XN", 0)
		else _p:Destroy() end
	end
end

--/ Instancing
_G.MoonlightDebug = true
if getgenv().Moonlight and not _G.MoonlightDebug then
	return getgenv().Moonlight
end

--/ Prerequisites
local Players = game:FindService("Players")
local speaker = Players.LocalPlayer

--/ Helper functions
-- Recent "patch" of old scripts just added encryption to action names
-- This function reverses it to make it usable again
function UnfilterAction(input)
	local offset = speaker.AccountAge
	local output = {}
	for _, code in utf8.codes(input) do
		table.insert(output, utf8.char(code + offset))
	end
	return table.concat(output)
end

--/ Moonlight
-- F3X Class
local F3X = {}
F3X.__index = F3X

function F3X.new()
	local tool
	if speaker:FindFirstChild("Backpack") then
		tool = speaker.Backpack:FindFirstChild("Building Tools") or
			speaker.Backpack:FindFirstChild("F3X")
	end
	if not tool and speaker.Character then
		tool = speaker.Character:FindFirstChild("Building Tools") or
			speaker.Character:FindFirstChild("F3X")
	end
	assert(tool, "Couldn't find F3X")

	local self = {}
	self.Tool = tool

	return setmetatable(self, F3X)
end

-- Low level functions
function F3X:IsActive()
	if not self.Tool then
		return false
	end
	if not self.Tool.Parent then
		return false
	end
	if not self.Tool:FindFirstChildOfClass("BindableFunction") then
		return false
	end
	if not self.Tool:FindFirstChildOfClass("BindableFunction")
		:FindFirstChildOfClass("RemoteFunction") then
		return false
	end
	return true
end

function F3X:Equip(state)
	if self.Tool.Parent:IsA("Model") and state == false then
		self.Tool.Parent = speaker.Backpack
	elseif self.Tool.Parent:IsA("Backpack") and state == true then
		self.Tool.Parent = speaker.Character
	end
end

function F3X:CallAPI(sync, action, ...)
	--[[
		Low-level function for direct calls to Sync API
	--]]
	assert(type(sync) == "boolean", "expected sync to be boolean")
	assert(type(action) == "string", "expected action to be string")
	assert(self:IsActive(), "F3X is inactive")
	self:Equip(true)

	local SyncAPI = self.Tool:FindFirstChildOfClass("BindableFunction")
		:FindFirstChildOfClass("RemoteFunction")
	if sync then
		return SyncAPI:InvokeServer(UnfilterAction(action), ...)
	else
		return task.spawn(function(...)
			SyncAPI:InvokeServer(UnfilterAction(action), ...)
		end, ...)
	end
end
function F3X:CallAPISync(action, ...)
	return self:CallAPI(true, action, ...)
end
function F3X:CallAPIAsync(action, ...)
	return self:CallAPI(false, action, ...)
end

-- High level functions
function F3X:Weld(p1, p2)
	assert(typeof(p1) == "Instance", "expected p1 to be Instance")
	assert(typeof(p2) == "Instance", "expected p2 to be Instance")
	assert(p1:IsA("BasePart"), "expected p1 to be BasePart")
	assert(p2:IsA("BasePart"), "expected p2 to be BasePart")
	-- if none are locked, or p0 is locked
	if (p1.Locked and not p2.Locked) or (not p1.Locked and not p2.Locked) then
		self:CallAPI(false, "CreateWelds", {p2}, p1)
	-- if p1 is locked
	elseif not p1.Locked and p2.Locked then
		self:CallAPI(false, "CreateWelds", {p1}, p2)
	-- if both are locked
	else
		error("Cannot weld two locked parts")
	end
end

function F3X:DestroyInstances(ins)
	assert(type(ins) == "table", "expected ins to be table")
	self:CallAPI(false, "UndoRemove", ins)
end

function F3X:DestroyInstance(ins)
	assert(typeof(ins) == "Instance", "expected ins to be Instance")
	self:CallAPI(false, "UndoRemove", {ins})
end

function F3X:SetProperties(ins, properties)
	assert(type(sync) == "boolean", "expected sync to be boolean")
	assert(typeof(ins) == "Instance", "expected ins to be Instance")
	assert(ins:IsA("BasePart"), "expected ins to be BasePart")
	assert(type(properties) == "table", "expected sync to be table")
	local surfaces = {}
	for key, value in properties do
		surfaces[key .. "\0."] = value
	end
	self:CallAPI(false, "SyncSurfaces", {
		{Part = ins, Surfaces = surfaces}
	})
end

-- Moonlight Class
local Moonlight = {}
Moonlight.__index = Moonlight

function Moonlight.new()
	return setmetatable({}, Moonlight)
end

function Moonlight:GetF3X()
	return F3X.new()
end

local instance = Moonlight.new()
getgenv().Moonlight = instance
return instance

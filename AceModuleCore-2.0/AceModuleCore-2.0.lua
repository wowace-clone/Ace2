--[[
Name: AceModuleCore-2.0
Revision: $Rev$
Author(s): Kaelten (kaelten@gmail.com)
           ckknight (ckknight@gmail.com)
Website: http://www.wowace.com/
Documentation: http://wiki.wowace.com/index.php/AceModuleCore-2.0
SVN: http://svn.wowace.com/root/trunk/Ace2/AceModuleCore-2.0
Description: Mixin to provide a module system so that modules or plugins can
             use an addon as its core.
Dependencies: AceLibrary, AceOO-2.0, AceAddon-2.0
]]

local MAJOR_VERSION = "AceModuleCore-2.0"
local MINOR_VERSION = "$Revision$"

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end

if not AceLibrary:HasInstance("AceOO-2.0") then error(MAJOR_VERSION .. " requires AceOO-2.0") end

local AceOO = AceLibrary:GetInstance("AceOO-2.0")
local AceModuleCore = AceOO.Mixin {"NewModule", "HasModule", "GetModule", "IsModule", "IterateModules", "SetModuleMixins"}

local function getlibrary(lib)
	if type(lib) == "string" then
		return AceLibrary(lib)
	else
		return lib
	end
end

local tmp
function AceModuleCore:NewModule(name, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
	if not self.modules then
		AceModuleCore:error("CreatePrototype() must be called before attempting to create a new module.", 2)
	end
	AceModuleCore:argCheck(name, 2, "string")
	if string.len(name) == 0 then
		AceModuleCore:error("Bad argument #2 to `NewModule`, string must not be empty")
	end
	if self.modules[name] then
		AceModuleCore:error("The module %q has already been registered", name)
	end
	
	if not tmp then
		tmp = {}
	end
	if a1 then table.insert(tmp, a1)
	if a2 then table.insert(tmp, a2)
	if a3 then table.insert(tmp, a3)
	if a4 then table.insert(tmp, a4)
	if a5 then table.insert(tmp, a5)
	if a6 then table.insert(tmp, a6)
	if a7 then table.insert(tmp, a7)
	if a8 then table.insert(tmp, a8)
	if a9 then table.insert(tmp, a9)
	if a10 then table.insert(tmp, a10)
	if a11 then table.insert(tmp, a11)
	if a12 then table.insert(tmp, a12)
	if a13 then table.insert(tmp, a13)
	if a14 then table.insert(tmp, a14)
	if a15 then table.insert(tmp, a15)
	if a16 then table.insert(tmp, a16)
	if a17 then table.insert(tmp, a17)
	if a18 then table.insert(tmp, a18)
	if a19 then table.insert(tmp, a19)
	if a20 then table.insert(tmp, a20)
	end end end end end end end end end end end end end end end end end end end end
	for k,v in ipairs(tmp) do
		tmp[k] = getlibrary(v)
	end
	
	if self.moduleMixins then
		for _,mixin in ipairs(self.moduleMixins) do
			local exists = false
			for _,v in ipairs(tmp) do
				if mixin == v then
					exists = true
					break
				end
			end
			if not exists then
				table.insert(tmp, mixin)
			end
		end
	end
	
	local module = AceOO.Classpool(self.moduleClass, unpack(tmp)):new()
	self.modules[name] = module
	module.name = name
	module.title = name
	
	AceModuleCore.totalModules[module] = true
	
	for k in pairs(tmp) do
		tmp[k] = nil
	end
	table.setn(tmp, 0)
	return module
end

function AceModuleCore:HasModule(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
	if a1 then if not self.modules[a1] then return false end
	if a2 then if not self.modules[a2] then return false end
	if a3 then if not self.modules[a3] then return false end
	if a4 then if not self.modules[a4] then return false end
	if a5 then if not self.modules[a5] then return false end
	if a6 then if not self.modules[a6] then return false end
	if a7 then if not self.modules[a7] then return false end
	if a8 then if not self.modules[a8] then return false end
	if a9 then if not self.modules[a9] then return false end
	if a10 then if not self.modules[a10] then return false end
	if a11 then if not self.modules[a11] then return false end
	if a12 then if not self.modules[a12] then return false end
	if a13 then if not self.modules[a13] then return false end
	if a14 then if not self.modules[a14] then return false end
	if a15 then if not self.modules[a15] then return false end
	if a16 then if not self.modules[a16] then return false end
	if a17 then if not self.modules[a17] then return false end
	if a18 then if not self.modules[a18] then return false end
	if a19 then if not self.modules[a19] then return false end
	if a20 then if not self.modules[a20] then return false end
	end end end end end end end end end end end end end end end end end end end end
	
	return true
end

function AceModuleCore:GetModule(name)
	if not self.modules then
		AceModuleCore:error("Error initializing class.  Please report error.")
	end
	if not self.modules[name] then
		AceModuleCore:error("Cannot find module %q.", name)
	end
	return self.modules[name]
end

function AceModuleCore:IsModule(module)
	if self == AceModuleCore then
		return AceModuleCore.totalModules[module]
	else
		for k,v in pairs(self.modules) do
			if v == module then
				return true
			end
		end
		return false
	end
end

function AceModuleCore:IterateModules()
	return pairs(self.modules)
end

function AceModuleCore:SetModuleMixins(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
	if self.moduleMixins then
		AceModuleCore:error('Cannot call "SetModuleMixins" twice')
	elseif not self.modules then
		AceModuleCore:error("Error initializing class.  Please report error.")
	elseif next(self.modules) then
		AceModuleCore:error('Cannot call "SetModuleMixins" after "NewModule" has been called.')
	end
	
	self.moduleMixins = {a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20}
	for k,v in ipairs(self.moduleMixins) do
		self.moduleMixins[k] = getlibrary(v)
	end
end

function AceModuleCore:OnInstanceInit(target)
	if target.modules then
		AceModuleCore:error("OnInstanceInit cannot be called twice")
	end
	target.modules = {}
	
	target.moduleClass = AceOO.Class("AceAddon-2.0")
	target.modulePrototype = target.moduleClass.prototype
end

AceModuleCore.OnManualEmbed = AceModuleCore.OnInstanceInit

local function activate(self, oldLib, oldDeactivate)
	AceModuleCore = self
	
	self.super.activate(self, oldLib, oldDeactivate)
	
	if oldLib then
		self.totalModules = oldLib.totalModules
	end
	if not self.totalModules then
		self.totalModules = {}
	end
end

AceLibrary:Register(AceModuleCore, MAJOR_VERSION, MINOR_VERSION, activate)
AceModuleCore = AceLibrary(MAJOR_VERSION)
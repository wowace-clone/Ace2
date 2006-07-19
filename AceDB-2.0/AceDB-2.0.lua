--[[
Name: AceDB-2.0
Revision: $Rev$
Author(s): ckknight (ckknight@gmail.com)
Inspired By: AceDB 1.x by Turan (<email here>)
Website: http://www.wowace.com/
Documentation: http://wiki.wowace.com/index.php/AceDB-2.0
SVN: http://svn.wowace.com/root/trunk/Ace2/AceDB-2.0
Description: Mixin to allow for fast, clean, and featureful saved variable
             access.
Dependencies: AceLibrary, AceOO-2.0, AceEvent-2.0
]]

local MAJOR_VERSION = "AceDB-2.0"
local MINOR_VERSION = "$Revision$"

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end

if not AceLibrary:HasInstance("AceOO-2.0") then error(MAJOR_VERSION .. " requires AceOO-2.0") end

-- localize --
local ACTIVE = "Active"
local STATE = "State"
local TOGGLE_ACTIVE = "Suspend/resume this addon"
local MAP_ACTIVESUSPENDED = { [true] = "|cff00ff00Active|r", [false] = "|cffff0000Suspended|r" }
local SET_PROFILE = "Set profile for this addon"
local SET_PROFILE_USAGE = "{char || class || realm || <profile name>}"
local PROFILE = "Profile"
local PLAYER_OF_REALM = "%s of %s"
-- localize --

local AceOO = AceLibrary("AceOO-2.0")
local AceEvent
local Mixin = AceOO.Mixin
local AceDB = Mixin {
						"RegisterDB",
						"RegisterDefaults",
						"ResetDB",
						"SetProfile",
						"GetProfile",
						"ToggleActive",
						"IsActive",
						"AcquireDBNamespace",
						"ToggleStandby", -- remove at 2006-07-21
						"IsEnabled", -- remove at 2006-07-21
					}

local _G = getfenv(0)

local function inheritDefaults(t, defaults)
	if not defaults then
		return t
	end
	for k,v in pairs(defaults) do
		if k == "*" then
			local v = v
			if type(v) == "table" then
				setmetatable(t, {
					__index = function(self, key)
						if key == nil then
							return nil
						end
						self[key] = {}
						inheritDefaults(self[key], v)
						return self[key]
					end
				} )
			else
				setmetatable(t, {
					__index = function(self, key)
						if key == nil then
							return nil
						end
						self[key] = v
						return self[key]
					end
				} )
			end
			for key in pairs(t) do
				if (defaults[key] == nil or key == "*") and type(t[key]) == "table" then
					inheritDefaults(t[key], v)
				end
			end
		else
			if type(v) == "table" then
				if type(t[k]) ~= "table" then
					t[k] = {}
				end
				inheritDefaults(t[k], v)
			elseif t[k] == nil then
				t[k] = v
			end
		end
	end
	return t
end

local _,race = UnitRace("player")
local faction
if race == "Orc" or race == "Scourge" or race == "Troll" or race == "Tauren" then
	faction = FACTION_HORDE
else
	faction = FACTION_ALLIANCE
end
local charID = string.format(PLAYER_OF_REALM, UnitName("player"), (string.gsub(GetRealmName(), "^%s*(.-)%s*$", "%1")))
local realm = string.gsub(GetRealmName(), "^%s*(.-)%s*$", "%1")
local realmID = realm .. " - " .. faction
local classID = UnitClass("player")

AceDB.CHAR_ID = charID
AceDB.REALM_ID = realmID
AceDB.CLASS_ID = classID

AceDB.FACTION = faction
AceDB.REALM = realm
AceDB.NAME = UnitName("player")

local caseInsensitive_mt = {
	__index = function(self, key)
		if type(key) ~= "string" then
			return nil
		end
		local lowerKey = string.lower(key)
		for k,v in pairs(self) do
			if string.lower(k) == lowerKey then
				return self[k]
			end
		end
	end,
	__newindex = function(self, key, value)
		if type(key) ~= "string" then
			return error("table index is nil", 2)
		end
		local lowerKey = string.lower(key)
		for k in pairs(self) do
			if string.lower(k) == lowerKey then
				rawset(self, k, nil)
				rawset(self, key, value)
				return
			end
		end
		rawset(self, key, value)
	end
}

local db_mt = { __index = function(db, key)
	if key == "char" then
		if db.charName then
			if type(_G[db.charName]) ~= "table" then
				_G[db.charName] = {}
			end
			if type(_G[db.charName].raw) ~= "table" then
				_G[db.charName].global = {}
			end
			rawset(db, 'char', _G[db.charName].global)
		else
			if type(db.raw.chars) ~= "table" then
				db.raw.chars = {}
			end
			local id = charID
			if type(db.raw.chars[id]) ~= "table" then
				db.raw.chars[id] = {}
			end
			rawset(db, 'char', db.raw.chars[id])
		end
		if db.defaults and db.defaults.char then
			inheritDefaults(db.char, db.defaults.char)
		end
		return db.char
	elseif key == "realm" then
		if type(db.raw.realms) ~= "table" then
			db.raw.realms = {}
		end
		local id = realmID
		if type(db.raw.realms[id]) ~= "table" then
			db.raw.realms[id] = {}
		end
		rawset(db, 'realm', db.raw.realms[id])
		if db.defaults and db.defaults.realm then
			inheritDefaults(db.realm, db.defaults.realm)
		end
		return db.realm
	elseif key == "account" then
		if type(db.raw.account) ~= "table" then
			db.raw.account = {}
		end
		rawset(db, 'account', db.raw.account)
		if db.defaults and db.defaults.account then
			inheritDefaults(db.account, db.defaults.account)
		end
		return db.account
	elseif key == "class" then
		if type(db.raw.classes) ~= "table" then
			db.raw.classes = {}
		end
		local id = classID
		if type(db.raw.classes[id]) ~= "table" then
			db.raw.classes[id] = {}
		end
		rawset(db, 'class', db.raw.classes[id])
		if db.defaults and db.defaults.class then
			inheritDefaults(db.class, db.defaults.class)
		end
		return db.class
	elseif key == "profile" then
		if type(db.raw.profiles) ~= "table" then
			db.raw.profiles = setmetatable({}, caseInsensitive_mt)
		else
			setmetatable(db.raw.profiles, caseInsensitive_mt)
		end
		local id = db.raw.currentProfile[charID]
		if id == "char" then
			id = "char/" .. charID
		elseif id == "class" then
			id = "class/" .. classID
		elseif id == "realm" then
			id = "realm/" .. realmID
		end
		if type(db.raw.profiles[id]) ~= "table" then
			db.raw.profiles[id] = {}
		end
		rawset(db, 'profile', db.raw.profiles[id])
		if db.defaults and db.defaults.profile then
			inheritDefaults(db.profile, db.defaults.profile)
		end
		return db.profile
	elseif key == "raw" or key == "defaults" or key == "name" or key == "charName" or key == "namespaces" then
		return nil
	end
	error(string.format('Cannot access key %q in db table. You may want to use db.profile[%q]', tostring(key), tostring(key)), 2)
end, __newindex = function(db, key, value)
	error(string.format('Cannot access key %q in db table. You may want to use db.profile[%q]', tostring(key), tostring(key)), 2)
end }

local namespace_mt = { __index = function(namespace, key)
	local db = namespace.db
	local name = namespace.name
	if key == "char" then
		if db.charName then
			if type(_G[db.charName]) ~= "table" then
				_G[db.charName] = {}
			end
			if type(_G[db.charName].namespaces) ~= "table" then
				_G[db.charName].namespaces = {}
			end
			if type(_G[db.charName].namespaces[name]) ~= "table" then
				_G[db.charName].namespaces[name] = {}
			end
			rawset(namespace, 'char', _G[db.charName].namespaces[name])
		else
			if type(db.raw.namespaces) ~= "table" then
				db.raw.namespaces = {}
			end
			if type(db.raw.namespaces[name]) ~= "table" then
				db.raw.namespaces[name] = {}
			end
			if type(db.raw.namespaces[name].chars) ~= "table" then
				db.raw.namespaces[name].chars = {}
			end
			local id = charID
			if type(db.raw.namespaces[name].chars[id]) ~= "table" then
				db.raw.namespaces[name].chars[id] = {}
			end
			rawset(namespace, 'char', db.raw.namespaces[name].chars[id])
		end
		if namespace.defaults and namespace.defaults.char then
			inheritDefaults(namespace.char, namespace.defaults.char)
		end
		return namespace.char
	elseif key == "realm" then
		if type(db.raw.namespaces) ~= "table" then
			db.raw.namespaces = {}
		end
		if type(db.raw.namespaces[name]) ~= "table" then
			db.raw.namespaces[name] = {}
		end
		if type(db.raw.namespaces[name].realms) ~= "table" then
			db.raw.namespaces[name].realms = {}
		end
		local id = realmID
		if type(db.raw.namespaces[name].realms[id]) ~= "table" then
			db.raw.namespaces[name].realms[id] = {}
		end
		rawset(namespace, 'realm', db.raw.namespaces[name].realms[id])
		if namespace.defaults and namespace.defaults.realm then
			inheritDefaults(namespace.realm, namespace.defaults.realm)
		end
		return namespace.realm
	elseif key == "account" then
		if type(db.raw.namespaces) ~= "table" then
			db.raw.namespaces = {}
		end
		if type(db.raw.namespaces[name]) ~= "table" then
			db.raw.namespaces[name] = {}
		end
		if type(db.raw.namespaces[name].account) ~= "table" then
			db.raw.namespaces[name].account = {}
		end
		rawset(namespace, 'account', db.raw.namespaces[name].account)
		if namespace.defaults and namespace.defaults.account then
			inheritDefaults(namespace.account, namespace.defaults.account)
		end
		return namespace.account
	elseif key == "class" then
		if type(db.raw.namespaces) ~= "table" then
			db.raw.namespaces = {}
		end
		if type(db.raw.namespaces[name]) ~= "table" then
			db.raw.namespaces[name] = {}
		end
		if type(db.raw.namespaces[name].classes) ~= "table" then
			db.raw.namespaces[name].classes = {}
		end
		local id = classID
		if type(db.raw.namespaces[name].classes[id]) ~= "table" then
			db.raw.namespaces[name].classes[id] = {}
		end
		rawset(namespace, 'class', db.raw.namespaces[name].classes[id])
		if namespace.defaults and namespace.defaults.class then
			inheritDefaults(namespace.class, namespace.defaults.class)
		end
		return namespace.class
	elseif key == "profile" then
		if type(db.raw.namespaces) ~= "table" then
			db.raw.namespaces = {}
		end
		if type(db.raw.namespaces[name]) ~= "table" then
			db.raw.namespaces[name] = {}
		end
		if type(db.raw.namespaces[name].profiles) ~= "table" then
			db.raw.namespaces[name].profiles = setmetatable({}, caseInsensitive_mt)
		else
			setmetatable(db.raw.namespaces[name].profiles, caseInsensitive_mt)
		end
		local id = db.raw.currentProfile[charID]
		if id == "char" then
			id = "char/" .. charID
		elseif id == "class" then
			id = "class/" .. classID
		elseif id == "realm" then
			id = "realm/" .. realmID
		end
		if type(db.raw.namespaces[name].profiles[id]) ~= "table" then
			db.raw.namespaces[name].profiles[id] = {}
		end
		rawset(namespace, 'profile', db.raw.namespaces[name].profiles[id])
		if namespace.defaults and namespace.defaults.profile then
			inheritDefaults(namespace.profile, namespace.defaults.profile)
		end
		return namespace.profile
	elseif key == "defaults" or key == "name" or key == "db" then
		return nil
	end
	error(string.format('Cannot access key %q in db table. You may want to use db.profile[%q]', tostring(key), tostring(key)), 2)
end, __newindex = function(db, key, value)
	error(string.format('Cannot access key %q in db table. You may want to use db.profile[%q]', tostring(key), tostring(key)), 2)
end }

function AceDB:InitializeDB(addonName)
	local db = self.db
	
	if not db then
		if addonName then
			AceDB.addonsLoaded[addonName] = true
		end
		return
	end
	
	if db.raw then
		-- someone manually initialized
		return
	end
	
	if type(_G[db.name]) ~= "table" then
		_G[db.name] = {}
	end
	rawset(db, 'raw', _G[db.name])
	if not db.raw.currentProfile then
		db.raw.currentProfile = {}
	end
	if not db.raw.currentProfile[charID] then
		db.raw.currentProfile[charID] = "default"
	end
	if db.raw.disabled then
		setmetatable(db.raw.disabled, caseInsensitive_mt)
	end
	setmetatable(db, db_mt)
end

function AceDB:OnEmbedInitialize(target, name)
	self.InitializeDB(target, name)
end

function AceDB:RegisterDB(name, charName)
	AceDB:argCheck(name, 2, "string")
	AceDB:argCheck(charName, 3, "string", "nil")
	if self.db then
		AceDB:error("Cannot call \"RegisterDB\" if self.db is set.")
	end
	local stack = debugstack()
	local addonName = string.gsub(stack, ".-\n.-\\AddOns\\(.-)\\.*", "%1")
	self.db = {
		name = name,
		charName = charName
	}
	if AceDB.addonsLoaded[addonName] then
		AceDB.InitializeDB(self, addonName)
	else
		AceDB.addonsToBeInitialized[self] = addonName
	end
	AceDB.registry[self] = true
end

function AceDB:RegisterDefaults(kind, defaults, a3)
	local name
	if a3 then
		name, kind, defaults = kind, defaults, a3
		AceDB:argCheck(name, 2, "string")
		AceDB:argCheck(kind, 3, "string")
		AceDB:argCheck(defaults, 4, "table")
		if kind ~= "char" and kind ~= "class" and kind ~= "profile" and kind ~= "account" and kind ~= "realm" then
			AceDB:error("Bad argument #3 to `RegisterDefaults' (\"char\", \"class\", \"profile\", \"account\", or \"realm\" expected, got %q)", kind)
		end
	else
		AceDB:argCheck(kind, 2, "string")
		AceDB:argCheck(defaults, 3, "table")
		if kind ~= "char" and kind ~= "class" and kind ~= "profile" and kind ~= "account" and kind ~= "realm" then
			AceDB:error("Bad argument #2 to `RegisterDefaults' (\"char\", \"class\", \"profile\", \"account\", or \"realm\" expected, got %q)", kind)
		end
	end
	if type(self.db) ~= "table" or type(self.db.name) ~= "string" then
		AceDB:error("Cannot call \"RegisterDefaults\" unless \"RegisterDB\" has been previously called.")
	end
	local db
	if name then
		local namespace = self:AcquireDBNamespace(name)
		if namespace.defaults and namespace.defaults[kind] then
			AceDB:error("\"RegisterDefaults\" has already been called for %q::%q.", name, kind)
		end
		db = namespace
	else
		if self.db.defaults and self.db.defaults[kind] then
			AceDB:error("\"RegisterDefaults\" has already been called for %q.", kind)
		end
		db = self.db
	end
	if not db.defaults then
		rawset(db, 'defaults', {})
	end
	db.defaults[kind] = defaults
	if rawget(db, kind) then
		inheritDefaults(db[kind], defaults)
	end
end

function AceDB:ResetDB(kind)
	AceDB:argCheck(kind, 2, "nil", "string")
	if not self.db or not self.db.raw then
		AceDB:error("Cannot call \"ResetDB\" before \"RegisterDB\" has been called and before \"ADDON_LOADED\" has been fired.")
	end
	local db = self.db
	if kind == nil then
		if db.charName then
			_G[db.charName] = nil
		end
		_G[db.name] = nil
		rawset(db, 'raw', nil)
		AceDB.InitializeDB(self)
		if db.namespaces then
			for name,v in pairs(db.namespaces) do
				rawset(v, 'account', nil)
				rawset(v, 'char', nil)
				rawset(v, 'class', nil)
				rawset(v, 'profile', nil)
				rawset(v, 'realm', nil)
			end
		end
	elseif kind == "account" then
		db.raw.account = nil
		rawset(db, 'account', nil)
		if db.namespaces then
			for name,v in pairs(db.namespaces) do
				rawset(v, 'account', nil)
			end
		end
	elseif kind == "char" then
		if db.charName then
			_G[db.charName] = nil
		else
			if db.raw.chars then
				db.raw.chars[charID] = nil
			end
			if db.raw.namespaces then
				for name,v in pairs(db.raw.namespaces) do
					if v.chars then
						v.chars[charID] = nil
					end
				end
			end
		end
		rawset(db, 'char', nil)
		if db.namespaces then
			for name,v in pairs(db.namespaces) do
				rawset(v, 'char', nil)
			end
		end
	elseif kind == "realm" then
		if db.raw.realms then
			db.raw.realms[realmID] = nil
		end
		rawset(db, 'realm', nil)
		if db.raw.namespaces then
			for name,v in pairs(db.raw.namespaces) do
				if v.realms then
					v.realms[realmID] = nil
				end
			end
		end
		if db.namespaces then
			for name,v in pairs(db.namespaces) do
				rawset(v, 'realm', nil)
			end
		end
	elseif kind == "class" then
		if db.raw.realms then
			db.raw.realms[classID] = nil
		end
		rawset(db, 'class', nil)
		if db.raw.namespaces then
			for name,v in pairs(db.raw.namespaces) do
				if v.classes then
					v.classes[classID] = nil
				end
			end
		end
		if db.namespaces then
			for name,v in pairs(db.namespaces) do
				rawset(v, 'class', nil)
			end
		end
	elseif kind == "profile" then
		local id = db.raw.currentProfile and db.raw.currentProfile[charID] or "default"
		if id == "char" then
			id = "char/" .. charID
		elseif id == "class" then
			id = "class/" .. classID
		elseif id == "realm" then
			id = "realm/" .. realmID
		end
		if db.raw.profiles then
			db.raw.profiles[id] = nil
		end
		rawset(db, 'profile', nil)
		if db.raw.namespaces then
			for name,v in pairs(db.raw.namespaces) do
				if v.profiles then
					v.profiles[id] = nil
				end
			end
		end
		if db.namespaces then
			for name,v in pairs(db.namespaces) do
				rawset(v, 'profile', nil)
			end
		end
	end
end

local function cleanDefaults(t, defaults)
	if defaults then
		for k,v in pairs(defaults) do
			if k == "*" then
				if type(v) == "table" then
					for k in pairs(t) do
						if (defaults[k] == nil or k == "*") and type(t[k]) == "table" then
							if cleanDefaults(t[k], v) then
								t[k] = nil
							end
						end
					end
				else
					for k in pairs(t) do
						if (defaults[k] == nil or k == "*") and t[k] == v then
							t[k] = nil
						end
					end
				end
			else
				if type(v) == "table" then
					if type(t[k]) == "table" then
						if cleanDefaults(t[k], v) then
							t[k] = nil
						end
					end
				elseif t[k] == v then
					t[k] = nil
				end
			end
		end
	end
	return not next(t)
end

function AceDB:GetProfile()
	if not self.db or not self.db.raw then
		return nil
	end
	local profile = self.db.raw.currentProfile[charID]
	if profile == "char" then
		return "char", "char/" .. charID
	elseif profile == "class" then
		return "class", "class/" .. classID
	elseif profile == "realm" then
		return "realm", "realm/" .. realmID
	end
	return profile, profile
end

local function copyTable(to, from)
	setmetatable(to, nil)
	for k,v in pairs(from) do
		if type(k) == "table" then
			k = copyTable({}, k)
		end
		if type(v) == "table" then
			v = copyTable({}, v)
		end
		to[k] = v
	end
	table.setn(to, table.getn(from))
	setmetatable(to, from)
	return to
end

local stage = 3
if tonumber(date("%Y%m%d")) < 20060713 then
	stage = 1
elseif tonumber(date("%Y%m%d")) < 20060720 then
	stage = 2
end

function AceDB:SetProfile(name, copyFrom)
	AceDB:argCheck(name, 2, "string")
	AceDB:argCheck(copyFrom, 3, "string", "nil")
	if not self.db or not self.db.raw then
		AceDB:error("Cannot call \"SetProfile\" before \"RegisterDB\" has been called and before \"ADDON_LOADED\" has been fired.")
	end
	local db = self.db
	local copy = false
	local lowerName = string.lower(name)
	local lowerCopyFrom = copyFrom and string.lower(copyFrom)
	if string.sub(lowerName, 1, 5) == "char/" or string.sub(lowerName, 1, 6) == "realm/" or string.sub(lowerName, 1, 6) == "class/" then
		if stage <= 2 then
			if string.sub(lowerName, 1, 5) == "char/" then
				name, copyFrom = "char", name
			else
				name, copyFrom = string.sub(lowerName, 1, 5), name
			end
			lowerName = string.lower(name)
			lowerCopyFrom = string.lower(copyFrom)
			if stage == 2 then
				local line = string.gsub(debugstack(), ".-\n(.-)\n.*", "%1")
				DEFAULT_CHAT_FRAME:AddMessage(line .. " - Bad argument #2 to `SetProfile'. Cannot start with char/, realm/, or class/. This will cause an error on July 20, 2006.")
			end
		else
			AceDB:error("Bad argument #2 to `SetProfile'. Cannot start with char/, realm/, or class/.")
		end
	end
	if copyFrom then
		if string.sub(lowerCopyFrom, 1, 5) == "char/" then
			AceDB:assert(lowerName == "char", "If argument #3 starts with `char/', argument #2 must be `char'")
		elseif string.sub(lowerCopyFrom, 1, 6) == "realm/" then
			AceDB:assert(lowerName == "realm", "If argument #3 starts with `realm/', argument #2 must be `realm'")
		elseif string.sub(lowerCopyFrom, 1, 6) == "class/" then
			AceDB:assert(lowerName == "class", "If argument #3 starts with `class/', argument #2 must be `class'")
		else
			AceDB:assert(lowerName ~= "char" and lowerName ~= "realm" and lowerName ~= "class", "If argument #3 does not start with a special prefix, that prefix cannot be copied to.")
		end
		if not db.raw.profiles or not db.raw.profiles[copyFrom] then
			AceDB:error("Cannot copy profile %q, it does not exist.", copyFrom)
		elseif (string.sub(lowerName, 1, 5) == "char/" and string.sub(lowerName, 6) == string.lower(charID)) or (string.sub(lowerName, 1, 6) == "realm/" and string.sub(lowerName, 7) == string.lower(realmID)) or (string.sub(lowerName, 1, 6) == "class/" and string.sub(lowerName, 7) == string.lower(classID)) then
			AceDB:error("Cannot copy profile %q, it is currently in use.", name)
		end
	end
	local oldName = db.raw.currentProfile[charID]
	if type(self.OnProfileDisable) == "function" then
		self:OnProfileDisable()
	end
	local oldProfileData = db.profile
	local realName = name
	if lowerName == "char" then
		realName = name .. "/" .. charID
	elseif lowerName == "realm/" then
		realName = name .. "/" .. realmID
	elseif lowerName == "class/" then
		realName = name .. "/" .. classID
	end
	local active = self:IsActive()
	db.raw.currentProfile[charID] = name
	rawset(db, 'profile', nil)
	if copyFrom then
		for k,v in pairs(db.profile) do
			db.profile[k] = nil
		end
		copyTable(db.profile, db.raw.profiles[copyFrom])
		inheritDefaults(db.profile, db.defaults and db.defaults.profile)
	end
	if type(self.OnProfileEnable) == "function" then
		self:OnProfileEnable(oldName, oldProfileData)
	end
	if cleanDefaults(oldProfileData, db.defaults and db.defaults.profile) then
		db.raw.profiles[oldName] = nil
		if not next(db.raw.profiles) then
			db.raw.profiles = nil
		end
	end
	local newactive = self:IsActive()
	if active ~= newactive then
		if AceOO.inherits(self, "AceAddon-2.0") then
			local AceAddon = AceLibrary("AceAddon-2.0")
			if not AceAddon.addonsStarted[self] then
				return
			end
		end
		if newactive then
			local current = self.class
			while true do
				if current == AceOO.Class then
					break
				end
				if current.mixins then
					for mixin in pairs(current.mixins) do
						if type(mixin.OnEmbedEnable) == "function" then
							mixin:OnEmbedEnable(self)
						end
					end
				end
				current = current.super
			end
			if type(self.OnEnable) == "function" then
				self:OnEnable()
			end
		else
			local current = self.class
			while true do
				if current == AceOO.Class then
					break
				end
				if current.mixins then
					for mixin in pairs(current.mixins) do
						if type(mixin.OnEmbedDisable) == "function" then
							mixin:OnEmbedDisable(self)
						end
					end
				end
				current = current.super
			end
			if type(self.OnDisabled) == "function" then
				self:OnDisable()
			end
		end
	end
end

local stage = 3
if tonumber(date("%Y%m%d")) < 20060714 then
	stage = 1
elseif tonumber(date("%Y%m%d")) < 20060721 then
	stage = 2
end

function AceDB:IsActive()
	return not self.db or not self.db.raw or not self.db.raw.disabled or not self.db.raw.disabled[self.db.raw.currentProfile[charID]]
end

function AceDB:ToggleActive(state)
	AceDB:argCheck(state, 2, "boolean", "nil")
	if not self.db or not self.db.raw then
		AceDB:error("Cannot call \"ToggleActive\" before \"RegisterDB\" has been called and before \"ADDON_LOADED\" has been fired.")
	end
	local db = self.db
	if not db.raw.disabled then
		db.raw.disabled = setmetatable({}, caseInsensitive_mt)
	end
	local profile = db.raw.currentProfile[charID]
	local disable
	if state == nil then
		disable = not db.raw.disabled[profile]
	else
		disable = not state
		if disable == db.raw.disabled[profile] then
			return
		end
	end
	db.raw.disabled[profile] = disable or nil
	if AceOO.inherits(self, "AceAddon-2.0") then
		local AceAddon = AceLibrary("AceAddon-2.0")
		if not AceAddon.addonsStarted[self] then
			return
		end
	end
	if not disable then
		local current = self.class
		while true do
			if current == AceOO.Class then
				break
			end
			if current.mixins then
				for mixin in pairs(current.mixins) do
					if type(mixin.OnEmbedEnable) == "function" then
						mixin:OnEmbedEnable(self)
					end
				end
			end
			current = current.super
		end
		if type(self.OnEnable) == "function" then
			self:OnEnable()
		end
	else
		local current = self.class
		while true do
			if current == AceOO.Class then
				break
			end
			if current.mixins then
				for mixin in pairs(current.mixins) do
					if type(mixin.OnEmbedDisable) == "function" then
						mixin:OnEmbedDisable(self)
					end
				end
			end
			current = current.super
		end
		if type(self.OnDisable) == "function" then
			self:OnDisable()
		end
	end
	return not disable
end

if stage <= 2 then
	function AceDB:IsEnabled()
		if stage == 2 then
			local line = string.gsub(debugstack(), ".-\n(.-)\n.*", "%1")
			DEFAULT_CHAT_FRAME:AddMessage(line .. " - :IsEnabled() has been replaced by :IsActive(). This will cause an error on July 21, 2006.")
		end
		return self:IsActive()
	end
	function AceDB:ToggleStandby()
		if stage == 2 then
			local line = string.gsub(debugstack(), ".-\n(.-)\n.*", "%1")
			DEFAULT_CHAT_FRAME:AddMessage(line .. " - :ToggleStandby() has been replaced by :ToggleActive([state]). This will cause an error on July 21, 2006.")
		end
		return self:ToggleActive()
	end
end

function AceDB:embed(target)
	self.super.embed(self, target)
	if not AceEvent then
		AceDB:error(MAJOR_VERSION .. " requires AceEvent-2.0")
	end
end

function AceDB:ADDON_LOADED(name)
	AceDB.addonsLoaded[name] = true
	for addon, addonName in pairs(AceDB.addonsToBeInitialized) do
		if name == addonName then
			AceDB.InitializeDB(addon, name)
			AceDB.addonsToBeInitialized[addon] = nil
		end
	end
end

function AceDB:PLAYER_LOGOUT()
	for addon in pairs(AceDB.registry) do
		local db = addon.db
		if db then
			setmetatable(db, nil)
			if db.char and cleanDefaults(db.char, db.defaults and db.defaults.char) then
				if db.charName and _G[db.charName].global == db.char then
					_G[db.charName].global = nil
					if not next(_G[db.charName]) then
						_G[db.charName] = nil
					end
				else
					db.raw.chars[charID] = nil
					if not next(db.raw.chars) then
						db.raw.chars = nil
					end
				end
			end
			if db.realm and cleanDefaults(db.realm, db.defaults and db.defaults.realm) then
				db.raw.realms[realmID] = nil
				if not next(db.raw.realms) then
					db.raw.realms = nil
				end
			end
			if db.class and cleanDefaults(db.class, db.defaults and db.defaults.class) then
				db.raw.classes[classID] = nil
				if not next(db.raw.classes) then
					db.raw.classes = nil
				end
			end
			if db.account and cleanDefaults(db.account, db.defaults and db.defaults.account) then
				db.raw.account = nil
			end
			if db.profile and cleanDefaults(db.profile, db.defaults and db.defaults.profile) then
				db.raw.profiles[db.raw.currentProfile[charID] or "default"] = nil
				if not next(db.raw.profiles) then
					db.raw.profiles = nil
				end
			end
			if db.namespaces then
				for name,v in pairs(db.namespaces) do
					setmetatable(v, nil)
					if v.char and cleanDefaults(v.char, v.defaults and v.defaults.char) then
						if db.charName and _G[db.charName] and _G[db.charName].namespaces and _G[db.charName].namespaces[name] == v then
							_G[db.charName].namespaces[name] = nil
							if not next(_G[db.charName].namespaces) then
								_G[db.charName].namespaces = nil
								if not next(_G[db.charName]) then
									_G[db.charName] = nil
								end
							end
						else
							db.raw.namespaces[name].chars[charID] = nil
							if not next(db.raw.namespaces[name].chars) then
								db.raw.namespaces[name].chars = nil
							end
						end
					end
					if v.realm and cleanDefaults(v.realm, v.defaults and v.defaults.realm) then
						db.raw.namespaces[name].realms[realmID] = nil
						if not next(db.raw.namespaces[name].realms) then
							db.raw.namespaces[name].realms = nil
						end
					end
					if v.class and cleanDefaults(v.class, v.defaults and v.defaults.class) then
						db.raw.namespaces[name].classes[classID] = nil
						if not next(db.raw.namespaces[name].classes) then
							db.raw.namespaces[name].classes = nil
						end
					end
					if v.account and cleanDefaults(v.account, v.defaults and v.defaults.account) then
						db.raw.namespaces[name].account = nil
					end
					if v.profile and cleanDefaults(v.profile, v.defaults and v.defaults.profile) then
						db.raw.namespaces[name].profiles[db.raw.currentProfile[charID] or "default"] = nil
						if not next(db.raw.namespaces[name].profiles) then
							db.raw.namespaces[name].profiles = nil
						end
					end
					if not next(db.raw.namespaces[name]) then
						db.raw.namespaces[name] = nil
					end
				end
				if not next(db.raw.namespaces) then
					db.raw.namespaces = nil
				end
			end
			if db.raw.disabled then
				if not next(db.raw.disabled) then
					db.raw.disabled = nil
				end
			end
			if db.raw.currentProfile then
				for k,v in pairs(db.raw.currentProfile) do
					if string.lower(v) == "default" then
						db.raw.currentProfile[k] = nil
					end
				end
				if not next(db.raw.currentProfile) then
					db.raw.currentProfile = nil
				end
			end
			if not next(db.raw) then
				_G[db.name] = nil
			end
		end
	end
end

function AceDB:AcquireDBNamespace(name)
	AceDB:argCheck(name, 2, "string")
	local db = self.db
	if not db then
		AceDB:error("Cannot call `AcquireDBNamespace' before `RegisterDB' has been called.", 2)
	end
	if not db.namespaces then
		rawset(db, 'namespaces', {})
	end
	if not db.namespaces[name] then
		local namespace = {}
		db.namespaces[name] = namespace
		namespace.db = db
		namespace.name = name
		setmetatable(namespace, namespace_mt)
	end
	return db.namespaces[name]
end

local options
function AceDB:GetAceOptionsDataTable(target)
	if not options then
		options = {
			standby = {
				cmdName = STATE,
				guiName = ACTIVE,
				name = ACTIVE,
				desc = TOGGLE_ACTIVE,
				type = "toggle",
				get = "IsActive",
				set = "ToggleActive",
				map = MAP_ACTIVESUSPENDED,
				order = -3,
			},
			profile = {
				name = PROFILE,
				desc = SET_PROFILE,
				get = "GetProfile",
				set = "SetProfile",
				usage = SET_PROFILE_USAGE,
				type = "text",
				order = -4,
			}
		}
	end
	return options
end

local function activate(self, oldLib, oldDeactivate)
	AceDB = self
	AceEvent = AceLibrary:HasInstance("AceEvent-2.0") and AceLibrary("AceEvent-2.0")
	
	self.super.activate(self, oldLib, oldDeactivate)
	
	for t in pairs(self.embedList) do
		if t.db then
			rawset(t.db, 'char', nil)
			rawset(t.db, 'realm', nil)
			rawset(t.db, 'class', nil)
			rawset(t.db, 'account', nil)
			rawset(t.db, 'profile', nil)
			setmetatable(t.db, db_mt)
		end
	end
	
	if oldLib then
		self.addonsToBeInitialized = oldLib.addonsToBeInitialized
		self.addonsLoaded = oldLib.addonsLoaded
		self.registry = oldLib.registry
	end
	if not self.addonsToBeInitialized then
		self.addonsToBeInitialized = {}
	end
	if not self.addonsLoaded then
		self.addonsLoaded = {}
	end
	if not self.registry then
		self.registry = {}
	end
	
	if oldLib then
		oldDeactivate(oldLib)
	end
end

local function external(self, major, instance)
	if major == "AceEvent-2.0" then
		AceEvent = instance
		
		AceEvent:embed(self)
		
		self:RegisterEvent("ADDON_LOADED")
		self:RegisterEvent("PLAYER_LOGOUT")
	end
end

AceLibrary:Register(AceDB, MAJOR_VERSION, MINOR_VERSION, activate, nil, external)
AceDB = AceLibrary(MAJOR_VERSION)

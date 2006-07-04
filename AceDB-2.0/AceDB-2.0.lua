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

local AceOO = AceLibrary("AceOO-2.0")
local AceEvent
local Mixin = AceOO.Mixin
local AceDB = Mixin {
						"RegisterDB",
						"RegisterDefaults",
						"SetProfile",
						"GetProfile",
						"ToggleStandby",
						"IsEnabled",
					}

local debugstack = debugstack
if type(debug) == "table" and debug.traceback then
	debugstack = debug.traceback
end
local inWoW = DEFAULT_CHAT_FRAME and true

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
						self[key] = {}
						inheritDefaults(self[key], v)
						return self[key]
					end
				} )
			else
				setmetatable(t, {
					__index = function(self, key)
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

local charID = UnitName("player") .. " of " .. GetRealmName()
local _,race = UnitRace("player")
local faction
if race == "Orc" or race == "Scourge" or race == "Troll" or race == "Tauren" then
	faction = FACTION_HORDE
else
	faction = FACTION_ALLIANCE
end
local realmID = GetRealmName() .. " - " .. faction
local classID = UnitClass("player")

local caseInsensitive_mt = {
	__index = function(self, key)
		local lowerKey = string.lower(key)
		for k,v in pairs(self) do
			if string.lower(k) == lowerKey then
				return self[k]
			end
		end
	end,
	__newindex = function(self, key, value)
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
			rawset(db, 'char', _G[db.charName])
		else
			if type(db.raw.chars) ~= "table" then
				db.raw.chars = {}
			end
			local name = charID
			if type(db.raw.chars[name]) ~= "table" then
				db.raw.chars[name] = {}
			end
			rawset(db, 'char', db.raw.chars[name])
		end
		if db.defaults and db.defaults.char then
			inheritDefaults(db.char, db.defaults.char)
		end
		return db.char
	elseif key == "realm" then
		if type(db.raw.realms) ~= "table" then
			db.raw.realms = {}
		end
		local name = realmID
		if type(db.raw.realms[name]) ~= "table" then
			db.raw.realms[name] = {}
		end
		rawset(db, 'realm', db.raw.realms[name])
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
		local name = classID
		if type(db.raw.classes[name]) ~= "table" then
			db.raw.classes[name] = {}
		end
		rawset(db, 'class', db.raw.classes[name])
		if db.defaults and db.defaults.class then
			inheritDefaults(db.class, db.defaults.class)
		end
		return db.class
	elseif key == "profile" then
		if type(db.raw.profiles) ~= "table" then
			db.raw.profiles = setmetatable({}, caseInsensitive_mt)
		end
		local name = db.raw.currentProfile[charID]
		if name == "char" then
			name = "char/" .. charID
		elseif name == "class" then
			name = "class/" .. classID
		elseif name == "realm" then
			name = "realm/" .. realmID
		end
		if type(db.raw.profiles[name]) ~= "table" then
			db.raw.profiles[name] = {}
		end
		rawset(db, 'profile', db.raw.profiles[name])
		if db.defaults and db.defaults.profile then
			inheritDefaults(db.profile, db.defaults.profile)
		end
		return db.profile
	elseif key == "raw" or key == "defaults" or key == "name" or key == "charName" then
		return nil
	end
	error(string.format('Cannot access key %q in db table. You may want to use db.profile[%q]', tostring(key), tostring(key)), 2)
end, __newindex = function(db, key, value)
	error(string.format('Cannot access key %q in db table. You may want to use db.profile[%q]', tostring(key), tostring(key)), 2)
end }

function AceDB:InitializeDB()
	local db = self.db
	
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

function AceDB:RegisterDB(name, charName)
	if type(name) ~= "string" then
		error(string.format("Bad argument #2 to `RegisterDB' (string expected, got %s)", tostring(type(name))), 2)
	elseif charName and type(charName) ~= "string" then
		error(string.format("Bad argument #3 to `RegisterDB' (string or nil expected, got %s)", tostring(type(charName))), 2)
	elseif self.db then
		error("Cannot call \"RegisterDB\" if self.db is set.", 2)
	end
	local stack = debugstack()
	local addonName = string.gsub(stack, ".-\n.-\\AddOns\\(.-)\\.*", "%1")
	if not inWoW then
		addonName = "Alpha"
	end
	self.db = {
		name = name,
		charName = charName
	}
	if AceDB.addonsLoaded[addonName] then
		AceDB.InitializeDB(self)
	else
		AceDB.addonsToBeInitialized[self] = addonName
	end
	AceDB.registry[self] = true
end

function AceDB:RegisterDefaults(kind, defaults, a3)
	if type(kind) ~= "string" then
		error(string.format("Bad argument #2 to `RegisterDefaults' (string expected, got %s)", tostring(type(kind))), 2)
	elseif kind ~= "char" and kind ~= "class" and kind ~= "profile" and kind ~= "account" and kind ~= "realm" then
		error(string.format("Bad argument #2 to `RegisterDefaults' (\"char\", \"class\", \"profile\", \"account\", or \"realm\" expected, got %q)", kind), 2)
	elseif type(self.db) ~= "table" or type(self.db.name) ~= "string" then
			error("Cannot call \"RegisterDefaults\" unless \"RegisterDB\" has been previously called.", 2)
	end
	if not a3 then
		if type(defaults) ~= "table" then
			error(string.format("Bad argument #3 to `RegisterDefaults' (table expected, got %s)", tostring(type(defaults))), 2)
		elseif self.db.defaults and self.db.defaults[kind] then
			error(string.format("\"RegisterDefaults\" has already been called for %q.", kind), 2)
		end
		if not self.db.defaults then
			rawset(self.db, 'defaults', {})
		end
		self.db.defaults[kind] = defaults
	else
		local subkey, defaults = defaults, a3
		if type(defaults) ~= "table" then
			error(string.format("Bad argument #4 to `RegisterDefaults' (table expected, got %s)", tostring(type(defaults))), 2)
		end
		if type(subkey) ~= "string" then
			error(string.format("Bad argument #3 to `RegisterDefaults' (string expected, got %s)", tostring(type(subkey))), 2)
		elseif subkey == '*' then
			error("Argument #3 to `RegisterDefaults' cannot be \"*\"", 2)
		end
		if self.db.defaults and self.db.defaults[kind] and self.db.defaults[kind][subkey] then
			error(string.format("\"RegisterDefaults\" has already been called for [%q][%q].", kind, subkey), 2)
		end
		if not self.db.defaults then
			rawset(self.db, 'defaults', {})
		end
		if not self.db.defaults[kind] then
			self.db.defaults[kind] = {}
		end
		self.db.defaults[kind][subkey] = defaults
		if rawget(self.db, kind) then
			if not rawget(self.db[kind], subkey) then
				self.db[kind][subkey] = {}
			end
			inheritDefaults(self.db[kind][subkey], defaults)
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
		return "char/" .. charID
	elseif profile == "class" then
		return "class/" .. classID
	elseif profile == "realm" then
		return "realm/" .. realmID
	end
	return profile
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

function AceDB:SetProfile(name)
	if type(name) ~= "string" then
		error(string.format("Bad argument #2 to `SetProfile' (string expected, got %s)", tostring(type(name))), 2)
	end
	if not self.db or not self.db.raw then
		error("Cannot call \"SetProfile\" before \"RegisterDB\" has been called and before \"ADDON_LOADED\" has been fired.", 2)
	end
	local db = self.db
	local copy = false
	local lowerName = string.lower(name)
	if string.sub(lowerName, 1, 5) == "char/" or string.sub(lowerName, 1, 6) == "realm/" or string.sub(lowerName, 1, 6) == "class/" then
		if not db.raw.profiles or not db.raw.profiles[name] then
			error(string.format("Cannot copy profile %q, it does not exist.", name), 2)
		else
			if (string.sub(lowerName, 1, 5) == "char/" and string.sub(lowerName, 6) == string.lower(charID)) or (string.sub(lowerName, 1, 6) == "realm/" and string.sub(lowerName, 7) == string.lower(realmID)) or (string.sub(lowerName, 1, 6) == "class/" and string.sub(lowerName, 7) == string.lower(classID)) then
				error(string.format("Cannot copy profile %q, it is currently in use.", name), 2)
			end
			copy = true
		end
	end
	local oldName = db.raw.currentProfile[charID]
	if type(self.OnProfileDisable) == "function" then
		self:OnProfileDisable()
	end
	local oldProfileData = db.profile
	if copy then
		local realName
		if string.sub(lowerName, 1, 5) == "char/" then
			realName, name = name, "char"
		elseif string.sub(lowerName, 1, 6) == "realm/" then
			realName, name = name, "realm"
		elseif string.sub(lowerName, 1, 6) == "class/" then
			realName, name = name, "class"
		end
		db.raw.currentProfile[charID] = name
		rawset(db, 'profile', nil)
		for k,v in pairs(db.profile) do
			db.profile[k] = nil
		end
		copyTable(db.profile, db.raw.profiles[realName])
		inheritDefaults(db.profile, db.defaults and db.defaults.profile)
	else
		db.raw.currentProfile[charID] = name
		rawset(db, 'profile', nil)
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
end

function AceDB:IsEnabled()
	return not self.db or not self.db.raw or not self.db.raw.disabled or not self.db.raw.disabled[self.db.raw.currentProfile[charID]]
end

function AceDB:ToggleStandby()
	if not self.db or not self.db.raw then
		error("Cannot call \"ToggleStandby\" before \"RegisterDB\" has been called and before \"ADDON_LOADED\" has been fired.", 2)
	end
	local db = self.db
	if not db.raw.disabled then
		db.raw.disabled = setmetatable({}, caseInsensitive_mt)
	end
	local profile = db.raw.currentProfile[charID]
	if db.raw.disabled[profile] then
		db.raw.disabled[profile] = nil
		if type(self.OnEnable) == "function" then
			self:OnEnable()
		end
		return true
	else
		db.raw.disabled[profile] = true
		if type(self.OnDisable) == "function" then
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
			self:OnDisable()
		end
		return false
	end
end

function AceDB:embed(target)
	self.class.prototype.embed(self, target)
	if not AceEvent then
		AceDB:error(MAJOR_VERSION .. " requires AceEvent-2.0")
	end
end

function AceDB:ADDON_LOADED(name)
	AceDB.addonsLoaded[name] = true
	for addon, addonName in pairs(AceDB.addonsToBeInitialized) do
		if name == addonName then
			AceDB.InitializeDB(addon)
			AceDB.addonsToBeInitialized[addon] = nil
		end
	end
end

function AceDB:PLAYER_LOGOUT()
	for addon in pairs(AceDB.registry) do
		local db = addon.db
		setmetatable(db, nil)
		if db then
			if db.char and cleanDefaults(db.char, db.defaults and db.defaults.char) then
				if db.charName and _G[db.charName] == db.char then
					_G[db.charName] = nil
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
			if db.raw.disabled then
				if not next(db.raw.diabled) then
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

local function activate(self, oldLib, oldDeactivate)
	AceDB = self
	
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
	else
		self.addonsToBeInitialized = {}
		self.addonsLoaded = {}
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

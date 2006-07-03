--[[
Name: AceAddon-2.0
Revision: $Rev: 3746 $
Author(s): ckknight (ckknight@gmail.com)
Inspired By: Ace 1.x by Turan (<email here>)
Website: http://www.wowace.com/
Documentation: http://wiki.wowace.com/index.php/AceAddon-2.0
SVN: http://svn.wowace.com/root/trunk/Ace2/AceAddon-2.0
Description: Base for all Ace addons to inherit from.
Dependencies: AceLibrary, AceOO-2.0, AceEvent-2.0, (optional) AceConsole-2.0
]]

local MAJOR_VERSION = "AceAddon-2.0"
local MINOR_VERSION = "$Revision: 3746 $"

-- This ensures the code is only executed if the libary doesn't already exist, or is a newer version
if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary.") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end

if not AceLibrary:HasInstance("AceOO-2.0") then error(MAJOR_VERSION .. " requires AceOO-2.0.") end

-- Localization
local STANDBY, TITLE, NOTES, VERSION, AUTHOR, DATE, CATEGORY, EMAIL, WEBSITE, CATEGORIES
if false then -- GetLocale() == "deDE"
else -- enUS
	STANDBY = "|cffff5050(standby)|r"
	
	TITLE = "Title"
	NOTES = "Notes"
	VERSION = "Version"
	AUTHOR = "Author"
	DATE = "Date"
	CATEGORY = "Category"
	EMAIL = "E-mail"
	WEBSITE = "Website"
	
	CATEGORIES = {
		["Action Bars"] = "Action Bars",
		["Auction"] = "Auction",
		["Audio"] = "Audio",
		["Battlegrounds/PvP"] = "Battlegrounds/PvP",
		["Buffs"] = "Buffs",
		["Chat/Communication"] = "Chat/Communication",
		["Druid"] = "Druid",
		["Hunter"] = "Hunter",
		["Mage"] = "Mage",
		["Paladin"] = "Paladin",
		["Priest"] = "Priest",
		["Rogue"] = "Rogue",
		["Shaman"] = "Shaman",
		["Warlock"] = "Warlock",
		["Warrior"] = "Warrior",
		["Healer"] = "Healer",
		["Tank"] = "Tank",
		["Caster"] = "Caster",
		["Combat"] = "Combat",
		["Compilations"] = "Compilations",
		["Data Export"] = "Data Export",
		["Development Tools "] = "Development Tools ",
		["Guild"] = "Guild",
		["Frame Modification"] = "Frame Modification",
		["Interface Enhancements"] = "Interface Enhancements",
		["Inventory"] = "Inventory",
		["Library"] = "Library",
		["Map"] = "Map",
		["Mail"] = "Mail",
		["Miscellaneous"] = "Miscellaneous",
		["Quest"] = "Quest",
		["Raid"] = "Raid",
		["Tradeskill"] = "Tradeskill",
		["UnitFrame"] = "UnitFrame",
	}
end

setmetatable(CATEGORIES, { __index = function(self, key) -- case-insensitive
	local lowerKey = string.lower(key)
	for k,v in CATEGORIES do
		if string.lower(k) == lowerKey then
			return v
		end
	end
end })

-- Create the library object

local AceOO = AceLibrary("AceOO-2.0")
local AceAddon = AceOO.Class()
local AceEvent = AceLibrary:HasInstance("AceEvent-2.0") and AceLibrary("AceEvent-2.0")
local AceConsole = AceLibrary:HasInstance("AceConsole-2.0") and AceLibrary("AceConsole-2.0")

function AceAddon:ToString()
	return "AceAddon"
end

local print = print
if DEFAULT_CHAT_FRAME then
	function print(text)
		DEFAULT_CHAT_FRAME:AddMessage(text)
	end
end

-- initialization for AceEvent
local function init(self, depth)
	init = nil
	if not AceEvent then
		if not AceLibrary:HasInstance("AceEvent-2.0") then
			error(MAJOR_VERSION .. " requires AceEvent-2.0", depth + 1)
		end
		AceEvent = AceLibrary("AceEvent-2.0")
	end
	
	AceEvent:embed(self)
	
	self:RegisterEvent("PLAYER_LOGIN", "PLAYER_LOGIN", true)
end

-- initialization for AceConsole (optional)
local function initChat(self)
	if not AceConsole then
		AceConsole = AceLibrary:HasInstance("AceConsole-2.0") and AceLibrary("AceConsole-2.0")
	end
	if AceConsole then
		local slashCommands = { "/ace2" }
		if not IsAddOnLoaded("Ace") then
			table.insert(slashCommands, "/ace")
		end
		local function listAddon(addon, depth)
			if not depth then
				depth = 0
			end
			
			local s = string.rep("  ", depth) .. " - " .. tostring(addon)
			if addon.version then
				s = s .. " - |cffffff7f" .. tostring(addon.version) .. "|r"
			end
			if addon.slashCommand then
				s = s .. " |cffffff7f(" .. tostring(addon.slashCommand) .. ")|r"
			end
			print(s)
			if type(addon.modules) == "table" then
				for k,v in pairs(addon.modules) do
					listAddon(v, depth + 1)
				end
			end
		end
		local function listNormalAddon(i)
			local name,_,_,enabled,loadable = GetAddOnInfo(i)
			if not loadable then
				enabled = false
			end
			if self.addons[name] then
				local addon = self.addons[name]
				if not AceCoreAddon or not AceCoreAddon:IsModule(addon) then
					listAddon(addon)
				end
			else
				local s = " - " .. tostring(GetAddOnMetadata(i, "Title") or name)
				local version = GetAddOnMetadata(i, "Version")
				if version then
					if string.find(version, "%$Revision: (%d+) %$") then
						version = string.gsub(version, "%$Revision: (%d+) %$", "%1")
					elseif string.find(version, "%$Rev: (%d+) %$") then
						version = string.gsub(version, "%$Rev: (%d+) %$", "%1")
					elseif string.find(version, "%$LastChangedRevision: (%d+) %$") then
						version = string.gsub(version, "%$LastChangedRevision: (%d+) %$", "%1")
					end
					s = s .. " - |cffffff7f" .. version .. "|r"
				end
				if not enabled then
					s = s .. " |cffff0000(disabled)|r"
				end
				if IsAddOnLoadOnDemand(i) then
					s = s .. " |cff00ff00[LoD]|r"
				end
				print(s)
			end
		end
		local function mySort(alpha, bravo)
			return tostring(alpha) < tostring(bravo)
		end
		AceConsole.RegisterChatCommand(self, slashCommands, {
			desc = "AddOn development framework",
			name = "Ace2",
			type = "group",
			args = {
				about = {
					desc = "Get information about Ace2",
					name = "About",
					type = "execute",
					func = function()
						print("|cffffff7fAce2|r - |cffffff7f2.0." .. string.gsub(MINOR_VERSION, "%$Revision: (%d+) %$", "%1") .. "|r - AddOn development framework")
						print(" - |cffffff7f" .. AUTHOR .. ":|r Ace Development Team")
						print(" - |cffffff7f" .. WEBSITE .. ":|r http://www.wowace.com/")
					end
				},
				list = {
					desc = "List addons",
					name = "List",
					type = "group",
					args = {
						ace2 = {
							desc = "List addons using Ace2",
							name = "Ace2",
							type = "execute",
							func = function()
								print("|cffffff7fAddon list:|r")
								local AceCoreAddon = AceLibrary:HasInstance("AceCoreAddon-2.0") and AceLibrary("AceCoreAddon-2.0")
								table.sort(self.addons, mySort)
								for _,v in ipairs(self.addons) do
									if not AceCoreAddon or not AceCoreAddon:IsModule(v) then
										listAddon(v)
									end
								end
							end
						},
						all = {
							desc = "List all addons",
							name = "All",
							type = "execute",
							func = function()
								print("|cffffff7fAddon list:|r")
								local AceCoreAddon = AceLibrary:HasInstance("AceCoreAddon-2.0") and AceLibrary("AceCoreAddon-2.0")
								local count = GetNumAddOns()
								for i = 1, count do
									listNormalAddon(i)
								end
							end
						},
						enabled = {
							desc = "List all enabled addons",
							name = "Enabled",
							type = "execute",
							func = function()
								print("|cffffff7fAddon list:|r")
								local AceCoreAddon = AceLibrary:HasInstance("AceCoreAddon-2.0") and AceLibrary("AceCoreAddon-2.0")
								local count = GetNumAddOns()
								for i = 1, count do
									local _,_,_,enabled,loadable = GetAddOnInfo(i)
									if enabled and loadable then
										listNormalAddon(i)
									end
								end
							end
						},
						disabled = {
							desc = "List all disabled addons",
							name = "Disabled",
							type = "execute",
							func = function()
								print("|cffffff7fAddon list:|r")
								local AceCoreAddon = AceLibrary:HasInstance("AceCoreAddon-2.0") and AceLibrary("AceCoreAddon-2.0")
								local count = GetNumAddOns()
								for i = 1, count do
									local _,_,_,enabled,loadable = GetAddOnInfo(i)
									if not enabled or not loadable then
										listNormalAddon(i)
									end
								end
							end
						},
						lod = {
							desc = "List all LoadOnDemand addons",
							name = "LoadOnDemand",
							type = "execute",
							func = function()
								print("|cffffff7fAddon list:|r")
								local AceCoreAddon = AceLibrary:HasInstance("AceCoreAddon-2.0") and AceLibrary("AceCoreAddon-2.0")
								local count = GetNumAddOns()
								for i = 1, count do
									if IsAddOnLoadOnDemand(i) then
										listNormalAddon(i)
									end
								end
							end
						},
						ace1 = {
							desc = "List all addons using Ace1",
							name = "Ace 1.x",
							type = "execute",
							func = function()
								print("|cffffff7fAddon list:|r")
								local count = GetNumAddOns()
								for i = 1, count do
									local dep1, dep2, dep3, dep4 = GetAddOnDependencies(i)
									if dep1 == "Ace" or dep2 == "Ace" or dep3 == "Ace" or dep4 == "Ace" then
										listNormalAddon(i)
									end
								end
							end
						},
						libs = {
							desc = "List all libraries using AceLibrary",
							name = "Libraries",
							type = "execute",
							func = function()
								if type(AceLibrary) == "table" and type(AceLibrary.libs) == "table" then
									print("|cffffff7fLibrary list:|r")
									for name, data in pairs(AceLibrary.libs) do
										local s
										if data.minor then
											s = " - " .. tostring(name) .. "." .. tostring(data.minor)
										else
											s = " - " .. tostring(name)
										end
										if AceLibrary(name).slashCommand then
											s = s .. " |cffffff7f(" .. tostring(AceLibrary(name).slashCommand) .. "|cffffff7f)"
										end
										print(s)
									end
								end
							end
						},
						search = {
							desc = "Search by name",
							name = "Search",
							type = "text",
							usage = "<keyword>",
							input = true,
							get = false,
							set = function(...)
								for i,v in ipairs(arg) do
									arg[i] = string.lower(string.gsub(string.gsub(v, '%*', '.*'), '%%', '%%%%'))
								end
								local count = GetNumAddOns()
								for i = 1, count do
									local name = GetAddOnInfo(i)
									local good = true
									for _,v in ipairs(arg) do
										if not string.find(string.lower(name), v) then
											good = false
											break
										end
									end
									if good then
										listNormalAddon(i)
									end
								end
							end
						}
					},
				},
				enable = {
					desc = "Enable addon",
					name = "Enable",
					type = "text",
					usage = "<addon>",
					get = false,
					set = function(text)
						local name,title,_,_,_,reason = GetAddOnInfo(text)
						if reason == "MISSING" then
							print(string.format("|cffffff7fAce2:|r AddOn %q does not exist", text))
						else
							EnableAddOn(text)
							print(string.format("|cffffff7fAce2:|r %s is now enabled", title or name))
						end
					end,
				},
				disable = {
					desc = "Disable addon",
					name = "Disable",
					type = "text",
					usage = "<addon>",
					get = false,
					set = function(text)
						local name,title,_,_,_,reason = GetAddOnInfo(text)
						if reason == "MISSING" then
							print(string.format("|cffffff7fAce2:|r AddOn %q does not exist", text))
						else
							DisableAddOn(text)
							print(string.format("|cffffff7fAce2:|r %s is now disabled", title or name))
						end
					end,
				},
				load = {
					desc = "Load addon",
					name = "Load",
					type = "text",
					usage = "<addon>",
					get = false,
					set = function(text)
						local name,title,_,_,loadable,reason = GetAddOnInfo(text)
						if reason == "MISSING" then
							print(string.format("|cffffff7fAce2:|r AddOn %q does not exist.", text))
						elseif not loadable then
							print(string.format("|cffffff7fAce2:|r AddOn %q is not loadable. Reason: %s", text, reason))
						else
							LoadAddOn(text)
							print(string.format("|cffffff7fAce2:|r %s is now loaded", title or name))
						end
					end
				},
				info = {
					desc = "Display information",
					name = "Information",
					type = "execute",
					func = function()
						local mem, threshold = gcinfo()
						print(string.format(" - |cffffff7fMemory usage [|r%.3f MiB|cffffff7f]|r", mem / 1024))
						print(string.format(" - |cffffff7fThreshold [|r%.3f MiB|cffffff7f]|r", threshold / 1024))
						print(string.format(" - |cffffff7fFramerate [|r%.0f fps|cffffff7f]|r", GetFramerate()))
						local bandwidthIn, bandwidthOut, latency = GetNetStats()
						bandwidthIn, bandwidthOut = floor(bandwidthIn * 1024), floor(bandwidthOut * 1024)
						print(string.format(" - |cffffff7fLatency [|r%.0f ms|cffffff7f]|r", latency))
						print(string.format(" - |cffffff7fBandwidth in [|r%.0f B/s|cffffff7f]|r", bandwidthIn))
						print(string.format(" - |cffffff7fBandwidth out [|r%.0f B/s|cffffff7f]|r", bandwidthOut))
						print(string.format(" - |cffffff7fTotal addons [|r%d|cffffff7f]|r", GetNumAddOns()))
						print(string.format(" - |cffffff7fAce2 addons [|r%d|cffffff7f]|r", table.getn(self.addons)))
						local ace = 0
						local enabled = 0
						local disabled = 0
						local lod = 0
						for i = 1, GetNumAddOns() do
							local dep1, dep2, dep3, dep4 = GetAddOnDependencies(i)
							if dep1 == "Ace" or dep2 == "Ace" or dep3 == "Ace" or dep4 == "Ace" then
								ace = ace + 1
							end
							if IsAddOnLoadOnDemand(i) then
								lod = lod + 1
							end
							local _,_,_,isEnabled,loadable = GetAddOnInfo(i)
							if not isEnabled or not loadable then
								disabled = disabled + 1
							else
								enabled = enabled + 1
							end
						end
						print(string.format(" - |cffffff7fAce 1.x addons [|r%d|cffffff7f]|r", ace))
						print(string.format(" - |cffffff7fLoadOnDemand addons [|r%d|cffffff7f]|r", lod))
						print(string.format(" - |cffffff7fenabled addons [|r%d|cffffff7f]|r", enabled))
						print(string.format(" - |cffffff7fdisabled addons [|r%d|cffffff7f]|r", disabled))
						local libs = 0
						if type(AceLibrary) == "table" and type(AceLibrary.libs) == "table" then
							for _ in pairs(AceLibrary.libs) do
								libs = libs + 1
							end
						end
						print(string.format(" - |cffffff7fAceLibrary instances [|r%d|cffffff7f]|r", libs))
					end
				}
			}
		})
		initChat = nil
	end
end

local nextAddon

local AceDB
function AceAddon:ADDON_LOADED(name)
	if not AceDB and AceLibrary:HasInstance("AceDB-2.0") then
		AceDB = AceLibrary("AceDB-2.0")
	end
	if type(nextAddon) == "table" then
		while table.getn(nextAddon) > 0 do
			local addon = table.remove(nextAddon, 1)
			table.insert(self.addons, addon)
			if not self.addons[name] then
				self.addons[name] = addon
			end
			self:InitializeAddon(addon, name)
		end
	elseif nextAddon then
		table.insert(self.addons, nextAddon)
		self.addons[name] = nextAddon
		self:InitializeAddon(nextAddon, name)
		nextAddon = nil
	end
end

function AceAddon:InitializeAddon(addon, name)
	if AceDB and AceOO.inherits(addon, AceDB) and type(addon.db) == "table" then
		AceDB.InitializeDB(addon)
	end
	
	if addon.name == nil then
		addon.name = name
	end
	if GetAddOnMetadata then
		-- TOC checks
		if addon.title == nil then
			addon.title = GetAddOnMetadata(name, "Title")
			if addon.title then
				local num = string.find(addon.title, " |cff7fff7f %-Ace2%-|r$")
				if num then
					addon.title = string.sub(addon.title, 1, num - 1)
				end
			end
		end
		if addon.notes == nil then
			addon.notes = GetAddOnMetadata(name, "Notes")
		end
		if addon.version == nil then
			addon.version = GetAddOnMetadata(name, "Version")
			if addon.version then
				if string.find(addon.version, "%$Revision: (%d+) %$") then
					addon.version = string.gsub(addon.version, "%$Revision: (%d+) %$", "%1")
				elseif string.find(addon.version, "%$Rev: (%d+) %$") then
					addon.version = string.gsub(addon.version, "%$Rev: (%d+) %$", "%1")
				elseif string.find(addon.version, "%$LastChangedRevision: (%d+) %$") then
					addon.version = string.gsub(addon.version, "%$LastChangedRevision: (%d+) %$", "%1")
				end
			end
		end
		if addon.author == nil then
			addon.author = GetAddOnMetadata(name, "Author")
		end
		if addon.date == nil then
			addon.date = GetAddOnMetadata(name, "X-Date") or GetAddOnMetadata(name, "X-ReleaseDate")
			if addon.date then
				if string.find(addon.date, "%$Date: (.-) %$") then
					addon.date = string.gsub(addon.date, "%$Date: (.-) %$", "%1")
				elseif string.find(addon.date, "%$LastChangedDate: (.-) %$") then
					addon.date = string.gsub(addon.date, "%$LastChangedDate: (.-) %$", "%1")
				end
			end
		end
		if addon.category == nil then
			addon.category = GetAddOnMetadata(name, "X-Category")
		end
		if addon.email == nil then
			addon.email = GetAddOnMetadata(name, "X-eMail") or GetAddOnMetadata(name, "X-Email")
		end
		if addon.website == nil then
			addon.website = GetAddOnMetadata(name, "X-Website")
		end
	end
	addon:OnInitialize()
end

function AceAddon.prototype:PrintAddonInfo()
	local x
	if self.title then
		x = "|cffffff7f" .. tostring(self.title) .. "|r"
	elseif self.name then
		x = "|cffffff7f" .. tostring(self.name) .. "|r"
	else
		x = "|cffffff7f<" .. tostring(self.class) .. " instance>|r"
	end
	if type(self.IsEnabled) == "function" then
		if not self:IsEnabled() then
			x = x .. " " .. STANDBY
		end
	end
	if self.version then
		x = x .. " - |cffffff7f" .. tostring(self.version) .. "|r"
	end
	if self.notes then
		x = x .. " - " .. tostring(self.notes)
	end
	print(x)
	if self.author then
		print(" - |cffffff7f" .. AUTHOR .. ":|r " .. tostring(self.author))
	end
	if self.date then
		print(" - |cffffff7f" .. DATE .. ":|r " .. tostring(self.date))
	end
	if self.category then
		local category = CATEGORIES[self.category]
		if category then
			print(" - |cffffff7f" .. CATEGORY .. ":|r " .. category)
		end
	end
	if self.email then
		print(" - |cffffff7f" .. EMAIL .. ":|r " .. tostring(self.email))
	end
	if self.website then
		print(" - |cffffff7f" .. WEBSITE .. ":|r " .. tostring(self.website))
	end
end

function AceAddon:PLAYER_LOGIN()
	self.playerLoginFired = true
	if self.pluginsToOnEnable then
		for plugin in pairs(self.pluginsToOnEnable) do
			if type(plugin.OnEnable) == "function" then
				plugin:OnEnable()
			end
		end
		self.pluginsToOnEnable = nil
	end
end

function AceAddon.prototype:Inject(t)
	if type(t) ~= "table" then
		error(string.format("Bad argument #2 to `Inject' (expected table, got %s)", tostring(type(t))), 2)
	end
	for k,v in pairs(t) do
		self[k] = v
	end
end

function AceAddon.prototype:init()
	if init then
		init(AceAddon, 4)
	end
	if initChat then
		initChat(AceAddon)
	end
	AceAddon.super.prototype.init(self)
	
	self.super = self.class.prototype
	
	AceAddon:RegisterEvent("ADDON_LOADED", "ADDON_LOADED", true)
	if nextAddon then
		table.insert(nextAddon, self)
	else
		nextAddon = {self}
	end
end

function AceAddon.prototype:OnInitialize(name)
	if self == AceAddon.prototype then
		error("Cannot call self.super:OnInitialize(). proper form is self.super.OnInitialize(self)", 2)
	end
	if type(self.OnEnable) == "function" then
		if type(self.IsEnabled) ~= "function" or self:IsEnabled() then
			if AceAddon.playerLoginFired then
				self:OnEnable()
			elseif DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.defaultLanguage then -- HACK
				self:OnEnable()
			elseif type(self.RegisterEvent) == "function" then
				self:RegisterEvent("PLAYER_LOGIN", "OnEnable", true)
			else
				if not AceAddon.pluginsToOnEnable then
					AceAddon.pluginsToOnEnable = {}
				end
				AceAddon.pluginsToOnEnable[self] = true
			end
		end
	end
end

function AceAddon.prototype:OnEnable()
	if self == AceAddon.prototype then
		error("Cannot call self.super:OnEnable(). proper form is self.super.OnEnable(self)", 2)
	end
end

function AceAddon.prototype:OnDisable()
	if self == AceAddon.prototype then
		error("Cannot call self.super:OnDisable(). proper form is self.super.OnDisable(self)", 2)
	end
end

function AceAddon.prototype:ToString()
	local x
	if type(self.title) == "string" then
		x = self.title
	elseif type(self.name) == "string" then
		x = self.name
	else
		x = "<" .. tostring(self.class) .. " instance>"
	end
	if type(self.IsEnabled) == "function" then
		if not self:IsEnabled() then
			x = x .. " " .. STANDBY
		end
	end
	return x
end

AceAddon.new = function(self, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15, m16, m17, m18, m19, m20)
	if init then
		init(self, 2)
	end
	local class = AceOO.Classpool(self, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15, m16, m17, m18, m19, m20)
	return class:new()
end

local function activate(self, oldLib, oldDeactivate)
	AceAddon = AceLibrary(MAJOR_VERSION)
	
	if oldLib then
		self.playerLoginFired = oldLib.playerLoginFired
		self.pluginsToOnEnable = oldLib.pluginsToOnEnable
		oldDeactivate(oldLib)
		self.addons = oldLib.addons
	else
		self.addons = {}
	end
	
	if init and AceLibrary:HasInstance("AceEvent-2.0") then
		init(self)
	end
	
	if initChat and AceLibrary:HasInstance("AceConsole-2.0") then
		initChat(self)
	end
end

AceLibrary:Register(AceAddon, MAJOR_VERSION, MINOR_VERSION, activate)
AceAddon = AceLibrary(MAJOR_VERSION)

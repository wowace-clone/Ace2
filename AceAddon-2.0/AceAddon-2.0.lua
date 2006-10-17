--[[
Name: AceAddon-2.0
Revision: $Rev$
Developed by: The Ace Development Team (http://www.wowace.com/index.php/The_Ace_Development_Team)
Inspired By: Ace 1.x by Turan (turan@gryphon.com)
Website: http://www.wowace.com/
Documentation: http://www.wowace.com/index.php/AceAddon-2.0
SVN: http://svn.wowace.com/root/trunk/Ace2/AceAddon-2.0
Description: Base for all Ace addons to inherit from.
Dependencies: AceLibrary, AceOO-2.0, AceEvent-2.0, (optional) AceConsole-2.0
]]

local MAJOR_VERSION = "AceAddon-2.0"
local MINOR_VERSION = "$Revision$"

-- This ensures the code is only executed if the libary doesn't already exist, or is a newer version
if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary.") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end

if not AceLibrary:HasInstance("AceOO-2.0") then error(MAJOR_VERSION .. " requires AceOO-2.0.") end

-- Localization
local STANDBY, TITLE, NOTES, VERSION, AUTHOR, DATE, CATEGORY, EMAIL, WEBSITE, CATEGORIES, ABOUT, PRINT_ADDON_INFO
if GetLocale() == "deDE" then
	STANDBY = "|cffff5050(Standby)|r" -- capitalized

	TITLE = "Titel"
	NOTES = "Anmerkung"
	VERSION = "Version"
	AUTHOR = "Autor"
	DATE = "Datum"
	CATEGORY = "Kategorie"
	EMAIL = "E-mail"
	WEBSITE = "Webseite"
		 
	ABOUT = "\195\188ber"
	PRINT_ADDON_INFO = "Gibt Addondaten aus"

	CATEGORIES = {
		["Action Bars"] = "Aktionsleisten",
		["Auction"] = "Auktion",
		["Audio"] = "Audio",
		["Battlegrounds/PvP"] = "Schlachtfeld/PvP",
		["Buffs"] = "Buffs",
		["Chat/Communication"] = "Chat/Kommunikation",
		["Druid"] = "Druide",
		["Hunter"] = "Jไger",
		["Mage"] = "Magier",
		["Paladin"] = "Paladin",
		["Priest"] = "Priester",
		["Rogue"] = "Schurke",
		["Shaman"] = "Schamane",
		["Warlock"] = "Hexenmeister",
		["Warrior"] = "Krieger",
		["Healer"] = "Heiler",
		["Tank"] = "Tank", -- noone use "Brecher"...
		["Caster"] = "Caster",
		["Combat"] = "Kampf",
		["Compilations"] = "Compilations", -- whats that o_O
		["Data Export"] = "Datenexport",
		["Development Tools"] = "Entwicklungs Tools",
		["Guild"] = "Gilde",
		["Frame Modification"] = "Frame Modifikation",
		["Interface Enhancements"] = "Interface Verbesserungen",
		["Inventory"] = "Inventar",
		["Library"] = "Library",
		["Map"] = "Map",
		["Mail"] = "Mail",
		["Miscellaneous"] = "Diverses",
		["Quest"] = "Quest",
		["Raid"] = "Schlachtzug",
		["Tradeskill"] = "Handelsf\195\164higkeit",
		["UnitFrame"] = "UnitFrame",
	}
elseif GetLocale() == "koKR" then
	STANDBY = "|cffff5050(์ฌ์ฉ๊ฐ๋ฅ)|r"
	
	TITLE = "์ ๋ชฉ"
	NOTES = "๋ธํธ"
	VERSION = "๋ฒ์ "
	AUTHOR = "์ ์์"
	DATE = "๋ ์ง"
	CATEGORY = "๋ถ๋ฅ"
	EMAIL = "E-mail"
	WEBSITE = "์น์ฌ์ดํธ"
	
	ABOUT = "์ ๋ณด"
	PRINT_ADDON_INFO = "์ ๋์จ ์ ๋ณด ์ถ๋ ฅ"
	
	CATEGORIES = {
		["Action Bars"] = "์ก์๋ฐ",
		["Auction"] = "๊ฒฝ๋งค",
		["Audio"] = "์ํฅ",
		["Battlegrounds/PvP"] = "์ ์ฅ/PvP",
		["Buffs"] = "๋ฒํ",
		["Chat/Communication"] = "๋ํ/์์ฌ์ํต",
		["Druid"] = "๋๋ฃจ์ด๋",
		["Hunter"] = "์ฌ๋ฅ๊พผ",
		["Mage"] = "๋ง๋ฒ์ฌ",
		["Paladin"] = "์ฑ๊ธฐ์ฌ",
		["Priest"] = "์ฌ์ ",
		["Rogue"] = "๋์ ",
		["Shaman"] = "์ฃผ์ ์ฌ",
		["Warlock"] = "ํ๋ง๋ฒ์ฌ",
		["Warrior"] = "์ ์ฌ",
		["Healer"] = "ํ๋ฌ",
		["Tank"] = "ํฑ์ปค",
		["Caster"] = "์บ์คํฐ",
		["Combat"] = "์ ํฌ",
		["Compilations"] = "๋ณตํฉ",
		["Data Export"] = "์๋ฃ ์ถ๋ ฅ",
		["Development Tools"] = "๊ฐ๋ฐ ๋๊ตฌ",
		["Guild"] = "๊ธธ๋",
		["Frame Modification"] = "๊ตฌ์กฐ ๋ณ๊ฒฝ",
		["Interface Enhancements"] = "์ธํฐํ์ด์ค ๊ฐํ",
		["Inventory"] = "์ธ๋ฒคํ ๋ฆฌ",
		["Library"] = "๋ผ์ด๋ธ๋ฌ๋ฆฌ",
		["Map"] = "์ง๋",
		["Mail"] = "์ฐํธ",
		["Miscellaneous"] = "๊ธฐํ",
		["Quest"] = "ํ์คํธ",
		["Raid"] = "๊ณต๊ฒฉ๋",
		["Tradeskill"] = "์ ๋ฌธ๊ธฐ์ ",
		["UnitFrame"] = "์ ๋ ํ๋ ์",
	}
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
	
	ABOUT = "About"
	PRINT_ADDON_INFO = "Print out addon info"
	
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
		["Development Tools"] = "Development Tools",
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
local AceEvent
local AceConsole
local AceModuleCore

function AceAddon:ToString()
	return "AceAddon"
end

local function print(text)
	DEFAULT_CHAT_FRAME:AddMessage(text)
end

function AceAddon:ADDON_LOADED(name)
	while table.getn(self.nextAddon) > 0 do
		local addon = table.remove(self.nextAddon, 1)
		table.insert(self.addons, addon)
		if not self.addons[name] then
			self.addons[name] = addon
		end
		self:InitializeAddon(addon, name)
	end
end

local function RegisterOnEnable(self)
	if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.defaultLanguage then -- HACK
		AceAddon.playerLoginFired = true
	end
	if AceAddon.playerLoginFired then
		AceAddon.addonsStarted[self] = true
		if (type(self.IsActive) ~= "function" or self:IsActive()) and (not AceModuleCore or not AceModuleCore:IsModule(self) or AceModuleCore:IsModuleActive(self)) then
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
		end
	else
		if not AceAddon.addonsToOnEnable then
			AceAddon.addonsToOnEnable = {}
		end
		table.insert(AceAddon.addonsToOnEnable, self)
	end
end

local function stripSpaces(text)
	if type(text) == "string" then
		return (string.gsub(string.gsub(text, "^%s*(.-)%s*$", "%1"), "%s%s+", " "))
	end
	return text
end

function AceAddon:InitializeAddon(addon, name)
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
				addon.title = stripSpaces(addon.title)
			end
		end
		if addon.notes == nil then
			addon.notes = GetAddOnMetadata(name, "Notes")
			addon.notes = stripSpaces(addon.notes)
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
			addon.version = stripSpaces(addon.version)
		end
		if addon.author == nil then
			addon.author = GetAddOnMetadata(name, "Author")
			addon.author = stripSpaces(addon.author)
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
			addon.date = stripSpaces(addon.date)
		end
		if addon.category == nil then
			addon.category = GetAddOnMetadata(name, "X-Category")
			addon.category = stripSpaces(addon.category)
		end
		if addon.email == nil then
			addon.email = GetAddOnMetadata(name, "X-eMail") or GetAddOnMetadata(name, "X-Email")
			addon.email = stripSpaces(addon.email)
		end
		if addon.website == nil then
			addon.website = GetAddOnMetadata(name, "X-Website")
			addon.website = stripSpaces(addon.website)
		end
	end
	local current = addon.class
	while true do
		if current == AceOO.Class then
			break
		end
		if current.mixins then
			for mixin in pairs(current.mixins) do
				if type(mixin.OnEmbedInitialize) == "function" then
					mixin:OnEmbedInitialize(addon, name)
				end
			end
		end
		current = current.super
	end
	if type(addon.OnInitialize) == "function" then
		addon:OnInitialize(name)
	end
	RegisterOnEnable(addon)
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
	if type(self.IsActive) == "function" then
		if not self:IsActive() then
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

local options
function AceAddon:GetAceOptionsDataTable(target)
	if not options then
		options = {
			about = {
				name = ABOUT,
				desc = PRINT_ADDON_INFO,
				type = "execute",
				func = "PrintAddonInfo",
				order = -1,
			}
		}
	end
	return options
end

function AceAddon:PLAYER_LOGIN()
	self.playerLoginFired = true
	if self.addonsToOnEnable then
		while table.getn(self.addonsToOnEnable) > 0 do
			local addon = table.remove(self.addonsToOnEnable, 1)
			self.addonsStarted[addon] = true
			if (type(addon.IsActive) ~= "function" or addon:IsActive()) and (not AceModuleCore or not AceModuleCore:IsModule(addon) or AceModuleCore:IsModuleActive(addon)) then
				local current = addon.class
				while true do
					if current == AceOO.Class then
						break
					end
					if current.mixins then
						for mixin in pairs(current.mixins) do
							if type(mixin.OnEmbedEnable) == "function" then
								mixin:OnEmbedEnable(addon)
							end
						end
					end
					current = current.super
				end
				if type(addon.OnEnable) == "function" then
					addon:OnEnable()
				end
			end
		end
		self.addonsToOnEnable = nil
	end
end

function AceAddon.prototype:Inject(t)
	AceAddon:argCheck(t, 2, "table")
	for k,v in pairs(t) do
		self[k] = v
	end
end

function AceAddon.prototype:init()
	if not AceEvent then
		error(MAJOR_VERSION .. " requires AceEvent-2.0", 4)
	end
	AceAddon.super.prototype.init(self)
	
	self.super = self.class.prototype
	
	AceAddon:RegisterEvent("ADDON_LOADED", "ADDON_LOADED", true)
	table.insert(AceAddon.nextAddon, self)
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
	if (type(self.IsActive) == "function" and not self:IsActive()) or (AceModuleCore and AceModuleCore:IsModule(addon) and AceModuleCore:IsModuleActive(addon)) then
		x = x .. " " .. STANDBY
	end
	return x
end

AceAddon.new = function(self, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15, m16, m17, m18, m19, m20)
	local class = AceAddon:pcall(AceOO.Classpool, self, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15, m16, m17, m18, m19, m20)
	return class:new()
end

local function external(self, major, instance)
	if major == "AceEvent-2.0" then
		AceEvent = instance
		
		AceEvent:embed(self)
		
		self:RegisterEvent("PLAYER_LOGIN", "PLAYER_LOGIN", true)
	elseif major == "AceConsole-2.0" then
		AceConsole = instance
		
		local slashCommands = { "/ace2" }
		local _,_,_,enabled,loadable = GetAddOnInfo("Ace")
		if not enabled or not loadable then
			table.insert(slashCommands, "/ace")
		end
		local function listAddon(addon, depth)
			if not depth then
				depth = 0
			end
			
			local s = string.rep("  ", depth) .. " - " .. tostring(addon)
			if rawget(addon, 'version') then
				s = s .. " - |cffffff7f" .. tostring(addon.version) .. "|r"
			end
			if rawget(addon, 'slashCommand') then
				s = s .. " |cffffff7f(" .. tostring(addon.slashCommand) .. ")|r"
			end
			print(s)
			if type(rawget(addon, 'modules')) == "table" then
				local i = 0
				for k,v in pairs(addon.modules) do
					i = i + 1
					if i == 6 then
						print(string.rep("  ", depth + 1) .. " - more...")
						break
					else
						listAddon(v, depth + 1)
					end
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
							local _,_,_,IsActive,loadable = GetAddOnInfo(i)
							if not IsActive or not loadable then
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
	elseif major == "AceModuleCore-2.0" then
		AceModuleCore = instance
	end
end

local function activate(self, oldLib, oldDeactivate)
	AceAddon = self
	
	if oldLib then
		self.playerLoginFired = oldLib.playerLoginFired or DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.defaultLanguage
		self.addonsToOnEnable = oldLib.addonsToOnEnable
		self.addons = oldLib.addons
		self.nextAddon = oldLib.nextAddon
		self.addonsStarted = oldLib.addonsStarted
	end
	if not self.addons then
		self.addons = {}
	end
	if not self.nextAddon then
		self.nextAddon = {}
	end
	if not self.addonsStarted then
		self.addonsStarted = {}
	end
	if oldDeactivate then
		oldDeactivate(oldLib)
	end
end

AceLibrary:Register(AceAddon, MAJOR_VERSION, MINOR_VERSION, activate, nil, external)
AceAddon = AceLibrary(MAJOR_VERSION)

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

local function safecall(func,...)
	local success, err = pcall(func,...)
	if not success then geterrorhandler()(err) end
end
-- Localization
local STANDBY, TITLE, NOTES, VERSION, AUTHOR, DATE, CATEGORY, EMAIL, CREDITS, WEBSITE, CATEGORIES, ABOUT, PRINT_ADDON_INFO
if GetLocale() == "deDE" then
	STANDBY = "|cffff5050(Standby)|r" -- capitalized

	TITLE = "Titel"
	NOTES = "Anmerkung"
	VERSION = "Version"
	AUTHOR = "Autor"
	DATE = "Datum"
	CATEGORY = "Kategorie"
	EMAIL = "E-Mail"
	WEBSITE = "Webseite"
	CREDITS = "Credits" -- fix

	ABOUT = "\195\156ber"
	PRINT_ADDON_INFO = "Gibt Addondaten aus"

	CATEGORIES = {
		["Action Bars"] = "Aktionsleisten",
		["Auction"] = "Auktion",
		["Audio"] = "Audio",
		["Battlegrounds/PvP"] = "Schlachtfeld/PvP",
		["Buffs"] = "St\195\164rkungszauber",
		["Chat/Communication"] = "Chat/Kommunikation",
		["Druid"] = "Druide",
		["Hunter"] = "J\195\164ger",
		["Mage"] = "Magier",
		["Paladin"] = "Paladin",
		["Priest"] = "Priester",
		["Rogue"] = "Schurke",
		["Shaman"] = "Schamane",
		["Warlock"] = "Hexenmeister",
		["Warrior"] = "Krieger",
		["Healer"] = "Heiler",
		["Tank"] = "Tank",
		["Caster"] = "Zauberer",
		["Combat"] = "Kampf",
		["Compilations"] = "Zusammenstellungen",
		["Data Export"] = "Datenexport",
		["Development Tools"] = "Entwicklungs Tools",
		["Guild"] = "Gilde",
		["Frame Modification"] = "Frame Ver\195\164nderungen",
		["Interface Enhancements"] = "Interface Verbesserungen",
		["Inventory"] = "Inventar",
		["Library"] = "Bibliotheken",
		["Map"] = "Karte",
		["Mail"] = "Post",
		["Miscellaneous"] = "Diverses",
		["Quest"] = "Quest",
		["Raid"] = "Schlachtzug",
		["Tradeskill"] = "Beruf",
		["UnitFrame"] = "Einheiten-Fenster",
	}
elseif GetLocale() == "frFR" then
	STANDBY = "|cffff5050(attente)|r"
	
	TITLE = "Titre"
	NOTES = "Notes"
	VERSION = "Version"
	AUTHOR = "Auteur"
	DATE = "Date"
	CATEGORY = "Cat\195\169gorie"
	EMAIL = "E-mail"
	WEBSITE = "Site web"
	CREDITS = "Credits" -- fix
	
	ABOUT = "A propos"
	PRINT_ADDON_INFO = "Afficher les informations sur l'addon"
	
	CATEGORIES = {
		["Action Bars"] = "Barres d'action",
		["Auction"] = "H\195\180tel des ventes",
		["Audio"] = "Audio",
		["Battlegrounds/PvP"] = "Champs de bataille/JcJ",
		["Buffs"] = "Buffs",
		["Chat/Communication"] = "Chat/Communication",
		["Druid"] = "Druide",
		["Hunter"] = "Chasseur",
		["Mage"] = "Mage",
		["Paladin"] = "Paladin",
		["Priest"] = "Pr\195\170tre",
		["Rogue"] = "Voleur",
		["Shaman"] = "Chaman",
		["Warlock"] = "D\195\169moniste",
		["Warrior"] = "Guerrier",
		["Healer"] = "Soigneur",
		["Tank"] = "Tank",
		["Caster"] = "Casteur",
		["Combat"] = "Combat",
		["Compilations"] = "Compilations",
		["Data Export"] = "Exportation de donn\195\169es",
		["Development Tools"] = "Outils de d\195\169veloppement",
		["Guild"] = "Guilde",
		["Frame Modification"] = "Modification des fen\195\170tres",
		["Interface Enhancements"] = "Am\195\169liorations de l'interface",
		["Inventory"] = "Inventaire",
		["Library"] = "Biblioth\195\168ques",
		["Map"] = "Carte",
		["Mail"] = "Courrier",
		["Miscellaneous"] = "Divers",
		["Quest"] = "Qu\195\170tes",
		["Raid"] = "Raid",
		["Tradeskill"] = "M\195\169tiers",
		["UnitFrame"] = "Fen\195\170tres d'unit\195\169",
	}
elseif GetLocale() == "koKR" then
	STANDBY = "|cffff5050(????)|r"
	
	TITLE = "??"
	NOTES = "??"
	VERSION = "??"
	AUTHOR = "???"
	DATE = "??"
	CATEGORY = "??"
	EMAIL = "E-mail"
	WEBSITE = "????"
	CREDITS = "Credits" -- fix
	
	ABOUT = "??"
	PRINT_ADDON_INFO = "??? ?? ??"
	
	CATEGORIES = {
		["Action Bars"] = "???",
		["Auction"] = "??",
		["Audio"] = "??",
		["Battlegrounds/PvP"] = "??/PvP",
		["Buffs"] = "??",
		["Chat/Communication"] = "??/????",
		["Druid"] = "????",
		["Hunter"] = "???",
		["Mage"] = "???",
		["Paladin"] = "???",
		["Priest"] = "??",
		["Rogue"] = "??",
		["Shaman"] = "???",
		["Warlock"] = "????",
		["Warrior"] = "??",
		["Healer"] = "??",
		["Tank"] = "??",
		["Caster"] = "???",
		["Combat"] = "??",
		["Compilations"] = "??",
		["Data Export"] = "?? ??",
		["Development Tools"] = "?? ??",
		["Guild"] = "??",
		["Frame Modification"] = "?? ??",
		["Interface Enhancements"] = "????? ??",
		["Inventory"] = "????",
		["Library"] = "?????",
		["Map"] = "??",
		["Mail"] = "??",
		["Miscellaneous"] = "??",
		["Quest"] = "???",
		["Raid"] = "???",
		["Tradeskill"] = "????",
		["UnitFrame"] = "?? ???",
	}
elseif GetLocale() == "zhTW" then
	STANDBY = "|cffff5050(??)|r"
	
	TITLE = "??"
	NOTES = "??"
	VERSION = "??"
	AUTHOR = "??"
	DATE = "??"
	CATEGORY = "??"
	EMAIL = "E-mail"
	WEBSITE = "??"
	CREDITS = "Credits" -- fix
	
	ABOUT = "??"
	PRINT_ADDON_INFO = "??????"
	
	CATEGORIES = {
		["Action Bars"] = "???",
		["Auction"] = "??",
		["Audio"] = "??",
		["Battlegrounds/PvP"] = "??/PvP",
		["Buffs"] = "??",
		["Chat/Communication"] = "??/??",
		["Druid"] = "???",
		["Hunter"] = "??",
		["Mage"] = "??",
		["Paladin"] = "???",
		["Priest"] = "??",
		["Rogue"] = "??",
		["Shaman"] = "??",
		["Warlock"] = "??",
		["Warrior"] = "??",
		["Healer"] = "???",
		["Tank"] = "??",
		["Caster"] = "???",
		["Combat"] = "??",
		["Compilations"] = "??",
		["Data Export"] = "????",
		["Development Tools"] = "????",
		["Guild"] = "??",
		["Frame Modification"] = "????",
		["Interface Enhancements"] = "????",
		["Inventory"] = "??",
		["Library"] = "???",
		["Map"] = "??",
		["Mail"] = "??",
		["Miscellaneous"] = "??",
		["Quest"] = "??",
		["Raid"] = "??",
		["Tradeskill"] = "????",
		["UnitFrame"] = "????",
	}
elseif GetLocale() == "zhCN" then
	STANDBY = "|cffff5050(\230\154\130\230\140\130)|r"
	
	TITLE = "\230\160\135\233\162\152"
	NOTES = "\233\153\132\230\179\168"
	VERSION = "\231\137\136\230\156\172"
	AUTHOR = "\228\189\156\232\128\133"
	DATE = "\230\151\165\230\156\159"
	CATEGORY = "\229\136\134\231\177\187"
	EMAIL = "\231\148\181\229\173\144\233\130\174\228\187\182"
	WEBSITE = "\231\189\145\231\171\153"
	CREDITS = "Credits" -- fix
	
	ABOUT = "\229\133\179\228\186\142"
	PRINT_ADDON_INFO = "\229\141\176\229\136\151\229\135\186\230\143\146\228\187\182\228\191\161\230\129\175"
	
	CATEGORIES = {
		["Action Bars"] = "\229\138\168\228\189\156\230\157\161",
		["Auction"] = "\230\139\141\229\141\150",
		["Audio"] = "\233\159\179\233\162\145",
		["Battlegrounds/PvP"] = "\230\136\152\229\156\186/PvP",
		["Buffs"] = "\229\162\158\231\155\138\233\173\148\230\179\149",
		["Chat/Communication"] = "\232\129\138\229\164\169/\228\186\164\230\181\129",
		["Druid"] = "\229\190\183\233\178\129\228\188\138",
		["Hunter"] = "\231\140\142\228\186\186",
		["Mage"] = "\230\179\149\229\184\136",
		["Paladin"] = "\229\156\163\233\170\145\229\163\171",
		["Priest"] = "\231\137\167\229\184\136",
		["Rogue"] = "\231\155\151\232\180\188",
		["Shaman"] = "\232\144\168\230\187\161\231\165\173\229\143\184",
		["Warlock"] = "\230\156\175\229\163\171",
		["Warrior"] = "\230\136\152\229\163\171",
--		["Healer"] = "\230\178\187\231\150\151\228\191\157\233\154\156",
--		["Tank"] = "\232\191\145\230\136\152\230\142\167\229\136\182",
--		["Caster"] = "\232\191\156\231\168\139\232\190\147\229\135\186",
		["Combat"] = "\230\136\152\230\150\151",
		["Compilations"] = "\231\188\150\232\175\145",
		["Data Export"] = "\230\149\176\230\141\174\229\175\188\229\135\186",
		["Development Tools"] = "\229\188\128\229\143\145\229\183\165\229\133\183",
		["Guild"] = "\229\133\172\228\188\154",
		["Frame Modification"] = "\230\161\134\230\158\182\228\191\174\230\148\185",
		["Interface Enhancements"] = "\231\149\140\233\157\162\229\162\158\229\188\186",
		["Inventory"] = "\232\131\140\229\140\133",
		["Library"] = "\229\186\147",
		["Map"] = "\229\156\176\229\155\190",
		["Mail"] = "\233\130\174\228\187\182",
		["Miscellaneous"] = "\230\157\130\233\161\185",
		["Quest"] = "\228\187\187\229\138\161",
		["Raid"] = "\229\155\162\233\152\159",
		["Tradeskill"] = "\229\149\134\228\184\154\230\138\128\232\131\189",
		["UnitFrame"] = "\229\164\180\229\131\143\230\161\134\230\158\182",
	}
elseif GetLocale() == "esES" then
	STANDBY = "|cffff5050(espera)|r"

	TITLE = "T\195\173tulo"
	NOTES = "Notas"
	VERSION = "Versi\195\179n"
	AUTHOR = "Autor"
	DATE = "Fecha"
	CATEGORY = "Categor\195\173a"
	EMAIL = "E-mail"
	WEBSITE = "Web"
	CREDITS = "Cr\195\169ditos"

	ABOUT = "Acerca de"
	PRINT_ADDON_INFO = "Muestra informaci\195\179n acerca del accesorio."

	CATEGORIES = {
		["Action Bars"] = "Barras de Acci\195\179n",
		["Auction"] = "Subasta",
		["Audio"] = "Audio",
		["Battlegrounds/PvP"] = "Campos de Batalla/PvP",
		["Buffs"] = "Buffs",
		["Chat/Communication"] = "Chat/Comunicaci\195\179n",
		["Druid"] = "Druida",
		["Hunter"] = "Cazador",
		["Mage"] = "Mago",
		["Paladin"] = "Palad\195\173n",
		["Priest"] = "Sacerdote",
		["Rogue"] = "P\195\173caro",
		["Shaman"] = "Cham\195\161n",
		["Warlock"] = "Brujo",
		["Warrior"] = "Guerrero",
		["Healer"] = "Sanador",
		["Tank"] = "Tanque",
		["Caster"] = "Conjurador",
		["Combat"] = "Combate",
		["Compilations"] = "Compilaciones",
		["Data Export"] = "Exportar Datos",
		["Development Tools"] = "Herramientas de Desarrollo",
		["Guild"] = "Hermandad",
		["Frame Modification"] = "Modificaci\195\179n de Marcos",
		["Interface Enhancements"] = "Mejoras de la Interfaz",
		["Inventory"] = "Inventario",
		["Library"] = "Biblioteca",
		["Map"] = "Mapa",
		["Mail"] = "Correo",
		["Miscellaneous"] = "Miscel\195\161neo",
		["Quest"] = "Misi\195\179n",
		["Raid"] = "Banda",
		["Tradeskill"] = "Habilidad de Comercio",
		["UnitFrame"] = "Marco de Unidades",
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
	CREDITS = "Credits"
	
	ABOUT = "About"
	PRINT_ADDON_INFO = "Show information about the addon."
	
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
	local lowerKey = key:lower()
	for k,v in pairs(CATEGORIES) do
		if k:lower() == lowerKey then
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

function AceAddon:GetLocalizedCategory(name)
	self:argCheck(name, 2, "string")
	return CATEGORIES[name] or UNKNOWN
end

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
							safecall(mixin.OnEmbedEnable,mixin,self)
						end
					end
				end
				current = current.super
			end
			if type(self.OnEnable) == "function" then
				safecall(self.OnEnable,self)
			end
			if AceEvent then
				AceEvent:TriggerEvent("Ace2_AddonEnabled", self)
			end
		end
	else
		if not AceAddon.addonsToOnEnable then
			AceAddon.addonsToOnEnable = {}
		end
		table.insert(AceAddon.addonsToOnEnable, self)
	end
end

function AceAddon:InitializeAddon(addon, name)
	if addon.name == nil then
		addon.name = name
	end
	if GetAddOnMetadata then
		-- TOC checks
		if addon.title == nil then
			addon.title = GetAddOnMetadata(name, "Title")
		end
		if type(addon.title) == "string" then
			local num = addon.title:find(" |cff7fff7f %-Ace2%-|r$")
			if num then
				addon.title = addon.title:sub(1, num - 1)
			end
			addon.title = addon.title:trim()
		end
		if addon.notes == nil then
			addon.notes = GetAddOnMetadata(name, "Notes")
		end
		if type(addon.notes) == "string" then
			addon.notes = addon.notes:trim()
		end
		if addon.version == nil then
			addon.version = GetAddOnMetadata(name, "Version")
		end	
		if type(addon.version) == "string" then
			if addon.version:find("%$Revision: (%d+) %$") then
				addon.version = addon.version:gsub("%$Revision: (%d+) %$", "%1")
			elseif addon.version:find("%$Rev: (%d+) %$") then
				addon.version = addon.version:gsub("%$Rev: (%d+) %$", "%1")
			elseif addon.version:find("%$LastChangedRevision: (%d+) %$") then
				addon.version = addon.version:gsub("%$LastChangedRevision: (%d+) %$", "%1")
			end
			addon.version = addon.version:trim()
		end
		if addon.author == nil then
			addon.author = GetAddOnMetadata(name, "Author")
		end
		if type(addon.author) == "string" then
			addon.author = addon.author:trim()
		end
		if addon.credits == nil then
			addon.credits = GetAddOnMetadata(name, "X-Credits")
		end
		if type(addon.credits) == "string" then
			addon.credits = addon.credits:trim()
		end
		if addon.date == nil then
			addon.date = GetAddOnMetadata(name, "X-Date") or GetAddOnMetadata(name, "X-ReleaseDate")
		end
		if type(addon.date) == "string" then
			if addon.date:find("%$Date: (.-) %$") then
				addon.date = addon.date:gsub("%$Date: (.-) %$", "%1")
			elseif addon.date:find("%$LastChangedDate: (.-) %$") then
				addon.date = addon.date:gsub("%$LastChangedDate: (.-) %$", "%1")
			end
			addon.date = addon.date:trim()
		end

		if addon.category == nil then
			addon.category = GetAddOnMetadata(name, "X-Category")
		end
		if type(addon.category) == "string" then
			addon.category = addon.category:trim()
		end
		if addon.email == nil then
			addon.email = GetAddOnMetadata(name, "X-eMail") or GetAddOnMetadata(name, "X-Email")
		end
		if type(addon.email) == "string" then
			addon.email = addon.email:trim()
		end
		if addon.website == nil then
			addon.website = GetAddOnMetadata(name, "X-Website")
		end
		if type(addon.website) == "string" then
			addon.website = addon.website:trim()
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
		safecall(addon.OnInitialize, addon, name)
	end
	if AceEvent then
		AceEvent:TriggerEvent("Ace2_AddonInitialized", addon)
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
	if self.credits then
		print(" - |cffffff7f" .. CREDITS .. ":|r " .. tostring(self.credits))
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
								safecall(mixin.OnEmbedEnable,mixin,addon)
							end
						end
					end
					current = current.super
				end
				if type(addon.OnEnable) == "function" then
					safecall(addon.OnEnable,addon)
				end
				if AceEvent then
					AceEvent:TriggerEvent("Ace2_AddonEnabled", addon)
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

AceAddon.new = function(self, ...)
	local class = AceAddon:pcall(AceOO.Classpool, self, ...)
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
			
			local s = ("  "):rep(depth) .. " - " .. tostring(addon)
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
						print(("  "):rep(depth + 1) .. " - more...")
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
					if version:find("%$Revision: (%d+) %$") then
						version = version:gsub("%$Revision: (%d+) %$", "%1")
					elseif version:find("%$Rev: (%d+) %$") then
						version = version:gsub("%$Rev: (%d+) %$", "%1")
					elseif version:find("%$LastChangedRevision: (%d+) %$") then
						version = version:gsub("%$LastChangedRevision: (%d+) %$", "%1")
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
						print("|cffffff7fAce2|r - |cffffff7f2.0." .. MINOR_VERSION:gsub("%$Revision: (%d+) %$", "%1") .. "|r - AddOn development framework")
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
										if rawget(AceLibrary(name), 'slashCommand') then
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
								local arg = { ... }
								for i,v in ipairs(arg) do
									arg[i] = v:gsub('%*', '.*'):gsub('%%', '%%%%'):lower()
								end
								local count = GetNumAddOns()
								for i = 1, count do
									local name = GetAddOnInfo(i)
									local good = true
									for _,v in ipairs(arg) do
										if not name:lower():find(v) then
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
						local name,title,_,enabled,_,reason = GetAddOnInfo(text)
						if reason == "MISSING" then
							print(string.format("|cffffff7fAce2:|r AddOn %q does not exist", text))
						elseif not enabled then
							EnableAddOn(text)
							print(string.format("|cffffff7fAce2:|r %s is now enabled", title or name))
						else
							print(string.format("|cffffff7fAce2:|r %s is already enabled", title or name))
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
						local name,title,_,enabled,_,reason = GetAddOnInfo(text)
						if reason == "MISSING" then
							print(string.format("|cffffff7fAce2:|r AddOn %q does not exist", text))
						elseif enabled then
							DisableAddOn(text)
							print(string.format("|cffffff7fAce2:|r %s is now disabled", title or name))
						else
							print(string.format("|cffffff7fAce2:|r %s is already disabled", title or name))
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
						if threshold then
							print(string.format(" - |cffffff7fThreshold [|r%.3f MiB|cffffff7f]|r", threshold / 1024))
						end
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

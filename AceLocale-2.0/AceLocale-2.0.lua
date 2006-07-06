--[[
Name: AceLocale-2.0
Revision: $Rev$
Author(s): ckknight (ckknight@gmail.com)
Website: http://www.wowace.com/
Documentation: http://wiki.wowace.com/index.php/AceLocale-2.0
SVN: http://svn.wowace.com/root/trunk/Ace2/AceLocale-2.0
Description: Localization library for addons to use to handle proper
             localization and internationalization.
Dependencies: AceLibrary
]]

local MAJOR_VERSION = "AceLocale-2.0"
local MINOR_VERSION = "$Revision$"

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary.") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end

local AceLocale = {}

local DEFAULT_LOCALE = "enUS"
local _G = getfenv(0)

function AceLocale:new(name, strict, baseLocale)
	self:argCheck(name, 2, "string")
	self:argCheck(strict, 3, "boolean", "nil")
	self:argCheck(baseLocale, 4, "string", "nil")
	
	local self = setmetatable({}, {
		__index = self.prototype,
		__call = strict and self.prototype.GetTranslationStrict or self.prototype.GetTranslation,
		__tostring = function(self)
			if type(self.GetLibraryVersion) == "function" then
				return self:GetLibraryVersion()
			else
				return "AceLocale(" .. name .. ")"
			end
		end
	})
	
	if not baseLocale then
		baseLocale = DEFAULT_LOCALE
	end
	if type(_G[name .. "_Locale_" .. baseLocale]) ~= "function" then
		self:error("You have not provided adequate translations. You must at least have global function %s_Locale_%s that returns a translation table.", name, baseLocale)
	end
	local locale = GetLocale()
	local func = _G[name .. "_Locale_" .. locale]
	if harsh then
		if type(func) == "function" then
			self.translations = func()
		elseif func == nil then
			self.translations = {}
		end
	else
		if type(func) ~= "function" then
			func = _G[name .. "_Locale_" .. baseLocale]
		end
		self.translations = func()
	end
	if type(self.translations) ~= "table" then
		self:error("You have not provided adequate translations. You must at least have global function %s that returns a translation table.", name .. "_Locale_" .. baseLocale)
	end
	if func == _G[name .. "_Locale_" .. baseLocale] then
		self.baseTranslations = self.translations
	else
		self.baseTranslations = _G[name .. "_Locale_" .. baseLocale]()
	end
	if type(self.baseTranslations) ~= "table" then
		self:error("You have not provided adequate translations. You must at least have global function %s that returns a translation table.", name .. "_Locale_" .. baseLocale)
	end
	
	if locale ~= baseLocale then
		for key in pairs(self.translations) do
			if not self.baseTranslations[key] then
				error("Improper translation exists. %q is likely misspelled for locale %s.", key, locale)
				break
			end
		end
	end
	_G[name .. "_Locale_enUS"] = nil
	_G[name .. "_Locale_deDE"] = nil
	_G[name .. "_Locale_frFR"] = nil
	_G[name .. "_Locale_zhCN"] = nil
	_G[name .. "_Locale_zhTW"] = nil
	_G[name .. "_Locale_koKR"] = nil
	
	return self
end

AceLocale.prototype = {}
AceLocale.prototype.class = AceLocale

function AceLocale.prototype:GetTranslationStrict(text, sublevel)
	AceLocale.argCheck(self, text, 1, "string")
	if sublevel then
		AceLocale.argCheck(self, sublevel, 2, "string")
		local t = self.translations[text]
		if type(t) ~= "table" then
			if type(self.baseTranslations[text]) == "table" then
				AceLocale:error("%q::%q has not been translated into %q", text, sublevel, locale)
				return
			else
				AceLocale:error("Translation for %q::%q does not exist", text, sublevel)
				return
			end
		end
		local translation = t[sublevel]
		if type(translation) ~= "string" then
			if type(self.baseTranslations[text]) == "table" then
				if type(self.baseTranslations[text][sublevel]) == "string" then
					AceLocale:error("%q::%q has not been translated into %q", text, sublevel, locale)
					return
				else
					AceLocale:error("Translation for %q::%q does not exist", text, sublevel)
					return
				end
			else
				AceLocale:error("Translation for %q::%q does not exist", text, sublevel)
				return
			end
		end
		return translation
	end
	local translation = self.translations[text]
	if type(translation) ~= "string" then
		if type(self.baseTranslations[text]) == "string" then
			AceLocale:error("%q has not been translated into %q", text, locale)
			return
		else
			AceLocale:error("Translation for %q does not exist", text)
			return
		end
	end
	return translation
end

function AceLocale.prototype:GetTranslation(text, sublevel)
	AceLocale:argCheck(text, 1, "string")
	if sublevel then
		AceLocale:argCheck(sublevel, 2, "string", "nil")
		local t = self.translations[text]
		if type(t) == "table" then
			local translation = t[sublevel]
			if type(translation) == "string" then
				return translation
			else
				t = self.baseTranslations[text]
				if type(t) ~= "table" then
					AceLocale:error("Translation table %q does not exist", text)
					return
				end
				translation = t[sublevel]
				if type(translation) ~= "string" then
					AceLocale:error("Translation for %q::%q does not exist", text, sublevel)
					return
				end
				return translation
			end
		else
			t = self.baseTranslations[text]
			if type(t) ~= "table" then
				AceLocale:error("Translation table %q does not exist", text)
				return
			end
			local translation = t[sublevel]
			if type(translation) ~= "string" then
				AceLocale:error("Translation for %q::%q does not exist", text, sublevel)
				return
			end
			return translation
		end
	end
	local translation = self.translations[text]
	if type(translation) == "string" then
		return translation
	else
		translation = self.baseTranslations[text]
		if type(translation) ~= "string" then
			AceLocale:error("Translation for %q does not exist", text)
			return
		end
		return translation
	end
end

local function initReverse(self)
	self.reverseTranslations = {}
	local alpha = self.translations
	local bravo = self.reverseTranslations
	for base, localized in pairs(alpha) do
		bravo[localized] = base
	end
end

function AceLocale.prototype:GetReverseTranslation(text)
	AceLocale.argCheck(self, text, 1, "string")
	if not self.reverseTranslations then
		initReverse(self)
	end
	local translation = self.reverseTranslations[text]
	if type(translation) ~= "string" then
		AceLocale:error("Reverse translation for %q does not exist", text)
		return
	end
	return translation
end

function AceLocale.prototype:GetIterator()
	return pairs(self.translations)
end

function AceLocale.prototype:GetReverseIterator()
	if not self.reverseTranslations then
		initReverse(self)
	end
	return pairs(self.reverseTranslations)
end

function AceLocale.prototype:HasTranslation(text, sublevel)
	AceLocale.argCheck(self, text, 1, "string")
	if sublevel then
		AceLocale.argCheck(self, sublevel, 2, "string", "nil")
		return type(self.translations[text]) == "table" and self.translations[text][sublevel] and true
	end
	return self.translations[text] and true
end

function AceLocale.prototype:HasReverseTranslation(text)
	if not self.reverseTranslations then
		initReverse(self)
	end
	return self.reverseTranslations[text] and true
end

function AceLocale.prototype:GetTableStrict(key, key2)
	AceLocale.argCheck(self, key, 1, "string")
	if key2 then
		AceLocale.argCheck(self, key2, 2, "string")
		local t = self.translations[key]
		if type(t) ~= "table" then
			if type(self.baseTranslations[key]) == "table" then
				AceLocale:error("%q::%q has not been translated into %q", key, key2, locale)
				return
			else
				AceLocale:error("Translation table %q::%q does not exist", key, key2)
				return
			end
		end
		local translation = t[key2]
		if type(translation) ~= "table" then
			if type(self.baseTranslations[key]) == "table" then
				if type(self.baseTranslations[key][key2]) == "table" then
					AceLocale:error("%q::%q has not been translated into %q", key, key2, locale)
					return
				else
					AceLocale:error("Translation table %q::%q does not exist", key, key2)
					return
				end
			else
				AceLocale:error("Translation table %q::%q does not exist", key, key2)
				return
			end
		end
		return translation
	end
	local translation = self.translations[key]
	if type(translation) ~= "table" then
		if type(self.baseTranslations[key]) == "table" then
			AceLocale:error("%q has not been translated into %q", key, locale)
			return
		else
			AceLocale:error("Translation table %q does not exist", key)
			return
		end
	end
	return translation
end

function AceLocale.prototype:GetTable(key, key2)
	AceLocale.argCheck(self, key, 1, "string")
	if key2 then
		AceLocale.argCheck(self, key2, 2, "string", "nil")
		local t = self.translations[key]
		if type(t) == "table" then
			local translation = t[key2]
			if type(translation) == "table" then
				return translation
			else
				t = self.baseTranslations[key]
				if type(t) ~= "table" then
					AceLocale:error("Translation table %q does not exist", key)
					return
				end
				translation = t[key2]
				if type(translation) ~= "table" then
					AceLocale:error("Translation table %q::%q does not exist", key, key2)
					return
				end
				return translation
			end
		else
			t = self.baseTranslations[key]
			if type(t) ~= "table" then
				AceLocale:error("Translation table %q does not exist", key)
				return
			end
			local translation = t[key2]
			if type(translation) ~= "table" then
				AceLocale:error("Translation table %q::%q does not exist", key, key2)
				return
			end
			return translation
		end
	end
	local translation = self.translations[key]
	if type(translation) == "table" then
		return translation
	else
		translation = self.baseTranslations[key]
		if type(translation) ~= "table" then
			AceLocale:error("Translation table %q does not exist", key)
			return
		end
		return translation
	end
end

function AceLocale:Debug(name, baseLocale)
	local function print(text)
		DEFAULT_CHAT_FRAME:AddMessage(text)
	end
	local words = {}
	local locales = {"enUS", "deDE", "frFR", "zhCN", "zhTW", "koKR"}
	local localizations = {}
	print("--- AceLocale Debug ---")
	for _,locale in ipairs(locales) do
		local gname = name .. "_Locale_" .. locale
		if _G[gname] then
			self:assert(type(_G[gname]) == "function")
			local t = _G[gname]()
			self:assert(type(t) == "table", "%q does not return a table", gname)
			localizations[locale] = t
		else
			print(string.format("Locale %q not found", locale))
		end
	end
	local localeDebug = {}
	for locale, localization in pairs(localizations) do
		localeDebug[locale] = {}
		for word in pairs(localization) do
			if type(localization[word]) == "table" then
				if type(words[word]) ~= "table" then
					words[word] = {}
				end
				for bit in pairs(localization[word]) do
					if type(localization[word][bit]) == "string" then
						words[word][bit] = true
					end
				end
			elseif type(localization[word]) == "string" then
				words[word] = true
			end
		end
	end
	for word in pairs(words) do
		if type(words[word]) == "table" then
			for bit in pairs(words[word]) do
				for locale, localization in pairs(localizations) do
					if not localization[word] or not localization[word][bit] then
						localeDebug[locale][word .. "::" .. bit] = true
					end
				end
			end
		else
			for locale, localization in pairs(localizations) do
				if not localization[word] then
					localeDebug[locale][word] = true
				end
			end
		end
	end
	for locale, t in pairs(localeDebug) do
		if not next(t) then
			print(string.format("Locale %q complete", locale))
		else
			print(string.format("Locale %q missing:", locale))
			for word in pairs(t) do
				print(string.format("    %q", word))
			end
		end
	end
	print("--- End AceLocale Debug ---")
end

local function activate(self, oldLib, oldDeactivate)
	AceLocale = self
	
	if oldDeactivate then
		oldDeactivate(oldLib)
	end
end

AceLibrary:Register(AceLocale, MAJOR_VERSION, MINOR_VERSION, activate)
AceLocale = AceLibrary(MAJOR_VERSION)

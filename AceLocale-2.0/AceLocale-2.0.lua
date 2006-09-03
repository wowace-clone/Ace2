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

local new, del
do
	local list = setmetatable({}, {__mode='k'})
	function new()
		local t = next(list)
		if t then
			list[t] = nil
			return t
		else
			return {}
		end
	end
	function del(t)
		setmetatable(t, nil)
		for k in pairs(t) do
			t[k] = nil
		end
		table.setn(t, 0)
		list[t] = true
	end
end

local __baseTranslations__, __debugging__, __translations__, __baseLocale__, __translationTables__, __reverseTranslations__

local callFunc = function(self, key1, key2)
	if key2 then
		return self[key1][key2]
	else
		return self[key1]
	end
end

local rawget = rawget
local rawset = rawset
local type = type

local lastSelf

local Create__index = function(superTable)
	return function(self, key)
		lastSelf = self
		local value = superTable[key]
		rawset(self, key, value)
		return value
	end
end

local __newindex = function(self, k, v)
	if type(v) ~= "function" and type(k) ~= "table" then
		AceLocale.error(self, "Cannot change the values of an AceLocale instance.")
	end
	rawset(self, k, v)
end

function AceLocale:new(name)
	self:argCheck(name, 2, "string")
	
	if self.registry[name] and type(rawget(self.registry[name], 'GetLibraryVersion')) ~= "function" then
		return self.registry[name]
	end
	
	local self = new()
	local mt = new()
	mt.__index = Create__index(AceLocale.prototype)
	mt.__newindex = __newindex
	mt.__call = callFunc
	mt.__tostring = function(self)
		if type(rawget(self, 'GetLibraryVersion')) == "function" then
			return self:GetLibraryVersion()
		else
			return "AceLocale(" .. name .. ")"
		end
	end
	setmetatable(self, mt)
	
	AceLocale.registry[name] = self
	return self
end

setmetatable(AceLocale, { __call = AceLocale.new })

AceLocale.prototype = {}
AceLocale.prototype.class = AceLocale

function AceLocale.prototype:EnableDebugging()
	if rawget(self, __baseTranslations__) then
		AceLocale:error("Cannot enable debugging after a translation has been registered.")
	end
	rawset(self, __debugging__, true)
end

function AceLocale.prototype:RegisterTranslations(locale, func)
	AceLocale.argCheck(self, locale, 2, "string")
	AceLocale.argCheck(self, func, 3, "function")
	
	if locale == rawget(self, __baseLocale__) then
		AceLocale.error(self, "Cannot provide the same locale more than once. %q provided twice.", locale)
	end
	
	if rawget(self, __baseTranslations__) and GetLocale() ~= locale then
		if rawget(self, __debugging__) then
			local t = func()
			func = nil
			if type(t) ~= "table" then
				AceLocale.error(self, "Bad argument #3 to `RegisterTranslations'. function did not return a table. (expected table, got %s)", type(t))
			end
			self[__translationTables__][locale] = t
			t = nil
		end
		func = nil
		return
	end
	local t = func()
	func = nil
	if type(t) ~= "table" then
		AceLocale.error(self, "Bad argument #3 to `RegisterTranslations'. function did not return a table. (expected table, got %s)", type(t))
	end
	
	rawset(self, __translations__, t)
	if not rawget(self, __baseTranslations__) then
		rawset(self, __baseTranslations__, t)
		rawset(self, __baseLocale__, locale)
		for key,value in pairs(t) do
			if value == true then
				t[key] = key
			end
		end
		local mt = getmetatable(self)
		mt.__index = Create__index(t)
		local mt2 = new()
		mt2.__index = AceLocale.prototype
		setmetatable(t, mt2)
	else
		for key, value in pairs(self[__translations__]) do
			if not rawget(self[__baseTranslations__], key) then
				AceLocale.error(self, "Improper translation exists. %q is likely misspelled for locale %s.", key, locale)
			end
			if value == true then
				AceLocale.error(self, "Can only accept true as a value on the base locale. %q is the base locale, %q is not.", rawget(self, __baseLocale__), locale)
			end
		end
		local mt = getmetatable(self)
		local __index = mt.__index
		mt.__index = Create__index(t)
		local mt2 = new()
		mt2.__index = self[__baseTranslations__]
		setmetatable(t, mt2)
	end
	if rawget(self, __debugging__) then
		if not rawget(self, __translationTables__) then
			rawset(self, __translationTables__, {})
		end
		self[__translationTables__][locale] = t
	end
	t = nil
end

function AceLocale.prototype:SetStrictness(strict)
	local mt = getmetatable(self)
	if not mt then
		AceLocale.error(self, "Cannot call `SetStrictness' without a metatable.")
	end
	local translations = rawget(self, __translations__)
	if not translations then
		AceLocale.error(self, "No translations registered.")
	end
	local baseTranslations = rawget(self, __baseTranslations__)
	local mt2 = getmetatable(translations)
	local mt3 = getmetatable(baseTranslations)
	if mt2 then
		mt2 = del(mt2)
		setmetatable(translations, nil)
	end
	if mt3 then
		mt3 = del(mt3)
		setmetatable(baseTranslations, nil)
	end
	getmetatable(self).__index = AceLocale.prototype
	if strict then
		local mt2 = new()
		mt2.__index = AceLocale.prototype
		setmetatable(translations, mt2)
		getmetatable(self).__index = Create__index(translations)
		for k,v in pairs(baseTranslations) do
			if rawget(self, k) == v then
				self[k] = nil
			end
		end
	else
		if baseTranslations ~= translations then
			local mt2 = new()
			mt2.__index = AceLocale.prototype
			setmetatable(baseTranslations, mt2)
			mt.__index = baseTranslations
			local mt3 = new()
			mt3.__index = baseTranslations
			setmetatable(translations, mt3)
			mt.__index = Create__index(translations)
		end
	end
end

function AceLocale.prototype:GetTranslationStrict(text, sublevel)
	AceLocale.argCheck(self, text, 1, "string")
	local translations = rawget(self, __translations__)
	if not translations then
		AceLocale.error(self, "No translations registered")
	end
	if sublevel then
		local t = rawget(translations, text)
		if type(t) ~= "table" then
			AceLocale.error(self, "Strict translation %q::%q does not exist", text, sublevel)
		end
		local value = t[sublevel]
		if not value then
			AceLocale.error(self, "Strict translation %q::%q does not exist", text, sublevel)
		end
		return value
	else
		local value = rawget(translations, text)
		if not value then
			AceLocale.error(self, "Strict translation %q does not exist", text)
		end
		return value
	end
end

function AceLocale.prototype:GetTranslation(text, sublevel)
	AceLocale.argCheck(self, text, 1, "string")
	local translations = rawget(self, __translations__)
	if not translations then
		AceLocale.error(self, "No translations registered")
	end
	if sublevel then
		local base = self[__baseTranslations__]
		local standard = rawget(translations, text)
		local current
		local baseStandard
		if not standard then
			baseStandard = rawget(base, text)
			current = baseStandard
		end
		if not type(current) ~= "table" then
			AceLocale.error(self, "Loose translation %q::%q does not exist", text, sublevel)
		end
		local value = current[sublevel]
		if not value then
			if current == baseStandard or type(baseStandard) ~= "table" then
				AceLocale.error(self, "Loose translation %q::%q does not exist", text, sublevel)
			end
			value = baseStandard[sublevel]
			if not value then
				AceLocale.error(self, "Loose translation %q::%q does not exist", text, sublevel)
			end
		end
		return value
	else
		local value = rawget(translations, text)
		if not value then
			AceLocale.error(self, "Loose translation %q does not exist", text)
		end
		return value
	end
end

local function initReverse(self)
	rawset(self, __reverseTranslations__, {})
	local alpha = self[__translations__]
	local bravo = self[__reverseTranslations__]
	for base, localized in pairs(alpha) do
		bravo[localized] = base
	end
end

function AceLocale.prototype:GetReverseTranslation(text)
	local x = rawget(self, __reverseTranslations__)
	if not x then
		if not rawget(self, __translations__) then
			AceLocale.error(self, "No translations registered")
		end
		initReverse(self)
		x = self[__reverseTranslations__]
	end
	local translation = x[text]
	if not translation then
		AceLocale.error(self, "Reverse translation for %q does not exist", text)
	end
	return translation
end

function AceLocale.prototype:GetIterator()
	local x = rawget(self, __translations__)
	if not x then
		AceLocale.error(self, "No translations registered")
	end
	return next, x, nil
end

function AceLocale.prototype:GetReverseIterator()
	local x = rawget(self, __reverseTranslations__)
	if not x then
		if not rawget(self, __translations__) then
			AceLocale.error(self, "No translations registered")
		end
		initReverse(self)
		x = self[__reverseTranslations__]
	end
	return next, x, nil
end

function AceLocale.prototype:HasTranslation(text, sublevel)
	AceLocale.argCheck(self, text, 1, "string")
	local x = rawget(self, __translations__)
	if not x then
		AceLocale.error(self, "No translations registered")
	end
	if sublevel then
		AceLocale.argCheck(self, sublevel, 2, "string", "nil")
		return type(rawget(x, text)) == "table" and x[text][sublevel] and true
	end
	return rawget(x, text) and true
end

function AceLocale.prototype:HasReverseTranslation(text)
	local x = rawget(self, __reverseTranslations__)
	if not x then
		if not rawget(self, __translations__) then
			AceLocale.error(self, "No translations registered")
		end
		initReverse(self)
		x = self[__reverseTranslations__]
	end
	return x[text] and true
end

AceLocale.prototype.GetTableStrict = AceLocale.prototype.GetTranslationStrict
AceLocale.prototype.GetTable = AceLocale.prototype.GetTranslation

function AceLocale.prototype:Debug()
	if not rawget(self, __debugging__) then
		return
	end
	local words = {}
	local locales = {"enUS", "deDE", "frFR", "koKR", "zhCN", "zhTW"}
	local localizations = {}
	DEFAULT_CHAT_FRAME:AddMessage("--- AceLocale Debug ---")
	for _,locale in ipairs(locales) do
		if not self[__translationTables__][locale] then
			DEFAULT_CHAT_FRAME:AddMessage(string.format("Locale %q not found", locale))
		else
			localizations[locale] = self[__translationTables__][locale]
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
			DEFAULT_CHAT_FRAME:AddMessage(string.format("Locale %q complete", locale))
		else
			DEFAULT_CHAT_FRAME:AddMessage(string.format("Locale %q missing:", locale))
			for word in pairs(t) do
				DEFAULT_CHAT_FRAME:AddMessage(string.format("    %q", word))
			end
		end
	end
	DEFAULT_CHAT_FRAME:AddMessage("--- End AceLocale Debug ---")
end

setmetatable(AceLocale.prototype, {
	__index = function(self, k)
		if type(k) ~= "table" and k ~= "GetLibraryVersion"  and k ~= "error" and k ~= "assert" and k ~= "argCheck" and k ~= "pcall" then -- HACK: remove "GetLibraryVersion" and such later.
			AceLocale.error(lastSelf or self, "Translation %q does not exist.", k)
		end
	end
})

local function activate(self, oldLib, oldDeactivate)
	AceLocale = self
	
	if oldLib then
		self.registry = oldLib.registry
		self.__baseTranslations__ = oldLib.__baseTranslations__
		self.__debugging__ = oldLib.__debugging__
		self.__translations__ = oldLib.__translations__
		self.__baseLocale__ = oldLib.__baseLocale__
		self.__translationTables__ = oldLib.__translationTables__
		self.__reverseTranslations__ = oldLib.__reverseTranslations__
	end
	if not self.__baseTranslations__ then
		self.__baseTranslations__ = {}
	end
	if not self.__debugging__ then
		self.__debugging__ = {}
	end
	if not self.__translations__ then
		self.__translations__ = {}
	end
	if not self.__baseLocale__ then
		self.__baseLocale__ = {}
	end
	if not self.__translationTables__ then
		self.__translationTables__ = {}
	end
	if not self.__reverseTranslations__ then
		self.__reverseTranslations__ = {}
	end
	
	__baseTranslations__ = self.__baseTranslations__
	__debugging__ = self.__debugging__
	__translations__ = self.__translations__
	__baseLocale__ = self.__baseLocale__
	__translationTables__ = self.__translationTables__
	__reverseTranslations__ = self.__reverseTranslations__
	
	if not self.registry then
		self.registry = {}
	else
		for name, instance in pairs(self.registry) do
			local name = name
			local mt = getmetatable(instance)
			setmetatable(instance, nil)
			local strict
			if instance.translations then
				instance[__translations__], instance.translations = instance.translations
				instance[__baseLocale__], instance.baseLocale = instance.baseLocale
				instance[__baseTranslations__], instance.baseTranslations = instance.baseTranslations
				instance[__debugging__], instance.debugging = instance.debugging
				instance.reverseTranslations = nil
				instance[__translationTables__], instance.translationTables = instance.translationTables
				if mt and mt.__call == oldLib.prototype.GetTranslationStrict then
					strict = true
				end
			else
				if instance[__translations__] ~= instance[__baseTranslations__] then
					if getmetatable(instance[__translations__]).__index == oldLib.prototype then
						strict = true
					end
				end
			end
			if instance[__translations__] then
				if instance[__translations__] == instance[__baseTranslations__] or strict then
					local mt = new()
					mt.__index = Create__index(instance[__translations__])
					mt.__newindex = __newindex
					mt.__call = callFunc
					mt.__tostring = function(self)
						if type(rawget(self, 'GetLibraryVersion')) == "function" then
							return self:GetLibraryVersion()
						else
							return "AceLocale(" .. name .. ")"
						end
					end
					setmetatable(instance, mt)
					
					local mt2 = new()
					mt2.__index = self.prototype
					setmetatable(instance[__translations__], mt2)
				else
					local mt = new()
					mt.__index = Create__index(instance[__translations__])
					mt.__newindex = __newindex
					mt.__call = callFunc
					mt.__tostring = function(self)
						if type(rawget(self, 'GetLibraryVersion')) == "function" then
							return self:GetLibraryVersion()
						else
							return "AceLocale(" .. name .. ")"
						end
					end
					setmetatable(instance, mt)
					
					local mt2 = new()
					mt2.__index = instance[__baseTranslations__]
					setmetatable(instance[__translations__], mt2)
					
					local mt3 = new()
					mt3.__index = self.prototype
					setmetatable(instance[__baseTranslations__], mt3)
				end
			else
				local mt = new()
				mt.__index = Create__index(self.prototype)
				mt.__newindex = __newindex
				mt.__call = callFunc
				mt.__tostring = function(self)
					if type(rawget(self, 'GetLibraryVersion')) == "function" then
						return self:GetLibraryVersion()
					else
						return "AceLocale(" .. name .. ")"
					end
				end
				setmetatable(instance, mt)
			end
		end
	end
	
	if oldDeactivate then
		oldDeactivate(oldLib)
	end
end

AceLibrary:Register(AceLocale, MAJOR_VERSION, MINOR_VERSION, activate)

--[[
Name: AceLocale-2.1
Revision: $Rev$
Author(s): kaelten (kaelten@gmail.com)
Website: http://www.wowace.com/
Documentation: http://wiki.wowace.com/index.php/AceLocale-2.1
SVN: http://svn.wowace.com/root/trunk/Ace2/AceLocale-2.1
Description: Localization library for addons to use to handle proper
             localization and internationalization.
Dependencies: AceLibrary
]]

local MAJOR_VERSION = "AceLocale-2.1"
local MINOR_VERSION = "$Revision$"

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary.") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end

local AceLocale = {}

function AceLocale:new(name)
	self:argCheck(name, 2, "string")
	
	if self.registry[name] and type(self.registry[name].GetLibraryVersion) ~= "function" then
		return self.registry[name]
	end
    
    self.registry[name] = {}
	self.registry[name].__uid__ = name
    
    setmetatable(self.registry[name], {
        __tostring = function(self)
			if type(self.GetLibraryVersion) == "function" then
				return self:GetLibraryVersion()
			else
				return "AceLocale(" .. name .. ")"
			end
		end,
        __call = function(obj, arg1, arg2)
            if arg2 == nil then return self[key] end
            arg1 == strlower(arg1)
            
            if arg1 == "getstrict" then 
                return rawget(self.__curTranslation__, arg2)
            elseif arg1 == "getloose" then
                return rawget(self.__curTranslation__, arg2) or self.__baseTranslation__[arg2]
            elseif arg1 == "getreverse" then
                return self:GetReverseTranslation(obj, arg2)
            elseif arg1 == "hastranslation" then
                return self:HasTranslation(obj, arg2)
            elseif arg1 == "hasreversetranslation" then
                return self:HasReverseTranslation(obj, arg2)
            end
        end,
    })
    
    return self.registry[name]
    
end

function AceLocale:RegisterTranslation(name, locale, func)
	self:argCheck(name, 2, "string")
    self:argCheck(locale, 2, "string")
	self:argCheck(func, 3, "function")
	
    if not self.registry[name] then self:new(name) end
    
    if not rawget(self.registry[name], "__translations__") then self.registry[name].__translations__ = {} end
    
	if self.registry[name].__translations__[locale] then
		self:error("Cannot provide the same locale more than once. %q provided twice for %s.", locale, name)
	end
	
    if rawget(self.registry[name], "__baseLocale__") then 
        for k, v in pairs(func()) do
			if not rawget(self.registry[name].__baseTranslation__, k) then
				self:error("Improper translation exists. %q is likely misspelled for locale %s.", k, locale)
			elseif value == true then
				self:error( "Can only accept true as a value on the base locale. %q is the base locale, %q is not.", self.registry[name].__baseLocale__, locale)
			end
		end
    else
        self.registry[name].__baseTranslation__ = func() 
        self.registry[name].__baseLocale__ = locale
        
        for k, v in pairs(self.registry[name].__baseTranslation__) do
            if type(v) ~= "string" then
                if type(v) == "boolean" then 
                    self.registry[name].__baseTranslation__[k] = k 
                else
                    self:error("Translation for %s is invalid.  Must be either string or boolean", k)
                end
            end
        end
        
        setmetatable(self.registry[name].__baseTranslation__, {__index = function(tbl, key)  
            self:error("Translation for %s not found", key)
        end})
    end
    
    self.registry[name].__translations__[locale] = func
end

function AceLocale:SetLocale(name, locale)
    self:argCheck(name, 2, "string")
    
    if not self.registry[name] then self:error("At least one translation must be registered before you can SetLocale().", name) end
    
    if rawget(self.registry[name], "__curLocale__") then
        locale = locale or GetLocale()
        if self.registry[name].__curLocale__ == locale then return end
    end
    
    
    if not self.registry[name] or not rawget(self.registry[name], "__translations__") then self:error("At least one translation must be registered before you can SetLocale().", name) end
    
    if locale then 
        if not self.registry[name].__translations__[locale] then
            self:error("Cannot SetLocale to %s for %s,  It has not been registered.", locale, name)
        end
    else 
        locale = GetLocale() 
    end
    
    if self.registry[name].__translations__[locale] and self.registry[name].__baseLocale__ ~= locale then
        self.registry[name].__curLocale__ = locale
        self.registry[name].__curTranslation__ = self.registry[name].__translations__[locale]()
    else
        self.registry[name].__curLocale__ = self.registry[name].__baseLocale__
        self.registry[name].__curTranslation__ = self.registry[name].__baseTranslation__
    end    
    
    if rawget(self.registry[name], "__strictTranslations__") then
        setmetatable(self.registry[name].__curTranslation__, {
            __index = function(tbl, key)  
                self:error("Translation for %s not found", key)
            end
        })
    else
        setmetatable(self.registry[name].__curTranslation__, {
            __index = self.registry[name].__baseTranslation__
        })
    end
    
    getmetatable(self.registry[name]).__index = self.registry[name].__curTranslation__

    
    if not rawget(self.registry[name], "__dynamic__") then
        self.registry[name].__translations__ = nil
    end
    
    if rawget(self.registry[name], "__reverseTranslation__") then
		self.registry[name].__reverseTranslation__ = nil
	end
end

function AceLocale:SetDynamicLocales(name, flag)
    self:argCheck(name, 2, "string", "table")
    self:argCheck(flag, 3, "boolean")
    if type(name) == "table" then name = name.__uid__ end
    
    if not self.registry[name] then self:error("At least one translation must be registered before you can SetDynamicLocales().") end

    self.registry[name].__dynamic__ = flag
end

function AceLocale:GetTranslation(name, locale)
    self:argCheck(name, 2, "string")
    
    if not self.registry[name] or (not rawget(self.registry[name], "__translations__") and not rawget(self.registry[name], "__curLocale__")) then self:error("At least one translation must be registered before you can GetTranslation().", name) end

    if locale and rawget(self.registry[name], "__translations__") and not self.registry[name].__translations__[locale] then
        self:error("Cannot GetTranslation for locale %s,  It has not been registered for %s.", locale, name)
    end
    
    self:SetLocale(name, locale)
    
    return self.registry[name]
end

function AceLocale:SetStrictness(name, strict)
    self:argCheck(name, 2, "string", "table")
    self:argCheck(strict, 2, "boolean")
	if type(name) == "table" then name = name.__uid__ end
    
	if not self.registry[name] then self:error("At least one translation must be registered before you can SetStrictness().") end
    local mt = getmetatable(self.registry[name].__curTranslation__)
    
	if strict and mt then
		mt.__index = function(tbl, key)  
            self:error("Translation for %s not found", key)
        end
	elseif mt then
		mt.__index = self.registry[name].__baseTranslation__
	end
    
    self.registry[name].__strictTranslations__ = strict
end

local function initReverse(self)
	self.__reverseTranslation__ = {}
	
	for k, v in pairs(self.__curTranslation__) do
		self.__reverseTranslation__[v] = k
	end
   
    setmetatable(self.__reverseTranslation__, {
        __index = function(tbl, key)  
            AceLocale:error("Reverse translation for %s not found", key)
        end
    })
end

function AceLocale:GetReverseTranslation(name, text)
	self:argCheck(name, 1, "string", "table")
    self:argCheck(text, 2, "string")
    if type(name) == "table" then name = name.__uid__ end
    
    if not self.registry[name] or not rawget(self.registry[name], "__curTranslation__") then self:error("At least one translation must be registered before you can GetReverseTranslation().") end
    
	if not rawget(self.registry[name], "__reverseTranslation__") then
		initReverse(self.registry[name])
	end
	
    return self.registry[name].__reverseTranslation__[text]	
end

function AceLocale:HasTranslation(name, text)
    self:argCheck(name, 1, "string", "table")
    self:argCheck(text, 2, "string")
    if type(name) == "table" then name = name.__uid__ end
    
    if not self.registry[name] or not rawget(self.registry[name], "__curTranslation__") then self:error("At least one translation must be registered before you can HasTranslation().") end
    
    return rawget(self.registry[name], "__curTranslation__")[text] and true or false
end

function AceLocale:HasReverseTranslation(name, text)
    self:argCheck(name, 1, "string", "table")
    self:argCheck(text, 2, "string")
    if type(name) == "table" then name = name.__uid__ end
    
    if not self.registry[name] or not rawget(self.registry[name], "__curTranslation__") then self:error("At least one translation must be registered before you can HasReverseTranslation().") end
    
    if not rawget(self.registry[name], "__reverseTranslation__") then
		initReverse(self.registry[name])
	end
    
    return rawget(self.registry[name], "__reverseTranslation__")[text] and true or false
end

function AceLocale:GetIterator(name)
    self:argCheck(name, 1, "string", "table")
    if type(name) == "table" then name = name.__uid__ end
    
    if not self.registry[name] or not rawget(self.registry[name], "__curTranslation__") then self:error("At least one translation must be registered before you can GetIterator().") end
    
    return pairs(self.registry[name].__curTranslation__)
end

function AceLocale:GetReverseIterator(name)
    self:argCheck(name, 1, "string", "table")
    if type(name) == "table" then name = name.__uid__ end
    
    if not self.registry[name] or not rawget(self.registry[name], "__curTranslation__") then self:error("At least one translation must be registered before you can GetReverseIterator().") end
    
    if not rawget(self.registry[name], "__reverseTranslation__") then
		initReverse(self.registry[name])
	end
    
    return pairs(self.registry[name].__reverseTranslation__)
end

local function activate(self, oldLib, oldDeactivate)
	AceLocale = self
	
	if oldLib then
		self.registry = oldLib.registry
	end
	if not self.registry then
		self.registry = {}
	end
	
	if oldDeactivate then
		oldDeactivate(oldLib)
	end
end

AceLibrary:Register(AceLocale, MAJOR_VERSION, MINOR_VERSION, activate)
AceLocale = AceLibrary(MAJOR_VERSION)
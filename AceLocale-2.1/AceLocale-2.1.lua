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

local _uid, curTranslation, baseTranslation, translations, baseLocale, curLocale, strictTranslations, dynamic, reverseTranslation
local AceLocale = {}
local backbone = {}

local function __call(obj, text, flag)
   if flag == nil then return obj[text] end
   
   if flag == true then
      local text = rawget(obj[curTranslation], arg2)
      if not text then AceLocale:error("Strict translation for %s not found", key) end
      return text
   elseif flag == false then
      return rawget(obj[curTranslation], arg2) or obj[baseTranslation][arg2]
   elseif strlower(flag) == "reverse" then
      if not rawget(obj, reverseTranslation) then
         initReverse(obj)
      end
      
      return obj[reverseTranslation][text]	
   else
      AceLocale:error("Invalid flag given to __call.  Should be true/false/\"reverse\" but %s was given", flag)
   end
end

local function NewInstance(self, uid)
   self:argCheck(uid, 2, "string")

   if self.registry[uid] and type(self.registry[uid].GetLibraryVersion) ~= "function" then
      return self.registry[uid]
   end

   self.registry[uid] = {}
   self.registry[uid][_uid] = uid
   self.registry[uid][translations] = {}
   
   setmetatable(self.registry[uid], {
     __tostring = function(self)
         if type(self.GetLibraryVersion) == "function" then
             return self:GetLibraryVersion()
         else
             return "AceLocale(" .. uid .. ")"
         end
     end,
     __call = __call,
     __index = backbone
   })
   
   return self.registry[uid]
end

local function initReverse(self)
   self[reverseTranslation] = {}

   for k, v in pairs(self[curTranslation]) do
      self[reverseTranslation][v] = k
   end

   setmetatable(self[reverseTranslation], {
      __index = function(tbl, key)  
         AceLocale:error("Reverse translation for %s not found", key)
      end
   })
end

function AceLocale:RegisterTranslation(uid, locale, func)
   self:argCheck(uid, 2, "string")
   self:argCheck(locale, 2, "string")
   self:argCheck(func, 3, "function")
	
   local instance = self.registry[uid] or NewInstance(self, uid)
   
   if instance[translations][locale] then
      self:error("Cannot provide the same locale more than once. %q provided twice for %s.", locale, uid)
   end
	
    if rawget(instance, baseLocale) then 
        for k, v in pairs(func()) do
			if not rawget(instance[baseTranslation], k) then
				self:error("Improper translation exists. %q is likely misspelled for locale %s.", k, locale)
			elseif value == true then
				self:error( "Can only accept true as a value on the base locale. %q is the base locale, %q is not.", instance[baseLocale], locale)
			end
		end
    else
        instance[baseTranslation] = func() 
        instance[baseLocale] = locale
        
        for k, v in pairs(instance[baseTranslation]) do
            if type(v) ~= "string" then
                if type(v) == "boolean" then 
                    instance[baseTranslation][k] = k 
                else
                    self:error("Translation for %s is invalid.  Must be either string or boolean", k)
                end
            end
        end
        
        setmetatable(instance[baseTranslation], {__index = backbone})
    end
    
    instance[translations][locale] = func
end

function AceLocale:GetInstance(uid, locale)
   self:argCheck(uid, 2, "string")
   
   local instance = self.registry[uid]
   
   if not instance then self:error("At least one translation must be registered before you can GetInstance().") end
    
   instance:SetLocale(locale)
   
   return instance
end



setmetatable(backbone, {__index = 
   function(tbl, key)  
      AceLocale:error("Translation for %s not found", key)
   end})

function backbone:SetLocale(locale)
   if locale == nil then return end
   
   if locale == true then locale = GetLocale() end
   
   if rawget(self, curLocale) and self[curLocale] == locale then return end

   if not self[translations][locale] then
      AceLocale:error("Cannot SetLocale to %s for %s,  It has not been registered.", locale, name)
   end

   if self[translations][locale] and self[baseLocale] == locale then
      self[curLocale] = self[baseLocale]
      self[curTranslation] = self[baseTranslation]
   else
      self[curLocale] = locale
      self[curTranslation] = self[translations][locale]()
   end    

   if rawget(self, strictTranslations) then
      setmetatable(self[curTranslation], {
         __index = function(tbl, key)  
            AceLocale:error("Translation for %s not found", key)
         end
      })
   else
      setmetatable(self[curTranslation], {
         __index = self[baseTranslation]
      })
   end

   getmetatable(self).__index = self[curTranslation]

   if not rawget(self, dynamic) then
      self[translations] = {}
   end

   if rawget(self, reverseTranslation) then
      self[reverseTranslation] = nil
   end
end

function backbone:SetDynamicLocales(flag)
   AceLocale:argCheck(flag, 1, "boolean")
   self[dynamic] = flag
end

function backbone:SetStrictness(flag)
   AceLocale:argCheck(flag, 1, "boolean")
   
   local mt = getmetatable(self[curTranslation])

   if strict and mt then
      mt.__index = function(tbl, key)  
         AceLocale:error("Translation for %s not found", key)
      end
   elseif mt then
      mt.__index = self[baseTranslation]
   end

   self[strictTranslations] = strict
end

function backbone:HasTranslation(text)
   AceLocale:argCheck(text, 1, "string")
   
   if not rawget(self, curTranslation) then AceLocale:error("A locale must be chosen before you can call HasTranslation().") end
   
   return rawget(self[curTranslation], text) and true or false
end

function backbone:HasReverseTranslation(text)
   AceLocale:argCheck(text, 1, "string")
    
    if not rawget(self, curTranslation) then AceLocale:error("A locale must be chosen before you can call HasReverseTranslation().") end
    
    if not rawget(self, reverseTranslation) then
		initReverse(self)
	end
    
    return rawget(self[reverseTranslation], text) and true or false
end

function backbone:GetIterator()
   if not rawget(self, curTranslation) then AceLocale:error("A locale must be chosen before you can call GetIterator().") end
   return pairs(self[curTranslation])
end

function backbone:GetReverseIterator()
    if not rawget(self, curTranslation) then AceLocale:error("A locale must be chosen before you can call HasReverseTranslation().") end
    
    if not rawget(self, reverseTranslation) then
		initReverse(self)
	end
    
    return pairs(self[reverseTranslation])
end

local function activate(self, oldLib, oldDeactivate)
   AceLocale = self
	
   if oldLib then
      self.registry = oldLib.registry
      self._uid = oldLib._uid
      self.curTranslation = oldLib.curTranslation
      self.baseTranslation = oldLib.baseTranslation
      self.translations = oldLib.translations
      self.baseLocale = oldLib.baseLocale
      self.curLocale = oldLib.curLocale
      self.strictTranslations = oldLib.strictTranslations
      self.dynamic = oldLib.dynamic
      self.reverseTranslation = oldLib.reverseTranslation
   end
	
   if not self.registry then self.registry = {} end
   if not self._uid then self._uid = {} end
   if not self.curTranslation then	self.curTranslation = {} end
   if not self.baseTranslation then self.baseTranslation = {} end
   if not self.translations then self.translations = {} end
   if not self.baseLocale then self.baseLocale = {} end
   if not self.curLocale then self.curLocale = {} end
   if not self.strictTranslations then	self.strictTranslations = {} end
   if not self.dynamic then self.dynamic = {} end
   if not self.reverseTranslation then	self.reverseTranslation = {} end
	
   if oldDeactivate then
      oldDeactivate(oldLib)
   end
	
   _uid = self._uid
   curTranslation = self.curTranslation
   baseTranslation = self.baseTranslation
   translations = self.translations
   baseLocale = self.baseLocale
   curLocale = self.curLocale
   strictTranslations = self.strictTranslations
   dynamic = self.dynamic
   reverseTranslation = self.reverseTranslation
end

AceLibrary:Register(AceLocale, MAJOR_VERSION, MINOR_VERSION, activate)
AceLocale = AceLibrary(MAJOR_VERSION)
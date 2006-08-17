local MAJOR_VERSION = "AceGUIButton-2.0"
local MINOR_VERSION = "$Rev$"

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary.") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end


local AceOO = AceLibrary("AceOO-2.0")
local AceGUIFrame = AceLibrary("AceGUIFrame-2.0")
local AceGUIButton = AceOO.Class(AceGUIFrame)
AceGUIButton.new = AceGUIFrame.new
AceGUIButton.CreateUIObject = AceGUIFrame.CreateUIObject
AceGUIButton.UIObjectType = "Button"

local factory = AceLibrary("AceGUIFactory-2.0")

local buttonTextTemplate = {
    type = "fontstring",
    anchors = {
        center = true,
    }
}

local function attachTexture(textureType,def,elements)
    if type(def[textureType]) == "table" then
        local textureDef = def[textureType]
        factory:SetupTemplate(textureDef)
        elements[textureType] = textureDef
        textureDef.type = "texture"
        textureDef.anchors = textureDef.anchors or buttonTextTemplate.anchors
    end
end

function AceGUIButton.prototype:Build(def,parent,name,handler)
    if def.enableMouse ~= false then
        def.enableMouse = true
    end
    
    --AceGUIButton.super.prototype.Build(self,def,parent,name,handler)
    AceGUIFrame.prototype.Build(self,def,parent,name,handler)
    
    def.elements = def.elements or {}
    local elements = def.elements
    local buttonText = def.ButtonText
    if buttonText then
        buttonText.type = "fontstring"
        buttonText.anchors = buttonText.anchors or buttonTextTemplate.anchors
    else
        buttonText = buttonTextTemplate
    end
    -- Possibly should yell at the user for trying to create an element named Text if they have
    -- but for now, just overwrite it
    elements.Text = buttonText        

    attachTexture("NormalTexture",def,elements)
    attachTexture("HighlightTexture",def,elements)
    attachTexture("PushedTexture",def,elements)
    attachTexture("DisabledTexture",def,elements)
end

local function setTexture(self,textureType,def)
    local method = "Set"..textureType
    local arg = def[textureType]
    if self[textureType] then
        arg = self[textureType]
    end
    self[method](self,arg)
    if not self[textureType] then
        self[textureType] = self["Get"..textureType](self)
    end
end

local function setTextColor(self,textType,def,method)
    if def[textType] then
        method = method or ("Set" .. textType)
        local c = def[textType]
        self[method](self,c.r or c[1], c.g or c[2],c .b or c[3], c.a or c[4])
    end
end

function AceGUIButton.prototype:Configure(def,parent,name,handler)
    --AceGUIButton.super.prototype.Configure(self,def,parent,name,handler)
    AceGUIFrame.prototype.Configure(self,def,parent,name,handler)
    
    self:SetFontString(self.Text)   
    
    setTexture(self,"NormalTexture",def)
    setTexture(self,"HighlightTexture",def)
    setTexture(self,"PushedTexture",def)
    setTexture(self,"DisabledTexture",def)
    
    self:SetTextFontObject(def.NormalFontObject or GameFontNormal)
    self:SetHighlightFontObject(def.HighlightFontObject or GameFontHighlight)
    self:SetDisabledFontObject(def.DisabledFontObject or GameFontDisable)
    
    def.NormalTextColor = def.NormalTextColor or def.TextColor
    def.TextColor = nil
    setTextColor(self,"NormalTextColor",def,"SetTextColor")
    setTextColor(self,"HighlightTextColor",def)
    setTextColor(self,"PushedTextColor",def)
    setTextColor(self,"DisabledTextColor",def)
    
    local o = def.pushedTextOffset 
    if type(o) == "table" then
        self:SetPusedTextOffset(o[1] or o.x or o.xOffset,o[2] or o.y or o.yOffset)
    elseif type(o) == "number" then
        self:SetPushedTextOffset(0,o)
    end
    
    local clicks = def.clicks
    if type(clicks) == "string" then
        self:RegisterForClicks(clicks)
    elseif type(clicks) == "table" then
        self:RegisterForClicks(unpack(clicks))
    elseif type(clicks) ~= "nil" then
        error("Unreachable Code")
    end
    
    if def.text then
        self:SetText(def.text)
    end
    
    if def.disabled then
        self:Disable()
    end
    
end
    

AceLibrary:Register(AceGUIButton, MAJOR_VERSION, MINOR_VERSION)
local MAJOR_VERSION = "AceGUICheckButton-2.0"
local MINOR_VERSION = "$Rev$"

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary.") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end


local AceOO = AceLibrary("AceOO-2.0")
local AceGUIButton = AceLibrary("AceGUIButton-2.0")
local AceGUICheckButton = AceOO.Class(AceGUIButton)
AceGUICheckButton.new = AceGUIButton.new
AceGUICheckButton.CreateUIObject = AceGUIButton.CreateUIObject
AceGUICheckButton.UIObjectType = "CheckButton"

local factory = AceLibrary("AceGUIFactory-2.0")

local anchors = {
    center = true,
}

local function attachTexture(textureType,def,elements)
    if type(def[textureType]) == "table" then
        local textureDef = def[textureType]
        factory:SetupTemplate(textureDef)
        elements[textureType] = textureDef
        textureDef.type = "texture"
        textureDef.anchors = textureDef.anchors or anchors
    end
end

function AceGUICheckButton.prototype:Build(def,parent,name,handler)
    --AceGUICheckButton.super.prototype.Build(self,def,parent,name,handler)
    AceGUIButton.prototype.Build(self,def,parent,name,handler)
    local elements = def.elements
    
    attachTexture("CheckedTexture",def,elements)
    attachTexture("DisabledCheckedTexture",def,elements)
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


function AceGUICheckButton.prototype:Configure(def,parent,name,handler)
    --AceGUIButton.super.prototype.Configure(self,def,parent,name,handler)
    AceGUIButton.prototype.Configure(self,def,parent,name,handler)
    
    setTexture(self,"CheckedTexture",def)
    setTexture(self,"DisabledCheckedTexture",def)
end
    

AceLibrary:Register(AceGUICheckButton, MAJOR_VERSION, MINOR_VERSION)
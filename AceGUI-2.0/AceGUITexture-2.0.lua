local MAJOR_VERSION = "AceGUITexture-2.0"
local MINOR_VERSION = "$Rev$"

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary.") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end

local AceOO = AceLibrary("AceOO-2.0")
local AceGUILayeredRegion = AceLibrary("AceGUILayeredRegion-2.0")
local AceGUITexture = AceOO.Class(AceGUILayeredRegion)
AceGUITexture.new = AceGUILayeredRegion.new
AceGUITexture.UIObjectType = "Texture"


function AceGUITexture:CreateUIObject(parent)
    return parent:CreateTexture()
end

function AceGUITexture.prototype:Configure(def,parent,name,handler)
    --AceGUITexture.super.prototype.Configure(self,def,parent,name,handler)
    AceGUILayeredRegion.prototype.Configure(self,def,parent,name,handler)
    
    local t = def.file
	if t then self:SetTexture(t) end
    
    t = def.blendMode
    if t then self:SetBlendMode(t) end
    
	t = def.color	
	if t then self:SetTexture(t[1] or t.r, t[2] or t.g, t[3] or t.g, t[4] or t.a) end

	self:SetDesaturated(def.desaturated)

	t = def.gradient
	if t then
		-- TODO: find out if SetGradient is the same as SetAlphaGradient with 1 in both alpha positions.
		local min = t.min
		local max = t.max
		self:SetGradientAlpha(t.orientation, 
            min.r or min[1], min.g or min[2], min.b or min[3], min.a or min[4] or 1,
            max.r or max[2], max.g or max[2], max.b or max[3], max.a or max[4] or 1)
	end

	local c = def.texCoord
	if c then
		if c.minX or c.left then
			self:SetTexCoord(c.minX or c.left, c.maxX or c.right, c.minY or c.bottom, c.maxY or c.top)
        else
			self:SetTexCoord(c.ULx, c.ULy, c.LLx, c.LLy, c.URx, c.URy, c.LRx, c.LRy)
		end
	end
    
end

AceLibrary:Register(AceGUITexture,MAJOR_VERSION,MINOR_VERSION)
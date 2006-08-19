local MAJOR_VERSION = "AceGUIFactory-2.0"
local MINOR_VERSION = "$Rev$"

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary.") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end
if not AceLibrary:HasInstance("AceOO-2.0") then error(MAJOR_VERSION .. " requires AceOO-2.0") end

local CLASS_MAP	= {
--	["generic"]			        = PLACEHOLDER,
	["frame"]				    = "AceGUIFrame-2.0",
--	[ACEGUI_BORDER_FRAME]		= PLACEHOLDER,
--	["dialog"]		            = PLACEHOLDER,
--	["optionsbox"]		    	= PLACEHOLDER,
	["button"]  				= "AceGUIButton-2.0",
	["checkbutton"]		        = "AceGUICheckButton-2.0",
--	[ACEGUI_DROPDOWN]			= AceGUIDropDown,
	["listbox"]			        = PLACEHOLDER,
	["editbox"]     			= "AceGUIEditBox-2.0",
--	[ACEGUI_INPUTBOX]			= PLACEHOLDER,
--	[ACEGUI_CHECKBOX]			= PLACEHOLDER,
--	[ACEGUI_SCROLL_EDITBOX]		= PLACEHOLDER,
--	["scrollframe"]     		= "AceGUIScrollFrame-2.0",
--	[ACEGUI_SCROLLBAR]			= PLACEHOLDER,
--	[ACEGUI_SCROLL_CHILD]		= PLACEHOLDER,
	["slider"]				    = "AceGUISlider-2.0",
	["fontstring"]  			= "AceGUIFontString-2.0",
	["texture"]     			= "AceGUITexture-2.0",
--	[ACEGUI_BACKDROP]			= PLACEHOLDER,
}

local AceOO = AceLibrary("AceOO-2.0")
local AceGUICustomClass = AceLibrary("AceGUICustomClass-2.0")
local AceGUIFactory = {}
local registry 
local templates = AceLibrary("AceGUITemplates-2.0")


function AceGUIFactory:SetupTemplate(def)
    local template = def.template
	if(not template or registry.templates[def]) then return end
    if type(template) == "string" then
        template = templates[def.template]
        def.template = template
    end 
    
	if(template.template) then self:SetupTemplate(template) end
	
	setmetatable(def,{__index = template})
	if(template.elements) then	
		if(def.elements) then
			for k,v in pairs(template.elements) do
				def.elements[k] = def.elements[k] or v
			end
		else
			def.elements = setmetatable({},{__index = template.elements})
		end
	end
	registry.templates[def] = true    
end


function AceGUIFactory:make(def,handler,parent,name)
    self:SetupTemplate(def)
    name = def.name or name
    if not name then
        error("Root Objects must define a name",3)
    end
       
    local class
    if type(def.type) == "string" then
        class = CLASS_MAP[def.type]
        if not class then error(def.type .. " is not a valid AceGUI type",2) end
        class = AceLibrary(class)
    elseif type(def.type) == "table" then
        if AceOO.inherits(def.type,AceGUICustomClass) then
            class = def.type
        else
            error(string.format("%s Is not a valid class.  All Custom classes must implement the AceGUICustomClass interface.",def.type),3)
        end
    else
        self:error("Type field must be a string or class reference. (%q gave %s)",name,type(def.type))
    end
    
    return class:new(def,handler,parent,name)
end

function AceGUIFactory:init()
    registry = AceLibrary("AceGUI-2.0").registry
end

AceLibrary:Register(AceGUIFactory,MAJOR_VERSION,MINOR_VERSION)
AceGUIFactory = AceLibrary(MAJOR_VERSION)
local MAJOR_VERSION = "AceGUIFactory-2.0"
local MINOR_VERSION = "$Rev$"

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary.") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end
if not AceLibrary:HasInstance("AceOO-2.0") then error(MAJOR_VERSION .. " requires AceOO-2.0") end

local ACEGUI_GENERIC				= "generic"
local ACEGUI_FRAME				= "frame"
local ACEGUI_BORDER_FRAME			= "border frame"
local ACEGUI_BASIC_DIALOG			= "basic dialog"
local ACEGUI_DIALOG 				= "dialog"
local ACEGUI_OPTIONSBOX			= "optionsbox"
local ACEGUI_BUTTON 				= "button"
local ACEGUI_CHECK_BUTTON			= "checkbutton"
local ACEGUI_DROPDOWN				= "dropdown"
local ACEGUI_LISTBOX				= "listbox"
local ACEGUI_EDITBOX				= "editbox"
local ACEGUI_INPUTBOX				= "inputbox"
local ACEGUI_CHECKBOX				= "checkbox"
local ACEGUI_SCROLL_EDITBOX		= "scroll editbox"
local ACEGUI_SCROLL_FRAME			= "scroll frame"
local ACEGUI_SCROLLBAR			= "scrollbar"
local ACEGUI_SCROLL_CHILD			= "scroll child"
local ACEGUI_SLIDER 				= "slider"
local ACEGUI_FONTSTRING			= "fontstring"
local ACEGUI_TEXTURE				= "texture"
local ACEGUI_BACKDROP				= "backdrop"
local ACEGUI_RADIO_BOX			= "radio box"
local ACEGUI_CONTAINTER			= "container"

local PLACEHOLDER = "AceGUIRegion-2.0"

local CLASS_MAP	= {
	[ACEGUI_GENERIC]			= PLACEHOLDER,
	[ACEGUI_FRAME]				= "AceGUIFrame-2.0",
	[ACEGUI_BORDER_FRAME]		= PLACEHOLDER,
	[ACEGUI_BASIC_DIALOG]		= PLACEHOLDER,
	[ACEGUI_DIALOG]				= PLACEHOLDER,
	[ACEGUI_OPTIONSBOX]			= PLACEHOLDER,
	[ACEGUI_BUTTON]				= "AceGUIButton-2.0",
	[ACEGUI_CHECK_BUTTON]		= "AceGUICheckButton-2.0",
--	[ACEGUI_DROPDOWN]			= AceGUIDropDown,
	[ACEGUI_LISTBOX]			= PLACEHOLDER,
	[ACEGUI_EDITBOX]			= "AceGUIEditBox-2.0",
	[ACEGUI_INPUTBOX]			= PLACEHOLDER,
	[ACEGUI_CHECKBOX]			= PLACEHOLDER,
	[ACEGUI_SCROLL_EDITBOX]		= PLACEHOLDER,
	[ACEGUI_SCROLL_FRAME]		= "AceGUIScrollFrame-2.0",
	[ACEGUI_SCROLLBAR]			= PLACEHOLDER,
	[ACEGUI_SCROLL_CHILD]		= PLACEHOLDER,
	[ACEGUI_SLIDER]				= PLACEHOLDER,
	[ACEGUI_FONTSTRING]			= "AceGUIFontString-2.0",
	[ACEGUI_TEXTURE]			= "AceGUITexture-2.0",
--	[ACEGUI_BACKDROP]			= PLACEHOLDER,
}

local AceOO = AceLibrary("AceOO-2.0")
local AceGUICustomClass = AceLibrary("AceGUICustomClass-2.0")
local AceGUIFactory = {}
ACEGUI_REGISTRY = ACEGUI_REGISTRY or {templates = {}, objects = {}}
local registry = ACEGUI_REGISTRY
local templates = AceLibrary("AceGUITemplates-2.0")

local function inheritTemplate(def)
	local template = def.template
	if(not template or registry.templates[def]) then return end
    if type(template) == "string" then
        template = templates[def.template]
        def.template = template
    end 
    
	if(template.template) then inheritTemplate(template) end
	
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
    inheritTemplate(def)
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
        error("The type field may only be a string or class reference",3)
    end
    
    return class:new(def,handler,parent,name)
end

AceLibrary:Register(AceGUIFactory,MAJOR_VERSION,MINOR_VERSION)
AceGUIFactory = AceLibrary(MAJOR_VERSION)
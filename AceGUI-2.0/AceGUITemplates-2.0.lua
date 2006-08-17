local MAJOR_VERSION = "AceGUITemplates-2.0"
local MINOR_VERSION = "$Rev$"
if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary.") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end

local templates = {}    

local mt = { __index = function(t,k)
   templates:error("Could not find a template named %q",k)
end}

function templates:GetTemplate(name)
    return self[name]
end

function templates:HasTemplate(name)
    return rawget(self,name) ~= nil
end

function templates:RegisterTemplate(name,def)
    if rawget(self,name) then
        self:error("A template named %q already exists",name)
    else
        self[name] = def
    end
end

templates.UIButtonTexture = {
    texCoord = {
        minX = 0, maxX = 0.625,
        minY = 0, maxY = 0.6875,
    },
    setAllPoints = true,
}
    
templates.UIPanelButton = {
    type = "button",
    width = 85,
    height = 28,
   
    text = CLOSE,
    clicks = "LeftButtonUp",

    NormalTexture = {
        file = "Interface/Buttons/UI-Panel-Button-Up",
        template = templates.UIButtonTexture,
    },
    DisabledTexture = {
        file = "Interface/Button/UI-Panel-Button-Disable",
        template = templates.UIButtonTexture,
    },
    PushedTexture = {
        file = "Interface/Buttons/UI-Panel-Button-Down",
        template = templates.UIButtonTexture,
    },
    HighlightTexture = {
        file = "Interface/Buttons/UI-Panel-Button-Highlight",
        template = templates.UIButtonTexture,
        blendMode = "ADD",
    }
}

templates.UIPanelHeader = {
    type = "texture",
    layer = "ARTWORK",
    file = "Interface/DialogFrame/UI-DialogBox-Header",
    height = 32,
    width = 132,
    texCoord = {
        minX = .23828,  maxX = .7578124,
        minY = 0.04687, maxY = .5625,
    },
}

templates.UIPanelDialog = {
    type = "frame",
    backdrop = {
		bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
		edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 32,
		insets = {
			left = 12, 	right = 12, 
			top = 12, bottom = 12
		},
	},
}

local checkButtonTexture = {
    width = 32,
    height = 32,
    anchors = { left = true },    
}

templates.UICheckButton = {
    type = "checkbutton",
    height = 32,
    width = 32,
    
    NormalTexture = {
        template = checkButtonTexture,
        file = "Interface/Buttons/UI-CheckBox-Up",
    },    
    PushedTexture = {
        template = checkButtonTexture,
        file = "Interface/Buttons/UI-CheckBox-Down",
    },
    DisabledTexture = {
        template = checkButtonTexture,
        file = "Interface/Buttons/UI-CheckBox-Disabled",
    },
    HighlightTexture = {
        template = checkButtonTexture,
        file = "Interface/Buttons/UI-CheckBox-Highlight",
        blendMode = "ADD",
    },
    CheckedTexture = {
        template = checkButtonTexture,
        file = "Interface/Buttons/UI-CheckBox-Check",
    },
    DisabledCheckTexture = {
        template = checkButtonTexture,
        file = "Interface/Buttons/UI-CheckBox-Check-Disabled",
    },
    
    clicks = "LeftButtonUp",
    ButtonText = {
        anchors = {
            left = { x = 34 },
        },
    },
    NormalFontObject = GameFontNormalSmall,
    HighlightFontObject = GameFontNormalSmall,
    pushedTextOffset = 0,    

}

AceLibrary:Register(templates,MAJOR_VERSION,MINOR_VERSION)
templates = AceLibrary(MAJOR_VERSION)
setmetatable(templates,mt)
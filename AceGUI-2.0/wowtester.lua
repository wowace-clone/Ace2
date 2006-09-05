TARD = {}
AceLibrary("AceGUI-2.0"):embed(TARD)
local templates = AceLibrary("AceGUITemplates-2.0")

local config = {
    template = templates.UIPanelDialog,
    name = "AceGUITestFrame",
    parent = UIParent,
    width = 300,
    height = 200,
    
    anchors = {
        center = true,
    },
    
    OnMouseDown = function()this:StartMoving()end,
    OnMouseUp = "OnMouseUp",
    enableMouse = true,
    movable = true,
    
    elements = {
        title = {
            type = "fontstring",
            layer = "OVERLAY",
            text = "Original Text",
            anchors = {
                center = {relTo="$parentheader"},
            } ,
            OnLoad = function()this:SetText("Neat!")end, --This is pimp
            
        },
        header = {
            template = "UIPanelHeader",
            anchors = {
                center = {relPoint = "top", y = -5}
            },
        },
        option1 = {
            template = "UICheckButton",
            anchors = {
                topleft = { x = 15, y = -20 }
            },
            text = "Option1",
            width = 100,
        },        
        option2 = {
            template = "OptionsSlider",
            anchors = { topleft = { x = 15, y = -60 } },
        },
        closeButton = {
            template = templates.UIPanelButton,
            anchors = {
                bottomright = { xOffset = -15, yOffset = 15 }
            },
            text = CLOSE,
            OnClick = "CloseDialog",
        },
        scrollBar = {
            template = "UIPanelScrollBar",
            anchors = { 
                topright = { x = -13, y = -33 },
                bottomright = { x = -13, y = 62 },
            },
            valueStep = 1,
        }
    }
}

function TARD:OnMouseUp()
    self.gui:StopMovingOrSizing()
end

function TARD:CloseDialog()
    self.gui:Hide()
end

function TARD:CreateAndShowGUI()
    self.gui = self.gui or self:CreateGUI(config)
    self.gui:Show()
end

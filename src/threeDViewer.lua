--- A module to handle the 3D viewer for the addon.
--- @module "ThreeDViewer"

local addon_name, _ = ...
local RanothUtils = LibStub("AceAddon-3.0"):GetAddon(addon_name)
local Debug = RanothUtils:GetModule("Debug")
local ThreeDViewer = RanothUtils:NewModule("ThreeDViewer")

local RanothUtilsGUI = LibStub("AceGUI-3.0")
local which_list = {
    "PLAYER",
    "TARGET",
    "SELF",
    "PET"
}


--- Create a model widget for the 3D viewer.
--- @param unitID any
--- @return unknown
local function CreateModelWidget(unitID)
    local modelWidget = RanothUtilsGUI:Create("SimpleGroup")
    modelWidget:SetFullWidth(true)
    modelWidget:SetFullHeight(true)
    modelWidget:SetLayout("Fill")

    local modelViewer = CreateFrame("PlayerModel", nil, modelWidget.frame)
    modelViewer:SetAllPoints()
    modelViewer:SetUnit(unitID)

    modelViewer.x = 0
    modelViewer.y = 0
    modelViewer.z = 0
    modelViewer.deltaX = 0

    --- Set the facing of the model viewer.
    --- @param deltaX number
    function modelViewer:SetRotation(deltaX)
        self.deltaX = self.deltaX + (deltaX * 0.01)
        self:SetFacing(self.deltaX)
    end

    --- Update the position of the model viewer.
    --- @param x number
    --- @param y number
    --- @param z number
    function modelViewer:UpdatePosition(x, y, z)
        self.x = self.x + (x * 0.05)
        self.y = self.y + (y * 0.005)
        self.z = self.z + (z * 0.005)
        self:SetPosition(self.x, self.y, self.z)
    end

    --- Update the position and zoom of the model viewer.
    --- @param x number
    --- @param y number
    --- @param z number
    function modelViewer:UpdatePositionZoom(x, y, z)
        self.x = self.x + (x * 0.2)
        self.y = self.y + (y * 0.02)
        self.z = self.z + (z * 0.02)
        self:SetPosition(self.x, self.y, self.z)
    end

    modelViewer:SetScript("OnMouseWheel", function(self, delta)
        modelViewer:UpdatePositionZoom(delta, 0, 0)
    end)

    local isDragging = false
    local buttonDown

    modelViewer:SetScript("OnMouseDown", function(self, button)
        isDragging = true
        buttonDown = button
    end)

    modelViewer:SetScript("OnMouseUp", function(self, button)
        isDragging = false
        buttonDown = nil
    end)

    modelViewer:SetScript("OnUpdate", function(self, elapsed)
        if isDragging and buttonDown == "LeftButton" then
            local deltaX, deltaY = GetScaledCursorDelta()
            modelViewer:SetRotation(deltaX)
        elseif isDragging and buttonDown == "RightButton" then
            local x, y, z = GetScaledCursorDelta()
            modelViewer:UpdatePosition(0, x, y)
        end
    end)

    --- Release the model widget. Needed because the model viewer is not an AceGUI widget.
    function modelWidget:Release()
        if modelViewer then
            modelViewer:Hide()
            modelViewer:SetParent(nil)
            modelViewer = nil
        end
    end

    return modelWidget
end

--- Create a frame for the 3D viewer.
--- @param unitGUID string
--- @param unitID any
function RanothUtils:CreateThreeDViewerFrame(unitGUID, unitID)
    if not unitGUID then
        Debug:Print("Error: unitGUID is nil in CreateThreeDViewerFrame")
        return
    end

    local _, _, _, _, _, unitName = GetPlayerInfoByGUID(unitGUID)
    if unitName == null then unitName = UnitName(unitID) end
    

    local frame = RanothUtilsGUI:Create("Frame")
    frame:SetTitle(unitName or unitGUID)
    frame:SetStatusText(unitGUID)
    frame:SetHeight(800)
    frame:SetWidth(700)
    frame:SetLayout("Flow")

    local modelWidget = CreateModelWidget(unitID)
    frame:AddChild(modelWidget)

    frame:SetCallback("OnClose", function(widget)
        RanothUtilsGUI:Release(widget)
        modelWidget:Release()
    end)
end

--- Add a button to the dropdown menu.
--- @param name string
--- @param level number
--- @param func function
local function addButton(name, level, func)
    local buttonExists = false
    for i = 1, UIDROPDOWNMENU_MAXBUTTONS do
        local button = _G["DropDownList1Button" .. i]
        if button and button:IsShown() and button:GetText() == name then
            buttonExists = true
            break
        end
    end

    if buttonExists then return end

    local info = UIDropDownMenu_CreateInfo()
    info.text, info.notCheckable, info.owner = name, true, which
    info.func = func

    UIDropDownMenu_AddButton(info, level)
end

--- Show the 3D viewer in the dropdown menu.
--- @param dropdownMenu any
--- @param which string
--- @param unitID any
--- @param name string
--- @param userData any
function RanothUtils:UnitPopup_ShowMenu(dropdownMenu, which, unitID, name, userData)
    if not tContains(which_list, which) then return end

    addButton("View model", 1, function()
        RanothUtils:CreateThreeDViewerFrame(UnitGUID(unitID), unitID)
    end)
end

function ThreeDViewer:OnEnable()
    RanothUtils:Hook("UnitPopup_ShowMenu", true)
end

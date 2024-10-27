--- A module to handle the 3D viewer for the addon.
--- @module "ThreeDViewer"

local addon_name, _ = ...
local RanothUtils = LibStub("AceAddon-3.0"):GetAddon(addon_name)
local ThreeDViewer = RanothUtils:NewModule("ThreeDViewer")

local Debug = RanothUtils:GetModule("Debug")
local Printer = RanothUtils:GetModule("Printer")

local RanothUtilsGUI = LibStub("AceGUI-3.0")

--- Create a model widget for the 3D viewer.
--- @param unitID any
--- @param displayID number?
--- @return unknown
local function CreateModelWidget(unitID, displayID)
    local modelWidget = RanothUtilsGUI:Create("SimpleGroup")
    modelWidget:SetFullWidth(true)
    modelWidget:SetFullHeight(true)
    modelWidget:SetLayout("Fill")

    local modelViewer = CreateFrame("PlayerModel", nil, modelWidget.frame)
    modelViewer:SetAllPoints()
    if not displayID then
        modelViewer:SetUnit(unitID)
    elseif displayID then
        modelViewer:SetDisplayInfo(displayID)
    end

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

    --- Update the position of the model viewer quicker.
    --- @param x number
    --- @param y number
    --- @param z number
    function modelViewer:UpdatePositionFaster(x, y, z)
        self.x = self.x + (x * 0.2)
        self.y = self.y + (y * 0.02)
        self.z = self.z + (z * 0.02)
        self:SetPosition(self.x, self.y, self.z)
    end

    modelViewer:SetScript("OnMouseWheel", function(self, delta)
        modelViewer:UpdatePositionFaster(delta, 0, 0)
    end)

    local isDragging = false
    local buttonDown

    modelViewer:SetScript("OnMouseDown", function(self, button)
        isDragging = true
        buttonDown = button
    end)

    modelViewer:SetScript("OnMouseUp", function(self, _)
        isDragging = false
        buttonDown = nil
    end)

    modelViewer:SetScript("OnUpdate", function(self, _)
        if isDragging and buttonDown == "LeftButton" then
            local deltaX, _ = GetScaledCursorDelta()
            modelViewer:SetRotation(deltaX)
        elseif isDragging and buttonDown == "RightButton" then
            local x, y, _ = GetScaledCursorDelta()
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
--- @param displayID number?
function ThreeDViewer:CreateThreeDViewerFrame(unitGUID, unitID, displayID)
    local unitName
    if not displayID then
        if not unitGUID then
            Debug:Print("Error: unitGUID is nil in CreateThreeDViewerFrame")
            return
        end

        _, _, _, _, _, unitName = GetPlayerInfoByGUID(unitGUID)
        if unitName == nil then unitName = UnitName(unitID) end
    end

    local frame = RanothUtilsGUI:Create("Frame")
    if not displayID then
        frame:SetTitle(unitName or unitGUID)
        frame:SetStatusText("GUID: " .. unitGUID)
    else
        frame:SetTitle("Name unavailable")
        frame:SetStatusText("Display ID: " .. displayID)
    end
    frame:SetHeight(800)
    frame:SetWidth(700)
    frame:SetLayout("Flow")

    local modelWidget
    if not displayID then modelWidget = CreateModelWidget(unitID) else modelWidget = CreateModelWidget(nil, displayID) end
    frame:AddChild(modelWidget)

    frame:SetCallback("OnClose", function(widget)
        RanothUtilsGUI:Release(widget)
        modelWidget:Release()
    end)

    _G["ThreeDViewerFrame"] = frame
    table.insert(UISpecialFrames, "ThreeDViewerFrame")
end

--- Inject the button in the unit menu.
local function InjectButtonInUnitMenu()
    local unitMenus = {
        "MENU_UNIT_PLAYER",
        "MENU_UNIT_ENEMY_PLAYER",
        "MENU_UNIT_TARGET",
        "MENU_UNIT_SELF",
        "MENU_UNIT_PET",
        "MENU_UNIT_PARTY1",
        "MENU_UNIT_RAID",
    }

    for _, menu in pairs(unitMenus) do
        if not ThreeDViewer:IsEnabled() then return end
        Menu.ModifyMenu(menu, function(_, rootDescription, contextData)
            rootDescription:CreateDivider()
            rootDescription:CreateTitle("Ranoth's Utility")
            rootDescription:CreateButton("View model", function()
                ThreeDViewer:CreateThreeDViewerFrame(UnitGUID(contextData.unit), contextData.unit)
            end)
        end)
    end
end

--- Toggle button on or off.
function ThreeDViewer:Toggle()
    if ThreeDViewer:IsEnabled() then
        ThreeDViewer:Disable()
    else
        ThreeDViewer:Enable()
    end
    Printer:Print(ThreeDViewer:IsEnabled() and "3D Viewer button enabled" or "3D Viewer button disabled")
    if not ThreeDViewer:IsEnabled() then
        ReloadUI()
    end
end

function ThreeDViewer:OnInitialize()
    self.db = RanothUtils.db.profile.threeDViewer
    if self.db then
        self:Enable()
    else
        self:Disable()
    end
end

function ThreeDViewer:OnEnable()
    InjectButtonInUnitMenu()
    RanothUtils.db.profile.threeDViewer = ThreeDViewer:IsEnabled()
end

function ThreeDViewer:OnDisable()
    RanothUtils.db.profile.threeDViewer = ThreeDViewer:IsEnabled()
end

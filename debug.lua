local Debug = RanothUtils:NewModule("Debug")

local toggled = false

local chatTabName = "Debug" -- replace with the name of your chat tab
local chatFrameIndex = 1    -- replace with the index of your chat frame
local chatFrame = _G["ChatFrame" .. chatFrameIndex]
local chatTab

for i = 1, NUM_CHAT_WINDOWS do
    local name = GetChatWindowInfo(i)
    if name == chatTabName then
        chatTab = _G["ChatFrame" .. i]
        break
    end
end

local function createToggledFunction(func)
    return function(...)
        if not toggled then return end
        return func(...)
    end
end

function Debug:Toggle()
    toggled = not toggled
    if toggled then
        print("Debug mode enabled")
    else
        print("Debug mode disabled")
    end
end

Debug.Print = createToggledFunction(function(...)
    local args = { ... }
    for i = 1, #args do
        args[i] = tostring(args[i])
    end
    chatTab:AddMessage(table.concat(args, " "))
end)

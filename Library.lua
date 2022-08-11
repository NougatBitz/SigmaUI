local UserInputService = game:GetService("UserInputService")

local SigmaUtil = loadstring(game.HttpGet(game, "https://raw.githubusercontent.com/NougatBitz/SigmaUI/main/Utility.lua"))()
local Objects   = game:GetObjects("rbxassetid://10551224467")[1];

local TabFunctions = {} do
    TabFunctions.__index = TabFunctions

    function TabFunctions:Button(Data)
        local ButtonObject = SigmaUtil:CreateButtonObject(self.Tab, Data.Title)
        
        SigmaUtil:InitButton(ButtonObject, Data.Callback)

        local SettingsObject = SigmaUtil:CreateSettingsTab(ButtonObject)
        local Functions = SigmaUtil:InitSettingsTab(SettingsObject)

        return Functions
    end


    function TabFunctions:Toggle(Data)
        local ToggleObject = SigmaUtil:CreateToggleObject(self.Tab, Data.Title)
        
        local Toggle = SigmaUtil:InitToggle(ToggleObject, Data.Callback) do
            Toggle:Set(Data.Default or false)
        end

        local SettingsObject = SigmaUtil:CreateSettingsTab(ToggleObject)
        local Functions = SigmaUtil:InitSettingsTab(SettingsObject)
        
        return Functions, Toggle
    end
end

local Sigma = {} do
    function Sigma:InitMain()
        local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
        
        local MainFrame = Objects.MainFrame:Clone() do
            MainFrame.Parent = ScreenGui
        end

        SigmaUtil:InitUI(MainFrame, Objects)
    end

    function Sigma:NewTab(Data)
        local TabObject = SigmaUtil:CreateTab(Data.Title, Data.Icon)
        return setmetatable({
            Tab = TabObject
        }, TabFunctions)
    end
end

local IsVisible = true;
UserInputService.InputBegan:Connect(function(input, gme)
    if not gme then
        if input.KeyCode == Enum.KeyCode.RightShift then
            IsVisible = not IsVisible
            if IsVisible then
                SigmaUtil:ShowUI()
            else
                SigmaUtil:HideMain()
            end
        end
    end
end)

return Sigma, SigmaUtil

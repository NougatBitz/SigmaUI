local IsLocal = false

local UserInputService = game:GetService("UserInputService")

local Utility = (IsLocal and readfile("SigmaUI\\Utility.lua")) or game:HttpGet("https://raw.githubusercontent.com/NougatBitz/SigmaUI/main/Utility.lua")
local SigmaUtil = loadstring(Utility)()

local IsVisible = true
UserInputService.InputBegan:Connect(function(Input, GPE)
    if (not GPE) then
        if Input.KeyCode == Enum.KeyCode.RightAlt then
            IsVisible = not IsVisible

            if IsVisible then
                SigmaUtil:ShowUI()
            else
                SigmaUtil:HideMain()
            end
        end
    end
end)

local Objects = game.GetObjects(game, "rbxassetid://10551224467")[1] do
    local SpecialColors = {
        ["SettingsFrame"] = Color3.fromRGB(15, 15, 15);
        ["ToggleIndicator"] = Color3.fromRGB(33, 33, 33);
        ["BackgroundFrame"] = Color3.fromRGB(5, 5, 5);
    }
    
    function InvertColor(color)
        return Color3.new(1 - color.R, 1 - color.G, 1 - color.B)
    end

    local CachedProperties = {}
    for i,v in next, Objects:GetDescendants() do
        local Properties = CachedProperties[v.ClassName] or getproperties(v)
        
        if (not CachedProperties[v.ClassName]) then
            CachedProperties[v.ClassName] = Properties
        end
        
        for i2,v2 in next, Properties do
            if i2:find("Color3") then
                v[i2] = SpecialColors[v.Name] or InvertColor(v2)
            end
        end
    end
end

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

return Sigma, SigmaUtil

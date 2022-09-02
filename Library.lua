local IsLocal = false

local CustomObjectColors = {
    ["SettingsFrame"]   = Color3.fromRGB(17, 17, 24);
    ["ToggleIndicator"] = Color3.fromRGB(89, 92, 150);
    ["BackgroundFrame"] = Color3.fromRGB(30, 30, 42);
    ["ObjectSettings"]  = Color3.fromRGB(200,200,200);
    ["TabButton"]       = Color3.fromRGB(200, 200, 200);
    ["BackButton"]      = Color3.fromRGB(89, 92, 150);
}

local ReplacementColors = {
    ["255, 255, 255"] = Color3.fromRGB(30, 30, 42);     -- white / main color
    ["27, 42, 53"]    = Color3.fromRGB(0,0,0);          -- outline (unused)
    ["0, 0, 0"]       = Color3.fromRGB(255, 255, 255);  -- black (text/icons)
    ["210, 211, 212"] = Color3.fromRGB(17, 17, 24);     -- SettingsHolder
    ["107, 107, 107"] = Color3.fromRGB(30, 30, 42);     -- Background color 
    ["16, 16, 16"]    = Color3.fromRGB(255, 255, 255);  -- ImageColor3
    ["127, 191, 156"] = Color3.fromRGB(89, 92, 150);    -- toggle indicator bgc
    ["144, 145, 145"] = Color3.fromRGB(17, 17, 24);     -- DropdownItemHolder
    ["191, 191, 191"] = Color3.fromRGB(89, 92, 150);    -- slider dot/ toggle indicator bgc
    ["168, 168, 168"] = Color3.fromRGB(89, 92, 150);    -- outline thing
}

local RoundingObjects = {
    ["InfoFrame"] = true;
}

local Utility = (IsLocal and readfile("SigmaUI\\Utility.lua")) or game:HttpGet("https://raw.githubusercontent.com/NougatBitz/SigmaUI/main/Utility.lua")
local SigmaUtil = loadstring(Utility)()

function Color3ToRGB(C3)
    return table.concat({
        math.floor(C3.R * 255), 
        math.floor(C3.G * 255),
        math.floor(C3.B * 255)
    }, ", ")
end

function RoundObject(Object)
    local UICorner        = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 4)
    UICorner.Parent       = Object

    return UICorner
end

local Objects = game.GetObjects(game, "rbxassetid://10551224467")[1] do
    --// Replace old "SettingsFrame", since i messed it up and made it a ScrollingFrame

    local NewSettingsFrame = Instance.new("Frame") do
        for _, CurrentObject in next, Objects.SettingsFrame:GetChildren() do
            CurrentObject:Clone().Parent = NewSettingsFrame 
        end

        for Property, Value in next, getproperties(Objects.SettingsFrame) do
            pcall(function()
                NewSettingsFrame[Property] = Value
            end)
        end
        
        Objects.SettingsFrame:Destroy()
    end
    RoundObject(NewSettingsFrame)
    NewSettingsFrame.Parent = Objects

    --// Check all Descendants to apply certain changes
    local CachedProperties = {}
    for i,v in next, Objects:GetDescendants() do

        --// Round Objects
        if RoundingObjects[v.Name] then
            RoundObject(v)
        end 

        --// Replace Colors
        local Properties = CachedProperties[v.ClassName] or getproperties(v)
        
        if (not CachedProperties[v.ClassName]) then
            CachedProperties[v.ClassName] = Properties
        end
        
        for i2,v2 in next, Properties do
            if typeof(v2) == "Color3" then
                v[i2] = CustomObjectColors[v.Name] or ReplacementColors[Color3ToRGB(v2)]
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
    function Sigma:InitMain(Name)
        local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
        
        local MainFrame = Objects.MainFrame:Clone() do
            MainFrame.Parent = ScreenGui
        end
        table.foreach(SigmaUtil, warn)
        SigmaUtil:AddDrag(MainFrame)

        SigmaUtil:InitUI(MainFrame, Objects, {
            Title = Name;
        })
    end

    function Sigma:NewTab(Data)
        local TabObject = SigmaUtil:CreateTab(Data.Title, Data.Icon)
        return setmetatable({
            Tab = TabObject
        }, TabFunctions)
    end
end

local IsVisible = true
game:GetService("UserInputService").InputBegan:Connect(function(Input, GPE)
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

return Sigma, SigmaUtil

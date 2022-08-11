--// Variables
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Sizes = {
	MainFrame = {
		OnTab = UDim2.new(0, 650, 0, 720);
		OnMenu = UDim2.new(0, 450, 0, 570);
	};
	BackgroundFrame = {
		OnTab 	= UDim2.new(1, 0, 1, 0);
		OnMenu 	= UDim2.new(1, 0, 1, 0);
		OnInit 	= UDim2.new(1, -150, 1, -150);
	};
	TabHolder = {
		OnTab = UDim2.new(1, -60, 1, -75);
		OnMenu = UDim2.new(1, -60,0, 0);
	};
	SettingsFrame = {
		Open = UDim2.new(1, 0, 1, 0);
		Closed = UDim2.new(1, 0,0, 0);
	}
}

local Positions = {
	Toggle = {
		[false] = UDim2.new(0,2,0,2);
		[true]  = UDim2.new(1,-17,0,2);
	};
}


--// Load Utility Module
local Utility = {
	CachedProperties = {}; 
	CurrentTab = nil; 
	CurrentSettings = false;
	MainUI = {};
	Objects = nil;
	Tabs = {};
	SettingsFunctions = {};
}
Utility.SettingsFunctions.__index = Utility.SettingsFunctions

--// https://github.com/Aztup/DrawingLibrary/blob/master/Main.lua
function Utility:ConvertToDarkColor(color)
	local h, s, v = Color3.toHSV(color);
	v = v - 0.25;

	return Color3.fromHSV(h, s, v);
end;

function Utility:ConvertToLightColor(color)
	local h, s, v = Color3.toHSV(color);
	v = v + 0.25;

	return Color3.fromHSV(h, s, v);
end;

function Utility:HoverEffect(Trigger, Object, Property)
	Trigger.MouseEnter:Connect(function()
		Object[Property] = self:ConvertToLightColor(Object[Property])
	end)

	Trigger.MouseLeave:Connect(function()
		Object[Property] = self:ConvertToDarkColor(Object[Property])
	end)
end

function Utility:Random()
	return HttpService:GenerateGUID(false)
end

--// Linoria Rewrite UI Library (i suck at math and)
function Utility:MapValue(Value, MinA, MaxA, MinB, MaxB)
	return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB;
end;


function Utility:HasProperty(Object, Property)
	if self.CachedProperties[Object.ClassName] then
		return true, Object[Property]
	end

	local Success, Result = pcall(function()
		return Object[Property]
	end)

	if Success then
		self.CachedProperties[Object.ClassName] = true

		return Success, Result
	end
end

function Utility:GetCanvasSize(Frame, EachRow)
	local GridLayout = Frame:FindFirstChildOfClass("UIGridLayout")
	if GridLayout then
		local CellPadding   = GridLayout.CellPadding
		local CellSize      = GridLayout.CellSize

		return UDim2.new(1,0,0,((#Frame:GetChildren() - 1) / EachRow) * (CellSize.Y.Offset + CellPadding.Y.Offset) )
	else
		local YSize = 0
		for i,v in next, Frame:GetChildren() do
			if v:IsA("GuiBase") then
				YSize = YSize + v.AbsoluteSize.Y
			end
		end
		return UDim2.new(1,0,0,YSize)
	end
end

function Utility:TweenProperties(Objects, Properties, Identifier)
	Identifier = Identifier or "Name"

	local Tweens = {} do
		for _, Object in next, Objects do 
			local Data = Properties[Object[Identifier]]
			if Data then
				Tweens[#Tweens + 1] = TweenService:Create(Object, Data.TweenInfo, Data.TweenTable)
			end
		end
	end

	for i,v in next, Tweens do
		v:Play()
	end
end

function Utility:ToggleMainElement(Object, State)
	local Transparency = (State and 0 or 1)

	local Background = Object:FindFirstChildOfClass("Frame")
	local TitleLabel = Object.TitleLabel
	local BindText   = Object.BindText

	local BindLabel  = BindText.BindLabel
	local UIStroke   = Background.UIStroke

	local ObjectSettings = Object.ObjectSettings


	local TweenObjects = { Background, TitleLabel, BindText, BindLabel, UIStroke, ObjectSettings }


	local ToggleIndicator = Background:FindFirstChildOfClass("Frame")
	if ToggleIndicator then
		table.insert(TweenObjects, ToggleIndicator)
	end

	self:TweenProperties(TweenObjects, {
		["TextLabel"] = {
			TweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad);
			TweenTable = { TextTransparency =  Transparency};
		};
		["ImageButton"] = {
			TweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad);
			TweenTable = { ImageTransparency =  Transparency};
		};
		["Frame"] = {
			TweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad);
			TweenTable = { BackgroundTransparency = (State and 0.3 or 1)};
		};
		["UIStroke"] = {
			TweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad);
			TweenTable = { Transparency = (State and 0.3 or 1)};
		};
	}, "ClassName")
end

function Utility:TweenLabel(Label, Text)
	TweenService:Create(Label, TweenInfo.new(0.25, Enum.EasingStyle.Circular), { TextTransparency = 1 }):Play()
	Label.Text = Text
	TweenService:Create(Label, TweenInfo.new(0.25, Enum.EasingStyle.Circular), { TextTransparency = 0 }):Play()
end

function Utility:InitUI(MainFrame, Objects)
	self.Objects = Objects
	local BackgroundFrame 	= MainFrame.BackgroundFrame
	local TitleLabel 		= MainFrame.TitleLabel
	local TabButtonHolder 	= MainFrame.TabButtonHolder
	local TabHolder 		= MainFrame.TabHolder
	local BackButton 		= MainFrame.BackButton
	local SettingsHolder 	= TabHolder.SettingsHolder

	self.MainUI = {
		ScreenGui       = MainFrame.Parent;
		MainFrame       = MainFrame;
		BackgroundFrame = BackgroundFrame;
		TitleLabel 		= TitleLabel;
		TabButtonHolder = TabButtonHolder;
		TabHolder 		= TabHolder;
		BackButton 		= BackButton;
		SettingsHolder 	= SettingsHolder;
	}

	--// Reset UI to default
	for i,v in next, TabHolder:GetChildren() do
		if v ~= SettingsHolder then
			v.Visible = false
			for _, UIElement in next, v:GetChildren() do
				if UIElement:IsA("Frame") then
					self:ToggleMainElement(UIElement, false)
				end
			end
		end
	end

	BackgroundFrame.Size 	= Sizes.BackgroundFrame.OnInit
	MainFrame.Size 			= Sizes.MainFrame.OnMenu
	TabHolder.Size			= Sizes.TabHolder.OnMenu

	BackgroundFrame.BackgroundTransparency = 1
	BackButton.ImageTransparency = 1
	TitleLabel.TextTransparency  = 1

	self:TweenProperties(self.MainUI.TabButtonHolder:GetDescendants(), {
		["TabButton"] = {
			TweenInfo = TweenInfo.new(0);
			TweenTable = { ImageTransparency = 1 };
		};
		["TitleLabel"] = {
			TweenInfo = TweenInfo.new(0);
			TweenTable = { 
				TextTransparency = 1;
			};
		};
	})

	--// Connections
	BackButton.MouseButton1Click:Connect(function()
		if self.CurrentSettings then
			Utility:CloseSettings()
			return
		end

		if self.CurrentTab then
			Utility:CloseTab(self.CurrentTab)
			return
		end
	end)
end

function Utility:OpenTab(Tab, Title)
	if self.CurrentTab then
		return
	end

	self.CurrentTab = Tab

	Tab.Visible = true

	self.MainUI.BackgroundFrame.Size = Sizes.BackgroundFrame.OnTab

	self:TweenProperties(self.MainUI.TabButtonHolder:GetDescendants(), {
		["TabButton"] = {
			TweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad);
			TweenTable = { ImageTransparency = 1 };
		};
		["TitleLabel"] = {
			TweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad);
			TweenTable = { TextTransparency = 1 };
		};
	})

	TweenService:Create(self.MainUI.MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Circular), { Size = Sizes.MainFrame.OnTab }):Play()

	self.MainUI.TabHolder.Size = Sizes.TabHolder.OnTab

	self:TweenLabel(self.MainUI.TitleLabel, (Title or Tab.Name) )

	task.wait(0.2)

	for _, UIElement in next, Tab:GetChildren() do
		if UIElement:IsA("Frame") then
			self:ToggleMainElement(UIElement, true)
		end
	end

	TweenService:Create(self.MainUI.BackButton, TweenInfo.new(0.25, Enum.EasingStyle.Circular), { ImageTransparency = 0 }):Play()
end

function Utility:CloseTab(Tab)
	for _, UIElement in next, Tab:GetChildren() do
		if UIElement:IsA("Frame") then
			self:ToggleMainElement(UIElement, false)
		end
	end

	TweenService:Create(self.MainUI.BackButton, TweenInfo.new(0.35, Enum.EasingStyle.Circular), { ImageTransparency = 1 }):Play()
	TweenService:Create(self.MainUI.MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Circular), { Size = Sizes.MainFrame.OnMenu }):Play()

	self.MainUI.TabHolder.Size = Sizes.TabHolder.OnMenu

	self:TweenLabel(self.MainUI.TitleLabel, "Main Menu")

	self:TweenProperties(self.MainUI.TabButtonHolder:GetDescendants(), {
		["TabButton"] = {
			TweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad);
			TweenTable = { ImageTransparency = 0 };
		};
		["TitleLabel"] = {
			TweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad);
			TweenTable = { TextTransparency = 0 };
		};
	})

	self.MainUI.BackgroundFrame.Size = Sizes.BackgroundFrame.OnMenu

	Tab.Visible = false

	self.CurrentTab = nil
end

function Utility:OpenSettings(SettingsFrame)
	if self.CurrentSettings then
		return
	end

	SettingsFrame.Visible = true
	self.CurrentSettings = SettingsFrame

	for _, UIElement in next, self.CurrentTab:GetChildren() do
		if UIElement:IsA("Frame") then
			self:ToggleMainElement(UIElement, false)
		end
	end

	TweenService:Create(SettingsFrame, TweenInfo.new(0.15), { Size = Sizes.SettingsFrame.Open }):Play()
end

function Utility:CloseSettings()
	TweenService:Create(self.CurrentSettings, TweenInfo.new(0.15), { Size = Sizes.SettingsFrame.Closed }):Play()

	for _, UIElement in next, self.CurrentTab:GetChildren() do
		if UIElement:IsA("Frame") then
			self:ToggleMainElement(UIElement, true)
		end
	end

	self.CurrentSettings = nil
end

function Utility:ShowUI()
	self:TweenLabel(self.MainUI.TitleLabel, "Main Menu")

	TweenService:Create(self.MainUI.BackgroundFrame, TweenInfo.new(0.25, Enum.EasingStyle.Circular), { BackgroundTransparency = 0.15 }):Play()
	TweenService:Create(self.MainUI.BackgroundFrame, TweenInfo.new(0.25, Enum.EasingStyle.Circular), { Size = Sizes.BackgroundFrame.OnMenu }):Play()

	self:TweenProperties(self.MainUI.TabButtonHolder:GetDescendants(), {
		["TabButton"] = {
			TweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad);
			TweenTable = { ImageTransparency = 0 };
		};
		["TitleLabel"] = {
			TweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad);
			TweenTable = { TextTransparency = 0 };
		};
	})

	TweenService:Create(self.MainUI.TitleLabel, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { TextTransparency = 0 }):Play()
end

function Utility:HideMain()
	if self.CurrentSettings then 
		self:CloseSettings()
		task.wait(0.25)
	end

	if self.CurrentTab then 
		self:CloseTab(self.CurrentTab) 
		task.wait(0.25)
	end

	TweenService:Create(self.MainUI.BackgroundFrame, TweenInfo.new(0.25, Enum.EasingStyle.Circular), { Size = Sizes.BackgroundFrame.OnInit }):Play()
	TweenService:Create(self.MainUI.BackgroundFrame, TweenInfo.new(0.25, Enum.EasingStyle.Circular), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(self.MainUI.MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Circular), { Size = Sizes.MainFrame.OnMenu }):Play()
	TweenService:Create(self.MainUI.TabHolder, TweenInfo.new(0.25, Enum.EasingStyle.Circular), { Size = Sizes.TabHolder.OnMenu }):Play()

	self:TweenProperties(self.MainUI.TabButtonHolder:GetDescendants(), {
		["TabButton"] = {
			TweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad);
			TweenTable = { ImageTransparency = 1 };
		};
		["TitleLabel"] = {
			TweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad);
			TweenTable = { TextTransparency = 1 };
		};
	})

	TweenService:Create(self.MainUI.TitleLabel, TweenInfo.new(0.25, Enum.EasingStyle.Circular), { TextTransparency = 1 }):Play()
end

function Utility:CreateTab(Name, Icon)
	local TabButton  = self.Objects.TabButton:Clone()
	TabButton.Parent = self.MainUI.TabButtonHolder
	TabButton.TitleLabel.Text = Name
    TabButton.Image = Icon

	local TabFrame  = self.Objects.TabFrame:Clone()
	TabFrame.Name   = self:Random()
	TabFrame.Parent = self.MainUI.TabHolder
	TabFrame.Visible = false
	TabFrame.ScrollBarThickness = 0

	TabButton.MouseButton1Click:Connect(function()
		self:OpenTab(TabFrame, Name)
	end)

	self.Tabs[TabButton] = {
		Frame = TabFrame;
		Title = Name;
	}

	return TabFrame
end

function Utility:InitMainElement()
end

function Utility:CreateToggleObject(Parent, Title)
	local ToggleFrame  = self.Objects.ToggleFrame:Clone()

	ToggleFrame.Parent = Parent
	ToggleFrame.TitleLabel.Text = Title

	if Parent:IsA("ScrollingFrame") then
		Parent.CanvasSize = self:GetCanvasSize(Parent, 3)
	end

	self:ToggleMainElement(ToggleFrame, false)

	return ToggleFrame
end

function Utility:InitToggle(ToggleFrame, Callback)
	local ToggleBackground = ToggleFrame.ToggleBackground
	local ToggleIndicator  = ToggleBackground.ToggleIndicator
	local Trigger		   = ToggleBackground.Trigger
	local UIStroke		   = ToggleBackground.UIStroke

	local ObjectSettings   = ToggleFrame:FindFirstChild("ObjectSettings")

	local Enabled          = false

	local LightColor = Utility:ConvertToLightColor(ToggleIndicator.BackgroundColor3)
	local NormalColor = ToggleIndicator.BackgroundColor3

	if ObjectSettings then
		Utility:HoverEffect(ObjectSettings, ObjectSettings, "ImageColor3")
	end

	Trigger.MouseButton1Down:Connect(function()
		Enabled = not Enabled

		Callback(Enabled)

		TweenService:Create(ToggleIndicator, TweenInfo.new(0.15), {
			Position            = Positions.Toggle[Enabled];
			BackgroundColor3    = Enabled and LightColor or NormalColor,
		}):Play()
	end)

	return {
		Set = function(self, Value)
			Enabled = Value or false

			Callback(Enabled)

			ToggleIndicator.Position = Positions.Toggle[Enabled]
			ToggleIndicator.BackgroundColor3 = Enabled and LightColor or NormalColor;
		end
	}
end

function Utility:CreateButtonObject(Parent, Title)
	local ButtonFrame  = self.Objects.ButtonFrame:Clone()

	ButtonFrame.Parent = Parent
	ButtonFrame.TitleLabel.Text = Title

	if Parent:IsA("ScrollingFrame") then
		Parent.CanvasSize = self:GetCanvasSize(Parent, 3)
	end

	self:ToggleMainElement(ButtonFrame, false)

	return ButtonFrame
end

function Utility:InitButton(ButtonFrame, Callback)
	local ButtonBackground = ButtonFrame.ButtonBackground
	local Trigger		   = ButtonBackground.Trigger
	local UIStroke		   = ButtonBackground.UIStroke

	local LightColor    = Utility:ConvertToLightColor(ButtonBackground.BackgroundColor3)
	local NormalColor   = ButtonBackground.BackgroundColor3

	Utility:HoverEffect(ButtonFrame.ObjectSettings, ButtonFrame.ObjectSettings, "ImageColor3")

	Trigger.MouseButton1Down:Connect(function()
		TweenService:Create(ButtonBackground, TweenInfo.new(0.15), {
			BackgroundColor3 = LightColor
		}):Play()
	end)

	Trigger.MouseButton1Up:Connect(function()
		TweenService:Create(ButtonBackground, TweenInfo.new(0.15), {
			BackgroundColor3 = NormalColor
		}):Play()
	end)

	Trigger.MouseButton1Click:Connect(function()
		Callback()
	end)
end

function Utility:CreateSettingsTab(ObjectFrame)
	local ObjectName = ObjectFrame.TitleLabel.Text .. "'s Settings"

	local NewSettingsFrame  = self.Objects.SettingsFrame:Clone()
	NewSettingsFrame.Parent = self.MainUI.SettingsHolder

	NewSettingsFrame.TitleLabel.Text = ObjectName

	ObjectFrame.ObjectSettings.MouseButton1Down:Connect(function()
		self:OpenSettings(NewSettingsFrame)
	end)

	return NewSettingsFrame
end

function Utility:AddListToHolder(List, Holder, Callback, Close)
	for i,v in next, Holder:GetChildren() do
		if v:IsA("TextButton") then 
			v:Destroy() 
		end
	end

	for i,v in next, List do
		local ListButton = self.Objects.ButtonItem:Clone()
		ListButton.Parent = Holder

		ListButton.ZIndex = 1000

		ListButton.Text = i
		ListButton.MouseButton1Down:Connect(function()
			Callback(v)
			Close(i,v)
		end)
	end
end

function Utility:InitSettingsTab(SettingsFrame)
	return setmetatable({
		Parent = SettingsFrame.Holder;
	}, Utility.SettingsFunctions)
end

function Utility.SettingsFunctions:Dropdown(Data)
	local IsVisible = false

	local NewDropdown = Utility.Objects.Dropdown:Clone() do
		NewDropdown.Parent = self.Parent
		NewDropdown.TitleLabel.Text = Data.Title
		NewDropdown.InfoFrame.InfoText.Text = Data.Information
	end

	local Trigger = NewDropdown.Trigger
	local ItemHolder = Trigger.DropdownItemHolder

	local CloseDropdown = function(index, value)
		Trigger.Text = index
		IsVisible = false

		TweenService:Create(Trigger.Indicator, TweenInfo.new(0.15), { Rotation = -90 }):Play()
		TweenService:Create(ItemHolder, TweenInfo.new(0.15), { Size = UDim2.new(1,0,0,0) }):Play()
	end

	local ToggleDropdown = function()
		IsVisible = not IsVisible
		local CanvasSize = Utility:GetCanvasSize(ItemHolder)
		local FrameSize  = IsVisible and UDim2.new(1,0,0, math.clamp(CanvasSize.Y.Offset, 0, 200)) or UDim2.new(1,0,0,0)
		local Rotation   = IsVisible and 90 or -90

		ItemHolder.CanvasSize = CanvasSize;

		TweenService:Create(Trigger.Indicator, TweenInfo.new(0.15), { Rotation = Rotation }):Play()
		TweenService:Create(ItemHolder, TweenInfo.new(0.15), { Size = FrameSize }):Play()
	end


	Utility:AddListToHolder(Data.List, ItemHolder, Data.Callback, CloseDropdown)

	Trigger.MouseButton1Down:Connect(ToggleDropdown)

	return {
		UpdateList = function(self, List)
			CloseDropdown()
			Utility:AddListToHolder(List, ItemHolder, Data.Callback, CloseDropdown)
		end;
	}
end

function Utility.SettingsFunctions:Toggle(Data)
	local NewToggle = Utility.Objects.Toggle:Clone() do
		NewToggle.Parent = self.Parent
		NewToggle.TitleLabel.Text = Data.Title
		NewToggle.InfoFrame.InfoText.Text = Data.Information
	end

	local Toggle = Utility:InitToggle(NewToggle, Data.Callback)

	Toggle:Set(Data.Default)

	return Toggle
end	

function Utility.SettingsFunctions:Slider(Data)
	local MouseDown = false

	Data.Min = Data.Min or 0
	Data.Max = Data.Max or 100
	Data.Value = (Data.Value or Data.Default) or (Data.Max / 2)

	local NewSlider = Utility.Objects.Slider:Clone() do
		NewSlider.Parent = self.Parent
		NewSlider.TitleLabel.Text = string.format("%s: %s", Data.Title, Data.Value)
		NewSlider.InfoFrame.InfoText.Text = Data.Information
	end

	local TitleLabel  = NewSlider.TitleLabel
	local SliderLimit = NewSlider.SliderLimit
	local SliderDot   = SliderLimit.SliderDot
	local Trigger     = SliderLimit.Trigger

	local function GetValueFromXOffset(X)
		return math.floor(Utility:MapValue(X, 0, 250, Data.Min, Data.Max));
	end

	SliderDot.Position = UDim2.new(0, math.ceil(Utility:MapValue(Data.Value, Data.Min, Data.Max, 0, 250)), 0.5, 0)


	UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then MouseDown = false end end)
	Trigger.MouseButton1Down:Connect(function() MouseDown = true end)
	Trigger.MouseButton1Up:Connect(function() MouseDown = false end)

	RunService.Heartbeat:Connect(function()
		if MouseDown then
			local MouseLocation = UserInputService:GetMouseLocation()

			local XLocation = math.clamp((MouseLocation.X - SliderLimit.AbsolutePosition.X), 0, 250)
			SliderDot.Position = UDim2.new(0, XLocation, 0.5, 0)

			Data.Value = GetValueFromXOffset(XLocation)

			Data.Callback(Data.Value)
			TitleLabel.Text = string.format("%s: %s", Data.Title, Data.Value)
		end;
	end);
end

return Utility

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "XieroxHUB",
    SubTitle = "v1.0.0",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

Fluent:ToggleTransparency(false)

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "sparkles" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

Tabs.Main:AddParagraph({
    Title = "Welcome to XieroxHUB",
    Content = "The interface is running on Fluent with customized branding."
})

local Toggle = Tabs.Main:AddToggle("MyToggle", {Title = "Auto Farm", Default = false })

Toggle:OnChanged(function()
    print("Toggle state:", Options.MyToggle.Value)
end)

local Slider = Tabs.Main:AddSlider("MySlider", {
    Title = "WalkSpeed",
    Min = 16,
    Max = 200,
    Default = 16,
    Rounding = 1,
    Callback = function(Value)
        pcall(function()
            game:GetService("Players").LocalPlayer.Character.Humanoid.WalkSpeed = Value
        end)
    end
})

local Dropdown = Tabs.Main:AddDropdown("MyDropdown", {
    Title = "Select Mob",
    Values = {"Aura Mob", "Boss Mob"},
    Default = 1,
})

Dropdown:OnChanged(function(Value)
    print("Dropdown selected:", Value)
end)

Tabs.Settings:AddButton({
    Title = "Unload Script",
    Description = "Completely closes the script interface.",
    Callback = function()
        Fluent:Destroy()
    end
})

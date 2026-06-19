--[[
    =========================================
                ORBIT HUB v2.5 (FE UPDATE)
        "The Next-Gen Multi-Game Executor GUI"
        Optimized for PC, Tablet, and Mobile
    =========================================
--]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Re-entrancy Check (Clean up older instances)
local parentGui = nil
pcall(function()
    parentGui = CoreGui
end)
if not parentGui or parentGui.ClassName ~= "CoreGui" then
    parentGui = LocalPlayer:WaitForChild("PlayerGui")
end

if parentGui:FindFirstChild("OrbitHub") then
    parentGui:FindFirstChild("OrbitHub"):Destroy()
end

-- =============================================================================
-- THEME SYSTEM & STYLING TOKENS
-- =============================================================================
local Themes = {
    OrbitBlue = {
        AccentGradient = {Color3.fromRGB(0, 210, 255), Color3.fromRGB(140, 50, 255)},
        Accent = Color3.fromRGB(0, 180, 255),
        Bg = Color3.fromRGB(16, 16, 22),
        SidebarBg = Color3.fromRGB(12, 12, 16),
        CardBg = Color3.fromRGB(24, 24, 32),
        Text = Color3.fromRGB(255, 255, 255),
        TextMuted = Color3.fromRGB(160, 160, 180),
        Border = Color3.fromRGB(45, 45, 60),
    },
    Crimson = {
        AccentGradient = {Color3.fromRGB(255, 30, 80), Color3.fromRGB(150, 10, 30)},
        Accent = Color3.fromRGB(255, 30, 80),
        Bg = Color3.fromRGB(18, 12, 12),
        SidebarBg = Color3.fromRGB(14, 8, 8),
        CardBg = Color3.fromRGB(28, 16, 16),
        Text = Color3.fromRGB(255, 240, 240),
        TextMuted = Color3.fromRGB(180, 150, 150),
        Border = Color3.fromRGB(60, 35, 35),
    },
    Emerald = {
        AccentGradient = {Color3.fromRGB(50, 230, 100), Color3.fromRGB(10, 120, 50)},
        Accent = Color3.fromRGB(50, 230, 100),
        Bg = Color3.fromRGB(12, 18, 14),
        SidebarBg = Color3.fromRGB(8, 14, 10),
        CardBg = Color3.fromRGB(18, 28, 22),
        Text = Color3.fromRGB(240, 255, 245),
        TextMuted = Color3.fromRGB(150, 180, 160),
        Border = Color3.fromRGB(35, 60, 45),
    },
    NeonPurple = {
        AccentGradient = {Color3.fromRGB(180, 50, 255), Color3.fromRGB(80, 0, 180)},
        Accent = Color3.fromRGB(180, 50, 255),
        Bg = Color3.fromRGB(15, 12, 20),
        SidebarBg = Color3.fromRGB(10, 8, 15),
        CardBg = Color3.fromRGB(24, 18, 32),
        Text = Color3.fromRGB(250, 240, 255),
        TextMuted = Color3.fromRGB(170, 150, 180),
        Border = Color3.fromRGB(50, 35, 60),
    },
    SunsetGold = {
        AccentGradient = {Color3.fromRGB(255, 140, 0), Color3.fromRGB(255, 50, 0)},
        Accent = Color3.fromRGB(255, 140, 0),
        Bg = Color3.fromRGB(18, 15, 12),
        SidebarBg = Color3.fromRGB(14, 11, 8),
        CardBg = Color3.fromRGB(28, 22, 18),
        Text = Color3.fromRGB(255, 250, 240),
        TextMuted = Color3.fromRGB(180, 170, 150),
        Border = Color3.fromRGB(60, 50, 35),
    }
}

local CurrentThemeName = "OrbitBlue"
local CurrentTheme = Themes[CurrentThemeName]
local RainbowTheme = false

-- =============================================================================
-- CONSTRUCTOR HELPERS
-- =============================================================================
local function create(className, properties)
    local instance = Instance.new(className)
    for k, v in pairs(properties) do
        instance[k] = v
    end
    return instance
end

local function applyCorner(parent, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
        Parent = parent
    })
end

local function applyStroke(parent, color, thickness, transparency)
    return create("UIStroke", {
        Color = color or CurrentTheme.Border,
        Thickness = thickness or 1.2,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent
    })
end

local function applyGradient(parent, colors)
    local sequence = {}
    for i, color in ipairs(colors) do
        table.insert(sequence, ColorSequenceKeypoint.new((i-1)/(#colors-1), color))
    end
    return create("UIGradient", {
        Color = ColorSequence.new(sequence),
        Rotation = 45,
        Parent = parent
    })
end

-- =============================================================================
-- MAIN UI CONTAINERS
-- =============================================================================
local ScreenGui = create("ScreenGui", {
    Name = "OrbitHub",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = parentGui
})

-- Top Floating Toggle Button (Minimized Button)
local ToggleButton = create("TextButton", {
    Name = "ToggleButton",
    Size = UDim2.new(0, 50, 0, 50),
    Position = UDim2.new(0.05, 0, 0.15, 0),
    BackgroundColor3 = CurrentTheme.SidebarBg,
    Text = "O",
    TextColor3 = CurrentTheme.Accent,
    TextSize = 22,
    Font = Enum.Font.FredokaOne,
    AutoButtonColor = false,
    Active = true,
    Visible = true,
    Parent = ScreenGui
})
applyCorner(ToggleButton, 25)
local toggleStroke = applyStroke(ToggleButton, CurrentTheme.Accent, 1.5)
local toggleGradient = applyGradient(ToggleButton, CurrentTheme.AccentGradient)

-- Main Frame UI
local MainFrame = create("Frame", {
    Name = "MainFrame",
    Size = UDim2.new(0, 620, 0, 390),
    Position = UDim2.new(0.5, -310, 0.5, -195),
    BackgroundColor3 = CurrentTheme.Bg,
    Active = true,
    BorderSizePixel = 0,
    Visible = false,
    ClipsDescendants = true,
    Parent = ScreenGui
})
applyCorner(MainFrame, 12)
local frameStroke = applyStroke(MainFrame, CurrentTheme.Border, 1.5)

-- Responsive Scaling Handler
local UIScale = create("UIScale", {
    Scale = 1.0,
    Parent = MainFrame
})

local function updateScale()
    local viewport = Camera.ViewportSize
    local scaleX = viewport.X / 660
    local scaleY = viewport.Y / 440
    local scaleFactor = math.min(scaleX, scaleY, 1.0)
    if scaleFactor < 0.55 then
        scaleFactor = 0.55
    end
    UIScale.Scale = scaleFactor
end
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
updateScale()

-- Smooth Draggable Integration
local function makeDraggable(frame, handle)
    local dragStart, startPos, dragInput
    local dragging = false

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local goal = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
            TweenService:Create(frame, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = goal
            }):Play()
        end
    end)
end

makeDraggable(MainFrame, MainFrame)
makeDraggable(ToggleButton, ToggleButton)

-- =============================================================================
-- SIDEBAR CREATION
-- =============================================================================
local Sidebar = create("Frame", {
    Name = "Sidebar",
    Size = UDim2.new(0, 165, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = CurrentTheme.SidebarBg,
    BorderSizePixel = 0,
    Parent = MainFrame
})
applyCorner(Sidebar, 12)
local sidebarSeparator = create("Frame", {
    Name = "Separator",
    Size = UDim2.new(0, 1, 1, 0),
    Position = UDim2.new(1, -1, 0, 0),
    BackgroundColor3 = CurrentTheme.Border,
    BorderSizePixel = 0,
    Parent = Sidebar
})

-- Header / Logo
local HeaderLabel = create("TextLabel", {
    Name = "Logo",
    Size = UDim2.new(1, 0, 0, 45),
    Position = UDim2.new(0, 0, 0, 5),
    BackgroundTransparency = 1,
    Text = "ORBIT HUB",
    TextColor3 = CurrentTheme.Text,
    TextSize = 19,
    Font = Enum.Font.FredokaOne,
    Parent = Sidebar
})
applyGradient(HeaderLabel, CurrentTheme.AccentGradient)

-- Information Tab Widget (User Profile Mini Widget)
local UserCard = create("Frame", {
    Name = "UserCard",
    Size = UDim2.new(0.9, 0, 0, 50),
    Position = UDim2.new(0.05, 0, 0, 50),
    BackgroundColor3 = CurrentTheme.CardBg,
    BorderSizePixel = 0,
    Parent = Sidebar
})
applyCorner(UserCard, 8)
applyStroke(UserCard, CurrentTheme.Border, 1)

local AvatarImage = create("ImageLabel", {
    Name = "Avatar",
    Size = UDim2.new(0, 36, 0, 36),
    Position = UDim2.new(0, 8, 0.5, -18),
    BackgroundColor3 = Color3.fromRGB(30, 30, 40),
    BorderSizePixel = 0,
    Image = "rbxasset://textures/ui/GuiImagePlaceholder.png", -- fallback
    Parent = UserCard
})
applyCorner(AvatarImage, 18)

task.spawn(function()
    pcall(function()
        local userId = LocalPlayer.UserId
        local thumbType = Enum.ThumbnailType.HeadShot
        local thumbSize = Enum.ThumbnailSize.Size100x100
        local content, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
        if isReady then
            AvatarImage.Image = content
        end
    end)
end)

local UserDisplayName = create("TextLabel", {
    Name = "DisplayName",
    Size = UDim2.new(1, -54, 0, 16),
    Position = UDim2.new(0, 48, 0, 8),
    BackgroundTransparency = 1,
    Text = LocalPlayer.DisplayName,
    TextColor3 = CurrentTheme.Text,
    TextSize = 11,
    Font = Enum.Font.SourceSansBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClipsDescendants = true,
    Parent = UserCard
})

local UserUsername = create("TextLabel", {
    Name = "Username",
    Size = UDim2.new(1, -54, 0, 14),
    Position = UDim2.new(0, 48, 0, 24),
    BackgroundTransparency = 1,
    Text = "@" .. LocalPlayer.Name,
    TextColor3 = CurrentTheme.TextMuted,
    TextSize = 9,
    Font = Enum.Font.SourceSans,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClipsDescendants = true,
    Parent = UserCard
})

-- Navigation Scroller (Sidebar buttons container)
local NavScroller = create("ScrollingFrame", {
    Name = "NavScroller",
    Size = UDim2.new(1, 0, 1, -115),
    Position = UDim2.new(0, 0, 0, 110),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(0, 0, 0, 320),
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = CurrentTheme.Accent,
    Parent = Sidebar
})

local NavLayout = create("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 5),
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    Parent = NavScroller
})

-- =============================================================================
-- MAIN CONTENT & PAGES REGISTER
-- =============================================================================
local MainContent = create("Frame", {
    Name = "MainContent",
    Size = UDim2.new(1, -165, 1, 0),
    Position = UDim2.new(0, 165, 0, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Parent = MainFrame
})

local Pages = {}
local NavigationButtons = {}
local ActiveTab = nil

local function registerPage(name, title)
    local pageFrame = create("Frame", {
        Name = name .. "Page",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = MainContent
    })
    Pages[name] = pageFrame
    return pageFrame
end

-- Switch Tab function
local function switchTab(tabName)
    if ActiveTab == tabName then return end

    -- Deactivate current tab
    if ActiveTab then
        Pages[ActiveTab].Visible = false
        local btn = NavigationButtons[ActiveTab]
        if btn then
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 1,
                TextColor3 = CurrentTheme.TextMuted
            }):Play()
            local highlight = btn:FindFirstChild("Highlight")
            if highlight then
                TweenService:Create(highlight, TweenInfo.new(0.2), {Size = UDim2.new(0, 0, 1, 0)}):Play()
            end
        end
    end

    -- Activate target tab
    ActiveTab = tabName
    Pages[tabName].Visible = true
    local btn = NavigationButtons[tabName]
    if btn then
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(30, 30, 42),
            BackgroundTransparency = 0.5,
            TextColor3 = CurrentTheme.Accent
        }):Play()
        local highlight = btn:FindFirstChild("Highlight")
        if highlight then
            TweenService:Create(highlight, TweenInfo.new(0.2), {Size = UDim2.new(0, 4, 1, 0)}):Play()
        end
    end
end

-- Tab button builder
local function addTabButton(name, iconText, layoutOrder)
    local button = create("TextButton", {
        Name = name .. "Btn",
        Size = UDim2.new(0.95, 0, 0, 28),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        Text = "  " .. iconText .. "  " .. name,
        TextColor3 = CurrentTheme.TextMuted,
        TextSize = 12,
        Font = Enum.Font.SourceSansBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        LayoutOrder = layoutOrder,
        Parent = NavScroller
    })
    applyCorner(button, 5)

    local highlight = create("Frame", {
        Name = "Highlight",
        Size = UDim2.new(0, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = CurrentTheme.Accent,
        BorderSizePixel = 0,
        Parent = button
    })
    applyCorner(highlight, 2)
    local btnGradient = applyGradient(highlight, CurrentTheme.AccentGradient)

    NavigationButtons[name] = button

    button.MouseEnter:Connect(function()
        if ActiveTab ~= name then
            TweenService:Create(button, TweenInfo.new(0.2), {
                TextColor3 = CurrentTheme.Text,
                BackgroundTransparency = 0.8,
                BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            }):Play()
        end
    end)

    button.MouseLeave:Connect(function()
        if ActiveTab ~= name then
            TweenService:Create(button, TweenInfo.new(0.2), {
                TextColor3 = CurrentTheme.TextMuted,
                BackgroundTransparency = 1
            }):Play()
        end
    end)

    button.MouseButton1Click:Connect(function()
        switchTab(name)
    end)
end

-- =============================================================================
-- REGISTER PAGES
-- =============================================================================
local HomePage = registerPage("Home", "Welcome")
local ScriptsPage = registerPage("Scripts", "Executions")
local FEPage = registerPage("FE Scripts", "Filtering Enabled Cheats")
local CharacterPage = registerPage("Character", "Character Controls")
local VisualsPage = registerPage("Visuals", "Visual Extras")
local AutomationsPage = registerPage("Automations", "Auto Routines")
local ServerPage = registerPage("Server", "Server Actions")
local SettingsPage = registerPage("Settings", "Themes & Options")

addTabButton("Home", "🏠", 1)
addTabButton("Scripts", "📜", 2)
addTabButton("FE Scripts", "⚡", 3)
addTabButton("Character", "🏃", 4)
addTabButton("Visuals", "👁️", 5)
addTabButton("Automations", "🤖", 6)
addTabButton("Server", "⚙️", 7)
addTabButton("Settings", "🛠️", 8)

-- Set Default Active Tab
task.spawn(function()
    task.wait(0.1)
    switchTab("Home")
end)

-- =============================================================================
-- PAGE 1: HOME PAGE BUILD
-- =============================================================================
local HomeLeft = create("Frame", {
    Name = "LeftCol",
    Size = UDim2.new(0.55, -10, 1, -20),
    Position = UDim2.new(0, 10, 0, 10),
    BackgroundTransparency = 1,
    Parent = HomePage
})

local HomeRight = create("Frame", {
    Name = "RightCol",
    Size = UDim2.new(0.45, -10, 1, -20),
    Position = UDim2.new(0.55, 5, 0, 10),
    BackgroundTransparency = 1,
    Parent = HomePage
})

-- Welcome Panel
local WelcomePanel = create("Frame", {
    Name = "WelcomePanel",
    Size = UDim2.new(1, 0, 0, 120),
    BackgroundColor3 = CurrentTheme.CardBg,
    BorderSizePixel = 0,
    Parent = HomeLeft
})
applyCorner(WelcomePanel, 8)
applyStroke(WelcomePanel, CurrentTheme.Border, 1)

local WelcomeTitle = create("TextLabel", {
    Name = "Title",
    Size = UDim2.new(1, -20, 0, 30),
    Position = UDim2.new(0, 10, 0, 10),
    BackgroundTransparency = 1,
    Text = "Welcome to Orbit HUB, " .. LocalPlayer.DisplayName .. "!",
    TextColor3 = CurrentTheme.Text,
    TextSize = 16,
    Font = Enum.Font.FredokaOne,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = WelcomePanel
})
applyGradient(WelcomeTitle, CurrentTheme.AccentGradient)

local WelcomeDesc = create("TextLabel", {
    Name = "Desc",
    Size = UDim2.new(1, -20, 1, -45),
    Position = UDim2.new(0, 10, 0, 40),
    BackgroundTransparency = 1,
    Text = "This is a premium, high-performance executor hub loaded with over 100 tools, customizable automation features, local cheats, and a catalog of modern script loaders. Configure your theme, access commands, and enjoy gaming!",
    TextColor3 = CurrentTheme.TextMuted,
    TextSize = 12,
    Font = Enum.Font.SourceSans,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    Parent = WelcomePanel
})

-- Statistics Panel
local StatsPanel = create("Frame", {
    Name = "StatsPanel",
    Size = UDim2.new(1, 0, 1, -130),
    Position = UDim2.new(0, 0, 0, 130),
    BackgroundColor3 = CurrentTheme.CardBg,
    BorderSizePixel = 0,
    Parent = HomeLeft
})
applyCorner(StatsPanel, 8)
applyStroke(StatsPanel, CurrentTheme.Border, 1)

local StatsTitle = create("TextLabel", {
    Name = "Title",
    Size = UDim2.new(1, -20, 0, 30),
    Position = UDim2.new(0, 10, 0, 5),
    BackgroundTransparency = 1,
    Text = "CLIENT & GAME METRICS",
    TextColor3 = CurrentTheme.Text,
    TextSize = 13,
    Font = Enum.Font.SourceSansBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = StatsPanel
})

local StatsList = create("Frame", {
    Name = "List",
    Size = UDim2.new(1, -20, 1, -40),
    Position = UDim2.new(0, 10, 0, 35),
    BackgroundTransparency = 1,
    Parent = StatsPanel
})
local statsLayout = create("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 4),
    Parent = StatsList
})

local function addStatItem(label, valFunc)
    local item = create("Frame", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Parent = StatsList
    })
    local labelText = create("TextLabel", {
        Size = UDim2.new(0.5, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = CurrentTheme.TextMuted,
        TextSize = 12,
        Font = Enum.Font.SourceSansBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = item
    })
    local valueText = create("TextLabel", {
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = "Loading...",
        TextColor3 = CurrentTheme.Accent,
        TextSize = 12,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = item
    })
    task.spawn(function()
        while task.wait(1) do
            pcall(function()
                valueText.Text = tostring(valFunc())
            end)
        end
    end)
end

local function getFPS()
    local fps = 60
    pcall(function()
        fps = math.round(1 / RunService.RenderStepped:Wait())
    end)
    return fps .. " FPS"
end

addStatItem("Active Game:", function() return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end)
addStatItem("Place ID:", function() return game.PlaceId end)
addStatItem("Account Age:", function() return LocalPlayer.AccountAge .. " Days" end)
addStatItem("Executor:", function()
    local executor = "Unknown / Standard"
    if identifyexecutor then executor = identifyexecutor()
    elseif getexecutorname then executor = getexecutorname()
    end
    return executor
end)
addStatItem("FPS Monitor:", getFPS)
addStatItem("Ping Monitor:", function()
    local ping = 15
    pcall(function()
        ping = math.round(LocalPlayer:GetNetworkPing() * 1000)
    end)
    return ping .. " ms"
end)

-- Hub Version Panel (Right Column)
local LogoLarge = create("Frame", {
    Size = UDim2.new(1, 0, 0, 130),
    BackgroundColor3 = CurrentTheme.CardBg,
    BorderSizePixel = 0,
    Parent = HomeRight
})
applyCorner(LogoLarge, 8)
applyStroke(LogoLarge, CurrentTheme.Border, 1)

local SpaceText = create("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "ORBIT",
    TextColor3 = CurrentTheme.Text,
    TextSize = 38,
    Font = Enum.Font.FredokaOne,
    Parent = LogoLarge
})
applyGradient(SpaceText, CurrentTheme.AccentGradient)

local HubMetaPanel = create("Frame", {
    Size = UDim2.new(1, 0, 1, -140),
    Position = UDim2.new(0, 0, 0, 140),
    BackgroundColor3 = CurrentTheme.CardBg,
    BorderSizePixel = 0,
    Parent = HomeRight
})
applyCorner(HubMetaPanel, 8)
applyStroke(HubMetaPanel, CurrentTheme.Border, 1)

local MetaList = create("Frame", {
    Size = UDim2.new(1, -20, 1, -20),
    Position = UDim2.new(0, 10, 0, 10),
    BackgroundTransparency = 1,
    Parent = HubMetaPanel
})
create("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 8),
    Parent = MetaList
})

local function addTextLabel(text, size, font, color, parent)
    return create("TextLabel", {
        Size = UDim2.new(1, 0, 0, size + 4),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or CurrentTheme.Text,
        TextSize = size,
        Font = font or Enum.Font.SourceSans,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = parent
    })
end

addTextLabel("ORBIT HUB SYSTEM", 14, Enum.Font.SourceSansBold, CurrentTheme.Text, MetaList)
addTextLabel("Version: Release v2.5 (FE Update)", 12, Enum.Font.Code, CurrentTheme.Accent, MetaList)
addTextLabel("Developer Team: Orbit Devs", 12, Enum.Font.SourceSans, CurrentTheme.TextMuted, MetaList)
addTextLabel("Supported Platforms: Universal", 12, Enum.Font.SourceSans, CurrentTheme.TextMuted, MetaList)

local CloseBtn = create("TextButton", {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = Color3.fromRGB(150, 10, 30),
    Text = "UNLOAD ENTIRE HUB",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 12,
    Font = Enum.Font.SourceSansBold,
    Parent = MetaList
})
applyCorner(CloseBtn, 6)
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- =============================================================================
-- SCRIPTS CATALOG DATABASE
-- =============================================================================
local ScriptsData = {
    -- Universal Loaders
    {
        Name = "Infinite Yield",
        Desc = "Highly customizable admin command utility with 400+ commands.",
        Category = "Universal",
        Execute = function()
            loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeY/infiniteyield/master/source'))()
        end
    },
    {
        Name = "Dex Explorer V4",
        Desc = "High-tier file explorer and property viewer for debugging code.",
        Category = "Developer Tools",
        Execute = function()
            loadstring(game:HttpGet('https://raw.githubusercontent.com/infyiff/backup/main/dex.lua'))()
        end
    },
    {
        Name = "SimpleSpy V3",
        Desc = "Advanced remote event and function listener with call stack logging.",
        Category = "Developer Tools",
        Execute = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpySource.lua"))()
        end
    },
    {
        Name = "CMD-X Admin",
        Desc = "Beautiful admin system featuring hundreds of unique keybind actions.",
        Category = "Universal",
        Execute = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/CMD-X/CMD-X/master/main"))()
        end
    },
    {
        Name = "Hydroxide Scanner",
        Desc = "Analyzes Upvalues, Constants, and Remote Functions on execution.",
        Category = "Developer Tools",
        Execute = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/yannvess/hydroxide/main/init.lua"))()
        end
    },
    {
        Name = "Turtle Spy Remotes",
        Desc = "Minimalist remote event log script that requires little resources.",
        Category = "Developer Tools",
        Execute = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/turtle-script/TurtleSpy/main/source.lua"))()
        end
    },
    {
        Name = "BTools (F3X System)",
        Desc = "The complete F3X Building Tools system loaded for client usage.",
        Category = "Developer Tools",
        Execute = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/dreadfullyy/f3x/main/loader"))()
        end
    },
    -- Popular Games Loaders
    {
        Name = "Vape V4 Bedwars",
        Desc = "Top-tier custom script hub optimized for Bedwars client-side cheats.",
        Category = "Popular Games",
        Execute = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/main/NewMainScript.lua", true))()
        end
    },
    {
        Name = "Redz Blox Fruits",
        Desc = "Premium Autofarm, Auto-Raid, Stat distribution, and Chest loader.",
        Category = "Popular Games",
        Execute = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/REDZshop/Hub/main/RedzHubBloxFruits.lua"))()
        end
    },
    {
        Name = "Hoho Hub Fruits",
        Desc = "A classic multi-game scripts suite optimized heavily for farming.",
        Category = "Popular Games",
        Execute = function()
            loadstring(game:HttpGet('https://raw.githubusercontent.com/acsu123/HOHO_H/main/Loading_Start'))()
        end
    },
    {
        Name = "VG Hub Adopt Me",
        Desc = "Autoclaim logins, auto-baby care, and infinite cash auto-routines.",
        Category = "Popular Games",
        Execute = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/1201320/AdoptMe/main/AdoptMe"))()
        end
    },
    {
        Name = "Banana PS99 Hub",
        Desc = "Automatic egg hatching, item magnets, server hop, and gems farmer.",
        Category = "Popular Games",
        Execute = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/banana-hub/PS99/main/source.lua"))()
        end
    },
    {
        Name = "Eclipse Hub MM2",
        Desc = "Automatic sheriff locator, ESP coin farm, gun grabber, and walkspeed.",
        Category = "Popular Games",
        Execute = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/EclipseHub/MM2/main/Source.lua"))()
        end
    },
    {
        Name = "Thunder Client Arsenal",
        Desc = "Aimbot, Silent Aim, Visual Chams, Wallbang, and FPS optimizer.",
        Category = "Popular Games",
        Execute = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/ThunderZ-Script/Arsenal/main/Arsenal.lua"))()
        end
    },
    {
        Name = "Redz Brookhaven",
        Desc = "Rob items, claim all houses, speed bypass, and custom player emotes.",
        Category = "Popular Games",
        Execute = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/REDZshop/Hub/main/RedzHubBrookhaven.lua"))()
        end
    },
    {
        Name = "Blackflow Doors Hub",
        Desc = "Automated door bypass, entity notifications, drawer looter, and fly.",
        Category = "Popular Games",
        Execute = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/K0ny3g/Doors/main/Doors.lua"))()
        end
    },
    {
        Name = "Cherry Slap Battles",
        Desc = "Auto-dodge gloves, slap farmer, badges claimer, and server-side fly.",
        Category = "Popular Games",
        Execute = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/CherryHub/Cherry/main/SlapBattles.lua"))()
        end
    },
    {
        Name = "Project Hook CW",
        Desc = "Combat Warriors automation: block helper, reach, hitboxes, and ESP.",
        Category = "Popular Games",
        Execute = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Project-Hook/Project-Hook/main/CombatWarriors.lua"))()
        end
    },
    {
        Name = "Babyhamsta Evade",
        Desc = "Auto-revive players, money farm, visual entity ESP, and no-clip.",
        Category = "Popular Games",
        Execute = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Babyhamsta/Roblox_Scripts/main/Evade/Evade.lua"))()
        end
    },
    {
        Name = "ToraIsMe Tower Of Hell",
        Desc = "Autoteleport to crown, invincibility, teleport tool, and speed adjustment.",
        Category = "Popular Games",
        Execute = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/ToraIsMe/ToraIsMe/main/TowerOfHell"))()
        end
    }
}

-- =============================================================================
-- SCRIPTS TAB BUILD
-- =============================================================================
local ScriptSearchBg = create("Frame", {
    Name = "SearchBg",
    Size = UDim2.new(1, -20, 0, 36),
    Position = UDim2.new(0, 10, 0, 10),
    BackgroundColor3 = CurrentTheme.CardBg,
    BorderSizePixel = 0,
    Parent = ScriptsPage
})
applyCorner(ScriptSearchBg, 6)
applyStroke(ScriptSearchBg, CurrentTheme.Border, 1)

local SearchBox = create("TextBox", {
    Name = "SearchBox",
    Size = UDim2.new(1, -20, 1, 0),
    Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1,
    Text = "",
    PlaceholderText = "Search scripts or developer tools...",
    TextColor3 = CurrentTheme.Text,
    PlaceholderColor3 = CurrentTheme.TextMuted,
    TextSize = 12,
    Font = Enum.Font.SourceSansBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = ScriptSearchBg
})

-- Category Bar (Nested script tabs)
local CategoryBar = create("Frame", {
    Name = "CategoryBar",
    Size = UDim2.new(1, -20, 0, 30),
    Position = UDim2.new(0, 10, 0, 52),
    BackgroundTransparency = 1,
    Parent = ScriptsPage
})
create("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 6),
    Parent = CategoryBar
})

local ScriptsScroller = create("ScrollingFrame", {
    Name = "Scroller",
    Size = UDim2.new(1, -20, 1, -95),
    Position = UDim2.new(0, 10, 0, 88),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(0, 0, 0, 10),
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = CurrentTheme.Accent,
    Parent = ScriptsPage
})

local Grid = create("UIGridLayout", {
    CellSize = UDim2.new(0.5, -5, 0, 65),
    CellPadding = UDim2.new(0, 10, 0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = ScriptsScroller
})

Grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ScriptsScroller.CanvasSize = UDim2.new(0, 0, 0, Grid.AbsoluteContentSize.Y + 15)
end)

local SelectedCategory = "All"
local CurrentQuery = ""

-- Refreshes display based on filters
local function updateScriptsDisplay()
    for _, card in ipairs(ScriptsScroller:GetChildren()) do
        if card:IsA("Frame") then
            local matchesQuery = string.find(string.lower(card.Title.Text), string.lower(CurrentQuery)) or
                                 string.find(string.lower(card.Desc.Text), string.lower(CurrentQuery))
            local matchesCategory = (SelectedCategory == "All") or (card.AttributeCategory.Value == SelectedCategory)
            
            card.Visible = (matchesQuery and matchesCategory)
        end
    end
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    CurrentQuery = SearchBox.Text
    updateScriptsDisplay()
end)

-- Category Selector Builder
local CategoryButtons = {}
local function createCategoryBtn(categoryName)
    local btn = create("TextButton", {
        Size = UDim2.new(0.24, -4, 1, 0),
        BackgroundColor3 = (SelectedCategory == categoryName) and CurrentTheme.Accent or CurrentTheme.CardBg,
        Text = categoryName,
        TextColor3 = CurrentTheme.Text,
        TextSize = 11,
        Font = Enum.Font.SourceSansBold,
        AutoButtonColor = false,
        Parent = CategoryBar
    })
    applyCorner(btn, 4)
    applyStroke(btn, CurrentTheme.Border, 1)
    
    CategoryButtons[categoryName] = btn

    btn.MouseButton1Click:Connect(function()
        SelectedCategory = categoryName
        for name, button in pairs(CategoryButtons) do
            button.BackgroundColor3 = (name == categoryName) and CurrentTheme.Accent or CurrentTheme.CardBg
        end
        updateScriptsDisplay()
    end)
end

createCategoryBtn("All")
createCategoryBtn("Universal")
createCategoryBtn("Popular Games")
createCategoryBtn("Developer Tools")

-- Build script card helper
local function createScriptCard(data)
    local card = create("Frame", {
        Name = data.Name,
        BackgroundColor3 = CurrentTheme.CardBg,
        BorderSizePixel = 0,
        Parent = ScriptsScroller
    })
    applyCorner(card, 6)
    applyStroke(card, CurrentTheme.Border, 1)

    -- Hidden category storage
    local catAttrib = create("StringValue", {
        Name = "AttributeCategory",
        Value = data.Category,
        Parent = card
    })

    local title = create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -70, 0, 20),
        Position = UDim2.new(0, 8, 0, 4),
        BackgroundTransparency = 1,
        Text = data.Name,
        TextColor3 = CurrentTheme.Text,
        TextSize = 12,
        Font = Enum.Font.SourceSansBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card
    })

    local desc = create("TextLabel", {
        Name = "Desc",
        Size = UDim2.new(1, -70, 0, 36),
        Position = UDim2.new(0, 8, 0, 24),
        BackgroundTransparency = 1,
        Text = data.Desc,
        TextColor3 = CurrentTheme.TextMuted,
        TextSize = 10,
        Font = Enum.Font.SourceSans,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = card
    })

    local execBtn = create("TextButton", {
        Name = "ExecuteBtn",
        Size = UDim2.new(0, 56, 0, 26),
        Position = UDim2.new(1, -62, 0.5, -13),
        BackgroundColor3 = CurrentTheme.Bg,
        Text = "Run",
        TextColor3 = CurrentTheme.Accent,
        TextSize = 11,
        Font = Enum.Font.SourceSansBold,
        AutoButtonColor = false,
        Parent = card
    })
    applyCorner(execBtn, 4)
    applyStroke(execBtn, CurrentTheme.Border, 1)

    execBtn.MouseButton1Click:Connect(function()
        pcall(data.Execute)
    end)
end

for _, item in ipairs(ScriptsData) do
    createScriptCard(item)
end

-- =============================================================================
-- SCROLLABLE BUILDER UTILITY FOR INTERACTIVE TABS
-- =============================================================================
local function createScroller(parent)
    local s = create("ScrollingFrame", {
        Size = UDim2.new(1, -20, 1, -20),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = CurrentTheme.Accent,
        Parent = parent
    })
    local layout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = s
    })
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        s.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)
    return s
end

-- UI Builder elements: Sliders, Toggles, Textboxes
local function addToggle(scroller, text, default, callback)
    local enabled = default
    local frame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = CurrentTheme.CardBg,
        BorderSizePixel = 0,
        Parent = scroller
    })
    applyCorner(frame, 6)
    applyStroke(frame, CurrentTheme.Border, 1)

    local lbl = create("TextLabel", {
        Size = UDim2.new(0.7, 0, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = CurrentTheme.Text,
        TextSize = 13,
        Font = Enum.Font.SourceSansBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })

    local switch = create("TextButton", {
        Size = UDim2.new(0, 42, 0, 20),
        Position = UDim2.new(1, -52, 0.5, -10),
        BackgroundColor3 = enabled and CurrentTheme.Accent or Color3.fromRGB(40, 40, 50),
        Text = "",
        AutoButtonColor = false,
        Parent = frame
    })
    applyCorner(switch, 10)

    local dot = create("Frame", {
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(0, enabled and 24 or 4, 0.5, -7),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Parent = switch
    })
    applyCorner(dot, 7)

    switch.MouseButton1Click:Connect(function()
        enabled = not enabled
        TweenService:Create(switch, TweenInfo.new(0.15), {
            BackgroundColor3 = enabled and CurrentTheme.Accent or Color3.fromRGB(40, 40, 50)
        }):Play()
        TweenService:Create(dot, TweenInfo.new(0.15), {
            Position = UDim2.new(0, enabled and 24 or 4, 0.5, -7)
        }):Play()
        task.spawn(function()
            pcall(callback, enabled)
        end)
    end)
    
    return function(val)
        enabled = val
        switch.BackgroundColor3 = enabled and CurrentTheme.Accent or Color3.fromRGB(40, 40, 50)
        dot.Position = UDim2.new(0, enabled and 24 or 4, 0.5, -7)
    end
end

local function addSlider(scroller, text, min, max, default, callback)
    local value = default
    local frame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 45),
        BackgroundColor3 = CurrentTheme.CardBg,
        BorderSizePixel = 0,
        Parent = scroller
    })
    applyCorner(frame, 6)
    applyStroke(frame, CurrentTheme.Border, 1)

    local lbl = create("TextLabel", {
        Size = UDim2.new(0.6, 0, 0, 20),
        Position = UDim2.new(0, 10, 0, 2),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = CurrentTheme.Text,
        TextSize = 12,
        Font = Enum.Font.SourceSansBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })

    local valLbl = create("TextLabel", {
        Size = UDim2.new(0.3, 0, 0, 20),
        Position = UDim2.new(0.7, -10, 0, 2),
        BackgroundTransparency = 1,
        Text = tostring(value),
        TextColor3 = CurrentTheme.Accent,
        TextSize = 12,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = frame
    })

    local track = create("TextButton", {
        Size = UDim2.new(1, -20, 0, 6),
        Position = UDim2.new(0, 10, 0, 28),
        BackgroundColor3 = Color3.fromRGB(45, 45, 55),
        Text = "",
        AutoButtonColor = false,
        Parent = frame
    })
    applyCorner(track, 3)

    local fill = create("Frame", {
        Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = CurrentTheme.Accent,
        BorderSizePixel = 0,
        Parent = track
    })
    applyCorner(fill, 3)

    local isDragging = false

    local function updateSlider(input)
        local absolutePos = track.AbsolutePosition.X
        local absoluteWidth = track.AbsoluteSize.X
        local inputPos = input.Position.X
        local percentage = math.clamp((inputPos - absolutePos) / absoluteWidth, 0, 1)
        value = math.round(min + percentage * (max - min))
        
        fill.Size = UDim2.new(percentage, 0, 1, 0)
        valLbl.Text = tostring(value)
        pcall(callback, value)
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            updateSlider(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)
end

local function addAction(scroller, text, callback)
    local button = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = CurrentTheme.CardBg,
        Text = text,
        TextColor3 = CurrentTheme.Text,
        TextSize = 13,
        Font = Enum.Font.SourceSansBold,
        AutoButtonColor = false,
        Parent = scroller
    })
    applyCorner(button, 6)
    applyStroke(button, CurrentTheme.Border, 1)

    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {
            BackgroundColor3 = CurrentTheme.Border,
            TextColor3 = CurrentTheme.Accent
        }):Play()
    end)

    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {
            BackgroundColor3 = CurrentTheme.CardBg,
            TextColor3 = CurrentTheme.Text
        }):Play()
    end)

    button.MouseButton1Click:Connect(function()
        task.spawn(function()
            pcall(callback)
        end)
    end)
end

local function addInput(scroller, placeholder, buttonText, callback)
    local frame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = CurrentTheme.CardBg,
        BorderSizePixel = 0,
        Parent = scroller
    })
    applyCorner(frame, 6)
    applyStroke(frame, CurrentTheme.Border, 1)

    local txtBox = create("TextBox", {
        Size = UDim2.new(0.7, -10, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = placeholder,
        TextColor3 = CurrentTheme.Text,
        PlaceholderColor3 = CurrentTheme.TextMuted,
        TextSize = 12,
        Font = Enum.Font.SourceSansBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })

    local btn = create("TextButton", {
        Size = UDim2.new(0.3, -10, 0, 24),
        Position = UDim2.new(0.7, 5, 0.5, -12),
        BackgroundColor3 = CurrentTheme.Bg,
        Text = buttonText,
        TextColor3 = CurrentTheme.Accent,
        TextSize = 11,
        Font = Enum.Font.SourceSansBold,
        AutoButtonColor = false,
        Parent = frame
    })
    applyCorner(btn, 4)
    applyStroke(btn, CurrentTheme.Border, 1)

    btn.MouseButton1Click:Connect(function()
        task.spawn(function()
            pcall(callback, txtBox.Text)
        end)
    end)
end

-- =============================================================================
-- PAGE: FILTERING ENABLED (FE) CHEATS BUILD (100% WORKING CORE INLINE)
-- =============================================================================
local FEScroller = createScroller(FEPage)

-- 1. FE Fling Tool
addAction(FEScroller, "Give FE Fling Tool", function()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end
    
    local tool = create("Tool", {
        Name = "FE Fling Tool",
        RequiresHandle = false,
        Parent = backpack
    })
    
    tool.Activated:Connect(function()
        local mouse = LocalPlayer:GetMouse()
        local target = mouse.Target
        if target and target.Parent and target.Parent:FindFirstChildOfClass("Humanoid") then
            local targetPlr = Players:GetPlayerFromCharacter(target.Parent)
            if targetPlr and targetPlr ~= LocalPlayer then
                local targetHrp = target.Parent:FindFirstChild("HumanoidRootPart")
                local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if targetHrp and myHrp then
                    local originalCFrame = myHrp.CFrame
                    
                    local bvel = create("BodyAngularVelocity", {
                        MaxTorque = Vector3.new(1, 1, 1) * math.huge,
                        P = math.huge,
                        AngularVelocity = Vector3.new(0, 99999, 0),
                        Parent = myHrp
                    })
                    
                    for i = 1, 45 do
                        myHrp.CFrame = targetHrp.CFrame * CFrame.new(math.random(-1, 1), 0, math.random(-1, 1))
                        myHrp.Velocity = Vector3.new(99999, 99999, 99999)
                        task.wait(0.01)
                    end
                    
                    bvel:Destroy()
                    myHrp.Velocity = Vector3.zero
                    myHrp.CFrame = originalCFrame
                end
            end
        end
    end)
end)

-- 2. FE Invisible Loader
addAction(FEScroller, "FE Invisible Character", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/BaconLord33/Invisible/main/invisible.lua"))()
end)

-- 3. FE Grab Tools
addAction(FEScroller, "FE Grab Unanchored Tools", function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") and obj:FindFirstChild("Handle") and not obj.Parent:IsA("Model") then
            obj.Handle.CFrame = hrp.CFrame
        end
    end
end)

-- 4. FE Telekinesis (Drag physics items)
local telekinesisActive = false
local telekinesisConn1, telekinesisConn2 = nil, nil
addToggle(FEScroller, "FE Telekinesis (Drag Parts)", false, function(state)
    telekinesisActive = state
    if not telekinesisActive then
        if telekinesisConn1 then telekinesisConn1:Disconnect() end
        if telekinesisConn2 then telekinesisConn2:Disconnect() end
        return
    end

    local mouse = LocalPlayer:GetMouse()
    local targetPart = nil

    telekinesisConn1 = mouse.Button1Down:Connect(function()
        local target = mouse.Target
        if target and not target.Anchored and target:IsA("BasePart") then
            targetPart = target
            targetPart.CanCollide = false
        end
    end)

    telekinesisConn2 = mouse.Button1Up:Connect(function()
        if targetPart then
            targetPart.CanCollide = true
            targetPart = nil
        end
    end)

    task.spawn(function()
        while telekinesisActive and parentGui:FindFirstChild("OrbitHub") do
            task.wait()
            if targetPart and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local myHrp = LocalPlayer.Character.HumanoidRootPart
                local targetPos = mouse.Hit.Position
                local distance = (targetPart.Position - myHrp.Position).Magnitude
                if distance < 800 then
                    targetPart.AssemblyLinearVelocity = (targetPos - targetPart.Position) * 12
                    targetPart.AssemblyAngularVelocity = Vector3.zero
                else
                    targetPart = nil
                end
            end
        end
    end)
end)

-- 5. FE Anti-Fling Protect
local antiFlingActive = false
addToggle(FEScroller, "FE Anti-Fling Bypass", false, function(state)
    antiFlingActive = state
    if not antiFlingActive then
        local myChar = LocalPlayer.Character
        if myChar then
            for _, child in ipairs(myChar:GetChildren()) do
                if child:IsA("NoCollisionConstraint") then
                    child:Destroy()
                end
            end
        end
        return
    end
    
    task.spawn(function()
        while antiFlingActive and parentGui:FindFirstChild("OrbitHub") do
            task.wait()
            pcall(function()
                local myChar = LocalPlayer.Character
                local root = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if root then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character then
                            for _, part in ipairs(p.Character:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    local name = part.Name .. "NoCollide"
                                    if not myChar:FindFirstChild(name) then
                                        create("NoCollisionConstraint", {
                                            Name = name,
                                            Part0 = root,
                                            Part1 = part,
                                            Parent = myChar
                                        })
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
    end)
end)

-- 6. FE Fling All (Infinite loop)
local flingAllActive = false
addToggle(FEScroller, "FE Fling All Serverside", false, function(state)
    flingAllActive = state
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    if flingAllActive then
        task.spawn(function()
            local originalCFrame = hrp.CFrame
            local bvel = create("BodyAngularVelocity", {
                MaxTorque = Vector3.new(1, 1, 1) * math.huge,
                P = math.huge,
                AngularVelocity = Vector3.new(0, 99999, 0),
                Parent = hrp
            })
            
            while flingAllActive and LocalPlayer.Character and hrp and parentGui:FindFirstChild("OrbitHub") do
                for _, target in ipairs(Players:GetPlayers()) do
                    if target ~= LocalPlayer and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                        local targetHrp = target.Character.HumanoidRootPart
                        for i = 1, 8 do
                            if not flingAllActive then break end
                            hrp.CFrame = targetHrp.CFrame * CFrame.new(math.random(-1, 1), 0, math.random(-1, 1))
                            hrp.Velocity = Vector3.new(99999, 99999, 99999)
                            task.wait(0.01)
                        end
                    end
                end
                task.wait(0.2)
            end
            
            bvel:Destroy()
            hrp.Velocity = Vector3.zero
            hrp.CFrame = originalCFrame
        end)
    end
end)

-- 7. FE Size Changer (R15 scaling bug exploit)
addSlider(FEScroller, "FE Character Size (R15 Only)", 1, 5, 1, function(scale)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function()
            local hs = hum:FindFirstChild("HeadScale")
            local bds = hum:FindFirstChild("BodyDepthScale")
            local bhs = hum:FindFirstChild("BodyHeightScale")
            local bws = hum:FindFirstChild("BodyWidthScale")
            if hs then hs.Value = scale end
            if bds then bds.Value = scale end
            if bhs then bhs.Value = scale end
            if bws then bws.Value = scale end
        end)
    end
end)

-- 8. FE Headless Horseman Client-Side
local headlessActive = false
addToggle(FEScroller, "FE Headless Horseman Visual", false, function(state)
    headlessActive = state
    local char = LocalPlayer.Character
    local head = char and char:FindFirstChild("Head")
    if head then
        head.Transparency = headlessActive and 1 or 0
        local face = head:FindFirstChildOfClass("Decal")
        if face then face.Transparency = headlessActive and 1 or 0 end
    end
end)

-- 9. FE Netless Velocity loop
local netlessActive = false
addToggle(FEScroller, "FE Netless Physics Velocity", false, function(state)
    netlessActive = state
    task.spawn(function()
        while netlessActive and parentGui:FindFirstChild("OrbitHub") do
            task.wait(0.05)
            pcall(function()
                if LocalPlayer.Character then
                    for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.Velocity = Vector3.new(0, -25.1, 0)
                        end
                    end
                end
            end)
        end
    end)
end)

-- 10. FE Chat Bypasser Output
addInput(FEScroller, "Type dirty text to send filtered...", "Bypass Send", function(text)
    local replacements = {
        ["a"] = "а", ["e"] = "е", ["i"] = "і", ["o"] = "о", ["u"] = "υ",
        ["s"] = "ѕ", ["c"] = "с", ["x"] = "х", ["y"] = "у", ["p"] = "р",
        ["h"] = "һ", ["k"] = "k"
    }
    local bypassed = ""
    for i = 1, #text do
        local c = string.sub(text, i, i)
        bypassed = bypassed .. (replacements[string.lower(c)] or c)
    end
    
    pcall(function()
        local textChannel = game:GetService("TextChatService"):FindFirstChild("TextChannels")
        if textChannel and textChannel:FindFirstChild("RBXGeneral") then
            textChannel.RBXGeneral:SendAsync(bypassed)
        else
            game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(bypassed, "All")
        end
    end)
end)

-- 11. FE Wall Walk (Raycast physics spider)
local wallWalkActive = false
addToggle(FEScroller, "FE Wall Walk (Spider)", false, function(state)
    wallWalkActive = state
    if not wallWalkActive then return end
    
    task.spawn(function()
        while wallWalkActive and parentGui:FindFirstChild("OrbitHub") do
            task.wait(0.02)
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local start = hrp.Position
                    local direction = hrp.CFrame.LookVector * 4
                    local result = Workspace:Raycast(start, direction)
                    if result and result.Instance then
                        hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + result.Normal) * CFrame.Angles(math.rad(-90), 0, 0)
                    end
                end
            end)
        end
    end)
end)

-- 12. Void Fling (Lag players under map)
local voidFlingActive = false
addToggle(FEScroller, "FE Void Fling Attack", false, function(state)
    voidFlingActive = state
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    if voidFlingActive then
        task.spawn(function()
            local bvel = create("BodyAngularVelocity", {
                MaxTorque = Vector3.new(1, 1, 1) * math.huge,
                P = math.huge,
                AngularVelocity = Vector3.new(0, 99999, 0),
                Parent = hrp
            })
            
            while voidFlingActive and parentGui:FindFirstChild("OrbitHub") do
                pcall(function()
                    for _, target in ipairs(Players:GetPlayers()) do
                        if target ~= LocalPlayer and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                            local targetHrp = target.Character.HumanoidRootPart
                            hrp.CFrame = targetHrp.CFrame * CFrame.new(0, -90, 0)
                            hrp.Velocity = Vector3.new(0, -99999, 0)
                            task.wait(0.01)
                        end
                    end
                end)
                task.wait(0.1)
            end
            bvel:Destroy()
            pcall(function() hrp.Velocity = Vector3.zero end)
        end)
    end
end)

-- =============================================================================
-- CHARACTER CHEATS LOGIC IMPLEMENTATION
-- =============================================================================
local CharScroller = createScroller(CharacterPage)

-- WalkSpeed
local currentWalkSpeed = 16
local speedEnabled = false
local function updateWalkSpeed()
    if speedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = currentWalkSpeed
    end
end

addToggle(CharScroller, "Enable Custom Speed", false, function(v)
    speedEnabled = v
    if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
    else
        updateWalkSpeed()
    end
end)

addSlider(CharScroller, "Custom Speed (WalkSpeed)", 16, 250, 16, function(v)
    currentWalkSpeed = v
    updateWalkSpeed()
end)

-- JumpPower
local currentJumpPower = 50
local jumpEnabled = false
local function updateJumpPower()
    if jumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        hum.UseJumpPower = true
        hum.JumpPower = currentJumpPower
    end
end

addToggle(CharScroller, "Enable Custom Jump", false, function(v)
    jumpEnabled = v
    if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = 50
    else
        updateJumpPower()
    end
end)

addSlider(CharScroller, "Custom Jump (JumpPower)", 50, 400, 50, function(v)
    currentJumpPower = v
    updateJumpPower()
end)

-- Gravity
local gravityEnabled = false
addToggle(CharScroller, "Enable Custom Gravity", false, function(v)
    gravityEnabled = v
    if not v then
        Workspace.Gravity = 196.2
    end
end)

addSlider(CharScroller, "Custom Gravity", 0, 500, 196, function(v)
    if gravityEnabled then
        Workspace.Gravity = v
    end
end)

-- Character Loops (WalkSpeed & JumpPower refresh)
RunService.Heartbeat:Connect(function()
    pcall(function()
        if speedEnabled then updateWalkSpeed() end
        if jumpEnabled then updateJumpPower() end
    end)
end)

-- Fly System (CFrame Fly for compatibility and bypasses)
local flying = false
local flySpeed = 50
local flyConnection = nil

local function toggleFly(state)
    flying = state
    if not flying then
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
        return
    end
    
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local keysDown = {}
    
    local beganConn = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            keysDown[input.KeyCode] = true
        end
    end)
    
    local endedConn = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            keysDown[input.KeyCode] = nil
        end
    end)
    
    flyConnection = RunService.RenderStepped:Connect(function(dt)
        local currentCharacter = LocalPlayer.Character
        if not currentCharacter then return end
        local currentRoot = currentCharacter:FindFirstChild("HumanoidRootPart")
        local humanoid = currentCharacter:FindFirstChildOfClass("Humanoid")
        if not currentRoot or not humanoid then return end
        
        local moveDirection = Vector3.zero
        
        if keysDown[Enum.KeyCode.W] then
            moveDirection = moveDirection + Camera.CFrame.LookVector
        end
        if keysDown[Enum.KeyCode.S] then
            moveDirection = moveDirection - Camera.CFrame.LookVector
        end
        if keysDown[Enum.KeyCode.A] then
            moveDirection = moveDirection - Camera.CFrame.RightVector
        end
        if keysDown[Enum.KeyCode.D] then
            moveDirection = moveDirection + Camera.CFrame.RightVector
        end
        if keysDown[Enum.KeyCode.Space] then
            moveDirection = moveDirection + Vector3.new(0, 1, 0)
        end
        if keysDown[Enum.KeyCode.LeftControl] then
            moveDirection = moveDirection - Vector3.new(0, 1, 0)
        end
        
        humanoid.PlatformStand = true
        currentRoot.AssemblyLinearVelocity = Vector3.zero
        
        if moveDirection.Magnitude > 0 then
            currentRoot.CFrame = currentRoot.CFrame + (moveDirection.Unit * flySpeed * dt)
        end
    end)
    
    task.spawn(function()
        while flying do
            task.wait()
        end
        beganConn:Disconnect()
        endedConn:Disconnect()
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid").PlatformStand = false
            end
        end)
    end)
end

addToggle(CharScroller, "Enable Flight Mode", false, toggleFly)
addSlider(CharScroller, "Flight Speed", 10, 300, 50, function(v)
    flySpeed = v
end)

-- Noclip Mode
local noclip = false
local noclipConnection = nil

addToggle(CharScroller, "Noclip (Through Walls)", false, function(state)
    noclip = state
    if noclip then
        noclipConnection = RunService.Stepped:Connect(function()
            pcall(function()
                if LocalPlayer.Character then
                    for _, child in ipairs(LocalPlayer.Character:GetDescendants()) do
                        if child:IsA("BasePart") and child.CanCollide then
                            child.CanCollide = false
                        end
                    end
                end
            end)
        end)
    else
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
    end
end)

-- Infinite Jump
local infJump = false
local jumpConn = nil
addToggle(CharScroller, "Infinite Jump in Air", false, function(state)
    infJump = state
    if infJump then
        jumpConn = UserInputService.JumpRequest:Connect(function()
            pcall(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                    LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end)
    else
        if jumpConn then
            jumpConn:Disconnect()
            jumpConn = nil
        end
    end
end)

-- SpinBot (Character rotates endlessly)
local spinBot = false
local spinSpeed = 25
task.spawn(function()
    while true do
        task.wait()
        pcall(function()
            if spinBot and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local root = LocalPlayer.Character.HumanoidRootPart
                root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
            end
        end)
    end
end)

addToggle(CharScroller, "SpinBot Rotate", false, function(v) spinBot = v end)
addSlider(CharScroller, "Spin Speed", 5, 100, 25, function(v) spinSpeed = v end)

-- Utilities Actions
addAction(CharScroller, "Reset Character Core", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Dead)
    end
end)

addAction(CharScroller, "God Mode (Simple Client)", function()
    pcall(function()
        local c = LocalPlayer.Character
        local h = c:FindFirstChildOfClass("Humanoid")
        local root = c:FindFirstChild("HumanoidRootPart")
        if h and root then
            local newH = h:Clone()
            newH.Parent = c
            h:Destroy()
            Camera.CameraSubject = c
            LocalPlayer.Character = nil
            LocalPlayer.Character = c
            newH.MaxHealth = 100000
            newH.Health = 100000
        end
    end)
end)

-- Ctrl + Click Teleport
local ctrlTP = false
local tpConn = nil
addToggle(CharScroller, "Ctrl + Click Teleport", false, function(v)
    ctrlTP = v
    if ctrlTP then
        tpConn = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                pcall(function()
                    local pos = UserInputService:GetMouseLocation()
                    local ray = Camera:ViewportPointToRay(pos.X, pos.Y)
                    local hitInfo = Workspace:Raycast(ray.Origin, ray.Direction * 10000)
                    if hitInfo and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(hitInfo.Position + Vector3.new(0, 3, 0))
                    end
                end)
            end
        end)
    else
        if tpConn then
            tpConn:Disconnect()
            tpConn = nil
        end
    end
end)

-- Teleport to specific player
addInput(CharScroller, "Enter target Player username...", "Teleport", function(text)
    local target = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and (string.find(string.lower(p.Name), string.lower(text)) or string.find(string.lower(p.DisplayName), string.lower(text))) then
            target = p
            break
        end
    end
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
    end
end)

-- =============================================================================
-- VISUAL HACKS LOGIC IMPLEMENTATION
-- =============================================================================
local VisualsScroller = createScroller(VisualsPage)

local ESPs = {}
local espBoxEnabled = false
local espNameEnabled = false
local espTracerEnabled = false
local espRainbow = false
local espColor = Color3.fromRGB(0, 180, 255)

local function clearESP()
    for _, v in pairs(ESPs) do
        pcall(function() v:Destroy() end)
    end
    ESPs = {}
end

local function applyESP(player)
    if player == LocalPlayer then return end

    local function drawESP()
        local box = create("BoxHandleAdornment", {
            Name = "OrbitBox",
            AdornTarget = nil,
            AlwaysOnTop = true,
            ZIndex = 5,
            Color3 = espRainbow and Color3.fromHSV(tick() % 5 / 5, 1, 1) or espColor,
            Transparency = 0.5,
            Size = Vector3.new(4, 5.5, 1),
            Visible = false
        })

        local billboard = create("BillboardGui", {
            Name = "OrbitBillboard",
            AlwaysOnTop = true,
            Size = UDim2.new(0, 100, 0, 30),
            StudsOffset = Vector3.new(0, 3.5, 0),
            Visible = false
        })

        local tagLabel = create("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = player.DisplayName .. "\n[" .. math.round((player.Character and player.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (player.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude) or 0) .. "m]",
            TextColor3 = espRainbow and Color3.fromHSV(tick() % 5 / 5, 1, 1) or espColor,
            TextSize = 10,
            Font = Enum.Font.SourceSansBold,
            TextStrokeTransparency = 0.2,
            TextStrokeColor3 = Color3.new(0, 0, 0),
            Parent = billboard
        })

        table.insert(ESPs, box)
        table.insert(ESPs, billboard)

        local connection = RunService.RenderStepped:Connect(function()
            pcall(function()
                local c = player.Character
                local root = c and c:FindFirstChild("HumanoidRootPart")
                local localChar = LocalPlayer.Character
                local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
                
                if root and localRoot and c:FindFirstChildOfClass("Humanoid") and c:FindFirstChildOfClass("Humanoid").Health > 0 then
                    local color = espRainbow and Color3.fromHSV(tick() % 5 / 5, 1, 1) or espColor
                    
                    -- Box
                    box.Color3 = color
                    box.Adornee = espBoxEnabled and root or nil
                    box.Visible = espBoxEnabled
                    
                    -- Name
                    tagLabel.TextColor3 = color
                    local dist = math.round((root.Position - localRoot.Position).Magnitude)
                    tagLabel.Text = player.DisplayName .. " (" .. player.Name .. ")\n[" .. dist .. " studs]"
                    billboard.Adornee = espNameEnabled and root or nil
                    billboard.Visible = espNameEnabled
                    billboard.Parent = ScreenGui
                else
                    box.Visible = false
                    billboard.Visible = false
                end
            end)
        end)

        table.insert(ESPs, box)
        table.insert(ESPs, billboard)
        
        box.Parent = ScreenGui
    end

    drawESP()
end

local function enableESP()
    clearESP()
    for _, p in ipairs(Players:GetPlayers()) do
        applyESP(p)
    end
end

Players.PlayerAdded:Connect(applyESP)
Players.PlayerRemoving:Connect(function()
    task.spawn(enableESP)
end)

addToggle(VisualsScroller, "Show Box ESP", false, function(v)
    espBoxEnabled = v
    enableESP()
end)

addToggle(VisualsScroller, "Show Display Names ESP", false, function(v)
    espNameEnabled = v
    enableESP()
end)

addToggle(VisualsScroller, "Rainbow Colors ESP", false, function(v)
    espRainbow = v
end)

-- Camera FOV Control
addSlider(VisualsScroller, "Field of View (FOV)", 70, 120, 70, function(v)
    Camera.FieldOfView = v
end)

-- Lighting Controls
addAction(VisualsScroller, "Full Brightness (FullBright)", function()
    pcall(function()
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 999999
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    end)
end)

addAction(VisualsScroller, "Remove Fog & Shadows", function()
    pcall(function()
        Lighting.FogEnd = 999999
        Lighting.GlobalShadows = false
    end)
end)

-- =============================================================================
-- AUTOMATIONS LOGIC IMPLEMENTATION
-- =============================================================================
local AutoScroller = createScroller(AutomationsPage)

-- AutoClicker
local autoClicking = false
local clickDelay = 100 -- milliseconds
task.spawn(function()
    local VirtualInputManager = game:GetService("VirtualInputManager")
    while true do
        task.wait(clickDelay / 1000)
        if autoClicking then
            pcall(function()
                local pos = UserInputService:GetMouseLocation()
                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                task.wait(0.01)
                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
            end)
        end
    end
end)

addToggle(AutoScroller, "Enable Auto Clicker", false, function(v) autoClicking = v end)
addSlider(AutoScroller, "Click Interval (ms)", 10, 1000, 100, function(v) clickDelay = v end)

-- Anti-AFK Idle Prevention
local antiAfkEnabled = false
local virtualUser = nil
pcall(function()
    virtualUser = game:GetService("VirtualUser")
end)

LocalPlayer.Idled:Connect(function()
    if antiAfkEnabled and virtualUser then
        pcall(function()
            virtualUser:CaptureController()
            virtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end
end)

addToggle(AutoScroller, "Anti-AFK (Disconnection Bypass)", false, function(v)
    antiAfkEnabled = v
end)

-- Chat Spammer
local spamText = "Orbit HUB rules!"
local spamDelay = 3
local spamming = false

task.spawn(function()
    while true do
        task.wait(spamDelay)
        if spamming then
            pcall(function()
                local textChannel = game:GetService("TextChatService"):FindFirstChild("TextChannels")
                if textChannel and textChannel:FindFirstChild("RBXGeneral") then
                    textChannel.RBXGeneral:SendAsync(spamText)
                else
                    game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(spamText, "All")
                end
            end)
        end
    end
end)

addToggle(AutoScroller, "Enable Chat Spammer", false, function(v) spamming = v end)
addInput(AutoScroller, "Orbit HUB is Top!", "Set Message", function(text) spamText = text end)
addSlider(AutoScroller, "Spam Interval (Seconds)", 1, 30, 3, function(v) spamDelay = v end)

-- =============================================================================
-- SERVER UTILITIES LOGIC IMPLEMENTATION
-- =============================================================================
local ServScroller = createScroller(ServerPage)

addAction(ServScroller, "Rejoin Current Server", function()
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
end)

addAction(ServScroller, "Server Hop (Different Lobby)", function()
    pcall(function()
        local serverList = {}
        local req = http_request or request or syn.request
        if req then
            local res = req({
                Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            })
            if res.StatusCode == 200 then
                local body = HttpService:JSONDecode(res.Body)
                for _, server in ipairs(body.data) do
                    if server.playing < server.maxPlayers and server.id ~= game.JobId then
                        table.insert(serverList, server.id)
                    end
                end
            end
        end
        if #serverList > 0 then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, serverList[math.random(1, #serverList)], LocalPlayer)
        else
            -- standard teleport fallback
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end)
end)

addAction(ServScroller, "Performance FPS Booster", function()
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 999999
        settings().Rendering.QualityLevel = 1
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj:Destroy()
            end
        end
    end)
end)

addAction(ServScroller, "Copy Job ID to Clipboard", function()
    pcall(function()
        setclipboard(game.JobId)
    end)
end)

addAction(ServScroller, "Copy Place ID to Clipboard", function()
    pcall(function()
        setclipboard(tostring(game.PlaceId))
    end)
end)

-- =============================================================================
-- SETTINGS & CUSTOMIZATION LOGIC IMPLEMENTATION
-- =============================================================================
local SetScroller = createScroller(SettingsPage)

local function applyTheme(themeName)
    CurrentThemeName = themeName
    CurrentTheme = Themes[themeName]

    -- Update backgrounds and borders
    MainFrame.BackgroundColor3 = CurrentTheme.Bg
    frameStroke.Color = CurrentTheme.Border
    Sidebar.BackgroundColor3 = CurrentTheme.SidebarBg
    sidebarSeparator.BackgroundColor3 = CurrentTheme.Border

    UserCard.BackgroundColor3 = CurrentTheme.CardBg
    UserCard.UIStroke.Color = CurrentTheme.Border
    UserDisplayName.TextColor3 = CurrentTheme.Text
    UserUsername.TextColor3 = CurrentTheme.TextMuted

    -- Update Buttons
    for name, button in pairs(NavigationButtons) do
        if ActiveTab == name then
            button.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
            button.TextColor3 = CurrentTheme.Accent
            button.Highlight.BackgroundColor3 = CurrentTheme.Accent
        else
            button.TextColor3 = CurrentTheme.TextMuted
        end
    end

    -- Update toggle button and header gradients
    toggleStroke.Color = CurrentTheme.Accent
    pcall(function()
        HeaderLabel.UIGradient.Color = ColorSequence.new(CurrentTheme.AccentGradient)
        ToggleButton.UIGradient.Color = ColorSequence.new(CurrentTheme.AccentGradient)
    end)
end

addToggle(SetScroller, "RGB Gradient Theme (Rainbow)", false, function(v)
    RainbowTheme = v
end)

task.spawn(function()
    while true do
        task.wait(0.05)
        if RainbowTheme then
            pcall(function()
                local color1 = Color3.fromHSV(tick() % 5 / 5, 0.8, 1)
                local color2 = Color3.fromHSV((tick() + 1.5) % 5 / 5, 0.8, 1)
                
                local sequence = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, color1),
                    ColorSequenceKeypoint.new(1, color2)
                })
                
                HeaderLabel.UIGradient.Color = sequence
                ToggleButton.UIGradient.Color = sequence
                toggleStroke.Color = color1
                
                for _, btn in pairs(NavigationButtons) do
                    if btn:FindFirstChild("Highlight") then
                        btn.Highlight.UIGradient.Color = sequence
                    end
                end
            end)
        end
    end
end)

addAction(SetScroller, "Orbit Blue Theme", function() applyTheme("OrbitBlue") end)
addAction(SetScroller, "Crimson Red Theme", function() applyTheme("Crimson") end)
addAction(SetScroller, "Emerald Green Theme", function() applyTheme("Emerald") end)
addAction(SetScroller, "Neon Purple Theme", function() applyTheme("NeonPurple") end)
addAction(SetScroller, "Sunset Gold Theme", function() applyTheme("SunsetGold") end)

-- Keybind to toggle UI
local openKey = Enum.KeyCode.RightControl
addInput(SetScroller, "RightControl", "Set Toggle Key", function(text)
    local code = Enum.KeyCode[text]
    if code then
        openKey = code
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == openKey then
        local targetVisible = not MainFrame.Visible
        if targetVisible then
            MainFrame.Size = UDim2.new(0, 0, 0, 0)
            MainFrame.Visible = true
            TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 620, 0, 390)
            }):Play()
        else
            TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 0, 0, 0)
            }):Play()
            task.delay(0.2, function()
                MainFrame.Visible = false
            end)
        end
    end
end)

-- Toggle Button triggers Frame open/close
ToggleButton.MouseButton1Click:Connect(function()
    local targetVisible = not MainFrame.Visible
    if targetVisible then
        MainFrame.Size = UDim2.new(0, 0, 0, 0)
        MainFrame.Visible = true
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 620, 0, 390)
        }):Play()
    else
        TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        }):Play()
        task.delay(0.2, function()
            MainFrame.Visible = false
        end)
    end
end)

-- Initialize Theme & Show UI on launch
applyTheme("OrbitBlue")
MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.Visible = true
TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 620, 0, 390)
}):Play()

print("[Orbit HUB] Loaded successfully. Press RightControl or tap floating button to open/close.")

-- ============================================================
-- ROBLOX MENU PRO v3.5 | ULTRA OPTIMIZED & STEALTH EDITION
-- Nâng cấp kỹ thuật toàn diện: Tối ưu hoá FPS/GC, chống quét,
-- bypass anti-cheat nhiều lớp, humanization aimbot,
-- Top-Center ESP Target Counter HUD.
-- ============================================================

-- Fast Localizations (Lua/Luau Micro-Optimizations)
local Vector2_new = Vector2.new
local Vector3_new = Vector3.new
local Vector3_zero = Vector3.new(0, 0, 0)
local CFrame_new = CFrame.new
local CFrame_Angles = CFrame.Angles
local Color3_fromRGB = Color3.fromRGB
local math_clamp = math.clamp
local math_floor = math.floor
local math_abs = math.abs
local math_min = math.min
local math_max = math.max
local math_sqrt = math.sqrt
local math_pow = math.pow
local math_random = math.random
local string_format = string.format
local string_sub = string.sub
local string_lower = string.lower
local string_find = string.find
local string_upper = string.upper
local table_insert = table.insert
local table_clear = table.clear or function(t) for k in pairs(t) do t[k] = nil end end
local os_clock = os.clock
local tick = tick
local task_wait = task.wait
local task_delay = task.delay
local task_spawn = task.spawn
local pcall = pcall
local type = type
local typeof = typeof
local ipairs = ipairs
local pairs = pairs

-- Core Services
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera
end)

local UI_Elements = {}
local isMenuConnected = false
local SendNotification = nil

-- Registry cho theme + search + active-dot
local ThemeObjects = { Panels = {}, Toggles = {}, SliderFills = {}, Dropbox = {} }
local SearchIndex = {}
local TabActiveKeys = {}

-- 3 bộ theme
local ThemePresets = {
    Dark = {
        MainBg = Color3_fromRGB(18, 18, 20), PanelBg = Color3_fromRGB(30, 30, 34),
        Panel = Color3_fromRGB(22, 22, 25), Stroke = Color3_fromRGB(45, 45, 50),
        AccentOn = Color3_fromRGB(255, 255, 255), AccentOff = Color3_fromRGB(45, 45, 50)
    },
    Midnight = {
        MainBg = Color3_fromRGB(9, 14, 26), PanelBg = Color3_fromRGB(20, 30, 52),
        Panel = Color3_fromRGB(14, 20, 36), Stroke = Color3_fromRGB(45, 75, 140),
        AccentOn = Color3_fromRGB(90, 170, 255), AccentOff = Color3_fromRGB(28, 40, 66)
    },
    Violet = {
        MainBg = Color3_fromRGB(18, 12, 28), PanelBg = Color3_fromRGB(38, 26, 56),
        Panel = Color3_fromRGB(27, 18, 42), Stroke = Color3_fromRGB(95, 55, 145),
        AccentOn = Color3_fromRGB(205, 125, 255), AccentOff = Color3_fromRGB(48, 34, 70)
    }
}

-- Static Constant Bone Tables (Eliminates GC Churn in Skeleton ESP)
local R15_BONES = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"}
}

local R6_BONES = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"},
    {"Torso", "Right Arm"},
    {"Torso", "Left Leg"},
    {"Torso", "Right Leg"}
}

-- ============================================================
-- LỚP ẨN DANH TÍNH (STEALTH LAYER)
-- ============================================================
local function RandomString(length)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local str = ""
    for _ = 1, length do
        local r = math_random(1, #chars)
        str = str .. string_sub(chars, r, r)
    end
    return str
end

local IDS = {
    UI = RandomString(12),
    ChamsFolder = RandomString(10),
    ConfigName = "FF_Pro_Config.json",
    Watermark = "SYS v" .. math_random(2, 9) .. "." .. math_random(0, 9) .. "." .. math_random(0, 9)
}

-- Lấy GUI cha an toàn nhất: gethui() (không bị screenshot/Roblox scan)
local function GetSafeParent()
    if gethui and type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    if syn and syn.ui and type(syn.ui) == "function" then
        local ok, hui = pcall(function() return syn.ui() end)
        if ok and hui then return hui end
    end
    local ok, parent = pcall(function() return CoreGui end)
    if ok and parent then return parent end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local parentGui = GetSafeParent()

local function ProtectInstance(inst)
    if protect_gui and type(protect_gui) == "function" then
        pcall(protect_gui, inst)
    end
    if syn and syn.secure_ui then
        pcall(function() syn.secure_ui(inst) end)
    end
    if protectui and type(protectui) == "function" then
        pcall(protectui, inst)
    end
end

-- ============================================================
-- CẤU HÌNH & THEME
-- ============================================================
local Settings = {
    AimEnabled = false, AimHoldMode = false, AimSafe = false, AimDist = 1000,
    TargetPart = "Head", WallCheck = false, TeamCheck = true,
    FOV = 170, FOVVisible = false, AimSnapline = false,
    AimSmoothness = 1, AimJitter = 0, ReactionDelay = 0,

    ProAimEnabled = false, ProAimHoldMode = false, ProAimFOV = 120,
    ProAimFOVVisible = false, ProAimSmoothness = 1, ProAimTargetPart = "Head",
    ProAimWallCheck = false, ProAimTeamCheck = true,
    ProAimHoldMouse = Enum.UserInputType.MouseButton2,
    ProAimSnapline = false, ProAimDist = 1000,
    ProAimJitter = 0, ProAimReaction = 0,
    AutoFire = false, AutoFireHoldM2 = false, AutoFireWallCheck = false, AutoFireDelay = 0, AutoFireFOV = 100,
    NoRecoil = false, NoRecoilStrength = 1,

    ESPEnabled = false, ESPTeamCheck = true, ESPDist = 1000,
    ESPBox = false, ESPName = false, ESPDistance = false, ESPHealth = false,
    ESPLine = false, ESPSkeleton = false,
    ESPChams = false, ChamsColor = "Red",
    ESPWeapon = false, ESPLevel = false, AimWarning = false, OffscreenArrows = false,
    ESPCount = true, -- Đếm số người ESP trên đỉnh màn hình (Top-Center HUD)

    Crosshair = false, CrosshairStyle = "Cross", CrosshairSize = 10,
    CrosshairThickness = 1.5, CrosshairColor = "Green",

    SpeedHack = false, WalkSpeed = 30,
    JumpHack = false, JumpPower = 100,
    InfJump = false, Fly = false, FlySpeed = 50, Noclip = false,
    AutoTeleport = false, AutoTeleportDistance = 3, AutoTeleportPosition = "Sau Lưng",
    AutoTeleportCameraLock = true, UndergroundNoclip = false, UndergroundDistance = 5,
    SpinBot = false, SpinSpeed = 50,

    OptimShadows = false, OptimTextures = false, OptimFog = false,

    AntiCheatBypass = true, BypassACMove = true,
    HeartbeatReply = true, AntiScreenshot = true,

    ToggleKeybind = Enum.KeyCode.Insert,
    Spectating = false, SpectatePlayer = "",
    ThemeName = "Dark",
    AimHotkey = Enum.KeyCode.N,
    AutoFireHotkey = Enum.KeyCode.M,
    AutoTeleportHotkey = Enum.KeyCode.E,
    UndergroundHotkey = Enum.KeyCode.Q
}

local function GetActivePreset()
    return ThemePresets[Settings.ThemeName] or ThemePresets.Dark
end

local ColorList = {
    ["White"] = Color3_fromRGB(255, 255, 255), ["Red"] = Color3_fromRGB(255, 50, 50),
    ["Green"] = Color3_fromRGB(0, 255, 0), ["Blue"] = Color3_fromRGB(50, 150, 255),
    ["Yellow"] = Color3_fromRGB(255, 255, 0), ["Pink"] = Color3_fromRGB(255, 105, 180),
    ["Black"] = Color3_fromRGB(0, 0, 0)
}

local Theme = {
    MainBg = Color3_fromRGB(18, 18, 20), PanelBg = Color3_fromRGB(30, 30, 34),
    TopBarText = Color3_fromRGB(180, 180, 180), TextWhite = Color3_fromRGB(240, 240, 240),
    TextDark = Color3_fromRGB(120, 120, 120), AccentOn = Color3_fromRGB(255, 255, 255),
    AccentOff = Color3_fromRGB(45, 45, 50), KnobOn = Color3_fromRGB(18, 18, 20),
    KnobOff = Color3_fromRGB(180, 180, 180), DotGreen = Color3_fromRGB(0, 255, 0),
    DotRed = Color3_fromRGB(255, 50, 50),
    Font = Enum.Font.GothamMedium, FontBold = Enum.Font.GothamBold
}

local MainFrame = nil
local MainStroke = nil

local function ApplyTheme()
    local p = GetActivePreset()
    Theme.MainBg = p.MainBg
    Theme.PanelBg = p.PanelBg
    Theme.AccentOn = p.AccentOn
    Theme.AccentOff = p.AccentOff

    if MainFrame then
        pcall(function() MainFrame.BackgroundColor3 = p.MainBg end)
    end
    if MainStroke then
        pcall(function() MainStroke.Color = p.Stroke end)
    end

    for _, o in pairs(ThemeObjects.Panels) do
        pcall(function()
            o.Bg.BackgroundColor3 = p.Panel
            o.Header.BackgroundColor3 = p.PanelBg
            o.HeaderSquare.BackgroundColor3 = p.PanelBg
            o.Stroke.Color = p.Stroke
        end)
    end
    for _, o in pairs(ThemeObjects.Toggles) do
        pcall(function()
            o.Btn.BackgroundColor3 = o.State and p.AccentOn or p.AccentOff
            o.Knob.BackgroundColor3 = o.State and Theme.KnobOn or Theme.KnobOff
        end)
    end
    for _, o in pairs(ThemeObjects.SliderFills) do
        pcall(function() o.Fill.BackgroundColor3 = p.AccentOn end)
    end
    for _, o in pairs(ThemeObjects.Dropbox) do
        pcall(function() o.Box.BackgroundColor3 = Color3_fromRGB(35, 35, 38) end)
    end
end

-- ============================================================
-- DRAWING CORE
-- ============================================================
local FOVring = Drawing.new("Circle")
FOVring.Visible = false; FOVring.Thickness = 1.5; FOVring.Color = Theme.AccentOn
FOVring.Filled = false; FOVring.Transparency = 1
FOVring.Radius = Settings.FOV; FOVring.Position = Camera.ViewportSize / 2

local AimSnaplineDraw = Drawing.new("Line")
AimSnaplineDraw.Visible = false; AimSnaplineDraw.Thickness = 1.5
AimSnaplineDraw.Color = Color3_fromRGB(255, 50, 50); AimSnaplineDraw.Transparency = 1

local CrosshairDraws = {
    L = Drawing.new("Line"), R = Drawing.new("Line"),
    T = Drawing.new("Line"), B = Drawing.new("Line"),
    Circle = Drawing.new("Circle"), Dot = Drawing.new("Circle")
}

local AimWarnText = Drawing.new("Text")
AimWarnText.Visible = false
AimWarnText.Center = true
AimWarnText.Outline = true
AimWarnText.Size = 22

local ESPTable = {}

-- Reusable RaycastParams for Wall Checks (Zero allocation per raycast)
local WallCheckRayParams = RaycastParams.new()
WallCheckRayParams.FilterType = Enum.RaycastFilterType.Exclude
WallCheckRayParams.IgnoreWater = true

-- ============================================================
-- KHIÊN CHỐNG BAN (SHIELD CORE)
-- ============================================================
local Shield = {
    Blocks = 0,
    ShieldActive = false
}

local BLOCK_REMOTES = {
    "report", "ban", "kick", "punish", "crash", "log",
    "anticheat", "adonis", "hdadmin", "moderator", "admin",
    "detect", "spectate", "teleport", "tase", "exploit", "cheat"
}

local HEARTBEAT_REMOTES = {
    "heartbeat", "ping", "accheck", "verif", "security",
    "authenticate", "validation", "checkclient", "response"
}

local function ClassifyRemote(name)
    if not name then return nil end
    local n = string_lower(tostring(name))
    for i = 1, #BLOCK_REMOTES do
        if string_find(n, BLOCK_REMOTES[i], 1, true) then return "block" end
    end
    for i = 1, #HEARTBEAT_REMOTES do
        if string_find(n, HEARTBEAT_REMOTES[i], 1, true) then return "heartbeat" end
    end
    return nil
end

local hasCheckcaller = checkcaller ~= nil
local function IsExternal()
    if not hasCheckcaller then return true end
    local ok, val = pcall(checkcaller)
    if ok then return not val end
    return true
end

-- Hook Metatable: chặn gói tin độc, trả lời heartbeat, spoof thuộc tính
local function InitShield()
    local ok, mt = pcall(getrawmetatable, game)
    if not ok or not mt then return end

    local hasNamecall = pcall(function() return mt.__namecall end)
    local hasIndex = pcall(function() return mt.__index end)
    if not hasNamecall and not hasIndex then return end

    local oldNamecall = mt.__namecall
    local oldIndex = mt.__index

    if setreadonly then pcall(setreadonly, mt, false) end

    local useCClosure = newcclosure ~= nil

    if hasNamecall then
        mt.__namecall = useCClosure and newcclosure(function(self, ...)
            if not IsExternal() then
                if oldNamecall then return oldNamecall(self, ...) end
                return self
            end

            local method = nil
            if getnamecallmethod then
                local ok2, m = pcall(getnamecallmethod)
                if ok2 then method = m end
            end

            if Settings.AntiCheatBypass and method == "FireServer" then
                local okName, rname = pcall(function() return self.Name end)
                if okName and rname then
                    local class = ClassifyRemote(rname)
                    if class == "block" then
                        Shield.Blocks = Shield.Blocks + 1
                        return
                    elseif class == "heartbeat" then
                        return
                    end
                end
            elseif Settings.AntiCheatBypass and method == "InvokeServer" then
                local okName, rname = pcall(function() return self.Name end)
                if okName and rname then
                    local class = ClassifyRemote(rname)
                    if class == "block" then
                        Shield.Blocks = Shield.Blocks + 1
                        return 0
                    elseif class == "heartbeat" then
                        return true
                    end
                end
            end

            if oldNamecall then return oldNamecall(self, ...) end
            return self
        end) or function(self, ...)
            if not IsExternal() or not Settings.AntiCheatBypass then
                if oldNamecall then return oldNamecall(self, ...) end
                return self
            end
            local okName, rname = pcall(function() return self.Name end)
            if okName and rname then
                local class = ClassifyRemote(rname)
                if method == "FireServer" and class == "block" then
                    Shield.Blocks = Shield.Blocks + 1
                    return
                end
                if method == "InvokeServer" and class == "block" then
                    Shield.Blocks = Shield.Blocks + 1
                    return 0
                end
            end
            if oldNamecall then return oldNamecall(self, ...) end
            return self
        end
    end

    if hasIndex then
        mt.__index = useCClosure and newcclosure(function(self, idx)
            if IsExternal() and Settings.AntiCheatBypass then
                local okIsA = pcall(function() return self.IsA end)
                if okIsA then
                    local isHum, ok1 = pcall(function() return self:IsA("Humanoid") end)
                    if ok1 and isHum then
                        if idx == "WalkSpeed" then return 16 end
                        if idx == "JumpPower" then return 50 end
                    end
                    local isRoot, ok2 = pcall(function()
                        return self:IsA("BasePart") and self.Name == "HumanoidRootPart"
                    end)
                    if ok2 and isRoot then
                        if idx == "Velocity" or idx == "AssemblyLinearVelocity" then
                            return Vector3_zero
                        end
                    end
                end
            end
            if oldIndex then return oldIndex(self, idx) end
            return nil
        end) or function(self, idx)
            if oldIndex then return oldIndex(self, idx) end
            return nil
        end
    end

    if setreadonly then pcall(setreadonly, mt, true) end
    Shield.ShieldActive = true
end

-- ============================================================
-- ESP CREATE/REMOVE (MEMORY LEAK SAFE)
-- ============================================================
local ChamsFolder = Instance.new("Folder")
ChamsFolder.Name = IDS.ChamsFolder
pcall(function() ChamsFolder.Parent = parentGui end)
if not ChamsFolder.Parent then pcall(function() ChamsFolder.Parent = Camera end) end

local function createESP(player)
    if ESPTable[player] then return end
    local esp = {}
    esp.Box = Drawing.new("Square"); esp.Box.Thickness = 1.5
    esp.Box.Color = Color3_fromRGB(255, 255, 255); esp.Box.Filled = false
    esp.Name = Drawing.new("Text"); esp.Name.Size = 14; esp.Name.Center = true
    esp.Name.Outline = true; esp.Name.Color = Color3_fromRGB(255, 255, 255)
    esp.HealthBg = Drawing.new("Line"); esp.HealthBg.Thickness = 3
    esp.HealthBg.Color = Color3_fromRGB(0, 0, 0)
    esp.Health = Drawing.new("Line"); esp.Health.Thickness = 1.5
    esp.Health.Color = Color3_fromRGB(0, 255, 0)
    esp.Tracer = Drawing.new("Line"); esp.Tracer.Thickness = 1.5
    esp.Tracer.Color = Color3_fromRGB(255, 255, 255)

    esp.Info = Drawing.new("Text")
    esp.Info.Size = 12
    esp.Info.Center = true
    esp.Info.Outline = true
    esp.Info.Color = Color3_fromRGB(255, 255, 255)

    esp.Skeleton = {}
    for i = 1, 14 do
        local bone = Drawing.new("Line")
        bone.Thickness = 1.5
        bone.Color = Color3_fromRGB(255, 255, 255)
        bone.Visible = false
        esp.Skeleton[i] = bone
    end

    esp.Chams = Instance.new("Highlight")
    esp.Chams.Name = RandomString(8)
    esp.Chams.FillTransparency = 0.5
    esp.Chams.OutlineTransparency = 0.1
    esp.Chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    esp.Chams.Enabled = false
    esp.Chams.Parent = ChamsFolder

    esp.Arrow1 = Drawing.new("Line"); esp.Arrow1.Thickness = 2.5; esp.Arrow1.Color = Color3_fromRGB(255, 35, 35); esp.Arrow1.Visible = false
    esp.Arrow2 = Drawing.new("Line"); esp.Arrow2.Thickness = 2.5; esp.Arrow2.Color = Color3_fromRGB(255, 35, 35); esp.Arrow2.Visible = false
    esp.Arrow3 = Drawing.new("Line"); esp.Arrow3.Thickness = 2; esp.Arrow3.Color = Color3_fromRGB(255, 35, 35); esp.Arrow3.Visible = false

    esp._chamsOn = false
    ESPTable[player] = esp
end

local function removeESP(player)
    local esp = ESPTable[player]
    if esp then
        pcall(function() if esp.Box then esp.Box:Remove() end end)
        pcall(function() if esp.Name then esp.Name:Remove() end end)
        pcall(function() if esp.HealthBg then esp.HealthBg:Remove() end end)
        pcall(function() if esp.Health then esp.Health:Remove() end end)
        pcall(function() if esp.Tracer then esp.Tracer:Remove() end end)
        pcall(function() if esp.Info then esp.Info:Remove() end end)
        pcall(function() if esp.Chams then esp.Chams:Destroy() end end)
        pcall(function()
            if esp.Arrow1 then esp.Arrow1:Remove() end
            if esp.Arrow2 then esp.Arrow2:Remove() end
            if esp.Arrow3 then esp.Arrow3:Remove() end
        end)
        if esp.Skeleton then
            for i = 1, #esp.Skeleton do
                pcall(function() if esp.Skeleton[i] then esp.Skeleton[i]:Remove() end end)
            end
        end
        ESPTable[player] = nil
    end
end

Players.PlayerAdded:Connect(createESP)
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then createESP(player) end
end
Players.PlayerRemoving:Connect(removeESP)

-- ============================================================
-- UI CHÍNH
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = IDS.UI
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = parentGui
ProtectInstance(ScreenGui)

MainFrame = Instance.new("Frame")
MainFrame.Name = RandomString(8)
MainFrame.Size = UDim2.new(0, 650, 0, 420)
MainFrame.Position = UDim2.new(0.5, -325, 0.5, -210)
MainFrame.BackgroundColor3 = Theme.MainBg
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3_fromRGB(45, 45, 50)
MainStroke.Thickness = 1
MainStroke.Parent = MainFrame

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

-- ============================================================
-- TOP-CENTER ESP TARGET COUNTER (KHUNG ĐEN VUÔNG - SỐ PHÓNG TO)
-- ============================================================
local ESPCounterBox = Instance.new("Frame")
ESPCounterBox.Name = "ESPCounterBox"
ESPCounterBox.AnchorPoint = Vector2_new(0.5, 0)
ESPCounterBox.Position = UDim2.new(0.5, 0, 0, 15)
ESPCounterBox.Size = UDim2.new(0, 60, 0, 56)
ESPCounterBox.BackgroundColor3 = Color3_fromRGB(10, 10, 12)
ESPCounterBox.BackgroundTransparency = 0.15
ESPCounterBox.BorderSizePixel = 0
ESPCounterBox.Visible = false
ESPCounterBox.Parent = ScreenGui
Instance.new("UICorner", ESPCounterBox).CornerRadius = UDim.new(0, 8)

local ESPCounterStroke = Instance.new("UIStroke")
ESPCounterStroke.Color = Color3_fromRGB(50, 50, 55)
ESPCounterStroke.Thickness = 1.5
ESPCounterStroke.Transparency = 0.3
ESPCounterStroke.Parent = ESPCounterBox

local ESPCounterLabel = Instance.new("TextLabel")
ESPCounterLabel.Name = "ESPCounterLabel"
ESPCounterLabel.Size = UDim2.new(1, 0, 1, 0)
ESPCounterLabel.Position = UDim2.new(0, 0, 0, 0)
ESPCounterLabel.BackgroundTransparency = 1
ESPCounterLabel.BorderSizePixel = 0
ESPCounterLabel.Text = "0"
ESPCounterLabel.TextColor3 = Color3_fromRGB(255, 50, 50)
ESPCounterLabel.Font = Enum.Font.GothamBold
ESPCounterLabel.TextSize = 36
ESPCounterLabel.TextStrokeColor3 = Color3_fromRGB(0, 0, 0)
ESPCounterLabel.TextStrokeTransparency = 0.4
ESPCounterLabel.TextXAlignment = Enum.TextXAlignment.Center
ESPCounterLabel.TextYAlignment = Enum.TextYAlignment.Center
ESPCounterLabel.Parent = ESPCounterBox

-- Watermark
local WatermarkFrame = Instance.new("Frame")
WatermarkFrame.Size = UDim2.new(0, 300, 0, 20)
WatermarkFrame.Position = UDim2.new(1, -310, 1, -30)
WatermarkFrame.BackgroundTransparency = 1
WatermarkFrame.Parent = ScreenGui

local Watermark = Instance.new("TextLabel")
Watermark.Size = UDim2.new(1, 0, 1, 0)
Watermark.BackgroundTransparency = 1
Watermark.RichText = true
Watermark.Text = "✨ ĐẶC QUYỀN ✨ " .. IDS.Watermark .. " | <font color=\"#FFD700\">An Nguyễn Studio</font>"
Watermark.TextColor3 = Color3_fromRGB(255, 215, 0)
Watermark.Font = Theme.FontBold
Watermark.TextSize = 14
Watermark.TextXAlignment = Enum.TextXAlignment.Right
Watermark.TextStrokeTransparency = 0.5
Watermark.Parent = WatermarkFrame

local function UpdateWatermarkColor(color)
    pcall(function() Watermark.TextColor3 = color end)
end

local NotifyFrame = Instance.new("Frame")
NotifyFrame.Name = RandomString(6)
NotifyFrame.Size = UDim2.new(0, 250, 1, -50)
NotifyFrame.Position = UDim2.new(1, -260, 0, 10)
NotifyFrame.BackgroundTransparency = 1
NotifyFrame.Parent = ScreenGui

local NotifyLayout = Instance.new("UIListLayout")
NotifyLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifyLayout.Padding = UDim.new(0, 5)
NotifyLayout.Parent = NotifyFrame

-- Tooltip theo chuột
local Tooltip = Instance.new("TextLabel")
Tooltip.Size = UDim2.new(0, 190, 0, 26)
Tooltip.BackgroundColor3 = Color3_fromRGB(16, 16, 18)
Tooltip.BackgroundTransparency = 0.1
Tooltip.BorderSizePixel = 0
Tooltip.TextColor3 = Color3_fromRGB(230, 230, 230)
Tooltip.Font = Enum.Font.Gotham
Tooltip.TextSize = 11
Tooltip.TextXAlignment = Enum.TextXAlignment.Center
Tooltip.Visible = false
Tooltip.ZIndex = 50
Tooltip.Parent = ScreenGui
Instance.new("UICorner", Tooltip).CornerRadius = UDim.new(0, 6)

local function ShowTooltip(text)
    if text and text ~= "" then
        Tooltip.Text = text
        Tooltip.Visible = true
        local pos = UserInputService:GetMouseLocation()
        Tooltip.Position = UDim2.new(0, pos.X + 14, 0, pos.Y + 14)
    else
        Tooltip.Visible = false
    end
end

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and Tooltip.Visible then
        local pos = UserInputService:GetMouseLocation()
        Tooltip.Position = UDim2.new(0, pos.X + 14, 0, pos.Y + 14)
    end
end)

SendNotification = function(title, text)
    local Notif = Instance.new("Frame")
    Notif.Size = UDim2.new(1, 0, 0, 60)
    Notif.BackgroundColor3 = Theme.PanelBg
    Notif.BackgroundTransparency = 1
    Notif.Parent = NotifyFrame

    Instance.new("UICorner", Notif).CornerRadius = UDim.new(0, 8)
    local Stroke = Instance.new("UIStroke", Notif)
    Stroke.Color = Color3_fromRGB(45, 45, 50)
    Stroke.Transparency = 1

    local Title = Instance.new("TextLabel", Notif)
    Title.Size = UDim2.new(1, -20, 0, 25)
    Title.Position = UDim2.new(0, 10, 0, 5)
    Title.BackgroundTransparency = 1
    Title.Text = title
    Title.TextColor3 = Theme.TextWhite
    Title.TextTransparency = 1
    Title.Font = Theme.FontBold
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local Desc = Instance.new("TextLabel", Notif)
    Desc.Size = UDim2.new(1, -20, 0, 20)
    Desc.Position = UDim2.new(0, 10, 0, 30)
    Desc.BackgroundTransparency = 1
    Desc.Text = text
    Desc.TextColor3 = Theme.TextDark
    Desc.TextTransparency = 1
    Desc.Font = Theme.Font
    Desc.TextSize = 12
    Desc.TextXAlignment = Enum.TextXAlignment.Left

    TweenService:Create(Notif, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
    TweenService:Create(Stroke, TweenInfo.new(0.3), {Transparency = 0}):Play()
    TweenService:Create(Title, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
    TweenService:Create(Desc, TweenInfo.new(0.3), {TextTransparency = 0}):Play()

    task_delay(3, function()
        TweenService:Create(Notif, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        TweenService:Create(Stroke, TweenInfo.new(0.3), {Transparency = 1}):Play()
        TweenService:Create(Title, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        TweenService:Create(Desc, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        task_wait(0.3)
        Notif:Destroy()
    end)
end

local function MakeDraggable(topbar, main)
    local dragging, dragInput, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    topbar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

MakeDraggable(WatermarkFrame, WatermarkFrame)

-- ============================================================
-- TOP BAR
-- ============================================================
local TopBar = Instance.new("Frame")
TopBar.Name = RandomString(6)
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundTransparency = 1
TopBar.Parent = MainFrame
MakeDraggable(TopBar, MainFrame)

local TopBarLine = Instance.new("Frame")
TopBarLine.Size = UDim2.new(1, 0, 0, 1)
TopBarLine.Position = UDim2.new(0, 0, 1, -1)
TopBarLine.BackgroundColor3 = Color3_fromRGB(35, 35, 40)
TopBarLine.BorderSizePixel = 0
TopBarLine.Parent = TopBar

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(0, 400, 1, 0)
StatusText.Position = UDim2.new(0, 15, 0, 0)
StatusText.BackgroundTransparency = 1
StatusText.RichText = true
StatusText.Text = "<font color=\"#ffffff\">● Rivals Menu</font>   <font color=\"#666677\">/</font>   <font color=\"#aaaaaa\">Login</font>"
StatusText.TextColor3 = Theme.TopBarText
StatusText.Font = Theme.Font
StatusText.TextSize = 12
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Visible = true
StatusText.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 40, 1, 0)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Theme.TextDark
CloseBtn.Font = Theme.Font
CloseBtn.TextSize = 14
CloseBtn.Parent = TopBar
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- SIDEBAR & TABS
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 50, 1, -40)
Sidebar.Position = UDim2.new(0, 0, 0, 40)
Sidebar.BackgroundTransparency = 1
Sidebar.Visible = false
Sidebar.Parent = MainFrame

local SidebarLine = Instance.new("Frame")
SidebarLine.Size = UDim2.new(0, 1, 1, 0)
SidebarLine.Position = UDim2.new(1, -1, 0, 0)
SidebarLine.BackgroundColor3 = Color3_fromRGB(35, 35, 40)
SidebarLine.BorderSizePixel = 0
SidebarLine.Parent = Sidebar

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -60, 1, -50)
ContentArea.Position = UDim2.new(0, 50, 0, 40)
ContentArea.BackgroundTransparency = 1
ContentArea.Visible = false
ContentArea.Parent = MainFrame

-- ============================================================
-- CỬA SỔ CHECK KEY (LOGIN FRAME ĐỘC LẬP)
-- ============================================================
local LoginFrame = Instance.new("Frame")
LoginFrame.Name = "LoginFrame"
LoginFrame.Size = UDim2.new(0, 360, 0, 225)
LoginFrame.Position = UDim2.new(0.5, -180, 0.5, -112)
LoginFrame.BackgroundColor3 = Theme.MainBg
LoginFrame.BorderSizePixel = 0
LoginFrame.Visible = true
LoginFrame.Parent = ScreenGui
Instance.new("UICorner", LoginFrame).CornerRadius = UDim.new(0, 10)

local LoginStroke = Instance.new("UIStroke", LoginFrame)
LoginStroke.Color = Color3_fromRGB(45, 45, 50)
LoginStroke.Thickness = 1

local LoginTopBar = Instance.new("Frame")
LoginTopBar.Size = UDim2.new(1, 0, 0, 40)
LoginTopBar.BackgroundTransparency = 1
LoginTopBar.Parent = LoginFrame
MakeDraggable(LoginTopBar, LoginFrame)

local LoginTopLine = Instance.new("Frame")
LoginTopLine.Size = UDim2.new(1, 0, 0, 1)
LoginTopLine.Position = UDim2.new(0, 0, 1, -1)
LoginTopLine.BackgroundColor3 = Color3_fromRGB(35, 35, 40)
LoginTopLine.BorderSizePixel = 0
LoginTopLine.Parent = LoginTopBar

local LoginTitle = Instance.new("TextLabel")
LoginTitle.Size = UDim2.new(0, 300, 1, 0)
LoginTitle.Position = UDim2.new(0, 15, 0, 0)
LoginTitle.BackgroundTransparency = 1
LoginTitle.RichText = true
LoginTitle.Text = "<font color=\"#ffffff\">● Rivals Menu</font>   <font color=\"#666677\">/</font>   <font color=\"#aaaaaa\">Login</font>"
LoginTitle.TextColor3 = Theme.TopBarText
LoginTitle.Font = Theme.Font
LoginTitle.TextSize = 12
LoginTitle.TextXAlignment = Enum.TextXAlignment.Left
LoginTitle.Parent = LoginTopBar

local LoginCloseBtn = Instance.new("TextButton")
LoginCloseBtn.Size = UDim2.new(0, 40, 1, 0)
LoginCloseBtn.Position = UDim2.new(1, -40, 0, 0)
LoginCloseBtn.BackgroundTransparency = 1
LoginCloseBtn.Text = "X"
LoginCloseBtn.TextColor3 = Theme.TextDark
LoginCloseBtn.Font = Theme.Font
LoginCloseBtn.TextSize = 14
LoginCloseBtn.Parent = LoginTopBar
LoginCloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local LoginBody = Instance.new("Frame")
LoginBody.Size = UDim2.new(1, 0, 1, -40)
LoginBody.Position = UDim2.new(0, 0, 0, 40)
LoginBody.BackgroundTransparency = 1
LoginBody.Parent = LoginFrame

local LicenseKeyLbl = Instance.new("TextLabel")
LicenseKeyLbl.Size = UDim2.new(1, -36, 0, 18)
LicenseKeyLbl.Position = UDim2.new(0, 18, 0, 10)
LicenseKeyLbl.BackgroundTransparency = 1
LicenseKeyLbl.Text = "LICENSE KEY"
LicenseKeyLbl.TextColor3 = Color3_fromRGB(130, 130, 145)
LicenseKeyLbl.Font = Theme.FontBold
LicenseKeyLbl.TextSize = 11
LicenseKeyLbl.TextXAlignment = Enum.TextXAlignment.Left
LicenseKeyLbl.Parent = LoginBody

local KeyInputBox = Instance.new("TextBox")
KeyInputBox.Size = UDim2.new(1, -36, 0, 42)
KeyInputBox.Position = UDim2.new(0, 18, 0, 32)
KeyInputBox.BackgroundColor3 = Color3_fromRGB(12, 12, 16)
KeyInputBox.TextColor3 = Theme.TextWhite
KeyInputBox.PlaceholderText = "RLX-XXXX-XXXX-XXXX"
KeyInputBox.PlaceholderColor3 = Color3_fromRGB(70, 70, 85)
KeyInputBox.Font = Enum.Font.Gotham
KeyInputBox.TextSize = 13
KeyInputBox.Text = ""
KeyInputBox.TextStrokeTransparency = 1
KeyInputBox.ClearTextOnFocus = false
KeyInputBox.TextXAlignment = Enum.TextXAlignment.Left
KeyInputBox.Parent = LoginBody
Instance.new("UICorner", KeyInputBox).CornerRadius = UDim.new(0, 8)

local KeyInputPadding = Instance.new("UIPadding", KeyInputBox)
KeyInputPadding.PaddingLeft = UDim.new(0, 14)
KeyInputPadding.PaddingRight = UDim.new(0, 14)

local KeyInputStroke = Instance.new("UIStroke", KeyInputBox)
KeyInputStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
KeyInputStroke.Color = Color3_fromRGB(35, 35, 45)
KeyInputStroke.Thickness = 1

local LoginBtn = Instance.new("TextButton")
LoginBtn.Size = UDim2.new(1, -36, 0, 40)
LoginBtn.Position = UDim2.new(0, 18, 0, 84)
LoginBtn.BackgroundColor3 = Color3_fromRGB(245, 245, 250)
LoginBtn.TextColor3 = Color3_fromRGB(10, 10, 15)
LoginBtn.Font = Theme.FontBold
LoginBtn.TextSize = 14
LoginBtn.Text = "LOGIN"
LoginBtn.AutoButtonColor = false
LoginBtn.Parent = LoginBody
Instance.new("UICorner", LoginBtn).CornerRadius = UDim.new(0, 8)

-- KHUNG TRẠNG THÁI MÀU ĐỎ (CHỈ HIỆN KHI NHẬP VÀ BẤM LOGIN)
local StatusBox = Instance.new("Frame")
StatusBox.Size = UDim2.new(1, -36, 0, 38)
StatusBox.Position = UDim2.new(0, 18, 0, 134)
StatusBox.BackgroundColor3 = Color3_fromRGB(28, 16, 18)
StatusBox.BorderSizePixel = 0
StatusBox.Visible = false
StatusBox.Parent = LoginBody
Instance.new("UICorner", StatusBox).CornerRadius = UDim.new(0, 6)

local StatusStroke = Instance.new("UIStroke", StatusBox)
StatusStroke.Color = Color3_fromRGB(180, 45, 50)
StatusStroke.Thickness = 1

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 1, 0)
StatusLabel.Position = UDim2.new(0, 12, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = ""
StatusLabel.TextColor3 = Color3_fromRGB(255, 130, 140)
StatusLabel.Font = Enum.Font.Code
StatusLabel.TextSize = 13
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = StatusBox

local FooterLicenseLink = Instance.new("TextLabel")
FooterLicenseLink.Size = UDim2.new(0.5, -18, 0, 20)
FooterLicenseLink.Position = UDim2.new(0, 18, 1, -22)
FooterLicenseLink.BackgroundTransparency = 1
FooterLicenseLink.Text = "Get a license →"
FooterLicenseLink.TextColor3 = Color3_fromRGB(140, 140, 160)
FooterLicenseLink.Font = Theme.Font
FooterLicenseLink.TextSize = 12
FooterLicenseLink.TextXAlignment = Enum.TextXAlignment.Left
FooterLicenseLink.Parent = LoginBody

local FooterVersion = Instance.new("TextLabel")
FooterVersion.Size = UDim2.new(0.5, -18, 0, 20)
FooterVersion.Position = UDim2.new(0.5, 0, 1, -22)
FooterVersion.BackgroundTransparency = 1
FooterVersion.Text = "v2.14.0"
FooterVersion.TextColor3 = Color3_fromRGB(85, 85, 100)
FooterVersion.Font = Theme.Font
FooterVersion.TextSize = 12
FooterVersion.TextXAlignment = Enum.TextXAlignment.Right
FooterVersion.Parent = LoginBody

KeyInputBox.Focused:Connect(function()
    TweenService:Create(KeyInputStroke, TweenInfo.new(0.2), {Color = Color3_fromRGB(65, 65, 80)}):Play()
    if StatusBox.Visible then
        StatusBox.Visible = false
        TweenService:Create(LoginFrame, TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 360, 0, 225),
            Position = UDim2.new(0.5, -180, 0.5, -112)
        }):Play()
    end
end)
KeyInputBox.FocusLost:Connect(function()
    TweenService:Create(KeyInputStroke, TweenInfo.new(0.2), {Color = Color3_fromRGB(35, 35, 45)}):Play()
end)

local isCheckingKey = false
local function ProcessLogin()
    if isCheckingKey then return end
    isCheckingKey = true

    local inputKey = string.gsub(KeyInputBox.Text, "%s+", "")

    -- 1. Phóng to khung mượt mà để vừa khung đỏ trạng thái loading
    TweenService:Create(LoginFrame, TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 360, 0, 280),
        Position = UDim2.new(0.5, -180, 0.5, -140)
    }):Play()
    
    StatusBox.Visible = true
    StatusBox.BackgroundColor3 = Color3_fromRGB(28, 16, 18)
    StatusStroke.Color = Color3_fromRGB(180, 45, 50)
    StatusLabel.TextColor3 = Color3_fromRGB(255, 130, 140)

    -- Random thời gian kiểm tra từ 2s đến 4s
    local totalDuration = math.random(200, 400) / 100
    local step1Time = totalDuration * 0.45
    local step2Time = totalDuration * 0.55

    -- Bước 1: Kết nối server key với hiệu ứng chấm động
    local startTime = tick()
    local dotCount = 1
    while (tick() - startTime) < step1Time do
        StatusLabel.Text = "Connecting to key server" .. string.rep(".", dotCount)
        dotCount = (dotCount % 3) + 1
        task_wait(0.25)
    end

    -- Bước 2: Xác thực key với hiệu ứng chấm động
    startTime = tick()
    dotCount = 1
    while (tick() - startTime) < step2Time do
        StatusLabel.Text = "Authenticating key" .. string.rep(".", dotCount)
        dotCount = (dotCount % 3) + 1
        task_wait(0.25)
    end

    if string_lower(inputKey) == "admin" then
        -- Bước 3: Key hợp lệ (thành công)
        StatusBox.BackgroundColor3 = Color3_fromRGB(16, 30, 20)
        StatusStroke.Color = Color3_fromRGB(40, 180, 80)
        StatusLabel.TextColor3 = Color3_fromRGB(100, 255, 140)
        StatusLabel.Text = "Valid license key"

        LoginBtn.BackgroundColor3 = Color3_fromRGB(0, 220, 100)
        LoginBtn.TextColor3 = Color3_fromRGB(0, 0, 0)
        LoginBtn.Text = "ACCESS GRANTED ✓"
        task_wait(0.4)

        -- Đóng LoginFrame và hiện MainFrame cùng nút Kết Nối cũ
        LoginFrame.Visible = false
        MainFrame.Visible = true
        ConnectFrame.Visible = true
        ConnectBtn.Visible = true
        TerminalFrame.Visible = false
        isCheckingKey = false
    else
        -- Bước 3: Key không hợp lệ (thất bại)
        StatusBox.BackgroundColor3 = Color3_fromRGB(32, 14, 16)
        StatusStroke.Color = Color3_fromRGB(220, 50, 60)
        StatusLabel.TextColor3 = Color3_fromRGB(255, 110, 120)
        StatusLabel.Text = "Invalid license key"

        LoginBtn.BackgroundColor3 = Color3_fromRGB(220, 50, 50)
        LoginBtn.TextColor3 = Theme.TextWhite
        LoginBtn.Text = "LOGIN FAILED"

        task_wait(1)

        LoginBtn.BackgroundColor3 = Color3_fromRGB(245, 245, 250)
        LoginBtn.TextColor3 = Color3_fromRGB(10, 10, 15)
        LoginBtn.Text = "LOGIN"
        isCheckingKey = false
    end
end

LoginBtn.MouseButton1Click:Connect(ProcessLogin)
KeyInputBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then ProcessLogin() end
end)


-- ============================================================
-- KHUNG KẾT NỐI CŨ TRONG MENU CHÍNH (CONNECT FRAME)
-- ============================================================
local ConnectFrame = Instance.new("Frame")
ConnectFrame.Size = UDim2.new(1, 0, 1, -40)
ConnectFrame.Position = UDim2.new(0, 0, 0, 40)
ConnectFrame.BackgroundTransparency = 1
ConnectFrame.Visible = true
ConnectFrame.Parent = MainFrame

local ConnectBtn = Instance.new("TextButton")
ConnectBtn.Size = UDim2.new(0, 150, 0, 40)
ConnectBtn.Position = UDim2.new(0.5, -75, 0.5, -20)
ConnectBtn.BackgroundColor3 = Color3_fromRGB(0, 200, 0)
ConnectBtn.TextColor3 = Color3_fromRGB(0, 0, 0)
ConnectBtn.Font = Theme.FontBold
ConnectBtn.TextSize = 16
ConnectBtn.Text = "Set Prosers"
ConnectBtn.Parent = ConnectFrame
Instance.new("UICorner", ConnectBtn).CornerRadius = UDim.new(0, 8)

local TerminalFrame = Instance.new("Frame")
TerminalFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
TerminalFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
TerminalFrame.BackgroundColor3 = Color3_fromRGB(10, 10, 10)
TerminalFrame.BorderSizePixel = 0
TerminalFrame.Visible = false
TerminalFrame.Parent = ConnectFrame
Instance.new("UICorner", TerminalFrame).CornerRadius = UDim.new(0, 5)

local TerminalStroke = Instance.new("UIStroke")
TerminalStroke.Color = Color3_fromRGB(0, 255, 0)
TerminalStroke.Thickness = 1
TerminalStroke.Parent = TerminalFrame

local TerminalText = Instance.new("TextLabel")
TerminalText.Size = UDim2.new(1, -20, 1, -20)
TerminalText.Position = UDim2.new(0, 10, 0, 10)
TerminalText.BackgroundTransparency = 1
TerminalText.Text = ""
TerminalText.TextColor3 = Color3_fromRGB(0, 255, 0)
TerminalText.Font = Enum.Font.Code
TerminalText.TextSize = 14
TerminalText.TextXAlignment = Enum.TextXAlignment.Left
TerminalText.TextYAlignment = Enum.TextYAlignment.Top
TerminalText.RichText = true
TerminalText.Parent = TerminalFrame

local function TypeWriter(text, label, delayMs)
    local currentText = label.Text
    if currentText ~= "" then currentText = currentText .. "\n" end
    label.Text = currentText
    for i = 1, #text do
        label.Text = currentText .. string_sub(text, 1, i) .. (i % 2 == 0 and "_" or "")
        task_wait(delayMs or 0.02)
    end
    label.Text = currentText .. text
end

local function UnlockMenuFully(msg)
    isMenuConnected = true
    LoginFrame.Visible = false
    MainFrame.Visible = true
    ConnectFrame.Visible = false
    Sidebar.Visible = true
    ContentArea.Visible = true
    StatusText.Visible = true
    SendNotification("System", msg or "Đã kết nối thành công!")
end



-- XỬ LÝ NÚT KẾT NỐI CŨ TRONG MENU CHÍNH
ConnectBtn.MouseButton1Click:Connect(function()
    if ConnectBtn.Text ~= "Set Prosers" then return end
    ConnectBtn.Visible = false
    TerminalFrame.Visible = true

    task_spawn(function()
        local gameName = "RIVALS"
        pcall(function()
            local mps = game:GetService("MarketplaceService")
            local info = mps:GetProductInfo(game.PlaceId)
            if info and info.Name then gameName = info.Name end
        end)

        TypeWriter("> Khởi tạo phiên bảo mật...", TerminalText, 0.001)
        task_wait(0.02)
        TypeWriter("[+] Shield v3 đã kích hoạt... " .. (Shield.ShieldActive and "ACTIVE" or "MANUAL"), TerminalText, 0.001)
        task_wait(0.02)
        TypeWriter("[+] GUI ẩn: " .. IDS.UI, TerminalText, 0.001)
        task_wait(0.02)
        TypeWriter("[+] Đang tải tài nguyên... 100%", TerminalText, 0.001)
        task_wait(0.02)
        TypeWriter("> Xác nhận: " .. gameName, TerminalText, 0.001)
        task_wait(0.06)

        TweenService:Create(TerminalText, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
        task_wait(0.1)

        local GameLogo = Instance.new("ImageLabel")
        GameLogo.Size = UDim2.new(0, 110, 0, 110)
        GameLogo.Position = UDim2.new(0.5, -55, 0.5, -70)
        GameLogo.BackgroundTransparency = 1
        GameLogo.Image = "rbxthumb://type=Asset&id=" .. game.PlaceId .. "&w=150&h=150"
        GameLogo.ImageTransparency = 1
        GameLogo.Parent = TerminalFrame
        Instance.new("UICorner", GameLogo).CornerRadius = UDim.new(0, 12)
        local LogoStroke = Instance.new("UIStroke", GameLogo)
        LogoStroke.Color = Color3_fromRGB(0, 255, 0)
        LogoStroke.Thickness = 2
        LogoStroke.Transparency = 1

        local GameNameLbl = Instance.new("TextLabel")
        GameNameLbl.Size = UDim2.new(1, 0, 0, 30)
        GameNameLbl.Position = UDim2.new(0, 0, 0.5, 55)
        GameNameLbl.BackgroundTransparency = 1
        GameNameLbl.Text = "XÁC MINH: " .. string_upper(gameName)
        GameNameLbl.TextColor3 = Color3_fromRGB(50, 255, 50)
        GameNameLbl.Font = Enum.Font.GothamBold
        GameNameLbl.TextSize = 18
        GameNameLbl.TextTransparency = 1
        GameNameLbl.Parent = TerminalFrame

        local GameStatusLbl = Instance.new("TextLabel")
        GameStatusLbl.Size = UDim2.new(1, 0, 0, 20)
        GameStatusLbl.Position = UDim2.new(0, 0, 0.5, 80)
        GameStatusLbl.BackgroundTransparency = 1
        GameStatusLbl.Text = "Shield bảo vệ: " .. (Settings.AntiCheatBypass and "BẬT" or "TẮT")
        GameStatusLbl.TextColor3 = Color3_fromRGB(150, 150, 150)
        GameStatusLbl.Font = Enum.Font.Gotham
        GameStatusLbl.TextSize = 13
        GameStatusLbl.TextTransparency = 1
        GameStatusLbl.Parent = TerminalFrame

        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
        TweenService:Create(GameLogo, tweenInfo, {ImageTransparency = 0, Position = UDim2.new(0.5, -55, 0.5, -90)}):Play()
        TweenService:Create(LogoStroke, tweenInfo, {Transparency = 0.5}):Play()
        TweenService:Create(GameNameLbl, tweenInfo, {TextTransparency = 0, Position = UDim2.new(0, 0, 0.5, 35)}):Play()
        TweenService:Create(GameStatusLbl, tweenInfo, {TextTransparency = 0, Position = UDim2.new(0, 0, 0.5, 60)}):Play()
        task_wait(0.35)

        local fadeOutInfo = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(GameLogo, fadeOutInfo, {ImageTransparency = 1, Position = UDim2.new(0.5, -55, 0.5, -100)}):Play()
        TweenService:Create(LogoStroke, fadeOutInfo, {Transparency = 1}):Play()
        TweenService:Create(GameNameLbl, fadeOutInfo, {TextTransparency = 1}):Play()
        TweenService:Create(GameStatusLbl, fadeOutInfo, {TextTransparency = 1}):Play()
        TweenService:Create(TerminalFrame, fadeOutInfo, {BackgroundTransparency = 1}):Play()
        task_wait(0.12)

        GameLogo:Destroy()
        GameNameLbl:Destroy()
        GameStatusLbl:Destroy()

        UnlockMenuFully("Đã kết nối: " .. gameName)
    end)
end)

-- Phím tắt ẩn bỏ qua toàn bộ check key & kết nối: Shift + Enter
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Return
        and (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
        or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)) then
        if LoginFrame.Visible or ConnectFrame.Visible then
            UnlockMenuFully("Bỏ qua xác thực License Key & Trình kết nối")
        end
    end
end)

local Tabs = {}
local SidebarButtons = {}
local activeTab = nil

-- Chấm trạng thái trên icon tab: sáng khi tab có feature đang bật
local function UpdateTabDots()
    for tabName, _ in pairs(Tabs) do
        local anyOn = false
        for key, _ in pairs(TabActiveKeys[tabName] or {}) do
            if Settings[key] then
                anyOn = true
                break
            end
        end
        local btn = SidebarButtons[tabName]
        if btn and btn.Indicator then
            btn.Indicator.Visible = anyOn
        end
    end
end

local function CreateSidebarIcon(tabName, iconChar, yPos)
    local TabContent = Instance.new("Frame")
    TabContent.Size = UDim2.new(1, 0, 1, 0)
    TabContent.BackgroundTransparency = 1
    TabContent.Visible = false
    TabContent.Parent = ContentArea
    Tabs[tabName] = TabContent

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 30, 0, 30)
    Btn.Position = UDim2.new(0.5, -15, 0, yPos)
    Btn.BackgroundTransparency = 1
    Btn.BackgroundColor3 = Color3_fromRGB(255, 255, 255)
    Btn.Text = ""
    Btn.Parent = Sidebar
    SidebarButtons[tabName] = Btn
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)

    local Icon
    if iconChar:match("rbxasset") then
        Icon = Instance.new("ImageLabel")
        Icon.Name = "Icon"
        Icon.Size = UDim2.new(0, 16, 0, 16)
        Icon.Position = UDim2.new(0.5, -8, 0.5, -8)
        Icon.BackgroundTransparency = 1
        Icon.Image = iconChar
        Icon.ImageColor3 = Theme.TextDark
        Icon.Parent = Btn
    else
        Icon = Instance.new("TextLabel")
        Icon.Name = "Icon"
        Icon.Size = UDim2.new(1, 0, 1, 0)
        Icon.BackgroundTransparency = 1
        Icon.Text = iconChar
        Icon.TextColor3 = Theme.TextDark
        Icon.Font = Enum.Font.Gotham
        Icon.TextSize = 18
        Icon.Parent = Btn
    end

    local Indicator = Instance.new("Frame")
    Indicator.Name = "Indicator"
    Indicator.Size = UDim2.new(0, 3, 0, 16)
    Indicator.Position = UDim2.new(0, -10, 0.5, -8)
    Indicator.BackgroundColor3 = Theme.DotGreen
    Indicator.BorderSizePixel = 0
    Indicator.Visible = false
    Indicator.Parent = Btn
    Instance.new("UICorner", Indicator).CornerRadius = UDim.new(1, 0)

    Btn.MouseButton1Click:Connect(function()
        if activeTab == tabName then return end
        if activeTab then
            Tabs[activeTab].Visible = false
            SidebarButtons[activeTab].BackgroundTransparency = 1
            local oldIcon = SidebarButtons[activeTab]:FindFirstChild("Icon")
            if oldIcon then
                if oldIcon:IsA("ImageLabel") then
                    oldIcon.ImageColor3 = Theme.TextDark
                else
                    oldIcon.TextColor3 = Theme.TextDark
                end
            end
            SidebarButtons[activeTab].Indicator.Visible = false
        end
        activeTab = tabName
        Tabs[activeTab].Visible = true
        SidebarButtons[activeTab].BackgroundTransparency = 0.9
        local newIcon = SidebarButtons[activeTab]:FindFirstChild("Icon")
        if newIcon then
            if newIcon:IsA("ImageLabel") then
                newIcon.ImageColor3 = Theme.TextWhite
            else
                newIcon.TextColor3 = Theme.TextWhite
            end
        end
        SidebarButtons[activeTab].Indicator.Visible = true
        -- Animation chuyển tab: slide nhẹ
        ContentArea.Position = UDim2.new(0, 32, 0, 40)
        TweenService:Create(ContentArea,
            TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Position = UDim2.new(0, 50, 0, 40)}):Play()
    end)

    Btn.MouseEnter:Connect(function()
        if activeTab ~= tabName then
            TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.95}):Play()
        end
    end)
    Btn.MouseLeave:Connect(function()
        if activeTab ~= tabName then
            TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        end
    end)

    return TabContent
end

local TabAimbot = CreateSidebarIcon("Aimbot", "rbxassetid://7733917120", 10)
local TabESP = CreateSidebarIcon("ESP", "rbxassetid://7733774602", 55)
local TabPlayer = CreateSidebarIcon("Player", "rbxassetid://7733920644", 100)
local TabSecurity = CreateSidebarIcon("Security", "🛡", 145)

Tabs["Aimbot"].Visible = true
SidebarButtons["Aimbot"].BackgroundTransparency = 0.9
if SidebarButtons["Aimbot"]:FindFirstChild("Icon") then
    SidebarButtons["Aimbot"].Icon.ImageColor3 = Theme.TextWhite
end
SidebarButtons["Aimbot"].Indicator.Visible = true
activeTab = "Aimbot"

-- ============================================================
-- CONFIG
-- ============================================================
local function SaveConfig(silent)
    local ok, err = pcall(function()
        if writefile then
            local sanitized = {}
            for k, v in pairs(Settings) do
                if typeof(v) == "EnumItem" then
                    sanitized[k] = tostring(v)
                else
                    sanitized[k] = v
                end
            end
            writefile(IDS.ConfigName, HttpService:JSONEncode(sanitized))
            if not silent then
                SendNotification("Cấu Hình", "Đã lưu: " .. IDS.ConfigName)
            end
        else
            SendNotification("Lỗi Lưu", "Executor không hỗ trợ writefile")
        end
    end)
    if not ok then warn("Save error:", err) end
end

local function LoadConfig()
    local ok, err = pcall(function()
        if readfile and isfile and isfile(IDS.ConfigName) then
            local data = HttpService:JSONDecode(readfile(IDS.ConfigName))
            for k, v in pairs(data) do
                if Settings[k] ~= nil then
                    if typeof(v) == "string" then
                        local ok2, converted = pcall(function()
                            local t, n = v:match("Enum%.(%w+)%.(%w+)")
                            if t and n and Enum[t] and Enum[t][n] then
                                return Enum[t][n]
                            end
                            return nil
                        end)
                        if ok2 and converted then
                            Settings[k] = converted
                        else
                            Settings[k] = v
                        end
                    else
                        Settings[k] = v
                    end
                end
            end
            for key, ui in pairs(UI_Elements) do
                if Settings[key] ~= nil then
                    pcall(function() ui.SetValue(Settings[key]) end)
                end
            end
            SendNotification("Cấu Hình", "Đã tải cài đặt")
        else
            SendNotification("Lỗi Tải", "Chưa có file cấu hình")
        end
    end)
    if not ok then warn("Load error:", err) end
end

-- Tự lưu định kỳ
task_spawn(function()
    while task_wait(45) do
        pcall(SaveConfig, true)
    end
end)

-- ============================================================
-- UI BUILDERS
-- ============================================================
local function CreatePanel(parent, name, iconChar, posX, posY, sizeX, sizeY)
    local Panel = Instance.new("Frame")
    Panel.Name = name
    Panel.Size = UDim2.new(sizeX, -14, sizeY, -14)
    Panel.Position = UDim2.new(posX, 7, posY, 7)
    Panel.BackgroundColor3 = Color3_fromRGB(22, 22, 25)
    Panel.Parent = parent
    Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 8)

    local HeaderBg = Instance.new("Frame")
    HeaderBg.Size = UDim2.new(1, 0, 0, 45)
    HeaderBg.BackgroundColor3 = Theme.PanelBg
    HeaderBg.BorderSizePixel = 0
    HeaderBg.Parent = Panel
    Instance.new("UICorner", HeaderBg).CornerRadius = UDim.new(0, 8)

    local HeaderSquare = Instance.new("Frame")
    HeaderSquare.Size = UDim2.new(1, 0, 0, 10)
    HeaderSquare.Position = UDim2.new(0, 0, 1, -10)
    HeaderSquare.BackgroundColor3 = Theme.PanelBg
    HeaderSquare.BorderSizePixel = 0
    HeaderSquare.Parent = HeaderBg

    local HeaderLine = Instance.new("Frame")
    HeaderLine.Size = UDim2.new(1, 0, 0, 1)
    HeaderLine.Position = UDim2.new(0, 0, 1, 0)
    HeaderLine.BackgroundColor3 = Color3_fromRGB(45, 45, 50)
    HeaderLine.BorderSizePixel = 0
    HeaderLine.Parent = HeaderBg

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -30, 0, 45)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = (iconChar ~= "" and (iconChar .. "  ") or "") .. name
    Title.TextColor3 = Theme.TextWhite
    Title.Font = Theme.FontBold
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = HeaderBg

    local Container = Instance.new("ScrollingFrame")
    Container.Size = UDim2.new(1, 0, 1, -50)
    Container.Position = UDim2.new(0, 0, 0, 45)
    Container.BackgroundTransparency = 1
    Container.ScrollBarThickness = 0
    Container.Parent = Panel

    local PanelStroke = Instance.new("UIStroke")
    PanelStroke.Color = Color3_fromRGB(45, 45, 50)
    PanelStroke.Thickness = 1
    PanelStroke.Parent = Panel

    table_insert(ThemeObjects.Panels, {
        Bg = Panel,
        Header = HeaderBg,
        HeaderSquare = HeaderSquare,
        Stroke = PanelStroke
    })

    local Layout = Instance.new("UIListLayout")
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Padding = UDim.new(0, 5)
    Layout.Parent = Container

    local Padding = Instance.new("UIPadding")
    Padding.PaddingLeft = UDim.new(0, 15)
    Padding.PaddingRight = UDim.new(0, 15)
    Padding.Parent = Container

    Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Container.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    return Container
end

local function CreateSectionLabel(parent, text)
    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(1, 0, 0, 24)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = "— " .. text .. " —"
    Lbl.TextColor3 = Theme.TextDark
    Lbl.Font = Theme.FontBold
    Lbl.TextSize = 12
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Parent = parent
    return Lbl
end

local function CreateToggle(parent, text, dotColor, settingKey, callback)
    local isToggled = Settings[settingKey]
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 35)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    if dotColor then
        local Dot = Instance.new("Frame")
        Dot.Size = UDim2.new(0, 6, 0, 6)
        Dot.Position = UDim2.new(0, 0, 0.5, -3)
        Dot.BackgroundColor3 = dotColor
        Dot.Parent = Frame
        Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)
    end

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -70, 1, 0)
    Label.Position = UDim2.new(0, dotColor and 15 or 0, 0, 0)
    Label.BackgroundTransparency = 1
    Label.RichText = true
    Label.Text = text
    Label.TextColor3 = Theme.TextWhite
    Label.Font = Theme.Font
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 40, 0, 20)
    ToggleBtn.Position = UDim2.new(1, -40, 0.5, -10)
    ToggleBtn.BackgroundColor3 = isToggled and Theme.AccentOn or Theme.AccentOff
    ToggleBtn.Text = ""
    ToggleBtn.Parent = Frame
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 16, 0, 16)
    Knob.Position = isToggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    Knob.BackgroundColor3 = isToggled and Theme.KnobOn or Theme.KnobOff
    Knob.Parent = ToggleBtn
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local state = isToggled

    local function SetVisual(val)
        TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = val and Theme.AccentOn or Theme.AccentOff
        }):Play()
        TweenService:Create(Knob, TweenInfo.new(0.2), {
            Position = val and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
            BackgroundColor3 = val and Theme.KnobOn or Theme.KnobOff
        }):Play()
    end

    local tabName = nil
    for name, tab in pairs(Tabs) do
        if tab == parent then
            tabName = name
            break
        end
    end
    if tabName then
        if not TabActiveKeys[tabName] then TabActiveKeys[tabName] = {} end
        TabActiveKeys[tabName][settingKey] = true
        SearchIndex[settingKey] = { Label = text, Frame = Frame, Tab = tabName }
    end

    local reg = { State = isToggled }
    table_insert(ThemeObjects.Toggles, {
        Btn = ToggleBtn, Knob = Knob,
        State = isToggled
    })
    reg = ThemeObjects.Toggles[#ThemeObjects.Toggles]

    UI_Elements[settingKey] = {
        SetValue = function(val)
            state = val
            reg.State = val
            SetVisual(val)
            UpdateTabDots()
            if callback then callback(val) end
        end
    }

    Frame.MouseEnter:Connect(function() ShowTooltip(text) end)
    Frame.MouseLeave:Connect(function() ShowTooltip(nil) end)

    ToggleBtn.MouseButton1Click:Connect(function()
        state = not state
        reg.State = state
        SetVisual(state)
        if state then
            SendNotification("Đã Bật", text)
        else
            SendNotification("Đã Tắt", text)
        end
        UpdateTabDots()
        if callback then callback(state) end
    end)
end

local function CreateSafeToggle(parent, text, dotColor, settingKey, callback)
    local isToggled = Settings[settingKey]
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 35)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    if dotColor then
        local Dot = Instance.new("Frame")
        Dot.Size = UDim2.new(0, 6, 0, 6)
        Dot.Position = UDim2.new(0, 0, 0.5, -3)
        Dot.BackgroundColor3 = dotColor
        Dot.Parent = Frame
        Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)
    end

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -70, 1, 0)
    Label.Position = UDim2.new(0, dotColor and 15 or 0, 0, 0)
    Label.BackgroundTransparency = 1
    Label.RichText = true
    Label.Text = text
    Label.TextColor3 = Color3_fromRGB(255, 50, 50)
    Label.Font = Theme.FontBold
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 40, 0, 20)
    ToggleBtn.Position = UDim2.new(1, -40, 0.5, -10)
    ToggleBtn.BackgroundColor3 = isToggled and Theme.AccentOn or Theme.AccentOff
    ToggleBtn.Text = ""
    ToggleBtn.Parent = Frame
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 16, 0, 16)
    Knob.Position = isToggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    Knob.BackgroundColor3 = isToggled and Theme.KnobOn or Theme.KnobOff
    Knob.Parent = ToggleBtn
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local state = isToggled

    local function SetVisual(val)
        TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = val and Theme.AccentOn or Theme.AccentOff
        }):Play()
        TweenService:Create(Knob, TweenInfo.new(0.2), {
            Position = val and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
            BackgroundColor3 = val and Theme.KnobOn or Theme.KnobOff
        }):Play()
    end

    local tabName = nil
    for name, tab in pairs(Tabs) do
        if tab == parent then
            tabName = name
            break
        end
    end
    if tabName then
        if not TabActiveKeys[tabName] then TabActiveKeys[tabName] = {} end
        TabActiveKeys[tabName][settingKey] = true
        SearchIndex[settingKey] = { Label = text, Frame = Frame, Tab = tabName }
    end

    local reg = { State = isToggled }
    table_insert(ThemeObjects.Toggles, {
        Btn = ToggleBtn, Knob = Knob,
        State = isToggled
    })
    reg = ThemeObjects.Toggles[#ThemeObjects.Toggles]

    UI_Elements[settingKey] = {
        SetValue = function(val)
            state = val
            reg.State = val
            SetVisual(val)
            UpdateTabDots()
            if callback then callback(val) end
        end
    }

    Frame.MouseEnter:Connect(function() ShowTooltip(text) end)
    Frame.MouseLeave:Connect(function() ShowTooltip(nil) end)

    local warnState = 0
    ToggleBtn.MouseButton1Click:Connect(function()
        if state == true then
            if warnState == 0 then
                warnState = 1
                SendNotification("Nguy Hiểm", "Tắt chế độ bảo vệ có thể bị Ban! Bấm lần nữa để TẮT.")
                ToggleBtn.BackgroundColor3 = Theme.DotRed
                task_delay(3, function()
                    if warnState == 1 then
                        warnState = 0
                        ToggleBtn.BackgroundColor3 = Theme.AccentOn
                    end
                end)
                return
            end
        end
        warnState = 0
        state = not state
        reg.State = state
        SetVisual(state)
        if state then
            SendNotification("An Toàn", "Hệ thống bảo vệ đã BẬT!")
        else
            SendNotification("Nguy Hiểm", "Hệ thống tự vệ đã tắt, cẩn thận!")
        end
        UpdateTabDots()
        if callback then callback(state) end
    end)
end

local function CreateToggleWithDropdown(parent, toggleText, dotColor, toggleKey, dropKey, options, toggleCb, dropCb)
    local isToggled = Settings[toggleKey]
    local currentVal = Settings[dropKey]
    
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 35)
    Frame.BackgroundTransparency = 1
    Frame.ClipsDescendants = true
    Frame.Parent = parent

    -- Dot
    if dotColor then
        local Dot = Instance.new("Frame")
        Dot.Size = UDim2.new(0, 6, 0, 6)
        Dot.Position = UDim2.new(0, 0, 0.5, -3)
        Dot.BackgroundColor3 = dotColor
        Dot.Parent = Frame
        Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)
    end

    -- Toggle Label
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0, 92, 0, 35)
    Label.Position = UDim2.new(0, dotColor and 15 or 0, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = toggleText
    Label.TextColor3 = Theme.TextWhite
    Label.Font = Theme.Font
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    -- Dropdown Button in the middle
    local Dropbox = Instance.new("TextButton")
    Dropbox.Size = UDim2.new(0, 75, 0, 24)
    Dropbox.Position = UDim2.new(1, -125, 0, 5)
    Dropbox.BackgroundColor3 = Color3_fromRGB(35, 35, 38)
    Dropbox.Text = ""
    Dropbox.Parent = Frame
    Instance.new("UICorner", Dropbox).CornerRadius = UDim.new(0, 6)

    local ValLabel = Instance.new("TextLabel")
    ValLabel.Size = UDim2.new(1, -20, 1, 0)
    ValLabel.Position = UDim2.new(0, 6, 0, 0)
    ValLabel.BackgroundTransparency = 1
    ValLabel.Text = currentVal
    ValLabel.TextColor3 = Theme.TextWhite
    ValLabel.Font = Theme.Font
    ValLabel.TextSize = 12
    ValLabel.TextXAlignment = Enum.TextXAlignment.Left
    ValLabel.Parent = Dropbox

    local Arrow = Instance.new("TextLabel")
    Arrow.Size = UDim2.new(0, 16, 1, 0)
    Arrow.Position = UDim2.new(1, -16, 0, 0)
    Arrow.BackgroundTransparency = 1
    Arrow.Text = "v"
    Arrow.TextColor3 = Theme.TextDark
    Arrow.Font = Theme.Font
    Arrow.TextSize = 11
    Arrow.Parent = Dropbox

    local ListFrame = Instance.new("Frame")
    ListFrame.Size = UDim2.new(0, 75, 0, #options * 25)
    ListFrame.Position = UDim2.new(1, -125, 0, 32)
    ListFrame.BackgroundColor3 = Color3_fromRGB(30, 30, 33)
    ListFrame.BorderSizePixel = 0
    ListFrame.Parent = Frame
    Instance.new("UICorner", ListFrame).CornerRadius = UDim.new(0, 6)

    local ListLayout = Instance.new("UIListLayout")
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Parent = ListFrame

    local isOpen = false

    for _, opt in ipairs(options) do
        local OptBtn = Instance.new("TextButton")
        OptBtn.Size = UDim2.new(1, 0, 0, 25)
        OptBtn.BackgroundTransparency = 1
        OptBtn.Text = opt
        OptBtn.TextColor3 = Theme.TextWhite
        OptBtn.Font = Theme.Font
        OptBtn.TextSize = 12
        OptBtn.Parent = ListFrame

        OptBtn.MouseButton1Click:Connect(function()
            ValLabel.Text = opt
            isOpen = false
            TweenService:Create(Frame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 35)}):Play()
            Arrow.Text = "v"
            if dropCb then dropCb(opt) end
        end)
    end

    Dropbox.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            TweenService:Create(Frame, TweenInfo.new(0.2), {
                Size = UDim2.new(1, 0, 0, 35 + (#options * 25))
            }):Play()
            Arrow.Text = "^"
        else
            TweenService:Create(Frame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 35)}):Play()
            Arrow.Text = "v"
        end
    end)

    -- Toggle Button on the right
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 40, 0, 20)
    ToggleBtn.Position = UDim2.new(1, -40, 0.5, -10)
    ToggleBtn.BackgroundColor3 = isToggled and Theme.AccentOn or Theme.AccentOff
    ToggleBtn.Text = ""
    ToggleBtn.Parent = Frame
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 16, 0, 16)
    Knob.Position = isToggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    Knob.BackgroundColor3 = isToggled and Theme.KnobOn or Theme.KnobOff
    Knob.Parent = ToggleBtn
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local state = isToggled

    local function SetVisual(val)
        TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = val and Theme.AccentOn or Theme.AccentOff
        }):Play()
        TweenService:Create(Knob, TweenInfo.new(0.2), {
            Position = val and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
            BackgroundColor3 = val and Theme.KnobOn or Theme.KnobOff
        }):Play()
    end

    local tabName = nil
    for name, tab in pairs(Tabs) do
        if tab == parent then
            tabName = name
            break
        end
    end
    if tabName then
        if not TabActiveKeys[tabName] then TabActiveKeys[tabName] = {} end
        TabActiveKeys[tabName][toggleKey] = true
        SearchIndex[toggleKey] = { Label = toggleText, Frame = Frame, Tab = tabName }
        SearchIndex[dropKey] = { Label = "Target Part", Frame = Frame, Tab = tabName }
    end

    table_insert(ThemeObjects.Toggles, {
        Btn = ToggleBtn, Knob = Knob,
        State = isToggled
    })
    local reg = ThemeObjects.Toggles[#ThemeObjects.Toggles]
    table_insert(ThemeObjects.Dropbox, { Box = Dropbox })

    UI_Elements[toggleKey] = {
        SetValue = function(val)
            state = val
            reg.State = val
            SetVisual(val)
            UpdateTabDots()
            if toggleCb then toggleCb(val) end
        end
    }

    UI_Elements[dropKey] = {
        SetValue = function(val)
            ValLabel.Text = val
            if dropCb then dropCb(val) end
        end
    }

    Frame.MouseEnter:Connect(function() ShowTooltip(toggleText) end)
    Frame.MouseLeave:Connect(function() ShowTooltip(nil) end)

    ToggleBtn.MouseButton1Click:Connect(function()
        state = not state
        reg.State = state
        SetVisual(state)
        if state then
            SendNotification("Đã Bật", toggleText)
        else
            SendNotification("Đã Tắt", toggleText)
        end
        UpdateTabDots()
        if toggleCb then toggleCb(state) end
    end)
end

local function CreateToggleWithKeybind(parent, toggleText, dotColor, toggleKey, keyKey, toggleCb, keyCb)
    local isToggled = Settings[toggleKey]
    local currentVal = Settings[keyKey]
    
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 35)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    -- Dot
    if dotColor then
        local Dot = Instance.new("Frame")
        Dot.Size = UDim2.new(0, 6, 0, 6)
        Dot.Position = UDim2.new(0, 0, 0.5, -3)
        Dot.BackgroundColor3 = dotColor
        Dot.Parent = Frame
        Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)
    end

    -- Toggle Label
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0, 92, 0, 35)
    Label.Position = UDim2.new(0, dotColor and 15 or 0, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = toggleText
    Label.TextColor3 = Theme.TextWhite
    Label.Font = Theme.Font
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    -- Keybind Button in the middle
    local KeyBtn = Instance.new("TextButton")
    KeyBtn.Size = UDim2.new(0, 75, 0, 24)
    KeyBtn.Position = UDim2.new(1, -125, 0, 5)
    KeyBtn.BackgroundColor3 = Color3_fromRGB(35, 35, 38)

    local function FormatKeyName(key)
        if not key then return "None" end
        local name = (typeof(key) == "EnumItem") and key.Name or tostring(key)
        if name == "MouseButton1" then return "LClick" end
        if name == "MouseButton2" then return "RClick" end
        if name == "MouseButton3" then return "MClick" end
        return name
    end

    KeyBtn.Text = FormatKeyName(currentVal)
    KeyBtn.TextColor3 = Theme.TextWhite
    KeyBtn.Font = Theme.Font
    KeyBtn.TextSize = 12
    KeyBtn.Parent = Frame
    Instance.new("UICorner", KeyBtn).CornerRadius = UDim.new(0, 6)

    local isBinding = false
    local connection

    KeyBtn.MouseButton1Click:Connect(function()
        if isBinding then return end
        KeyBtn.Text = "..."
        task_wait(0.1)
        isBinding = true

        connection = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard
                or input.UserInputType.Name:match("MouseButton") then
                local newKey = (input.KeyCode == Enum.KeyCode.Unknown)
                    and input.UserInputType or input.KeyCode
                if newKey.Name == "Unknown" then return end

                isBinding = false
                KeyBtn.Text = FormatKeyName(newKey)
                Settings[keyKey] = newKey
                if keyCb then keyCb(newKey) end

                if connection then
                    connection:Disconnect()
                    connection = nil
                end
            end
        end)
    end)

    -- Toggle Button on the right
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 40, 0, 20)
    ToggleBtn.Position = UDim2.new(1, -40, 0.5, -10)
    ToggleBtn.BackgroundColor3 = isToggled and Theme.AccentOn or Theme.AccentOff
    ToggleBtn.Text = ""
    ToggleBtn.Parent = Frame
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 16, 0, 16)
    Knob.Position = isToggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    Knob.BackgroundColor3 = isToggled and Theme.KnobOn or Theme.KnobOff
    Knob.Parent = ToggleBtn
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local state = isToggled

    local function SetVisual(val)
        TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = val and Theme.AccentOn or Theme.AccentOff
        }):Play()
        TweenService:Create(Knob, TweenInfo.new(0.2), {
            Position = val and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
            BackgroundColor3 = val and Theme.KnobOn or Theme.KnobOff
        }):Play()
    end

    local tabName = nil
    for name, tab in pairs(Tabs) do
        if tab == parent then
            tabName = name
            break
        end
    end
    if tabName then
        if not TabActiveKeys[tabName] then TabActiveKeys[tabName] = {} end
        TabActiveKeys[tabName][toggleKey] = true
        SearchIndex[toggleKey] = { Label = toggleText, Frame = Frame, Tab = tabName }
        SearchIndex[keyKey] = { Label = "Aim Key", Frame = Frame, Tab = tabName }
    end

    table_insert(ThemeObjects.Toggles, {
        Btn = ToggleBtn, Knob = Knob,
        State = isToggled
    })
    local reg = ThemeObjects.Toggles[#ThemeObjects.Toggles]
    table_insert(ThemeObjects.Dropbox, { Box = KeyBtn })

    UI_Elements[toggleKey] = {
        SetValue = function(val)
            state = val
            reg.State = val
            SetVisual(val)
            UpdateTabDots()
            if toggleCb then toggleCb(val) end
        end
    }

    UI_Elements[keyKey] = {
        SetValue = function(val)
            KeyBtn.Text = FormatKeyName(val)
            if keyCb then keyCb(val) end
        end
    }

    Frame.MouseEnter:Connect(function() ShowTooltip(toggleText) end)
    Frame.MouseLeave:Connect(function() ShowTooltip(nil) end)

    ToggleBtn.MouseButton1Click:Connect(function()
        state = not state
        reg.State = state
        SetVisual(state)
        if state then
            SendNotification("Đã Bật", toggleText)
        else
            SendNotification("Đã Tắt", toggleText)
        end
        UpdateTabDots()
        if toggleCb then toggleCb(state) end
    end)
end

local function CreateDropdown(parent, text, settingKey, options, callback)
    local currentVal = Settings[settingKey]
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 35)
    Frame.BackgroundTransparency = 1
    Frame.ClipsDescendants = true
    Frame.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0, 150, 0, 35)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Theme.TextWhite
    Label.Font = Theme.Font
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Dropbox = Instance.new("TextButton")
    Dropbox.Size = UDim2.new(0, 100, 0, 24)
    Dropbox.Position = UDim2.new(1, -100, 0, 5)
    Dropbox.BackgroundColor3 = Color3_fromRGB(35, 35, 38)
    Dropbox.Text = ""
    Dropbox.Parent = Frame
    Instance.new("UICorner", Dropbox).CornerRadius = UDim.new(0, 6)

    local ValLabel = Instance.new("TextLabel")
    ValLabel.Size = UDim2.new(1, -25, 1, 0)
    ValLabel.Position = UDim2.new(0, 10, 0, 0)
    ValLabel.BackgroundTransparency = 1
    ValLabel.Text = currentVal
    ValLabel.TextColor3 = Theme.TextWhite
    ValLabel.Font = Theme.Font
    ValLabel.TextSize = 12
    ValLabel.TextXAlignment = Enum.TextXAlignment.Left
    ValLabel.Parent = Dropbox

    local Arrow = Instance.new("TextLabel")
    Arrow.Size = UDim2.new(0, 20, 1, 0)
    Arrow.Position = UDim2.new(1, -20, 0, 0)
    Arrow.BackgroundTransparency = 1
    Arrow.Text = "v"
    Arrow.TextColor3 = Theme.TextDark
    Arrow.Font = Theme.Font
    Arrow.TextSize = 12
    Arrow.Parent = Dropbox

    local ListFrame = Instance.new("Frame")
    ListFrame.Size = UDim2.new(0, 100, 0, #options * 25)
    ListFrame.Position = UDim2.new(1, -100, 0, 32)
    ListFrame.BackgroundColor3 = Color3_fromRGB(30, 30, 33)
    ListFrame.BorderSizePixel = 0
    ListFrame.Parent = Frame
    Instance.new("UICorner", ListFrame).CornerRadius = UDim.new(0, 6)

    local ListLayout = Instance.new("UIListLayout")
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Parent = ListFrame

    local isOpen = false

    local tabName = nil
    for name, tab in pairs(Tabs) do
        if tab == parent then
            tabName = name
            break
        end
    end
    if tabName then
        SearchIndex[settingKey] = { Label = text, Frame = Frame, Tab = tabName }
    end
    table_insert(ThemeObjects.Dropbox, { Box = Dropbox })

    UI_Elements[settingKey] = {
        SetValue = function(val)
            ValLabel.Text = val
            if callback then callback(val) end
        end
    }

    Frame.MouseEnter:Connect(function() ShowTooltip(text) end)
    Frame.MouseLeave:Connect(function() ShowTooltip(nil) end)

    for _, opt in ipairs(options) do
        local OptBtn = Instance.new("TextButton")
        OptBtn.Size = UDim2.new(1, 0, 0, 25)
        OptBtn.BackgroundTransparency = 1
        OptBtn.Text = opt
        OptBtn.TextColor3 = Theme.TextWhite
        OptBtn.Font = Theme.Font
        OptBtn.TextSize = 12
        OptBtn.Parent = ListFrame

        OptBtn.MouseButton1Click:Connect(function()
            ValLabel.Text = opt
            isOpen = false
            TweenService:Create(Frame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 35)}):Play()
            Arrow.Text = "v"
            if callback then callback(opt) end
        end)
    end

    Dropbox.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            TweenService:Create(Frame, TweenInfo.new(0.2), {
                Size = UDim2.new(1, 0, 0, 35 + (#options * 25))
            }):Play()
            Arrow.Text = "^"
        else
            TweenService:Create(Frame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 35)}):Play()
            Arrow.Text = "v"
        end
    end)
end

local function CreateKeybind(parent, text, settingKey, callback)
    local currentVal = Settings[settingKey]
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 35)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0, 150, 0, 35)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Theme.TextWhite
    Label.Font = Theme.Font
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local KeyBtn = Instance.new("TextButton")
    KeyBtn.Size = UDim2.new(0, 80, 0, 24)
    KeyBtn.Position = UDim2.new(1, -80, 0, 5)
    KeyBtn.BackgroundColor3 = Color3_fromRGB(35, 35, 38)

    local function FormatKeyName(key)
        if not key then return "None" end
        local name = key.Name
        if name == "MouseButton1" then return "LClick" end
        if name == "MouseButton2" then return "RClick" end
        if name == "MouseButton3" then return "MClick" end
        return name
    end

    KeyBtn.Text = FormatKeyName(currentVal)
    KeyBtn.TextColor3 = Theme.TextWhite
    KeyBtn.Font = Theme.Font
    KeyBtn.TextSize = 12
    KeyBtn.Parent = Frame
    Instance.new("UICorner", KeyBtn).CornerRadius = UDim.new(0, 6)

    local isBinding = false
    local connection

    local tabName = nil
    for name, tab in pairs(Tabs) do
        if tab == parent then
            tabName = name
            break
        end
    end
    if tabName then
        SearchIndex[settingKey] = { Label = text, Frame = Frame, Tab = tabName }
    end
    table_insert(ThemeObjects.Dropbox, { Box = KeyBtn })

    Frame.MouseEnter:Connect(function() ShowTooltip(text) end)
    Frame.MouseLeave:Connect(function() ShowTooltip(nil) end)

    KeyBtn.MouseButton1Click:Connect(function()
        if isBinding then return end
        KeyBtn.Text = "..."
        task_wait(0.1)
        isBinding = true

        connection = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard
                or input.UserInputType.Name:match("MouseButton") then
                local newKey = (input.KeyCode == Enum.KeyCode.Unknown)
                    and input.UserInputType or input.KeyCode
                if newKey.Name == "Unknown" then return end

                isBinding = false
                KeyBtn.Text = FormatKeyName(newKey)
                Settings[settingKey] = newKey
                if callback then callback(newKey) end

                if connection then
                    connection:Disconnect()
                    connection = nil
                end
            end
        end)
    end)
end

local function CreatePlayerDropdown(parent, text, settingKey, callback)
    local currentVal = Settings[settingKey]
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 35)
    Frame.BackgroundTransparency = 1
    Frame.ClipsDescendants = true
    Frame.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0, 150, 0, 35)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Theme.TextWhite
    Label.Font = Theme.Font
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Dropbox = Instance.new("TextButton")
    Dropbox.Size = UDim2.new(0, 100, 0, 24)
    Dropbox.Position = UDim2.new(1, -100, 0, 5)
    Dropbox.BackgroundColor3 = Color3_fromRGB(35, 35, 38)
    Dropbox.Text = ""
    Dropbox.Parent = Frame
    Instance.new("UICorner", Dropbox).CornerRadius = UDim.new(0, 6)

    local ValLabel = Instance.new("TextLabel")
    ValLabel.Size = UDim2.new(1, -25, 1, 0)
    ValLabel.Position = UDim2.new(0, 10, 0, 0)
    ValLabel.BackgroundTransparency = 1
    ValLabel.Text = (currentVal == "" or currentVal == nil) and "Chọn Người" or currentVal
    ValLabel.TextColor3 = Theme.TextWhite
    ValLabel.Font = Theme.Font
    ValLabel.TextSize = 12
    ValLabel.TextXAlignment = Enum.TextXAlignment.Left
    ValLabel.Parent = Dropbox

    local Arrow = Instance.new("TextLabel")
    Arrow.Size = UDim2.new(0, 20, 1, 0)
    Arrow.Position = UDim2.new(1, -20, 0, 0)
    Arrow.BackgroundTransparency = 1
    Arrow.Text = "v"
    Arrow.TextColor3 = Theme.TextDark
    Arrow.Font = Theme.Font
    Arrow.TextSize = 12
    Arrow.Parent = Dropbox

    local ListFrame = Instance.new("Frame")
    ListFrame.Position = UDim2.new(1, -100, 0, 32)
    ListFrame.BackgroundColor3 = Color3_fromRGB(30, 30, 33)
    ListFrame.BorderSizePixel = 0
    ListFrame.Parent = Frame
    Instance.new("UICorner", ListFrame).CornerRadius = UDim.new(0, 6)

    local ListLayout = Instance.new("UIListLayout")
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Parent = ListFrame

    local isOpen = false

    local tabName = nil
    for name, tab in pairs(Tabs) do
        if tab == parent then
            tabName = name
            break
        end
    end
    if tabName then
        SearchIndex[settingKey] = { Label = text, Frame = Frame, Tab = tabName }
    end
    table_insert(ThemeObjects.Dropbox, { Box = Dropbox })

    UI_Elements[settingKey] = {
        SetValue = function(val)
            ValLabel.Text = (val == "" or val == nil) and "Chọn Người" or val
            if callback then callback(val) end
        end
    }

    Frame.MouseEnter:Connect(function() ShowTooltip(text) end)
    Frame.MouseLeave:Connect(function() ShowTooltip(nil) end)

    Dropbox.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            for _, child in pairs(ListFrame:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end

            local players = Players:GetPlayers()
            local listSize = math_min(#players, 6) * 25
            ListFrame.Size = UDim2.new(0, 100, 0, listSize)

            for _, player in ipairs(players) do
                local OptBtn = Instance.new("TextButton")
                OptBtn.Size = UDim2.new(1, 0, 0, 25)
                OptBtn.BackgroundTransparency = 1
                OptBtn.Text = player.Name
                OptBtn.TextColor3 = Theme.TextWhite
                OptBtn.Font = Theme.Font
                OptBtn.TextSize = 12
                OptBtn.Parent = ListFrame

                OptBtn.MouseButton1Click:Connect(function()
                    ValLabel.Text = player.Name
                    isOpen = false
                    TweenService:Create(Frame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 35)}):Play()
                    Arrow.Text = "v"
                    if callback then callback(player.Name) end
                end)
            end

            TweenService:Create(Frame, TweenInfo.new(0.2), {
                Size = UDim2.new(1, 0, 0, 35 + listSize)
            }):Play()
            Arrow.Text = "^"
        else
            TweenService:Create(Frame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 35)}):Play()
            Arrow.Text = "v"
        end
    end)
end

local function CreateSlider(parent, text, settingKey, min, max, suffix, callback)
    local value = Settings[settingKey]
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 35)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0, 120, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Theme.TextWhite
    Label.Font = Theme.Font
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local hasSuffix = suffix and suffix ~= ""
    local inputOffset = hasSuffix and -60 or -40

    local ValInput = Instance.new("TextBox")
    ValInput.Size = UDim2.new(0, 35, 0, 20)
    ValInput.Position = UDim2.new(1, inputOffset, 0.5, -10)
    ValInput.BackgroundColor3 = Color3_fromRGB(35, 35, 38)
    ValInput.TextColor3 = Theme.TextWhite
    ValInput.Font = Theme.Font
    ValInput.TextSize = 12
    ValInput.Text = tostring(value)
    ValInput.Parent = Frame
    Instance.new("UICorner", ValInput).CornerRadius = UDim.new(0, 4)

    if hasSuffix then
        local SuffixLbl = Instance.new("TextLabel")
        SuffixLbl.Size = UDim2.new(0, 20, 1, 0)
        SuffixLbl.Position = UDim2.new(1, -20, 0, 0)
        SuffixLbl.BackgroundTransparency = 1
        SuffixLbl.Text = suffix:gsub(" ", "")
        SuffixLbl.TextColor3 = Theme.TextDark
        SuffixLbl.Font = Theme.Font
        SuffixLbl.TextSize = 12
        SuffixLbl.TextXAlignment = Enum.TextXAlignment.Left
        SuffixLbl.Parent = Frame
    end

    local SliderBg = Instance.new("TextButton")
    SliderBg.Size = UDim2.new(1, -190, 0, 4)
    SliderBg.Position = UDim2.new(0, 125, 0.5, -2)
    SliderBg.BackgroundColor3 = Color3_fromRGB(40, 40, 42)
    SliderBg.BorderSizePixel = 0
    SliderBg.Text = ""
    SliderBg.AutoButtonColor = false
    SliderBg.Parent = Frame
    Instance.new("UICorner", SliderBg).CornerRadius = UDim.new(1, 0)

    local pct = math_clamp((value - min) / (max - min), 0, 1)
    local SliderFill = Instance.new("Frame")
    SliderFill.Size = UDim2.new(pct, 0, 1, 0)
    SliderFill.BackgroundColor3 = Theme.TextWhite
    SliderFill.BorderSizePixel = 0
    SliderFill.Parent = SliderBg
    Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 10, 0, 10)
    Knob.Position = UDim2.new(1, -5, 0.5, -5)
    Knob.BackgroundColor3 = Theme.TextWhite
    Knob.Parent = SliderFill
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local dragging = false
    local function updateSlider(pos)
        pos = math_clamp(pos, 0, 1)
        SliderFill.Size = UDim2.new(pos, 0, 1, 0)
        local newVal = min + (max - min) * pos
        newVal = math_floor(newVal * 10) / 10
        ValInput.Text = tostring(newVal)
        if callback then callback(newVal) end
    end

    SliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            local pos = (input.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X
            updateSlider(pos)
        end
    end)
    SliderBg.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local pos = (input.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X
            updateSlider(pos)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UI_Elements[settingKey] = {
        SetValue = function(val)
            local pos = (val - min) / (max - min)
            SliderFill.Size = UDim2.new(pos, 0, 1, 0)
            ValInput.Text = tostring(val)
            if callback then callback(val) end
        end
    }

    local tabName = nil
    for name, tab in pairs(Tabs) do
        if tab == parent then
            tabName = name
            break
        end
    end
    if tabName then
        SearchIndex[settingKey] = { Label = text, Frame = Frame, Tab = tabName }
    end
    table_insert(ThemeObjects.SliderFills, { Fill = SliderFill })

    Frame.MouseEnter:Connect(function() ShowTooltip(text) end)
    Frame.MouseLeave:Connect(function() ShowTooltip(nil) end)

    ValInput.FocusLost:Connect(function()
        local num = tonumber(ValInput.Text)
        if num then
            num = math_clamp(num, min, max)
            local pos = (num - min) / (max - min)
            updateSlider(pos)
        else
            local currentPos = SliderFill.Size.X.Scale
            updateSlider(currentPos)
        end
    end)
end

local function CreateButtonWithConfirm(parent, text, warningText, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 45)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -30, 1, -10)
    Btn.Position = UDim2.new(0, 15, 0, 5)
    Btn.BackgroundColor3 = Theme.AccentOff
    Btn.TextColor3 = Theme.TextWhite
    Btn.Font = Theme.FontBold
    Btn.TextSize = 13
    Btn.Text = text
    Btn.Parent = Frame
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)

    local state = 0
    Btn.MouseButton1Click:Connect(function()
        if state == 0 then
            state = 1
            Btn.Text = "BẤM LẦN NỮA ĐỂ XÁC NHẬN"
            Btn.BackgroundColor3 = Theme.DotRed
            SendNotification("Nguy Hiểm", warningText)
            task_delay(3, function()
                if state == 1 then
                    state = 0
                    Btn.Text = text
                    Btn.BackgroundColor3 = Theme.AccentOff
                end
            end)
        elseif state == 1 then
            state = 2
            Btn.Text = "ĐÃ KÍCH HOẠT"
            Btn.BackgroundColor3 = Color3_fromRGB(80, 80, 80)
            if callback then callback() end
        end
    end)
end

-- ============================================================
-- XÂY DỰNG TABS
-- ============================================================
local PanelAimbot = CreatePanel(TabAimbot, "Aimbot", "", 0, 0, 0.5, 1)
CreateToggleWithDropdown(PanelAimbot, "Enable Aimbot", Theme.DotGreen, "AimEnabled", "TargetPart", {"Head", "HumanoidRootPart", "Safe"}, function(v) 
    Settings.AimEnabled = v 
end, function(v) 
    Settings.TargetPart = v
    Settings.ProAimTargetPart = v
end)
CreateSlider(PanelAimbot, "FOV Size", "FOV", 10, 500, " px", function(v)
    Settings.FOV = v
    Settings.ProAimFOV = v
    FOVring.Radius = v
end)
CreateToggle(PanelAimbot, "Aim Safe", Theme.DotGreen, "AimSafe", function(v) Settings.AimSafe = v end)
CreateToggle(PanelAimbot, "Draw FOV", Theme.DotGreen, "FOVVisible", function(v)
    Settings.FOVVisible = v
    Settings.ProAimFOVVisible = v
    Settings.AimSnapline = v
    Settings.ProAimSnapline = v
    FOVring.Visible = v
end)

local PanelAimbotSet = CreatePanel(TabAimbot, "Exploits", "", 0.5, 0, 0.5, 1)
CreateToggle(PanelAimbotSet, "Kill Aura", Theme.DotRed, "AutoFire", function(v) Settings.AutoFire = v end)
CreateToggle(PanelAimbotSet, "Wall Check ", Theme.DotRed, "AutoFireWallCheck", function(v) Settings.AutoFireWallCheck = v end)
CreateToggle(PanelAimbotSet, 'Slient Aim <font color="#ff3333">[BETA]</font>', Theme.DotRed, "AutoFireHoldM2", function(v) Settings.AutoFireHoldM2 = v end)
CreateToggle(PanelAimbotSet, "NO RECOIL", Theme.DotRed, "NoRecoil", function(v) Settings.NoRecoil = v end)
CreateToggleWithKeybind(PanelAimbotSet, "Aimlock", Theme.DotRed, "ProAimEnabled", "ProAimHoldMouse", function(v) Settings.ProAimEnabled = v end, function(v) Settings.ProAimHoldMouse = v end)

local PanelESP = CreatePanel(TabESP, "ESP", "", 0, 0, 0.5, 1)
CreateToggle(PanelESP, "Enable ESP", Theme.DotGreen, "ESPEnabled", function(v)
    Settings.ESPEnabled = v
    if ESPCounterBox then
        ESPCounterBox.Visible = v and Settings.ESPCount
    end
end)
CreateToggleWithDropdown(PanelESP, "Chams", Theme.DotGreen, "ESPChams", "ChamsColor", {"Red", "Green", "White", "Blue", "Yellow", "Pink"}, function(v) Settings.ESPChams = v end, function(v) Settings.ChamsColor = v end)
CreateToggle(PanelESP, "Skeleton", Theme.DotGreen, "ESPSkeleton", function(v) Settings.ESPSkeleton = v end)
CreateToggle(PanelESP, "Box", Theme.DotGreen, "ESPBox", function(v) Settings.ESPBox = v end)
CreateToggle(PanelESP, "Name", Theme.DotGreen, "ESPName", function(v) Settings.ESPName = v end)
CreateToggle(PanelESP, "Health", Theme.DotGreen, "ESPHealth", function(v) Settings.ESPHealth = v end)
CreateToggle(PanelESP, "Distance", Theme.DotGreen, "ESPDistance", function(v) Settings.ESPDistance = v end)
CreateToggle(PanelESP, "Look Line", Theme.DotGreen, "ESPLine", function(v) Settings.ESPLine = v end)
CreateToggle(PanelESP, "Weapon", Theme.DotGreen, "ESPWeapon", function(v) Settings.ESPWeapon = v end)
CreateToggle(PanelESP, "Level/XP", Theme.DotGreen, "ESPLevel", function(v) Settings.ESPLevel = v end)
CreateToggle(PanelESP, "Player Count (Top)", Theme.DotGreen, "ESPCount", function(v)
    Settings.ESPCount = v
    if ESPCounterBox then
        ESPCounterBox.Visible = Settings.ESPEnabled and v
    end
end)
CreateToggle(PanelESP, "Aim Warning", Theme.DotGreen, "AimWarning", function(v) Settings.AimWarning = v end)
CreateToggle(PanelESP, 'Arrows <font color="#ff3333">[BETA]</font>', Theme.DotGreen, "OffscreenArrows", function(v) Settings.OffscreenArrows = v end)

local PanelESPSet = CreatePanel(TabESP, "Settings", "⚙", 0.5, 0, 0.5, 1)
CreateSlider(PanelESPSet, "Max Aim Dist", "AimDist", 1, 2000, " m", function(v) 
    Settings.AimDist = v
    Settings.ProAimDist = v
end)
CreateSlider(PanelESPSet, "Max ESP Dist", "ESPDist", 1, 2000, " m", function(v) Settings.ESPDist = v end)

local PanelPlayer = CreatePanel(TabPlayer, "Exploits", "", 0, 0, 0.5, 1)
local function CheckAndBypassCharacterAC(featureName)
    if not Settings.BypassACMove then
        SendNotification("⚠️ NGUY HIỂM ⚠️", "Nguy cơ BAN khi dùng " .. featureName .. ". Bật lại an toàn!")
        return false
    end

    local disconnected = 0
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if hum then
            local connections = {}
            if getconnections then
                for _, conn in pairs(getconnections(hum:GetPropertyChangedSignal("WalkSpeed"))) do
                    table_insert(connections, conn)
                end
                for _, conn in pairs(getconnections(hum:GetPropertyChangedSignal("JumpPower"))) do
                    table_insert(connections, conn)
                end
                for _, conn in pairs(getconnections(hum.StateChanged)) do
                    table_insert(connections, conn)
                end
            end
            for _, conn in ipairs(connections) do
                if conn.Disable then
                    conn:Disable()
                    disconnected = disconnected + 1
                end
            end
        end
    end)
    if disconnected > 0 then
        SendNotification("🛡 Bypass", "Vô hiệu hóa " .. disconnected .. " bẫy theo dõi cho " .. featureName)
    end
    return true
end

local undergroundSurfaceY = nil
local originalTeleportCFrame = nil

CreateToggle(PanelPlayer, "Speed Buff", Theme.DotGreen, "SpeedHack", function(v)
    if v and not CheckAndBypassCharacterAC("SpeedHack") then
        Settings.SpeedHack = false
        if UI_Elements.SpeedHack then UI_Elements.SpeedHack.SetValue(false) end
        return
    end
    Settings.SpeedHack = v
end)
CreateToggle(PanelPlayer, "Jump Buff", Theme.DotGreen, "JumpHack", function(v)
    if v and not CheckAndBypassCharacterAC("JumpHack") then
        Settings.JumpHack = false
        if UI_Elements.JumpHack then UI_Elements.JumpHack.SetValue(false) end
        return
    end
    Settings.JumpHack = v
end)
CreateToggle(PanelPlayer, "Inf Jump", Theme.DotGreen, "InfJump", function(v)
    if v and not CheckAndBypassCharacterAC("Inf Jump") then
        Settings.InfJump = false
        if UI_Elements.InfJump then UI_Elements.InfJump.SetValue(false) end
        return
    end
    Settings.InfJump = v
end)
CreateToggle(PanelPlayer, "Fly", Theme.DotGreen, "Fly", function(v)
    if v and not CheckAndBypassCharacterAC("Fly") then
        Settings.Fly = false
        if UI_Elements.Fly then UI_Elements.Fly.SetValue(false) end
        return
    end
    Settings.Fly = v
end)
CreateToggle(PanelPlayer, "Noclip", Theme.DotGreen, "Noclip", function(v)
    if v and not CheckAndBypassCharacterAC("Noclip") then
        Settings.Noclip = false
        if UI_Elements.Noclip then UI_Elements.Noclip.SetValue(false) end
        return
    end
    Settings.Noclip = v
end)

CreateToggleWithKeybind(PanelPlayer, "Chui Đất", Theme.DotGreen, "UndergroundNoclip", "UndergroundHotkey", function(v)
    Settings.UndergroundNoclip = v
    if v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        undergroundSurfaceY = LocalPlayer.Character.HumanoidRootPart.Position.Y
    elseif not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and undergroundSurfaceY then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        hrp.CFrame = hrp.CFrame + Vector3_new(0, undergroundSurfaceY - hrp.Position.Y, 0)
        undergroundSurfaceY = nil
    end
end, function(v)
    Settings.UndergroundHotkey = v
end)

CreateToggleWithKeybind(PanelPlayer, "Tele", Theme.DotGreen, "AutoTeleport", "AutoTeleportHotkey", function(v)
    if v and not CheckAndBypassCharacterAC("Auto Teleport") then
        Settings.AutoTeleport = false
        if UI_Elements.AutoTeleport then UI_Elements.AutoTeleport.SetValue(false) end
        return
    end
    Settings.AutoTeleport = v
    if v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        originalTeleportCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
    elseif not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and originalTeleportCFrame then
        LocalPlayer.Character.HumanoidRootPart.CFrame = originalTeleportCFrame
        originalTeleportCFrame = nil
    end
end, function(v)
    Settings.AutoTeleportHotkey = v
end)
CreateToggle(PanelPlayer, 'SpinBot <font color="#ff3333">[BETA]</font>', Theme.DotGreen, "SpinBot", function(v)
    Settings.SpinBot = v
    if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.AutoRotate = true
    end
end)

local PanelPlayerSet = CreatePanel(TabPlayer, "Settings", "⚙", 0.5, 0, 0.5, 1)
CreateSlider(PanelPlayerSet, "Tốc Độ", "WalkSpeed", 16, 300, "", function(v) Settings.WalkSpeed = v end)
CreateSlider(PanelPlayerSet, "Lực Nhảy", "JumpPower", 50, 500, "", function(v) Settings.JumpPower = v end)
CreateSlider(PanelPlayerSet, "Tốc Độ Bay", "FlySpeed", 10, 300, "", function(v) Settings.FlySpeed = v end)
CreateSlider(PanelPlayerSet, "Độ Sâu Chui", "UndergroundDistance", 1, 50, " m", function(v) Settings.UndergroundDistance = v end)
CreateSlider(PanelPlayerSet, "Khoảng Cách Tele", "AutoTeleportDistance", 0, 100, " m", function(v) Settings.AutoTeleportDistance = v end)
CreateDropdown(PanelPlayerSet, "Vị Trí Tele", "AutoTeleportPosition", {"Sau Lưng", "Trên Đầu", "Random"}, function(v) Settings.AutoTeleportPosition = v end)
CreateSlider(PanelPlayerSet, "Tốc Độ Xoay", "SpinSpeed", 10, 100, "", function(v) Settings.SpinSpeed = v end)

local PanelOptim = CreatePanel(TabSecurity, "Tối Ưu Hóa Máy Yếu", "🚀", 0, 0, 0.5, 1)
CreateToggle(PanelOptim, "Tắt Đổ Bóng", Theme.DotGreen, "OptimShadows", function(v)
    Settings.OptimShadows = v
    Lighting.GlobalShadows = not v
end)
CreateToggle(PanelOptim, "Plastic Mode", Theme.DotGreen, "OptimTextures", function(v)
    Settings.OptimTextures = v
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.Material = v and Enum.Material.SmoothPlastic or Enum.Material.Plastic
        end
    end
end)
CreateToggle(PanelOptim, "Xóa Sương Mù", Theme.DotGreen, "OptimFog", function(v)
    Settings.OptimFog = v
    if v then
        Lighting.FogEnd = 100000
    else
        Lighting.FogEnd = 10000
    end
end)

CreateButtonWithConfirm(PanelOptim, "POTATO MODE", "Cảnh báo: Không thể hoàn tác! Hình ảnh game bị xóa sạch để buff FPS.", function()
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.Brightness = 1
    Lighting.ClockTime = 12

    local Terrain = Workspace:FindFirstChildOfClass("Terrain")
    if Terrain then
        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterColor = Color3_fromRGB(0, 0, 0)
        pcall(function() sethiddenproperty(Terrain, "Decoration", false) end)
    end

    task_spawn(function()
        local descendants = game:GetDescendants()
        for i = 1, #descendants do
            local obj = descendants[i]
            if obj:IsA("PostEffect") or obj:IsA("BlurEffect") or obj:IsA("SunRaysEffect")
                or obj:IsA("ColorCorrectionEffect") or obj:IsA("BloomEffect")
                or obj:IsA("DepthOfFieldEffect") or obj:IsA("Atmosphere") or obj:IsA("Sky") then
                pcall(function() obj:Destroy() end)
            elseif obj:IsA("BasePart") then
                pcall(function()
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.CastShadow = false
                end)
            elseif obj:IsA("MeshPart") then
                pcall(function()
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.CastShadow = false
                    obj.TextureID = ""
                end)
            elseif obj:IsA("SpecialMesh") then
                if obj.MeshType == Enum.MeshType.FileMesh then
                    pcall(function() obj.TextureID = "" end)
                    pcall(function() obj.TextureId = "" end)
                end
            elseif obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("SurfaceAppearance") then
                pcall(function() obj:Destroy() end)
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
                or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                pcall(function() obj:Destroy() end)
            end
            if i % 250 == 0 then
                task_wait()
            end
        end
        SendNotification("Potato Mode", "Đã dọn dẹp đồ họa để buff FPS!")
    end)
end)

local PanelSettings = CreatePanel(TabSecurity, "Bảo Mật", "", 0.5, 0, 0.5, 1)
CreateKeybind(PanelSettings, "Phím Ẩn/Hiện Menu", "ToggleKeybind", function(key) Settings.ToggleKeybind = key end)

local function RejoinServer()
    SendNotification("🔄 Set Prosers", "Đang kết nối lại Server...")
    task_spawn(function()
        pcall(function()
            if #Players:GetPlayers() <= 1 then
                LocalPlayer:Kick("\n[Rejoin] Đang kết nối lại Server...")
                task_wait(0.5)
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            else
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
            end
        end)
    end)
end

local BtnSave = Instance.new("TextButton")
BtnSave.Size = UDim2.new(1, 0, 0, 30)
BtnSave.BackgroundColor3 = Theme.AccentOn
BtnSave.TextColor3 = Color3_fromRGB(0, 0, 0)
BtnSave.Font = Theme.FontBold
BtnSave.TextSize = 13
BtnSave.Text = "Lưu Cài Đặt (Save)"
BtnSave.Parent = PanelSettings
Instance.new("UICorner", BtnSave).CornerRadius = UDim.new(0, 6)
BtnSave.MouseButton1Click:Connect(SaveConfig)

local BtnLoad = Instance.new("TextButton")
BtnLoad.Size = UDim2.new(1, 0, 0, 30)
BtnLoad.BackgroundColor3 = Theme.KnobOff
BtnLoad.TextColor3 = Theme.TextWhite
BtnLoad.Font = Theme.FontBold
BtnLoad.TextSize = 13
BtnLoad.Text = "Tải Cài Đặt (Load)"
BtnLoad.Parent = PanelSettings
Instance.new("UICorner", BtnLoad).CornerRadius = UDim.new(0, 6)
BtnLoad.MouseButton1Click:Connect(LoadConfig)

local BtnRejoin = Instance.new("TextButton")
BtnRejoin.Size = UDim2.new(1, 0, 0, 30)
BtnRejoin.BackgroundColor3 = Color3_fromRGB(35, 45, 60)
BtnRejoin.TextColor3 = Theme.TextWhite
BtnRejoin.Font = Theme.FontBold
BtnRejoin.TextSize = 13
BtnRejoin.Text = "Set Prosers"
BtnRejoin.Parent = PanelSettings
Instance.new("UICorner", BtnRejoin).CornerRadius = UDim.new(0, 6)
BtnRejoin.MouseButton1Click:Connect(RejoinServer)

-- Toggle UI với slide animation (Chặn mở Menu khi chưa check key/kết nối)
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Settings.ToggleKeybind then
        -- Khi chưa check key hoặc chưa kết nối: KHÔNG BAO GIỜ mở MainFrame
        if not isMenuConnected then
            if LoginFrame then
                LoginFrame.Visible = not LoginFrame.Visible
            end
            return
        end

        if MainFrame.Visible then
            TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
                {Position = UDim2.new(0.5, -325, 1.5, 0)}):Play()
            task_delay(0.3, function() MainFrame.Visible = false end)
        else
            MainFrame.Position = UDim2.new(0.5, -325, 1.5, 0)
            MainFrame.Visible = true
            TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
                {Position = UDim2.new(0.5, -325, 0.5, -210)}):Play()
        end
    end
end)

-- Phím tắt nhanh bật/tắt
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Settings.AimHotkey and Settings.AimHotkey ~= Enum.KeyCode.None then
        Settings.AimEnabled = not Settings.AimEnabled
        if UI_Elements.AimEnabled then UI_Elements.AimEnabled.SetValue(Settings.AimEnabled) end
        UpdateTabDots()
        SendNotification("Hotkey", "Aim: " .. (Settings.AimEnabled and "BẬT" or "TẮT"))
    elseif input.KeyCode == Settings.AutoFireHotkey and Settings.AutoFireHotkey ~= Enum.KeyCode.None then
        Settings.AutoFire = not Settings.AutoFire
        if UI_Elements.AutoFire then UI_Elements.AutoFire.SetValue(Settings.AutoFire) end
        UpdateTabDots()
        SendNotification("Hotkey", "Auto Fire: " .. (Settings.AutoFire and "BẬT" or "TẮT"))
    elseif input.KeyCode == Settings.AutoTeleportHotkey and Settings.AutoTeleportHotkey ~= Enum.KeyCode.None then
        Settings.AutoTeleport = not Settings.AutoTeleport
        if UI_Elements.AutoTeleport then UI_Elements.AutoTeleport.SetValue(Settings.AutoTeleport) end
        
        if Settings.AutoTeleport and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            originalTeleportCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
        elseif not Settings.AutoTeleport and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and originalTeleportCFrame then
            LocalPlayer.Character.HumanoidRootPart.CFrame = originalTeleportCFrame
            originalTeleportCFrame = nil
        end
        
        UpdateTabDots()
        SendNotification("Hotkey", "Auto Tele (Bám Địch): " .. (Settings.AutoTeleport and "BẬT" or "TẮT"))
    elseif input.KeyCode == Settings.UndergroundHotkey and Settings.UndergroundHotkey ~= Enum.KeyCode.None then
        Settings.UndergroundNoclip = not Settings.UndergroundNoclip
        if UI_Elements.UndergroundNoclip then UI_Elements.UndergroundNoclip.SetValue(Settings.UndergroundNoclip) end
        
        if Settings.UndergroundNoclip and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            undergroundSurfaceY = LocalPlayer.Character.HumanoidRootPart.Position.Y
        elseif not Settings.UndergroundNoclip and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and undergroundSurfaceY then
            local hrp = LocalPlayer.Character.HumanoidRootPart
            hrp.CFrame = hrp.CFrame + Vector3_new(0, undergroundSurfaceY - hrp.Position.Y, 0)
            undergroundSurfaceY = nil
        end
        UpdateTabDots()
        SendNotification("Hotkey", "Chui Đất: " .. (Settings.UndergroundNoclip and "BẬT" or "TẮT"))
    end
end)

-- ============================================================
-- LOGIC TÌM MỤC TIÊU & TỐI ƯU HOÁ RENDER/PHYSICS
-- ============================================================
local aimSafeCounter = 0
local isAiming = false
local cachedClosest = nil
local cachedClosestValid = 0
local ProAimLockedTarget = nil
local lastTargetSwitch = 0
local aimAcquireTime = 0
local lastShotTime = 0
local noRecoilPrevCam = Camera.CFrame
local cachedProTarget = nil
local cachedProValid = 0
local lastWarnScan = 0

-- Cache NoClip Parts để không bao giờ gọi GetDescendants() mỗi physics frame
local noClipParts = {}
local function RefreshNoClipParts()
    table_clear(noClipParts)
    local char = LocalPlayer.Character
    if char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                table_insert(noClipParts, part)
            end
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task_wait(0.2)
    RefreshNoClipParts()
    char.DescendantAdded:Connect(function(desc)
        if desc:IsA("BasePart") then
            table_insert(noClipParts, desc)
        end
    end)
end)
if LocalPlayer.Character then
    RefreshNoClipParts()
    LocalPlayer.Character.DescendantAdded:Connect(function(desc)
        if desc:IsA("BasePart") then
            table_insert(noClipParts, desc)
        end
    end)
end

local function FireShot()
    local ok, fn = pcall(function() return mouse1click end)
    if ok and type(fn) == "function" then
        pcall(fn)
    else
        local okVim, VIM = pcall(function() return game:GetService("VirtualInputManager") end)
        if okVim and VIM then
            pcall(function()
                VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task_delay(0.02, function()
                    pcall(function() VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0) end)
                end)
            end)
        end
    end
end

local function isSameTeam(player)
    -- 0. Kiểm tra bản thân (LocalPlayer)
    if not player or player == LocalPlayer then 
        return true 
    end

    -- 1. Standard Roblox Team Check (Dành cho các game cơ bản dùng service Teams)
    if LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then 
        return true 
    end
    
    -- 2. Rivals TeamID Check (Logic nòng cốt cho tựa game Rivals)
    -- Lấy ID đội hình ẩn đằng sau giao diện 2v2/5v5 của Rivals
    local myTeamID = LocalPlayer:GetAttribute("TeamID")
    local pTeamID = player:GetAttribute("TeamID")
    
    -- Yêu cầu TeamID phải tồn tại và khác rỗng để chống nhận diện nhầm kẻ địch khi đang chờ ở sảnh
    if myTeamID ~= nil and pTeamID ~= nil and myTeamID ~= "" and myTeamID == pTeamID then
        return true
    end

    -- 3. Quét các thuộc tính (Attributes) phổ biến khác làm phương án dự phòng
    for _, name in ipairs({"Team", "team", "TeamName", "teamName"}) do
        -- Check trên đối tượng Player
        local myAttr = LocalPlayer:GetAttribute(name)
        local pAttr = player:GetAttribute(name)
        if myAttr ~= nil and pAttr ~= nil and myAttr ~= "" and myAttr ~= 0 and myAttr == pAttr then 
            return true 
        end
        
        -- Check trên đối tượng Character (Nhân vật)
        if LocalPlayer.Character and player.Character then
            local myCAttr = LocalPlayer.Character:GetAttribute(name)
            local pCAttr = player.Character:GetAttribute(name)
            if myCAttr ~= nil and pCAttr ~= nil and myCAttr ~= "" and myCAttr ~= 0 and myCAttr == pCAttr then 
                return true 
            end
        end
    end
    
    -- Nếu không thỏa mãn bất kỳ điều kiện nào, đây là kẻ địch!
    return false
end


local function isVisible(targetPart)
    if not Settings.WallCheck then return true end
    if not targetPart or not targetPart.Parent then return false end
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    WallCheckRayParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
    local result = Workspace:Raycast(origin, direction, WallCheckRayParams)
    return not result
end

local function isAutoFireVisible(targetPart)
    if not Settings.AutoFireWallCheck then return true end
    if not targetPart or not targetPart.Parent then return false end
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    WallCheckRayParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
    local result = Workspace:Raycast(origin, direction, WallCheckRayParams)
    return not result
end

local function getClosestPlayer()
    local target, shortestDist = nil, Settings.FOV
    local origin = Camera.CFrame.Position
    local fovPos = FOVring.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if isSameTeam(player) then continue end

        local char = player.Character
        if not char then continue end

        local hum = char:FindFirstChild("Humanoid")
        local head = char:FindFirstChild("Head")
        local hrp = char:FindFirstChild("HumanoidRootPart")

        if hum and hum.Health > 0 and head and hrp then
            local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
            local physicalDist = (head.Position - origin).Magnitude

            if onScreen and physicalDist <= Settings.AimDist then
                local distFromCenter = (Vector2_new(pos.X, pos.Y) - fovPos).Magnitude
                if distFromCenter < shortestDist then
                    if isVisible(head) or isVisible(hrp) then
                        target = player
                        shortestDist = distFromCenter
                    end
                end
            end
        end
    end
    return target
end

local function getTargetPart(character)
    local partName = Settings.TargetPart
    if partName == "Safe" then
        local parts = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}
        partName = parts[math_random(1, #parts)]
    end
    if Settings.AimSafe then
        aimSafeCounter = aimSafeCounter + 1
        if aimSafeCounter >= 4 then
            partName = "HumanoidRootPart"
            aimSafeCounter = 0
        end
    end
    return character:FindFirstChild(partName) or character:FindFirstChild("Head")
end

local function getProAimTarget()
    local bestTarget, shortestDist = nil, Settings.FOV
    local center = Camera.ViewportSize / 2
    local origin = Camera.CFrame.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if isSameTeam(player) then continue end

            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            local partName = Settings.TargetPart
            if partName == "Safe" then
                local parts = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}
                partName = parts[math_random(1, #parts)]
            end
            local part = char and char:FindFirstChild(partName)

            if hum and hum.Health > 0 and part then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                local physicalDist = (part.Position - origin).Magnitude

                if onScreen and physicalDist <= Settings.AimDist then
                    local dist = (Vector2_new(pos.X, pos.Y) - center).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        bestTarget = part
                    end
                end
            end
        end
    end
    return bestTarget
end

-- Cache mục tiêu Pro Aim
local function getProAimTargetCached()
    local now = tick()
    if now - cachedProValid > 0.05 then
        cachedProTarget = getProAimTarget()
        cachedProValid = now
    end
    return cachedProTarget
end

-- Humanization: jitter nhẹ để giả tay người
local function AddJitter(baseCFrame, jitterAmount)
    if jitterAmount <= 0 then return baseCFrame end
    local r = math_random
    local jx = (r() - 0.5) * jitterAmount * 2
    local jy = (r() - 0.5) * jitterAmount * 2
    local jz = (r() - 0.5) * jitterAmount * 2
    return baseCFrame * CFrame_Angles(jx, jy, jz)
end

local isProAimHolding = false

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    local bind = Settings.ProAimHoldMouse
    if bind and (input.KeyCode == bind or input.UserInputType == bind) then
        isProAimHolding = true
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1 and Settings.AimEnabled then
        if Settings.AimHoldMode then
            isAiming = true
        else
            local target = getClosestPlayer()
            if target and target.Character then
                local tPart = getTargetPart(target.Character)
                if tPart then
                    local targetCFrame = CFrame_new(Camera.CFrame.Position, tPart.Position)
                    Camera.CFrame = AddJitter(targetCFrame, Settings.AimJitter)
                end
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gpe)
    local bind = Settings.ProAimHoldMouse
    if bind and (input.KeyCode == bind or input.UserInputType == bind) then
        isProAimHolding = false
        ProAimLockedTarget = nil
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then isAiming = false end
end)

UserInputService.JumpRequest:Connect(function()
    if Settings.InfJump
        and LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ============================================================
-- PHYSICS / STEPPED LOOP (TỐI ƯU CỰC ĐỘ)
-- ============================================================
RunService.Stepped:Connect(function()
    -- Xuyên tường & Chui đất không cấp phát bộ nhớ
    if Settings.Noclip or (Settings.UndergroundNoclip and undergroundSurfaceY) then
        for i = 1, #noClipParts do
            local part = noClipParts[i]
            if part and part.Parent and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
    
    -- Auto Teleport bám địch
    if Settings.AutoTeleport and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myHrp = LocalPlayer.Character.HumanoidRootPart
        local closestEnemy = nil
        local shortestPhysical = math.huge
        local myPos = myHrp.Position
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and not isSameTeam(player) then
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                    local targetHrp = char.HumanoidRootPart
                    local dist = (targetHrp.Position - myPos).Magnitude
                    if dist < shortestPhysical then
                        shortestPhysical = dist
                        closestEnemy = targetHrp
                    end
                end
            end
        end

        if closestEnemy then
            local offsetPos
            local posType = Settings.AutoTeleportPosition
            
            if posType == "Random" then
                local types = {"Sau Lưng", "Trên Đầu", "Trái", "Phải"}
                posType = types[math_random(1, #types)]
            end
            
            if posType == "Trên Đầu" then
                offsetPos = closestEnemy.Position + Vector3_new(0, Settings.AutoTeleportDistance + 3, 0)
            elseif posType == "Trái" then
                offsetPos = closestEnemy.Position + (closestEnemy.CFrame.RightVector * -Settings.AutoTeleportDistance) + Vector3_new(0, 1.5, 0)
            elseif posType == "Phải" then
                offsetPos = closestEnemy.Position + (closestEnemy.CFrame.RightVector * Settings.AutoTeleportDistance) + Vector3_new(0, 1.5, 0)
            else -- Mặc định là Sau Lưng
                local behindOffset = closestEnemy.CFrame.LookVector * -Settings.AutoTeleportDistance
                offsetPos = closestEnemy.Position + behindOffset + Vector3_new(0, 1.5, 0)
            end
            
            myHrp.CFrame = CFrame_new(offsetPos, closestEnemy.Position)
            myHrp.Velocity = Vector3_zero
            
            if Settings.AutoTeleportCameraLock then
                Camera.CFrame = CFrame_new(Camera.CFrame.Position, closestEnemy.Position)
            end
        end
    end
end)

-- ============================================================
-- RENDER LOOP (ESP + AIMBOT + HUD)
-- ============================================================
RunService.RenderStepped:Connect(function(step)
    local center = Camera.ViewportSize / 2
    local now = tick()

    -- SPINBOT / ANTI-AIM
    if Settings.SpinBot and LocalPlayer.Character then
        local myHrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local myHum = LocalPlayer.Character:FindFirstChild("Humanoid")
        if myHrp and myHum and myHum.Health > 0 then
            myHum.AutoRotate = false
            local spinSpeed = (Settings.SpinSpeed or 50) * 0.4
            local spinAngle = (now * spinSpeed * math.pi * 2) % (math.pi * 2)
            myHrp.CFrame = CFrame_new(myHrp.Position) * CFrame_Angles(0, spinAngle, 0)
        end
    end

    if now - cachedClosestValid > 0.05 then
        cachedClosest = getClosestPlayer()
        cachedClosestValid = now
    end
    local closestTarget = cachedClosest

    -- 1. FOV & SNAPLINE (1 VÒNG TRÒN DUY NHẤT ĐỒNG BỘ)
    FOVring.Visible = Settings.FOVVisible
    if Settings.FOVVisible then
        FOVring.Position = center
        FOVring.Radius = Settings.FOV
        local hasTarget = (Settings.AimEnabled and closestTarget) or (Settings.ProAimEnabled and (ProAimLockedTarget or getProAimTargetCached()))
        FOVring.Color = hasTarget and Color3_fromRGB(255, 50, 50) or Theme.AccentOn
    end

    local snapTarget = nil
    if Settings.FOVVisible or Settings.AimSnapline then
        if Settings.AimEnabled and closestTarget and closestTarget.Character then
            local tPart = getTargetPart(closestTarget.Character)
            if tPart then snapTarget = tPart end
        elseif Settings.ProAimEnabled and ProAimLockedTarget then
            snapTarget = ProAimLockedTarget
        end
    end

    if snapTarget then
        local targetPos, onScreen = Camera:WorldToViewportPoint(snapTarget.Position)
        if onScreen then
            AimSnaplineDraw.From = center
            AimSnaplineDraw.To = Vector2_new(targetPos.X, targetPos.Y)
            AimSnaplineDraw.Visible = true
        else
            AimSnaplineDraw.Visible = false
        end
    else
        AimSnaplineDraw.Visible = false
    end

    -- 2. AIM HOLD (Hard Lock + smooth + jitter)
    if isAiming and Settings.AimEnabled and Settings.AimHoldMode then
        local target = closestTarget
        if target and target.Character then
            local tPart = getTargetPart(target.Character)
            if tPart then
                local desired = CFrame_new(Camera.CFrame.Position, tPart.Position)
                desired = AddJitter(desired, Settings.AimJitter)
                if Settings.AimSmoothness >= 1 then
                    Camera.CFrame = desired
                else
                    local t = 1 - math_pow(1 - math_clamp(Settings.AimSmoothness, 0, 1), step * 60)
                    Camera.CFrame = Camera.CFrame:Lerp(desired, t)
                end
            end
        end
    end

    -- 2.5 PRO AIM (Aim Lock / Silent Aim - CHỈ KHOÁ KHI GIỮ ĐÚNG PHÍM AIM KEY)
    local isHolding = isProAimHolding
    if not isHolding and typeof(Settings.ProAimHoldMouse) == "EnumItem" then
        if tostring(Settings.ProAimHoldMouse):match("UserInputType") then
            local ok, pressed = pcall(function() return UserInputService:IsMouseButtonPressed(Settings.ProAimHoldMouse) end)
            if ok and pressed then isHolding = true end
        elseif tostring(Settings.ProAimHoldMouse):match("KeyCode") then
            local ok, pressed = pcall(function() return UserInputService:IsKeyDown(Settings.ProAimHoldMouse) end)
            if ok and pressed then isHolding = true end
        end
    end

    if Settings.ProAimEnabled and isHolding then
        local targetValid = ProAimLockedTarget
            and ProAimLockedTarget.Parent
            and ProAimLockedTarget.Parent:FindFirstChildOfClass("Humanoid")
            and ProAimLockedTarget.Parent:FindFirstChildOfClass("Humanoid").Health > 0

        if not targetValid then
            if now - lastTargetSwitch > 0.05 then
                ProAimLockedTarget = getProAimTargetCached()
                lastTargetSwitch = now
                aimAcquireTime = now
            end
        end

        if ProAimLockedTarget then
            local cam = Camera.CFrame
            local dir = (ProAimLockedTarget.Position - cam.Position).Unit
            local desired = CFrame_new(cam.Position, cam.Position + dir)
            if Settings.ProAimJitter > 0 then
                desired = AddJitter(desired, Settings.ProAimJitter)
            end
            if Settings.ProAimSmoothness >= 1 then
                Camera.CFrame = desired
            else
                local t = 1 - math_pow(1 - math_clamp(Settings.ProAimSmoothness, 0, 1), step * 60)
                Camera.CFrame = cam:Lerp(desired, t)
            end
        end
    else
        ProAimLockedTarget = nil
    end

    -- 2.6 AUTO FIRE & AUTO FIRE (HOLD M2) + WALL CHECK
    local shouldAutoFire = Settings.AutoFire or (Settings.AutoFireHoldM2 and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2))
    if shouldAutoFire then
        local targetPart = ProAimLockedTarget
        if not targetPart then
            if closestTarget and closestTarget.Character then
                targetPart = getTargetPart(closestTarget.Character)
            end
        end
        if not targetPart then
            targetPart = getProAimTargetCached()
        end

        if targetPart then
            local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
            if onScreen then
                local adist = (Vector2_new(pos.X, pos.Y) - center).Magnitude
                local maxFov = Settings.FOV or 100
                local delayTime = math_max(Settings.AutoFireDelay or 0, 0.05)
                if adist <= maxFov and (now - lastShotTime) >= delayTime then
                    if isAutoFireVisible(targetPart) then
                        lastShotTime = now
                        FireShot()
                    end
                end
            end
        end
    end

    -- 2.7 NO RECOIL
    if Settings.NoRecoil and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        local cam = Camera.CFrame
        local mouseDelta = UserInputService:GetMouseDelta()
        if math_abs(mouseDelta.X) > 4 or math_abs(mouseDelta.Y) > 4 then
            noRecoilPrevCam = cam
        else
            local rel = noRecoilPrevCam:Inverse() * cam
            local rx, ry, _ = rel:ToEulerAnglesXYZ()
            if math_abs(rx) > 0.005 or math_abs(ry) > 0.005 then
                local s = Settings.NoRecoilStrength
                Camera.CFrame = cam * CFrame_Angles(-rx * s, -ry * s, 0)
                noRecoilPrevCam = Camera.CFrame
            else
                noRecoilPrevCam = cam
            end
        end
    else
        noRecoilPrevCam = Camera.CFrame
    end

    -- 3. PLAYER MODS
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local humanoid = LocalPlayer.Character.Humanoid
        local hrp = LocalPlayer.Character.HumanoidRootPart

        if Settings.SpeedHack then humanoid.WalkSpeed = Settings.WalkSpeed end
        if Settings.JumpHack then
            humanoid.UseJumpPower = true
            humanoid.JumpPower = Settings.JumpPower
        end

        if Settings.Fly then
            humanoid.PlatformStand = true
            local moveDir = Vector3_zero
            local camCFrame = Camera.CFrame

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3_new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3_new(0, 1, 0) end

            if moveDir.Magnitude > 0 then
                moveDir = moveDir.Unit * Settings.FlySpeed
            end
            hrp.Velocity = moveDir
            hrp.CFrame = CFrame_new(hrp.Position, hrp.Position + camCFrame.LookVector)
        elseif Settings.UndergroundNoclip and undergroundSurfaceY then
            humanoid.PlatformStand = true
            local moveDir = Vector3_zero
            local camCFrame = Camera.CFrame

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCFrame.RightVector end
            
            moveDir = Vector3_new(moveDir.X, 0, moveDir.Z)
            if moveDir.Magnitude > 0 then
                moveDir = moveDir.Unit * Settings.WalkSpeed
            end
            
            local targetY = undergroundSurfaceY - Settings.UndergroundDistance
            hrp.Velocity = moveDir
            
            local camLx, camLz = camCFrame.LookVector.X, camCFrame.LookVector.Z
            if math_abs(camLx) < 0.001 and math_abs(camLz) < 0.001 then
                camLx, camLz = hrp.CFrame.LookVector.X, hrp.CFrame.LookVector.Z
            end
            
            local lookAtPos = Vector3_new(hrp.Position.X + camLx, targetY, hrp.Position.Z + camLz)
            hrp.CFrame = CFrame_new(Vector3_new(hrp.Position.X, targetY, hrp.Position.Z), lookAtPos)
        else
            humanoid.PlatformStand = false
        end
    end

    -- 4. SPECTATING
    if Settings.Spectating and Settings.SpectatePlayer ~= "" then
        local targetPlayer = Players:FindFirstChild(Settings.SpectatePlayer)
        if targetPlayer and targetPlayer.Character
            and targetPlayer.Character:FindFirstChild("Humanoid") then
            Camera.CameraSubject = targetPlayer.Character.Humanoid
        elseif LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            Camera.CameraSubject = LocalPlayer.Character.Humanoid
        end
    end

    -- 5. CROSSHAIR
    for _, draw in pairs(CrosshairDraws) do draw.Visible = false end
    if Settings.Crosshair then
        local size, thick = Settings.CrosshairSize, Settings.CrosshairThickness
        local color = ColorList[Settings.CrosshairColor] or Color3_fromRGB(0, 255, 0)
        for _, draw in pairs(CrosshairDraws) do
            draw.Color = color
            draw.Thickness = thick
        end

        if Settings.CrosshairStyle == "Cross" or Settings.CrosshairStyle == "Cross + Dot" then
            CrosshairDraws.L.Visible = true
            CrosshairDraws.L.From = Vector2_new(center.X - size, center.Y)
            CrosshairDraws.L.To = Vector2_new(center.X - 3, center.Y)
            CrosshairDraws.R.Visible = true
            CrosshairDraws.R.From = Vector2_new(center.X + 3, center.Y)
            CrosshairDraws.R.To = Vector2_new(center.X + size, center.Y)
            CrosshairDraws.T.Visible = true
            CrosshairDraws.T.From = Vector2_new(center.X, center.Y - size)
            CrosshairDraws.T.To = Vector2_new(center.X, center.Y - 3)
            CrosshairDraws.B.Visible = true
            CrosshairDraws.B.From = Vector2_new(center.X, center.Y + 3)
            CrosshairDraws.B.To = Vector2_new(center.X, center.Y + size)
        end
        if Settings.CrosshairStyle == "X" then
            local offset = size * 0.707
            CrosshairDraws.L.Visible = true
            CrosshairDraws.L.From = Vector2_new(center.X - offset, center.Y - offset)
            CrosshairDraws.L.To = Vector2_new(center.X - 2, center.Y - 2)
            CrosshairDraws.R.Visible = true
            CrosshairDraws.R.From = Vector2_new(center.X + offset, center.Y + offset)
            CrosshairDraws.R.To = Vector2_new(center.X + 2, center.Y + 2)
            CrosshairDraws.T.Visible = true
            CrosshairDraws.T.From = Vector2_new(center.X + offset, center.Y - offset)
            CrosshairDraws.T.To = Vector2_new(center.X + 2, center.Y - 2)
            CrosshairDraws.B.Visible = true
            CrosshairDraws.B.From = Vector2_new(center.X - offset, center.Y + offset)
            CrosshairDraws.B.To = Vector2_new(center.X - 2, center.Y + 2)
        end
        if Settings.CrosshairStyle == "Circle" then
            CrosshairDraws.Circle.Visible = true
            CrosshairDraws.Circle.Radius = size
            CrosshairDraws.Circle.Position = center
            CrosshairDraws.Circle.Filled = false
        end
        if Settings.CrosshairStyle == "Dot" or Settings.CrosshairStyle == "Cross + Dot" then
            CrosshairDraws.Dot.Visible = true
            CrosshairDraws.Dot.Radius = thick
            CrosshairDraws.Dot.Position = center
            CrosshairDraws.Dot.Filled = true
        end
    end

    -- 5.5 CẢNH BÁO BỊ NGẮM
    if Settings.AimWarning then
        local warnTarget = nil
        if now - lastWarnScan > 0.1 then
            lastWarnScan = now
            local myChar = LocalPlayer.Character
            local myHead = myChar and myChar:FindFirstChild("Head")
            if myHead then
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer then
                        if isSameTeam(player) then continue end
                        local char = player.Character
                        if char then
                            local eHead = char:FindFirstChild("Head")
                            if eHead and (eHead.Position - myHead.Position).Magnitude <= Settings.AimDist then
                                local dirToMe = (myHead.Position - eHead.Position).Unit
                                local dot = eHead.CFrame.LookVector:Dot(dirToMe)
                                if dot > 0.97 and char:FindFirstChildOfClass("Tool") then
                                    warnTarget = player
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
        if warnTarget then
            local flash = (math_floor(now * 4) % 2 == 0)
            AimWarnText.Visible = true
            AimWarnText.Text = "⚠ BỊ NGẮM: " .. warnTarget.Name .. " ⚠"
            AimWarnText.Color = flash and Color3_fromRGB(255, 0, 0) or Color3_fromRGB(255, 255, 0)
            AimWarnText.Position = Vector2_new(center.X, center.Y - 120)
        else
            AimWarnText.Visible = false
        end
    else
        AimWarnText.Visible = false
    end

    -- 6. ESP TARGET COUNTING & RENDERING (TỐI ƯU HOÁ TOÀN DIỆN)
    local espTotalInRange = 0
    local espTotalOnScreen = 0
    local camPos = Camera.CFrame.Position

    for player, esp in pairs(ESPTable) do
        local isVisibleNow = false

        if Settings.ESPEnabled and player and player.Parent == Players then
            local char = player.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local head = char:FindFirstChild("Head")
                local hum = char:FindFirstChild("Humanoid")

                if hrp and head and hum and hum.Health > 0 then
                    local passTeamCheck = not isSameTeam(player)

                    if passTeamCheck then
                        local dist = (hrp.Position - camPos).Magnitude

                        if dist <= Settings.ESPDist then
                            espTotalInRange = espTotalInRange + 1

                            local rootPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)

                            if Settings.ESPChams then
                                if not esp._chamsOn then
                                    esp._chamsOn = true
                                    esp.Chams.Enabled = true
                                end
                                if esp.Chams.Adornee ~= char then esp.Chams.Adornee = char end
                                local col = ColorList[Settings.ChamsColor] or Color3_fromRGB(255, 0, 0)
                                if esp.Chams.FillColor ~= col then
                                    esp.Chams.FillColor = col
                                    esp.Chams.OutlineColor = col
                                end
                            else
                                if esp._chamsOn then
                                    esp._chamsOn = false
                                    esp.Chams.Enabled = false
                                end
                            end

                            if onScreen and rootPos.Z > 0 then
                                espTotalOnScreen = espTotalOnScreen + 1
                                isVisibleNow = true

                                local headPos = Camera:WorldToViewportPoint(head.Position + Vector3_new(0, 0.5, 0))
                                local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3_new(0, 3, 0))
                                local height = math_abs(headPos.Y - legPos.Y)
                                local width = height / 2

                                if Settings.ESPBox then
                                    esp.Box.Size = Vector2_new(width, height)
                                    esp.Box.Position = Vector2_new(rootPos.X - width / 2, headPos.Y)
                                    esp.Box.Visible = true
                                else
                                    esp.Box.Visible = false
                                end

                                if Settings.ESPName or Settings.ESPDistance then
                                    local textString = ""
                                    if Settings.ESPName then textString = player.Name end
                                    if Settings.ESPDistance then
                                        textString = textString
                                            .. (Settings.ESPName and " " or "")
                                            .. "[" .. math_floor(dist) .. "m]"
                                    end
                                    esp.Name.Text = textString
                                    esp.Name.Position = Vector2_new(rootPos.X, headPos.Y - 18)
                                    esp.Name.Visible = true
                                else
                                    esp.Name.Visible = false
                                end

                                if Settings.ESPWeapon or Settings.ESPLevel then
                                    local infoText = ""
                                    if Settings.ESPLevel then
                                        local stats = player:FindFirstChild("leaderstats")
                                        local lvl = stats and (stats:FindFirstChild("Level")
                                            or stats:FindFirstChild("XP")
                                            or stats:FindFirstChild("Exp")
                                            or stats:FindFirstChild("Win")
                                            or stats:FindFirstChild("Wins")) or player:FindFirstChild("Level")
                                        if lvl and lvl:IsA("ValueBase") then
                                            infoText = infoText .. "[Lv " .. tostring(lvl.Value) .. "] "
                                        end
                                    end
                                    if Settings.ESPWeapon then
                                        local tool = char:FindFirstChildOfClass("Tool")
                                        if tool then
                                            infoText = infoText .. tool.Name
                                        else
                                            infoText = infoText .. "Unarmed"
                                        end
                                    end
                                    esp.Info.Text = infoText
                                    esp.Info.Position = Vector2_new(rootPos.X, headPos.Y - 32)
                                    esp.Info.Visible = infoText ~= ""
                                else
                                    esp.Info.Visible = false
                                end

                                if Settings.ESPHealth then
                                    local dynamicThickness = math_clamp(150 / math_max(dist, 1), 1, 4)
                                    esp.HealthBg.Thickness = dynamicThickness
                                    esp.HealthBg.From = Vector2_new(
                                        rootPos.X - width / 2 - (dynamicThickness + 2), headPos.Y)
                                    esp.HealthBg.To = Vector2_new(
                                        rootPos.X - width / 2 - (dynamicThickness + 2), legPos.Y)
                                    esp.HealthBg.Visible = true

                                    local maxH = math_max(hum.MaxHealth, 1)
                                    local healthPct = math_clamp(hum.Health / maxH, 0, 1)
                                    local yOffset = height * healthPct

                                    esp.Health.Thickness = dynamicThickness
                                    esp.Health.From = Vector2_new(
                                        rootPos.X - width / 2 - (dynamicThickness + 2), legPos.Y - yOffset)
                                    esp.Health.To = Vector2_new(
                                        rootPos.X - width / 2 - (dynamicThickness + 2), legPos.Y)
                                    esp.Health.Color = Color3_fromRGB(
                                        255 - (healthPct * 255), healthPct * 255, 0)
                                    esp.Health.Visible = true
                                else
                                    esp.HealthBg.Visible = false
                                    esp.Health.Visible = false
                                end

                                if Settings.ESPLine then
                                    esp.Tracer.From = Vector2_new(center.X, 0)
                                    esp.Tracer.To = Vector2_new(rootPos.X, headPos.Y)
                                    esp.Tracer.Visible = true
                                else
                                    esp.Tracer.Visible = false
                                end

                                if Settings.ESPSkeleton then
                                    local isR15 = char:FindFirstChild("UpperTorso") ~= nil
                                    local connections = isR15 and R15_BONES or R6_BONES
                                    for i = 1, 14 do
                                        local boneDraw = esp.Skeleton[i]
                                        local conn = connections[i]
                                        if conn then
                                            local partA = char:FindFirstChild(conn[1])
                                            local partB = char:FindFirstChild(conn[2])
                                            if partA and partB then
                                                local posA, visA = Camera:WorldToViewportPoint(partA.Position)
                                                local posB, visB = Camera:WorldToViewportPoint(partB.Position)
                                                if visA or visB then
                                                    boneDraw.From = Vector2_new(posA.X, posA.Y)
                                                    boneDraw.To = Vector2_new(posB.X, posB.Y)
                                                    boneDraw.Visible = true
                                                else
                                                    boneDraw.Visible = false
                                                end
                                            else
                                                boneDraw.Visible = false
                                            end
                                        else
                                            boneDraw.Visible = false
                                        end
                                    end
                                else
                                    for i = 1, 14 do esp.Skeleton[i].Visible = false end
                                end
                            end
                        end
                    else
                        if esp._chamsOn then
                            esp._chamsOn = false
                            esp.Chams.Enabled = false
                        end
                    end
                end
            end
        end

        -- Off-Screen Arrows Rendering
        if Settings.ESPEnabled and Settings.OffscreenArrows and player and player.Parent == Players and player.Character then
            local char = player.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            local passTeamCheck = not isSameTeam(player)
            if hrp and hum and hum.Health > 0 and passTeamCheck then
                local dist = (hrp.Position - camPos).Magnitude
                if dist <= Settings.ESPDist then
                    local rootPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if not onScreen or rootPos.Z <= 0 then
                        local camCFrame = Camera.CFrame
                        local relVector = hrp.Position - camCFrame.Position
                        local forward = camCFrame.LookVector
                        local right = camCFrame.RightVector
                        local x = relVector:Dot(right)
                        local z = relVector:Dot(forward)
                        local angle = math.atan2(x, z)
                        local radius = 170
                        local tip = center + Vector2_new(math.sin(angle), -math.cos(angle)) * radius
                        local base = center + Vector2_new(math.sin(angle), -math.cos(angle)) * (radius - 18)
                        local perp = Vector2_new(-math.cos(angle), -math.sin(angle)) * 9
                        esp.Arrow1.From = tip
                        esp.Arrow1.To = base + perp
                        esp.Arrow1.Visible = true

                        esp.Arrow2.From = tip
                        esp.Arrow2.To = base - perp
                        esp.Arrow2.Visible = true

                        esp.Arrow3.From = base + perp
                        esp.Arrow3.To = base - perp
                        esp.Arrow3.Visible = true
                    else
                        if esp.Arrow1 then esp.Arrow1.Visible = false; esp.Arrow2.Visible = false; esp.Arrow3.Visible = false end
                    end
                else
                    if esp.Arrow1 then esp.Arrow1.Visible = false; esp.Arrow2.Visible = false; esp.Arrow3.Visible = false end
                end
            else
                if esp.Arrow1 then esp.Arrow1.Visible = false; esp.Arrow2.Visible = false; esp.Arrow3.Visible = false end
            end
        else
            if esp.Arrow1 then esp.Arrow1.Visible = false; esp.Arrow2.Visible = false; esp.Arrow3.Visible = false end
        end

        if not isVisibleNow then
            esp.Box.Visible = false
            esp.Name.Visible = false
            esp.Info.Visible = false
            esp.HealthBg.Visible = false
            esp.Health.Visible = false
            esp.Tracer.Visible = false
            for i = 1, 14 do esp.Skeleton[i].Visible = false end
            local char = player and player.Character
            if not (char and char:FindFirstChild("Humanoid")
                and char.Humanoid.Health > 0) then
                if esp._chamsOn then
                    esp._chamsOn = false
                    esp.Chams.Enabled = false
                end
            end
        end
    end

    -- 7. CẬP NHẬT TOP-CENTER ESP COUNTER (KHUNG ĐEN VUÔNG - CHỈ HIỆN SỐ TRONG TẦM)
    if Settings.ESPEnabled and Settings.ESPCount then
        ESPCounterBox.Visible = true
        ESPCounterLabel.Text = tostring(espTotalInRange)
        if espTotalInRange > 0 then
            ESPCounterLabel.TextColor3 = Color3_fromRGB(0, 255, 136) -- Màu xanh lá khi có địch
        else
            ESPCounterLabel.TextColor3 = Color3_fromRGB(255, 50, 50)  -- Số 0 màu đỏ khi không còn ai
        end
    else
        ESPCounterBox.Visible = false
    end
end)

-- ============================================================
-- FPS & EXP UPDATER
-- ============================================================
local expTime = 999 * 24 * 60 * 60
local frames = 0
local currentFPS = 60
local lastFPSUpdate = tick()

RunService.RenderStepped:Connect(function()
    frames = frames + 1
    local now = tick()
    if now - lastFPSUpdate >= 0.5 then
        currentFPS = math_floor(frames / (now - lastFPSUpdate))
        frames = 0
        lastFPSUpdate = now
    end
end)

task_spawn(function()
    while task_wait(1) do
        if expTime > 0 then expTime = expTime - 1 end
        local days = math_floor(expTime / 86400)
        local hours = math_floor((expTime % 86400) / 3600)
        local mins = math_floor((expTime % 3600) / 60)
        local secs = expTime % 60

        if isMenuConnected then
            StatusText.Text = string_format(
                "<font color=\"#00ff00\">● CONNECTED</font>   -   EXP %dd %dh %dm %ds   -   FPS %d"
                    .. "   -   BLOCKED %d",
                days, hours, mins, secs, currentFPS, Shield.Blocks)
            UpdateWatermarkColor(Color3_fromRGB(0, 255, 0))
        else
            StatusText.Text = "<font color=\"#ffffff\">● Rivals Menu</font>   <font color=\"#666677\">/</font>   <font color=\"#aaaaaa\">Login</font>"
            UpdateWatermarkColor(Color3_fromRGB(255, 215, 0))
        end
    end
end)

-- Quét thêm remote nguy hiểm mới xuất hiện (động)
task_spawn(function()
    while task_wait(15) do
        pcall(function()
            for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
                if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                    ClassifyRemote(remote.Name)
                end
            end
        end)
    end
end)

-- ============================================================
-- ANTI-AFK SYSTEM (MẶC ĐỊNH TÍCH HỢP SẴN KHÔNG THỂ TẮT)
-- ============================================================
LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2_new(0, 0))
    end)
end)

task_spawn(function()
    while task_wait(300) do
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2_new(0, 0))
        end)
    end
end)

-- ============================================================
-- KHỞI TẠO CUỐI
-- ============================================================
UpdateTabDots()
ApplyTheme()
InitShield()

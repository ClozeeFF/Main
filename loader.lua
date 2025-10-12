-- Lucy Loader v1.1 (with Key UI)
-- โหลด TEST.lua จาก GitHub หลังจากใส่ key ถูกต้อง

local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPlayers()[1]

-- 🔑 Key ที่ต้องใช้
local VALID_KEY = "LucyTestKey123"

-- 🔗 URL ของสคริปต์หลัก (TEST.lua)
local MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/ClozeeFF/Main/refs/heads/main/TEST.lua"

-- ฟังก์ชันโหลดและรัน TEST.lua
local function load_main_script()
    print("[Lucy Loader] Fetching TEST.lua...")
    local ok, data = pcall(function()
        return game:HttpGet(MAIN_SCRIPT_URL)
    end)
    if not ok or not data or data == "" then
        warn("[Lucy Loader] Failed to download main script:", data)
        return
    end
    print("[Lucy Loader] Running TEST.lua...")
    local success, err = pcall(function()
        loadstring(data)()
    end)
    if not success then
        warn("[Lucy Loader] Error while running TEST.lua:", err)
    else
        print("[Lucy Loader] ✅ Script executed successfully!")
    end
end

-- UI: Key Input
local screen = Instance.new("ScreenGui")
screen.Name = "Lucy_KeyUI"
screen.ResetOnSpawn = false
screen.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 160)
frame.Position = UDim2.new(0.5, -150, 0.5, -80)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderSizePixel = 0
frame.Parent = screen

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "🔑 Enter Access Key"
title.Font = Enum.Font.GothamSemibold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Parent = frame

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -40, 0, 40)
box.Position = UDim2.new(0, 20, 0, 50)
box.PlaceholderText = "Your key here..."
box.Text = ""
box.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
box.TextColor3 = Color3.fromRGB(255, 255, 255)
box.Font = Enum.Font.Gotham
box.TextSize = 16
box.ClearTextOnFocus = true
box.Parent = frame

Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)

local button = Instance.new("TextButton")
button.Size = UDim2.new(1, -40, 0, 36)
button.Position = UDim2.new(0, 20, 0, 100)
button.Text = "Unlock"
button.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.GothamSemibold
button.TextSize = 16
button.Parent = frame

Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

-- แจ้งเตือน (UI ข้อความชั่วคราว)
local function showNotice(msg, color)
    local notice = Instance.new("TextLabel")
    notice.Size = UDim2.new(0, 240, 0, 30)
    notice.Position = UDim2.new(0.5, -120, 0, -40)
    notice.BackgroundColor3 = color or Color3.fromRGB(40, 40, 40)
    notice.TextColor3 = Color3.new(1, 1, 1)
    notice.Font = Enum.Font.GothamSemibold
    notice.TextSize = 14
    notice.Text = msg
    notice.Parent = frame
    notice.BackgroundTransparency = 0.15
    Instance.new("UICorner", notice).CornerRadius = UDim.new(0, 6)
    task.delay(2.5, function()
        if notice and notice.Parent then notice:Destroy() end
    end)
end

-- เมื่อกดปุ่ม Unlock
button.MouseButton1Click:Connect(function()
    local key = box.Text
    if key == "" then
        showNotice("⚠️ Please enter your key!", Color3.fromRGB(150, 80, 0))
        return
    end
    if key == VALID_KEY then
        showNotice("✅ Key verified!", Color3.fromRGB(0, 180, 70))
        task.wait(1)
        screen:Destroy()
        load_main_script()
    else
        showNotice("❌ Invalid key!", Color3.fromRGB(180, 50, 50))
        box.Text = ""
    end
end)

-- Lucy Loader v2.0 (Key System from GitHub)
-- ดึง key.json จาก GitHub และตรวจ key ก่อนโหลด TEST.lua

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPlayers()[1]

-- 🔗 URLs (ปรับให้ตรงกับ repo ของคุณ)
local KEY_URL  = "https://raw.githubusercontent.com/ClozeeFF/Main/main/key.json"
local MAIN_URL = "https://raw.githubusercontent.com/ClozeeFF/Main/main/TEST.lua"

-- โหลด key.json จาก GitHub
local function fetch_keys()
    local ok, res = pcall(function()
        return game:HttpGet(KEY_URL)
    end)
    if not ok or not res then
        warn("[Lucy Loader] ❌ Cannot download key.json:", res)
        return {}
    end
    local success, data = pcall(function()
        return HttpService:JSONDecode(res)
    end)
    if success and data and data.keys then
        print("[Lucy Loader] ✅ Loaded keys from GitHub (" .. #data.keys .. ")")
        return data.keys
    else
        warn("[Lucy Loader] ⚠️ JSON decode failed")
        return {}
    end
end

-- โหลดและรัน TEST.lua
local function load_main_script()
    print("[Lucy Loader] Fetching TEST.lua...")
    local ok, code = pcall(function()
        return game:HttpGet(MAIN_URL)
    end)
    if not ok or not code or code == "" then
        warn("[Lucy Loader] ❌ Failed to get TEST.lua:", code)
        return
    end
    local run_ok, err = pcall(function()
        loadstring(code)()
    end)
    if not run_ok then
        warn("[Lucy Loader] ⚠️ Script Error:", err)
    else
        print("[Lucy Loader] ✅ TEST.lua executed successfully!")
    end
end

-- สร้าง UI สำหรับกรอก key
local screen = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screen.Name = "Lucy_KeyUI"

local frame = Instance.new("Frame", screen)
frame.Size = UDim2.new(0, 300, 0, 160)
frame.Position = UDim2.new(0.5, -150, 0.5, -80)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderSizePixel = 0
local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "🔑 Enter Access Key"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamSemibold
title.TextSize = 18
title.BackgroundTransparency = 1

local box = Instance.new("TextBox", frame)
box.Size = UDim2.new(1, -40, 0, 40)
box.Position = UDim2.new(0, 20, 0, 50)
box.PlaceholderText = "Your key here..."
box.Text = ""
box.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
box.TextColor3 = Color3.fromRGB(255, 255, 255)
box.Font = Enum.Font.Gotham
box.TextSize = 16
box.ClearTextOnFocus = true
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)

local button = Instance.new("TextButton", frame)
button.Size = UDim2.new(1, -40, 0, 36)
button.Position = UDim2.new(0, 20, 0, 100)
button.Text = "Unlock"
button.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.GothamSemibold
button.TextSize = 16
Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

-- UI แจ้งเตือน
local function showNotice(text, color)
    local n = Instance.new("TextLabel", frame)
    n.Size = UDim2.new(0, 240, 0, 30)
    n.Position = UDim2.new(0.5, -120, 0, -35)
    n.BackgroundColor3 = color or Color3.fromRGB(40, 40, 40)
    n.TextColor3 = Color3.new(1, 1, 1)
    n.Font = Enum.Font.GothamSemibold
    n.TextSize = 14
    n.Text = text
    n.BackgroundTransparency = 0.15
    Instance.new("UICorner", n).CornerRadius = UDim.new(0, 6)
    task.delay(2.5, function()
        if n and n.Parent then n:Destroy() end
    end)
end

-- ตรวจ key เมื่อคลิกปุ่ม
button.MouseButton1Click:Connect(function()
    local enteredKey = box.Text
    if enteredKey == "" then
        showNotice("⚠️ Please enter your key!", Color3.fromRGB(180, 120, 0))
        return
    end

    button.Text = "Checking..."
    button.Active = false

    local validKeys = fetch_keys()
    local matched = false
    for _, k in ipairs(validKeys) do
        if k == enteredKey then
            matched = true
            break
        end
    end

    if matched then
        showNotice("✅ Key verified!", Color3.fromRGB(0, 200, 90))
        task.wait(1)
        screen:Destroy()
        load_main_script()
    else
        showNotice("❌ Invalid key!", Color3.fromRGB(200, 50, 50))
        button.Text = "Unlock"
        button.Active = true
        box.Text = ""
    end
end)

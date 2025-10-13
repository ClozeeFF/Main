-- Lucy Loader - HWID + Auto Login
-- ตรวจสอบ HWID จาก key.json และโหลด TEST.lua ถ้าผ่าน

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Analytics = game:GetService("RbxAnalyticsService")
local hwid = Analytics:GetClientId()

-- 🔗 URLs
local KEY_URL  = "https://raw.githubusercontent.com/ClozeeFF/Main/refs/heads/main/key.json"
local MAIN_URL = "https://raw.githubusercontent.com/ClozeeFF/Main/refs/heads/main/BAZ.lua"

-- 📂 Local save path
if makefolder and not isfolder("LucySystem") then
    pcall(makefolder, "LucySystem")
end
local savePath = "LucySystem/Auth.txt"

-- 🧩 ฟังก์ชันโหลด key.json
local function fetch_key_data()
    local ok, res = pcall(function()
        return game:HttpGet(KEY_URL)
    end)
    if not ok or not res then
        warn("[Lucy Loader] ❌ Failed to load key.json:", res)
        return nil
    end

    local success, data = pcall(function()
        return HttpService:JSONDecode(res)
    end)
    if success and data and data.keys then
        print("[Lucy Loader] ✅ Loaded", #data.keys, "keys")
        return data.keys
    end

    warn("[Lucy Loader] ⚠️ Invalid JSON format")
    return nil
end

-- 🧩 ตรวจสอบ HWID
local function verify_hwid(keyList, userHWID)
    if not keyList then return false, "no_data" end

    for _, item in ipairs(keyList) do
        if item.hwid == userHWID then
            local expire = tostring(item.expire or "permanent")
            if string.lower(expire) == "permanent" then
                return true, "permanent"
            end

            local y, m, d = expire:match("(%d+)%-(%d+)%-(%d+)")
            if y and m and d then
                local expTime = os.time({
                    year = tonumber(y),
                    month = tonumber(m),
                    day = tonumber(d),
                    hour = 23, min = 59, sec = 59
                })
                if os.time() <= expTime then
                    return true, expire
                else
                    return false, "expired"
                end
            end
        end
    end
    return false, "not_found"
end

-- 🧩 โหลดและรัน TEST.lua
local function load_main_script()
    print("[Lucy Loader] 🔄 Fetching TEST.lua...")
    local ok, code = pcall(function()
        return game:HttpGet(MAIN_URL)
    end)
    if not ok or not code or code == "" then
        warn("[Lucy Loader] ❌ Failed to download:", code)
        return
    end
    print("[Lucy Loader] ✅ Running TEST.lua")
    local success, err = pcall(function()
        loadstring(code)()
    end)
    if not success then
        warn("[Lucy Loader] ⚠️ Script error:", err)
    end
end

-- 🧩 แสดง UI สำหรับตรวจสอบ HWID
local function createHWIDUI()
    local screen = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
    screen.Name = "Lucy_HWIDUI"

    local frame = Instance.new("Frame", screen)
    frame.Size = UDim2.new(0, 340, 0, 160)
    frame.Position = UDim2.new(0.5, -170, 0.5, -80)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 36)
    title.Text = "🔑 HWID Access System"
    title.Font = Enum.Font.GothamSemibold
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1

    local box = Instance.new("TextBox", frame)
    box.Size = UDim2.new(1, -40, 0, 40)
    box.Position = UDim2.new(0, 20, 0, 55)
    box.Text = hwid
    box.ClearTextOnFocus = false
    box.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.Gotham
    box.TextSize = 14
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)

    local button = Instance.new("TextButton", frame)
    button.Size = UDim2.new(1, -40, 0, 36)
    button.Position = UDim2.new(0, 20, 0, 105)
    button.Text = "Check HWID"
    button.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = 16
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

    button.MouseButton1Click:Connect(function()
        button.Text = "Checking..."
        button.Active = false

        local keyList = fetch_key_data()
        local ok, info = verify_hwid(keyList, hwid)

        if ok then
            print("[Lucy Loader] ✅ HWID matched! Expire:", info)
            if writefile then
                pcall(writefile, savePath, hwid)
                print("[Lucy Loader] 💾 Saved HWID to local:", savePath)
            end
            frame:Destroy()
            load_main_script()
        else
            button.Text = ({
                expired = "⏳ Expired",
                not_found = "❌ Not Found",
                no_data = "⚠️ No Data"
            })[info] or "❌ Invalid"

            task.wait(1.5)
            button.Text = "Check HWID"
            button.Active = true
            warn("[Lucy Loader] ❌ HWID check failed:", info)
        end
    end)
end

-- 🧩 ตรวจสอบ Auto Login
local function tryAutoLogin()
    if isfile and isfile(savePath) then
        local savedHWID = readfile(savePath)
        if savedHWID and savedHWID == hwid then
            print("[Lucy Loader] 🔓 Auto login success (saved HWID)")
            load_main_script()
            return true
        end
    end
    return false
end

-- 🟢 เริ่ม Loader
if not tryAutoLogin() then
    createHWIDUI()
end

-- Lucy Loader v4.0 (Key + HWID + Expire + AutoLogin + Copy HWID)
-- โหลด TEST.lua จาก GitHub ถ้า key/hwid/expire ถูกต้อง

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Analytics = game:GetService("RbxAnalyticsService")

local player = Players.LocalPlayer or Players:GetPlayers()[1]
local hwid = Analytics:GetClientId()

-- 🔗 URLs
local KEY_URL  = "https://raw.githubusercontent.com/ClozeeFF/Main/refs/heads/main/key.json"
local MAIN_URL = "https://raw.githubusercontent.com/ClozeeFF/Main/refs/heads/main/BAZ.lua"

-- 🔒 Local save path
local SAVE_FOLDER = "LucySystem"
local SAVE_PATH = SAVE_FOLDER .. "/key.txt"

-- 🧩 Helper: อ่าน/เขียนไฟล์ (บาง executor ต้องรองรับ writefile)
local function readSavedKey()
    if isfolder and not isfolder(SAVE_FOLDER) then
        pcall(makefolder, SAVE_FOLDER)
    end
    if isfile and isfile(SAVE_PATH) then
        local ok, data = pcall(readfile, SAVE_PATH)
        if ok and data and data ~= "" then
            return data
        end
    end
    return nil
end

local function saveKeyLocally(key)
    if not writefile then return end
    if isfolder and not isfolder(SAVE_FOLDER) then
        pcall(makefolder, SAVE_FOLDER)
    end
    pcall(writefile, SAVE_PATH, key)
    print("[Lucy Loader] Key saved locally at:", SAVE_PATH)
end

-- 🧩 โหลด key.json
local function fetch_key_data()
    local ok, res = pcall(function()
        return game:HttpGet(KEY_URL)
    end)
    if not ok or not res then
        warn("[Lucy Loader] ❌ Failed to get key.json:", res)
        return nil
    end
    local success, data = pcall(function()
        return HttpService:JSONDecode(res)
    end)
    if success and data and data.keys then
        print("[Lucy Loader] ✅ Loaded keys from GitHub (" .. #data.keys .. ")")
        return data.keys
    else
        warn("[Lucy Loader] ⚠️ Invalid JSON format in key.json")
        return nil
    end
end

-- 🧩 ตรวจสอบ key / hwid / expire
local function verify_key(keyList, enteredKey, userHWID)
    if not keyList then return false, "no_data" end

    for _, item in ipairs(keyList) do
        if item.key == enteredKey then
            if item.hwid ~= userHWID then
                return false, "hwid_mismatch"
            end

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
            else
                return false, "invalid_expire"
            end
        end
    end

    return false, "invalid_key"
end

-- 🧩 โหลดและรัน TEST.lua
local function load_main_script()
    print("[Lucy Loader] Fetching TEST.lua...")
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

-- 🧩 สร้าง UI
local function createKeyUI()
    local screen = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
    screen.Name = "Lucy_KeyUI"

    local frame = Instance.new("Frame", screen)
    frame.Size = UDim2.new(0, 340, 0, 200)
    frame.Position = UDim2.new(0.5, -170, 0.5, -100)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 36)
    title.Text = "🔑 Enter Access Key"
    title.Font = Enum.Font.GothamSemibold
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1

    local hwidLabel = Instance.new("TextLabel", frame)
    hwidLabel.Size = UDim2.new(1, -20, 0, 20)
    hwidLabel.Position = UDim2.new(0, 10, 0, 36)
    hwidLabel.Text = "HWID: " .. string.sub(hwid, 1, 16) .. "..."
    hwidLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
    hwidLabel.Font = Enum.Font.Gotham
    hwidLabel.TextSize = 12
    hwidLabel.BackgroundTransparency = 1
    hwidLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- ปุ่มคัดลอก HWID
    local copyBtn = Instance.new("TextButton", frame)
    copyBtn.Size = UDim2.new(0, 80, 0, 24)
    copyBtn.Position = UDim2.new(1, -90, 0, 34)
    copyBtn.Text = "Copy HWID"
    copyBtn.Font = Enum.Font.GothamSemibold
    copyBtn.TextSize = 12
    copyBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 6)

    copyBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(hwid)
            copyBtn.Text = "Copied!"
            task.delay(1.5, function()
                if copyBtn then copyBtn.Text = "Copy HWID" end
            end)
            print("[Lucy Loader] HWID copied:", hwid)
        else
            copyBtn.Text = "No Access"
        end
    end)

    local box = Instance.new("TextBox", frame)
    box.Size = UDim2.new(1, -40, 0, 40)
    box.Position = UDim2.new(0, 20, 0, 70)
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
    button.Position = UDim2.new(0, 20, 0, 130)
    button.Text = "Unlock"
    button.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = 16
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

    local function showNotice(msg, color)
        local lbl = Instance.new("TextLabel", frame)
        lbl.Size = UDim2.new(0, 260, 0, 30)
        lbl.Position = UDim2.new(0.5, -130, 0, -36)
        lbl.BackgroundColor3 = color or Color3.fromRGB(50, 50, 50)
        lbl.TextColor3 = Color3.new(1, 1, 1)
        lbl.Text = msg
        lbl.Font = Enum.Font.GothamSemibold
        lbl.TextSize = 14
        lbl.BackgroundTransparency = 0.1
        Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 6)
        task.delay(2.5, function()
            if lbl and lbl.Parent then lbl:Destroy() end
        end)
    end

    button.MouseButton1Click:Connect(function()
        local enteredKey = box.Text
        if enteredKey == "" then
            showNotice("⚠️ Please enter your key!", Color3.fromRGB(200, 150, 0))
            return
        end

        button.Text = "Checking..."
        button.Active = false

        local keyList = fetch_key_data()
        local ok, info = verify_key(keyList, enteredKey, hwid)

        if ok then
            saveKeyLocally(enteredKey)
            showNotice("✅ Key verified!", Color3.fromRGB(0, 200, 80))
            print("[Lucy Loader] Key valid. Expire:", info)
            task.wait(1)
            screen:Destroy()
            load_main_script()
        else
            local msg = ({
                invalid_key = "❌ Invalid Key!",
                hwid_mismatch = "⚠️ HWID Mismatch!",
                expired = "⏳ Key Expired!",
                invalid_expire = "⚠️ Invalid Expire Date",
                no_data = "⚠️ Cannot load key list!"
            })[info] or "❌ Key Error!"
            showNotice(msg, Color3.fromRGB(180, 50, 50))
            button.Text = "Unlock"
            button.Active = true
            box.Text = ""
        end
    end)
end

-- 🔄 Auto login check
local savedKey = readSavedKey()
if savedKey then
    print("[Lucy Loader] Saved key found. Auto checking...")
    local keyList = fetch_key_data()
    local ok, info = verify_key(keyList, savedKey, hwid)
    if ok then
        print("[Lucy Loader] ✅ Auto login success! Expire:", info)
        load_main_script()
        return
    else
        print("[Lucy Loader] ❌ Auto login failed:", info)
    end
end

-- แสดง UI ถ้าไม่มี key ที่ใช้ได้
createKeyUI()

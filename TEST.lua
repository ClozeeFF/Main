-- loader_encrypted.lua
-- Lucy Loader: ดาวน์โหลดไฟล์ .enc จาก GitHub, XOR ถอดรหัส, ตรวจสอบ key/hwid/expire, แจ้งเตือน, save key, load main

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPlayers()[1]
local hwiduser = game:GetService("RbxAnalyticsService"):GetClientId()

-- ========== CONFIG ==========
-- เปลี่ยนสอง URL นี้ไปยัง raw GitHub ของไฟล์ที่เข้ารหัส (.enc)
local CONFIG_URL = "https://raw.githubusercontent.com/ClozeeFF/Main/refs/heads/main/key.json.enc"
local BAZ_URL    = "https://raw.githubusercontent.com/ClozeeFF/Main/refs/heads/main/BAZ.lua.enc"

-- คีย์ที่ใช้ XOR ในการเข้ารหัส/ถอดรหัส (ต้องเหมือนกับที่ใช้ตอนเข้ารหัส)
local SECRET_KEY = "MySecretKey123"
-- ============================

-- ฟังก์ชันช่วย: XOR ถอดรหัสจาก string ของ byte
local function xor_decrypt_bytes(enc_str, key)
    -- enc_str เป็น raw string (byte values)
    local out = {}
    local klen = #key
    for i = 1, #enc_str do
        local byte = string.byte(enc_str, i)
        local k = string.byte(key, ((i-1) % klen) + 1)
        out[i] = string.char(bit32.bxor(byte, k))
    end
    return table.concat(out)
end

-- ดาวน์โหลดและถอดรหัสไฟล์ .enc เป็น plain string (pcheck)
local function fetch_and_decrypt(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if not ok then
        warn("[Lucy Loader] Failed to HttpGet:", url, res)
        return nil, res
    end
    local success, dec = pcall(function()
        return xor_decrypt_bytes(res, SECRET_KEY)
    end)
    if not success then
        warn("[Lucy Loader] Decrypt failed:", dec)
        return nil, dec
    end
    return dec
end

-- โหลดและ parse config JSON ที่ถูกถอดรหัส
local function load_config()
    local dec, err = fetch_and_decrypt(CONFIG_URL)
    if not dec then
        warn("[Lucy Loader] Cannot fetch/decrypt config:", err)
        return nil
    end
    local ok, data = pcall(function() return HttpService:JSONDecode(dec) end)
    if not ok then
        warn("[Lucy Loader] JSONDecode failed:", data)
        return nil
    end
    return data
end

-- คืนค่า true/false + info
local function checkKeyPair(data, enteredKey, hwid)
    if not data or not data.keys then return false, "no_data" end
    for _, pair in ipairs(data.keys) do
        if pair.key == enteredKey and pair.hwid == hwid then
            local expire = tostring(pair.expire or "permanent")
            if string.lower(expire) == "permanent" then
                return true, "permanent"
            end
            -- parse YYYY-MM-DD
            local y,m,d = expire:match("(%d+)%-(%d+)%-(%d+)")
            if y and m and d then
                local expireTime = os.time({year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 23, min = 59, sec = 59})
                if os.time() <= expireTime then
                    return true, expire
                else
                    return false, "expired"
                end
            else
                return false, "invalid_expire_format"
            end
        end
    end
    return false, "invalid"
end

-- ฟังก์ชันโหลดสคริปต์หลัก (BAZ) หลังถอดรหัส
local function load_main_from_github()
    local decBaz, err = fetch_and_decrypt(BAZ_URL)
    if not decBaz then
        warn("[Lucy Loader] Failed to fetch/decrypt BAZ:", err)
        return
    end
    -- ถ้า BAZ.lua มี dependence บางอย่าง ให้รันใน pcall
    local ok, e = pcall(function()
        loadstring(decBaz)()
    end)
    if not ok then
        warn("[Lucy Loader] Error running BAZ:", e)
    end
end

-- ฟังก์ชันแสดง notice หมดอายุในเกม
local function showExpireNotice(expire)
    if not expire or string.lower(expire) == "permanent" then return end
    local notice = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
    notice.Name = "Lucy_ExpireNotice"

    local label = Instance.new("TextLabel", notice)
    label.Size = UDim2.new(0, 260, 0, 36)
    label.Position = UDim2.new(1, -270, 1, -46)
    label.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
    label.BackgroundTransparency = 0.15
    label.TextColor3 = Color3.fromRGB(255, 210, 0)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 15
    label.Text = "⏳ Key Expire: " .. tostring(expire)
    label.TextStrokeTransparency = 0.8
    label.ZIndex = 9999
    local corner = Instance.new("UICorner", label)
    corner.CornerRadius = UDim.new(0, 8)

    -- หายไปหลัง 10 วินาที
    task.delay(10, function()
        if notice and notice.Parent then notice:Destroy() end
    end)
end

-- เตรียมโฟลเดอร์เก็บ key local
if makefolder and not isfolder("LucySystem") then
    pcall(makefolder, "LucySystem")
end
local savePath = "LucySystem/Key.txt"
local savedKey = (isfile and isfile(savePath)) and readfile(savePath) or nil

-- เริ่มโหลด config
local config = load_config()
if not config then
    warn("[Lucy Loader] No config loaded - aborting")
    return
end

-- ถ้ามี savedKey ให้ตรวจสอบอัตโนมัติ
if savedKey then
    local ok, info = checkKeyPair(config, savedKey, hwiduser)
    if ok then
        print("[Lucy Loader] Auto login success (saved key) expire:", tostring(info))
        showExpireNotice(info)
        load_main_from_github()
        return
    else
        if info == "expired" then
            warn("[Lucy Loader] Saved key expired")
            -- ถ้าต้องการลบไฟล์ key ทิ้งเมื่อหมดอายุ ให้เปิดคอมเมนต์บรรทัดนี้:
            -- if writefile then pcall(writefile, savePath, "") end
        else
            warn("[Lucy Loader] Saved key invalid or HWID mismatch:", info)
        end
    end
end

-- สร้าง UI ให้กรอก key ถ้ายังไม่มี key ที่ใช้ได้
local screen = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screen.Name = "Lucy_KeySystem"

local frame = Instance.new("Frame", screen)
frame.Size = UDim2.new(0, 320, 0, 150)
frame.Position = UDim2.new(0.5, -160, 0.5, -75)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderSizePixel = 0
frame.Active = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 36)
title.Position = UDim2.new(0, 0, 0, 6)
title.Text = "🔑 Enter Access Key"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamSemibold
title.TextSize = 18

local box = Instance.new("TextBox", frame)
box.Size = UDim2.new(1, -24, 0, 40)
box.Position = UDim2.new(0, 12, 0, 46)
box.PlaceholderText = "Your key here..."
box.Text = ""
box.ClearTextOnFocus = true
box.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
box.TextColor3 = Color3.fromRGB(255, 255, 255)
box.Font = Enum.Font.Gotham
box.TextSize = 16
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

local button = Instance.new("TextButton", frame)
button.Size = UDim2.new(1, -24, 0, 36)
button.Position = UDim2.new(0, 12, 0, 98)
button.Text = "Unlock"
button.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.GothamSemibold
button.TextSize = 16
Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)

local function checkAndLogin()
    local enteredKey = box.Text
    if enteredKey == "" then
        box.PlaceholderText = "Please enter a key!"
        return
    end
    button.Text = "Checking..."
    button.Active = false

    local ok, info = checkKeyPair(config, enteredKey, hwiduser)
    if ok then
        print("[Lucy Loader] Key valid (expire: ".. tostring(info) ..")")
        if writefile then
            pcall(writefile, savePath, enteredKey)
            print("[Lucy Loader] Saved key to:", savePath)
        end
        -- แสดง notice ถ้ามี expire
        showExpireNotice(info)
        -- ซ่อน UI และโหลดสคริปต์
        if screen and screen.Parent then screen:Destroy() end
        load_main_from_github()
    else
        if info == "expired" then
            button.Text = "Expired"
            task.wait(1.4)
            button.Text = "Unlock"
            button.Active = true
            warn("[Lucy Loader] Provided key expired")
        else
            button.Text = "Invalid Key"
            task.wait(1.4)
            button.Text = "Unlock"
            button.Active = true
            warn("[Lucy Loader] Provided key invalid or HWID mismatch:", info)
        end
    end
end

button.MouseButton1Click:Connect(checkAndLogin)
box.FocusLost:Connect(function(enter)
    if enter then checkAndLogin() end
end)

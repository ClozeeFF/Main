-- Lucy HWID Loader (Fixed Version)
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Analytics = game:GetService("RbxAnalyticsService")

local player = Players.LocalPlayer
local hwid = Analytics:GetClientId()

local KEY_URL  = "https://raw.githubusercontent.com/ClozeeFF/Main/main/key.json"
local MAIN_URL = "https://raw.githubusercontent.com/ClozeeFF/Main/main/BAZ.lua"
local savePath = "LucySystem/Auth.txt"
if makefolder and not isfolder("LucySystem") then pcall(makefolder, "LucySystem") end

-- รองรับ executor ทุกแบบ
local function httpGet(url)
	local ok, res = pcall(function()
		if syn and syn.request then
			return syn.request({Url=url, Method="GET"}).Body
		elseif http_request then
			return http_request({Url=url, Method="GET"}).Body
		else
			return game:HttpGet(url)
		end
	end)
	return ok and res or nil
end

-- โหลด key.json
local function getData()
	local res = httpGet(KEY_URL)
	if not res then return nil end
	local s, d = pcall(function() return HttpService:JSONDecode(res).keys end)
	return s and d or nil
end

-- ตรวจ HWID
local function validHWID(keys)
	for _, v in ipairs(keys or {}) do
		if v.hwid == hwid then
			local e = tostring(v.expire or "permanent")
			if e == "permanent" then return true end
			local y,m,d = e:match("(%d+)%-(%d+)%-(%d+)")
			if y and os.time() <= os.time({year=y,month=m,day=d,hour=23,min=59,sec=59}) then return true end
		end
	end
end

-- โหลด TEST.lua
local function loadMain()
	local src = httpGet(MAIN_URL)
	if src and src ~= "" then
		local ok, err = pcall(function() loadstring(src)() end)
		if not ok then warn("Loader error:", err) end
	else
		warn("Failed to fetch TEST.lua")
	end
end

-- Auto Login
if isfile and isfile(savePath) and readfile(savePath) == hwid then
	loadMain()
	return
end

-- UI
local ui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
local frame = Instance.new("Frame", ui)
frame.Size = UDim2.new(0, 300, 0, 130)
frame.Position = UDim2.new(0.5, -150, 0.5, -65)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 28)
title.Text = "🔑 HWID Access"
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamSemibold
title.TextSize = 15

local box = Instance.new("TextBox", frame)
box.Size = UDim2.new(1, -30, 0, 34)
box.Position = UDim2.new(0, 15, 0, 40)
box.Text = hwid
box.ClearTextOnFocus = false
box.BackgroundColor3 = Color3.fromRGB(40,40,40)
box.TextColor3 = Color3.new(1,1,1)
box.Font = Enum.Font.Gotham
box.TextSize = 14
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)

local btn = Instance.new("TextButton", frame)
btn.Size = UDim2.new(1, -30, 0, 30)
btn.Position = UDim2.new(0, 15, 0, 85)
btn.Text = "Check HWID"
btn.BackgroundColor3 = Color3.fromRGB(0,140,255)
btn.TextColor3 = Color3.new(1,1,1)
btn.Font = Enum.Font.GothamSemibold
btn.TextSize = 14
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

btn.MouseButton1Click:Connect(function()
	btn.Text = "Checking..."
	btn.Active = false
	local ok = validHWID(getData())
	if ok then
		if writefile then pcall(writefile, savePath, hwid) end
		ui:Destroy()
		loadMain()
	else
		btn.Text = "Denied"
		task.wait(1.3)
		btn.Text = "Check HWID"
		btn.Active = true
	end
end)

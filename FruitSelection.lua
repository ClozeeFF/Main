local FruitSelection = {}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Hardcoded Fruit Data with emojis
local FruitData = {
    Strawberry = {
        Name = "Strawberry",
        Price = "5,000",
        Icon = "🍓",
        Rarity = 1,
        FeedValue = 600
    }
}

-- UI Variables
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui = nil
local MainFrame = nil
local selectedItems = {}
local isDragging = false
local dragStart = nil
local startPos = nil
local isMinimized = false
local originalSize = nil
local minimizedSize = nil
local searchText = ""

-- Callback functions
local onSelectionChanged = nil
local onToggleChanged = nil

-- macOS Dark Theme Colors
local colors = {
    background = Color3.fromRGB(18, 18, 20), -- Darker background for better contrast
    surface = Color3.fromRGB(32, 32, 34), -- Lighter surface for cards
    primary = Color3.fromRGB(0, 122, 255), -- Brighter blue accent
    secondary = Color3.fromRGB(88, 86, 214), -- Purple accent
    text = Color3.fromRGB(255, 255, 255), -- Pure white text
    textSecondary = Color3.fromRGB(200, 200, 200), -- Brighter gray text
    textTertiary = Color3.fromRGB(150, 150, 150), -- Medium gray for placeholders
    border = Color3.fromRGB(50, 50, 52), -- Slightly darker border
    selected = Color3.fromRGB(0, 122, 255), -- Bright blue for selected
    hover = Color3.fromRGB(45, 45, 47), -- Lighter hover state
    close = Color3.fromRGB(255, 69, 58), -- Red close button
    minimize = Color3.fromRGB(255, 159, 10), -- Yellow minimize
    maximize = Color3.fromRGB(48, 209, 88) -- Green maximize
}

-- Utility Functions
local function formatNumber(num)
    if type(num) == "string" then
        return num
    end
    if num >= 1e12 then
        return string.format("%.1fT", num / 1e12)
    elseif num >= 1e9 then
        return string.format("%.1fB", num / 1e9)
    elseif num >= 1e6 then
        return string.format("%.1fM", num / 1e6)
    elseif num >= 1e3 then
        return string.format("%.1fK", num / 1e3)
    else
        return tostring(num)
    end
end

local function getRarityColor(rarity)
    if rarity >= 6 then return Color3.fromRGB(255, 45, 85) -- Ultra pink
    elseif rarity >= 5 then return Color3.fromRGB(255, 69, 58) -- Legendary red
    elseif rarity >= 4 then return Color3.fromRGB(175, 82, 222) -- Epic purple
    elseif rarity >= 3 then return Color3.fromRGB(88, 86, 214) -- Rare blue
    elseif rarity >= 2 then return Color3.fromRGB(48, 209, 88) -- Uncommon green
    else return Color3.fromRGB(174, 174, 178) -- Common gray
    end
end

-- Price parsing function
local function parsePrice(priceStr)
    if type(priceStr) == "number" then
        return priceStr
    end
    -- Remove commas and convert to number
    local cleanPrice = priceStr:gsub(",", "")
    return tonumber(cleanPrice) or 0
end

-- Sort data by price (low to high)
local function sortDataByPrice(data)
    local sortedData = {}
    for id, item in pairs(data) do
        table.insert(sortedData, {id = id, data = item})
    end
    
    table.sort(sortedData, function(a, b)
        local priceA = parsePrice(a.data.Price)
        local priceB = parsePrice(b.data.Price)
        return priceA < priceB
    end)
    
    return sortedData
end

-- Filter data by search text
local function filterDataBySearch(data, searchText)
    if searchText == "" then
        return data
    end
    
    local filteredData = {}
    local searchLower = string.lower(searchText)
    
    for id, item in pairs(data) do
        local nameLower = string.lower(item.Name)
        if string.find(nameLower, searchLower, 1, true) then
            filteredData[id] = item
        end
    end
    
    return filteredData
end

-- Create macOS Style Window Controls
    -- Close Button (Red)

    -- Minimize Button (Yellow)
    
    -- Maximize Button (Green)

-- Create Item Card (macOS style)
local function createItemCard(itemId, itemData, parent)
    local card = Instance.new("TextButton")
    card.Name = itemId
    card.Size = UDim2.new(0.33, -8, 0, 120)
    card.BackgroundColor3 = colors.surface
    card.BorderSizePixel = 0
    card.Text = ""
    card.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = colors.border
    stroke.Thickness = 1
    stroke.Parent = card
    
    -- Create Icon (TextLabel for emoji)
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 50, 0, 50)
    icon.Position = UDim2.new(0.5, -25, 0.2, 0)
    icon.BackgroundTransparency = 1
    icon.Text = itemData.Icon
    icon.TextSize = 32
    icon.Font = Enum.Font.GothamBold
    icon.TextColor3 = getRarityColor(itemData.Rarity)
    icon.Parent = card
    
    local name = Instance.new("TextLabel")
    name.Name = "Name"
    name.Size = UDim2.new(1, -16, 0, 20)
    name.Position = UDim2.new(0, 8, 0.6, 0)
    name.BackgroundTransparency = 1
    name.Text = itemData.Name
    name.TextSize = 12
    name.Font = Enum.Font.GothamSemibold
    name.TextColor3 = colors.text
    name.TextXAlignment = Enum.TextXAlignment.Center
    name.TextWrapped = true
    name.Parent = card
    
    local price = Instance.new("TextLabel")
    price.Name = "Price"
    price.Size = UDim2.new(1, -16, 0, 16)
    price.Position = UDim2.new(0, 8, 0.8, 0)
    price.BackgroundTransparency = 1
    price.Text = "$" .. itemData.Price
    price.TextSize = 10
    price.Font = Enum.Font.Gotham
    price.TextColor3 = colors.textSecondary
    price.TextXAlignment = Enum.TextXAlignment.Center
    price.TextWrapped = true
    price.Parent = card
    
    local checkmark = Instance.new("TextLabel")
    checkmark.Name = "Checkmark"
    checkmark.Size = UDim2.new(0, 20, 0, 20)
    checkmark.Position = UDim2.new(1, -24, 0, 4)
    checkmark.BackgroundTransparency = 1
    checkmark.Text = "✓"
    checkmark.TextSize = 16
    checkmark.Font = Enum.Font.GothamBold
    checkmark.TextColor3 = colors.selected
    checkmark.Visible = false
    checkmark.Parent = card
    
    -- Set initial selection state
    if selectedItems[itemId] then
        checkmark.Visible = true
        card.BackgroundColor3 = colors.selected
    end
    
    -- Hover effect
    card.MouseEnter:Connect(function()
        if not selectedItems[itemId] then
            TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = colors.hover}):Play()
        end
    end)
    
    card.MouseLeave:Connect(function()
        if not selectedItems[itemId] then
            TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = colors.surface}):Play()
        end
    end)
    
    -- Click effect
    card.MouseButton1Click:Connect(function()
        if selectedItems[itemId] then
            selectedItems[itemId] = nil
            checkmark.Visible = false
            TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = colors.surface}):Play()
        else
            selectedItems[itemId] = true
            checkmark.Visible = true
            TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = colors.selected}):Play()
        end
        
        if onSelectionChanged then
            onSelectionChanged(selectedItems)
        end
    end)
    
    return card
end

-- Create Search Bar (macOS style)

-- Create UI
function FruitSelection.CreateUI()
    if ScreenGui then
        ScreenGui:Destroy()
    end
    
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FruitSelectionUI"
    ScreenGui.Parent = PlayerGui
    
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 600, 0, 400)
    MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    MainFrame.BackgroundColor3 = colors.background
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    -- Window Controls
    local windowControls = createWindowControls(MainFrame)
    
    -- Title

    -- Search Bar
    
    -- Content Area


    
    -- Window Control Events

    
    -- Dragging - Fixed to work properly

    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            
            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDragging = false
                    connection:Disconnect()
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and isDragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    return ScreenGui
end

-- Refresh Content
function FruitSelection.RefreshContent()
    if not ScreenGui then return end
    
    local scrollFrame = ScreenGui.MainFrame.Content.ScrollFrame
    if not scrollFrame then return end
    
    -- Clear existing content
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- Filter by search
    local filteredData = filterDataBySearch(FruitData, searchText)
    
    -- Sort by price (low to high)
    local sortedData = sortDataByPrice(filteredData)
    
    -- Add content
    for i, item in ipairs(sortedData) do
        local card = createItemCard(item.id, item.data, scrollFrame)
        card.LayoutOrder = i -- Ensure proper ordering
        
        -- Apply saved selection state
        if selectedItems[item.id] then
            local checkmark = card:FindFirstChild("Checkmark")
            if checkmark then
                checkmark.Visible = true
            end
            card.BackgroundColor3 = colors.selected
        end
    end
end

-- Public Functions
function FruitSelection.Show(callback, toggleCallback, savedFruits)
    onSelectionChanged = callback
    onToggleChanged = toggleCallback
    
    -- Apply saved selections if provided
    if savedFruits then
        for fruitId, _ in pairs(savedFruits) do
            selectedItems[fruitId] = true
        end
    end
    
    if not ScreenGui then
        FruitSelection.CreateUI()
    end
    
    -- Wait a frame to ensure UI is created
    task.wait()
    FruitSelection.RefreshContent()
    ScreenGui.Enabled = true
    ScreenGui.Parent = PlayerGui
end

function FruitSelection.Hide()
    if ScreenGui then
        ScreenGui.Enabled = false
    end
end

function FruitSelection.GetSelectedItems()
    return selectedItems
end

function FruitSelection.IsVisible()
    return ScreenGui and ScreenGui.Enabled
end

function FruitSelection.GetCurrentSelections()
    return selectedItems
end

function FruitSelection.UpdateSelections(fruits)
    selectedItems = {}
    
    if fruits then
        for fruitId, _ in pairs(fruits) do
            selectedItems[fruitId] = true
        end
    end
    
    if ScreenGui then
        FruitSelection.RefreshContent()
    end
end

return FruitSelection

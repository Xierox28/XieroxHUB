local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

pcall(function()
    if writefile then
        writefile("XieroxHUB/MyGamingCafe_Logs.txt", "[XieroxHUB Log Started]\n")
    end
end)

local LogParagraph = nil
local logHistory = {}
local function log(message)
    local timestamp = os.date("%H:%M:%S")
    local formatted = string.format("[%s] %s", timestamp, tostring(message))
    pcall(function()
        if appendfile then
            appendfile("XieroxHUB/MyGamingCafe_Logs.txt", formatted .. "\n")
        elseif writefile and readfile then
            local existing = ""
            pcall(function() existing = readfile("XieroxHUB/MyGamingCafe_Logs.txt") or "" end)
            writefile("XieroxHUB/MyGamingCafe_Logs.txt", existing .. formatted .. "\n")
        end
    end)
end

log("Initializing core script wrapper...")

local initSuccess, initError = pcall(function()
    local Window = Fluent:CreateWindow({
        Title = "XieroxHUB | My Gaming Cafe",
        SubTitle = "v1.0.0",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = false,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.RightControl
    })

    Fluent:ToggleTransparency(false)

    local Tabs = {
        Main = Window:AddTab({ Title = "Autofarm", Icon = "sparkles" }),
        Player = Window:AddTab({ Title = "Player Settings", Icon = "user" }),
        Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
    }

    local Options = Fluent.Options

    Tabs.Main:AddParagraph({
        Title = "Autofarm Panel",
        Content = "Configure automation functions for My Gaming Cafe."
    })

    getgenv().XieroxConfig = {
        AutoSpin = false,
        AutoTake = false,
        AutoTrash = false,
        AutoUpgrade = false,
        MinRarity = 1
    }

    local AutoSpinToggle = Tabs.Main:AddToggle("AutoSpinToggle", {Title = "Auto Spin Wheels", Default = false })
    local AutoTakeToggle = Tabs.Main:AddToggle("AutoTakeToggle", {Title = "Auto Take & Place Spun Items", Default = false })
    local AutoTrashToggle = Tabs.Main:AddToggle("AutoTrashToggle", {Title = "Auto Trash Held Items", Default = false })
    local AutoUpgradeToggle = Tabs.Main:AddToggle("AutoUpgradeToggle", {Title = "Auto Buy Upgrades", Default = false })

    local MinRarityInput = Tabs.Main:AddInput("MinRarityInput", {
        Title = "Min Rarity to Keep/Place (1 in X)",
        Default = "1",
        Placeholder = "Type minimum rarity (e.g. 50)",
        Numeric = true,
        Finished = true,
        Callback = function(Value)
            local val = tonumber(Value) or 1
            getgenv().XieroxConfig.MinRarity = val
            log("Min Rarity set to " .. tostring(val))
        end
    })

    AutoSpinToggle:OnChanged(function(value)
        getgenv().XieroxConfig.AutoSpin = value
        log("Auto Spin set to " .. tostring(value))
    end)

    AutoTakeToggle:OnChanged(function(value)
        getgenv().XieroxConfig.AutoTake = value
        log("Auto Take set to " .. tostring(value))
    end)

    AutoTrashToggle:OnChanged(function(value)
        getgenv().XieroxConfig.AutoTrash = value
        log("Auto Trash set to " .. tostring(value))
    end)

    AutoUpgradeToggle:OnChanged(function(value)
        getgenv().XieroxConfig.AutoUpgrade = value
        log("Auto Upgrade set to " .. tostring(value))
    end)

    local WalkSpeed = Tabs.Player:AddSlider("WalkSpeedSlider", {
        Title = "WalkSpeed",
        Min = 16,
        Max = 150,
        Default = 16,
        Rounding = 1,
        Callback = function(Value)
            pcall(function()
                game:GetService("Players").LocalPlayer.Character.Humanoid.WalkSpeed = Value
            end)
        end
    })

    local JumpPower = Tabs.Player:AddSlider("JumpPowerSlider", {
        Title = "JumpPower",
        Min = 50,
        Max = 300,
        Default = 50,
        Rounding = 1,
        Callback = function(Value)
            pcall(function()
                game:GetService("Players").LocalPlayer.Character.Humanoid.JumpPower = Value
            end)
        end
    })

    local ToggleKeybind = Tabs.Settings:AddKeybind("ToggleUIKeybind", {
        Title = "Toggle UI Keybind",
        Mode = "Toggle",
        Default = "RightControl",
        ChangedCallback = function(New)
            Window.MinimizeKey = New
            log("Toggle UI keybind changed to: " .. tostring(New))
        end
    })
    Tabs.Settings:AddButton({
        Title = "Unload Script",
        Description = "Completely closes the script interface.",
        Callback = function()
            Fluent:Destroy()
        end
    })

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local UpgradesService = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.UpgradesService.RF
    local SpinService = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.SpinService.RF
    local TableService = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.TableService.RF

    local ItemData = {
        ["Basic PC"] = {Chance = 2, Type = "PC"},
        ["Office PC"] = {Chance = 3, Type = "PC"},
        ["Basic Monitor"] = {Chance = 2, Type = "Monitor"},
        ["Office Monitor"] = {Chance = 3, Type = "Monitor"},
        ["Basic Keyboard & Mouse"] = {Chance = 2, Type = "Keyboard"},
        ["Office Keyboard & Mouse"] = {Chance = 3, Type = "Keyboard"}
    }

    local function parseChance(text)
        if not text then return 0 end
        text = string.gsub(text, ",", "")
        local numbers = {}
        for num in string.gmatch(text, "%d+") do
            table.insert(numbers, tonumber(num))
        end
        if #numbers >= 2 then
            return numbers[2]
        elseif #numbers == 1 then
            return numbers[1]
        end
        return 0
    end

    local function cleanPrice(txt)
        if not txt then return nil end
        local lower = txt:lower()
        local multiplier = 1
        if string.find(lower, "k") then
            multiplier = 1000
        elseif string.find(lower, "m") then
            multiplier = 1000000
        elseif string.find(lower, "b") then
            multiplier = 1000000000
        elseif string.find(lower, "t") then
            multiplier = 1000000000000
        end
        local clean = string.gsub(txt, "[^%d.]", "")
        local localDecimal = tostring(0.5):match("[^%d]") or "."
        if localDecimal ~= "." then
            clean = string.gsub(clean, "%.", localDecimal)
        end
        local num = tonumber(clean)
        if num then
            return num * multiplier
        end
        return nil
    end

    local function getButtonCost(btn)
        if not btn then return nil end
        local bestCost = nil
        for _, child in ipairs(btn:GetChildren()) do
            if child:IsA("TextLabel") then
                local txt = child.Text
                local cost = cleanPrice(txt)
                log(string.format("Button %s child %s text: '%s' | Parsed: %s", btn.Name, child.Name, txt, tostring(cost)))
                if cost and (not bestCost or cost > bestCost) then
                    bestCost = cost
                end
            end
        end
        if bestCost then return bestCost end
        local label = btn:FindFirstChildOfClass("TextLabel")
        if label then
            return cleanPrice(label.Text)
        end
        return nil
    end

    local function getUpgradeCost(button, siblingName)
        if not button then return nil end
        local cost = getButtonCost(button)
        if cost then return cost end
        local parent = button.Parent
        if parent and siblingName then
            local sibling = parent:FindFirstChild(siblingName)
            if sibling then
                local amountLabel = sibling:FindFirstChild("AmountText") or sibling:FindFirstChildOfClass("TextLabel")
                if amountLabel then
                    return cleanPrice(amountLabel.Text)
                end
            end
        end
        return nil
    end

    local function getItemType(name)
        if not name then return "PC" end
        name = name:lower()
        if string.find(name, "monitor") or string.find(name, "screen") or string.find(name, "display") then
            return "Monitor"
        elseif string.find(name, "keyboard") or string.find(name, "mouse") or string.find(name, "kb") then
            return "Keyboard"
        else
            return "PC"
        end
    end

    local function cleanItemName(name, itemType)
        if not name then return "" end
        name = string.gsub(name, "%s*1%s*in%s*%d+", "")
        name = string.gsub(name, "%s*1%s*In%s*%d+", "")
        name = string.gsub(name, "%s*1%s*IN%s*%d+", "")
        name = string.gsub(name, "[^%a%d%s]", "")
        local lower = name:lower()
        if itemType == "PC" then
            if string.sub(lower, -3) == " pc" then name = string.sub(name, 1, -4) end
            if string.sub(lower, -9) == " computer" then name = string.sub(name, 1, -10) end
        elseif itemType == "Monitor" then
            if string.sub(lower, -8) == " monitor" then name = string.sub(name, 1, -9) end
            if string.sub(lower, -7) == " screen" then name = string.sub(name, 1, -8) end
            if string.sub(lower, -8) == " display" then name = string.sub(name, 1, -9) end
        elseif itemType == "Keyboard" then
            if string.find(lower, "keyboard & mouse") then
                name = string.gsub(name, "%s*[Kk][Ee][Yy][Bb][Oo][Aa][Rr][Dd]%s*&%s*[Mm][Oo][Uu][Ss][Ee]%s*", "")
                name = string.gsub(name, "%s*[Kk][Ee][Yy][Bb][Oo][Aa][Rr][Dd]%s*[Mm][Oo][Uu][Ss][Ee]%s*", "")
            end
            if string.find(lower, "keyboard") then name = string.gsub(name, "%s*[Kk][Ee][Yy][Bb][Oo][Aa][Rr][Dd]%s*", "") end
            if string.find(lower, "mouse") then name = string.gsub(name, "%s*[Mm][Oo][Uu][Ss][Ee]%s*", "") end
        end
        name = string.match(name, "^%s*(.-)%s*$")
        return name
    end

    local function getLogicalTableKey(tableModel)
        if not tableModel then return nil end
        local tableId = string.match(tableModel.Name, "%d+")
        if tableId then
            return "Table" .. tableId
        end
        return nil
    end

    local cachedTables = nil
    local lastCacheTime = 0

    local function inspectTable(tbl, maxDepth, currentDepth)
        if not tbl then return "nil" end
        if type(tbl) ~= "table" then return tostring(tbl) end
        maxDepth = maxDepth or 2
        currentDepth = currentDepth or 0
        if currentDepth > maxDepth then return "{...}" end
        local parts = {}
        for k, v in pairs(tbl) do
            local keyStr = tostring(k)
            local valStr = ""
            if type(v) == "table" then
                valStr = inspectTable(v, maxDepth, currentDepth + 1)
            else
                valStr = tostring(v)
            end
            table.insert(parts, keyStr .. " = " .. valStr)
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end

    local function getTableData()
        local now = os.clock()
        if not cachedTables or (now - lastCacheTime > 1.5) then
            pcall(function()
                cachedTables = TableService.GetTables:InvokeServer()
                lastCacheTime = now
                if cachedTables then
                    log("Updated server tables cache: " .. inspectTable(cachedTables, 2))
                end
            end)
        end
        return cachedTables
    end

    local function invalidateTableCache()
        cachedTables = nil
    end

    local function getGameDataFolder()
        local rep = game:GetService("ReplicatedStorage")
        local gameData = rep:FindFirstChild("GameData")
        if not gameData then
            local utility = rep:FindFirstChild("Utility")
            if utility then
                gameData = utility:FindFirstChild("GameData")
            end
        end
        return gameData
    end

    local cachedGameData = {}
    local function getItemChance(itemType, itemName)
        local cleanedName = cleanItemName(itemName, itemType)
        local dataModule = nil
        pcall(function()
            local gameData = getGameDataFolder()
            if gameData then
                if itemType == "PC" then
                    dataModule = gameData:FindFirstChild("PCsData")
                elseif itemType == "Monitor" then
                    dataModule = gameData:FindFirstChild("MonitorsData")
                elseif itemType == "Keyboard" then
                    dataModule = gameData:FindFirstChild("KeyboardMouseData")
                end
            end
        end)
        if dataModule then
            local data = cachedGameData[dataModule]
            if not data then
                local ok, res = pcall(require, dataModule)
                if ok and type(res) == "table" then
                    cachedGameData[dataModule] = res
                    data = res
                end
            end
            if data then
                local searchName = cleanedName:lower()
                local rawName = itemName:lower()
                for k, val in pairs(data) do
                    local lowerK = k:lower()
                    if lowerK == searchName or lowerK == rawName or string.find(lowerK, searchName) or string.find(searchName, lowerK) then
                        local chance = nil
                        if type(val) == "table" then
                            chance = val.Chance or val.Rarity or val.chance or val.rarity
                        elseif type(val) == "number" then
                            chance = val
                        end
                        if chance then
                            return chance
                        end
                    end
                end
            end
        end
        local hardcodedKey = cleanedName
        if itemType == "PC" then
            hardcodedKey = cleanedName .. " PC"
        elseif itemType == "Monitor" then
            hardcodedKey = cleanedName .. " Monitor"
        elseif itemType == "Keyboard" then
            hardcodedKey = cleanedName .. " Keyboard & Mouse"
        end
        if ItemData[hardcodedKey] then
            return ItemData[hardcodedKey].Chance or 0
        end
        local parsedChance = parseChance(itemName)
        if parsedChance > 0 then
            return parsedChance
        end
        return 0
    end

    local function getItemCashValue(itemType, itemName)
        local cleanedName = cleanItemName(itemName, itemType)
        local dataModule = nil
        pcall(function()
            local gameData = getGameDataFolder()
            if gameData then
                if itemType == "PC" then
                    dataModule = gameData:FindFirstChild("PCsData")
                elseif itemType == "Monitor" then
                    dataModule = gameData:FindFirstChild("MonitorsData")
                elseif itemType == "Keyboard" then
                    dataModule = gameData:FindFirstChild("KeyboardMouseData")
                end
            end
        end)
        if dataModule then
            local data = cachedGameData[dataModule]
            if not data then
                local ok, res = pcall(require, dataModule)
                if ok and type(res) == "table" then
                    cachedGameData[dataModule] = res
                    data = res
                end
            end
            if data then
                local searchName = cleanedName:lower()
                local rawName = itemName:lower()
                for k, val in pairs(data) do
                    local lowerK = k:lower()
                    if lowerK == searchName or lowerK == rawName or string.find(lowerK, searchName) or string.find(searchName, lowerK) then
                        local cash = nil
                        if type(val) == "table" then
                            local tblInfo = {}
                            for subk, subv in pairs(val) do
                                table.insert(tblInfo, tostring(subk) .. "=" .. tostring(subv))
                            end
                            log(string.format("Item data for %s: {%s}", k, table.concat(tblInfo, ", ")))
                            for subk, subv in pairs(val) do
                                local sk = tostring(subk):lower()
                                if sk == "cash" or sk == "income" or sk == "gives" or sk == "value" or sk == "multiplier" or sk == "multi" or string.find(sk, "cash") or string.find(sk, "income") then
                                    cash = tonumber(subv)
                                    if cash then break end
                                end
                            end
                        elseif type(val) == "number" then
                            cash = val
                        end
                        if cash then
                            return cash
                        end
                    end
                end
            end
        end
        return 0
    end

    local function getPlacedItemCashValue(tableModel, slotType)
        local tableKey = getLogicalTableKey(tableModel)
        if not tableKey then return 0 end
        local serverTables = getTableData()
        if type(serverTables) == "table" then
            local tData = serverTables[tableKey]
            if tData and type(tData) == "table" then
                local itemName = nil
                for k, v in pairs(tData) do
                    if type(v) == "string" then
                        local itemType = getItemType(k) or getItemType(v)
                        if itemType == slotType then
                            itemName = v
                            break
                        end
                    end
                end
                if itemName then
                    local val = getItemCashValue(slotType, itemName)
                    if val > 0 then return val end
                    return getItemChance(slotType, itemName)
                end
            end
        end
        return 0
    end


    local function clickButton(btn)
        if not btn then return false end
        local clicked = false
        pcall(function()
            if getconnections then
                local fired = false
                for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do
                    conn:Fire()
                    fired = true
                end
                for _, conn in ipairs(getconnections(btn.MouseButton1Down)) do
                    conn:Fire()
                    fired = true
                end
                for _, conn in ipairs(getconnections(btn.Activated)) do
                    conn:Fire()
                    fired = true
                end
                if fired then
                    clicked = true
                end
            end
        end)
        return clicked
    end

    local function clickHomeButton()
        pcall(function()
            local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            if playerGui then
                for _, desc in ipairs(playerGui:GetDescendants()) do
                    if desc:IsA("ImageButton") or desc:IsA("TextButton") then
                        if string.lower(desc.Name) == "home" or (desc:FindFirstChildOfClass("TextLabel") and string.lower(desc:FindFirstChildOfClass("TextLabel").Text) == "home") then
                            log("Simulating Home button click to locate Plot...")
                            clickButton(desc)
                            break
                        end
                    end
                end
            end
        end)
    end

    local function isMyPlot(plot)
        for _, attr in ipairs({"Owner", "OwnerId", "UserId", "Player", "OwnerName"}) do
            local val = plot:GetAttribute(attr)
            if val == LocalPlayer.Name or val == LocalPlayer.UserId or tostring(val) == tostring(LocalPlayer.UserId) then
                return true
            end
        end
        return false
    end

    local cachedPlot = nil
    local function getMyPlot()
        if cachedPlot and isMyPlot(cachedPlot) then return cachedPlot end
        for _, plot in ipairs(workspace.Main.Plots:GetChildren()) do
            if isMyPlot(plot) then
                cachedPlot = plot
                log("Plot detected and cached by ownership attribute: " .. plot.Name)
                return plot
            end
        end
        log("Plot not found by ownership attribute. Simulating Home button click...")
        clickHomeButton()
        task.wait(1.0)
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local minDist = math.huge
            local closestPlot = nil
            for _, plot in ipairs(workspace.Main.Plots:GetChildren()) do
                local middle = plot:FindFirstChild("MiddlePart") or plot:FindFirstChild("SpinButton")
                if middle then
                    local part = middle:IsA("Model") and middle:FindFirstChild("Button") or middle
                    if part then
                        local dist = (hrp.Position - part.Position).Magnitude
                        if dist < minDist then
                            minDist = dist
                            closestPlot = plot
                        end
                    end
                end
            end
            if closestPlot and minDist < 150 then
                cachedPlot = closestPlot
                log(string.format("Plot detected and cached by Home proximity: %s (Distance: %.1f studs)", closestPlot.Name, minDist))
                return closestPlot
            end
        end
        return nil
    end

    pcall(function()
        log("=== Plot Diagnostics ===")
        for _, plot in ipairs(workspace.Main.Plots:GetChildren()) do
            local attrs = {}
            for _, name in ipairs({"Owner", "OwnerId", "UserId", "Player", "OwnerName"}) do
                local val = plot:GetAttribute(name)
                if val ~= nil then
                    table.insert(attrs, name .. "=" .. tostring(val))
                end
            end
            local plotUI = plot:FindFirstChild("MiddlePart") and plot.MiddlePart:FindFirstChild("PlotUI")
            local nameText = plotUI and plotUI:FindFirstChild("NameText") and plotUI.NameText.Text or "nil"
            log(string.format("Plot: %s | Attributes: %s | NameText: '%s'", plot.Name, table.concat(attrs, ", "), nameText))
        end
        log("========================")
    end)


    local function getPlacedItemChance(tableModel, slotType)
        local tableKey = getLogicalTableKey(tableModel)
        if not tableKey then return 0 end
        local serverTables = getTableData()
        if type(serverTables) == "table" then
            local tData = serverTables[tableKey]
            if tData and type(tData) == "table" then
                local itemName = nil
                for k, v in pairs(tData) do
                    if type(v) == "string" then
                        local itemType = getItemType(k) or getItemType(v)
                        if itemType == slotType then
                            itemName = v
                            break
                        end
                    end
                end
                if itemName then
                    return getItemChance(slotType, itemName)
                end
            end
        end
        return 0
    end

    local function firePromptAt(prompt)
        if not prompt then return end
        pcall(function()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local targetPart = prompt.Parent
                if targetPart then
                    local targetCFrame = targetPart:GetPivot()
                    local dist = (hrp.Position - targetCFrame.Position).Magnitude
                    local maxDist = prompt.MaxActivationDistance or 10
                    if dist > maxDist then
                        log(string.format("Prompt too far (%d studs). Teleporting near %s", math.floor(dist), targetPart.Name))
                        hrp.CFrame = targetCFrame + Vector3.new(0, 2, 0)
                        task.wait(0.35)
                    end
                end
            end
            fireproximityprompt(prompt)
            task.wait(0.1)
        end)
    end

    local function triggerUpgrade(upgradeData)
        local clicked = clickButton(upgradeData.Button)
        if clicked then
            log(string.format("Successfully clicked button for upgrade: %s", upgradeData.Name))
        else
            log(string.format("Click connection failed or getconnections unsupported. Invoking remote for %s...", upgradeData.Name))
            if upgradeData.Remote then
                local success, result = pcall(function()
                    return upgradeData.Remote:InvokeServer()
                end)
                log(string.format("Remote invocation result for %s: success = %s | result = %s", upgradeData.Name, tostring(success), tostring(result)))
            end
        end
    end

    local function getHeldItemInfo(heldModel)
        local name, chance, itemType = nil, nil, nil
        local ok, heldData = pcall(function()
            return SpinService.GetHeldItem:InvokeServer()
        end)
        if ok and heldData then
            if type(heldData) == "table" then
                name = heldData.Name or heldData.ItemName or heldData.ID
                local rawChance = heldData.Chance or heldData.Rarity
                if type(rawChance) == "string" then
                    chance = parseChance(rawChance)
                else
                    chance = rawChance
                end
                itemType = heldData.Type or heldData.ItemType or heldData.Category or heldData.Slot
            elseif type(heldData) == "string" then
                name = heldData
            end
        end
        if not name then
            local nameLabel = heldModel:FindFirstChild("NameText", true) or heldModel:FindFirstChild("Name", true)
            local chanceLabel = heldModel:FindFirstChild("ChanceText", true) or heldModel:FindFirstChild("Chance", true)
            if nameLabel then name = nameLabel.Text end
            if chanceLabel then chance = parseChance(chanceLabel.Text) end
        end
        local detectedType = "PC"
        local foundType = false
        if itemType then
            detectedType = getItemType(itemType)
            foundType = true
        elseif name then
            local lowerName = name:lower()
            if string.find(lowerName, "monitor") or string.find(lowerName, "screen") or string.find(lowerName, "display") then
                detectedType = "Monitor"
                foundType = true
            elseif string.find(lowerName, "keyboard") or string.find(lowerName, "mouse") or string.find(lowerName, "kb") then
                detectedType = "Keyboard"
                foundType = true
            elseif string.find(lowerName, "pc") or string.find(lowerName, "computer") or string.find(lowerName, "case") then
                detectedType = "PC"
                foundType = true
            end
        end
        if not foundType then
            for _, child in ipairs(heldModel:GetChildren()) do
                if child:IsA("MeshPart") or child:IsA("Part") then
                    local meshName = child.Name:lower()
                    if string.find(meshName, "monitor") or string.find(meshName, "screen") or string.find(meshName, "display") then
                        detectedType = "Monitor"
                        foundType = true
                        break
                    elseif string.find(meshName, "keyboard") or string.find(meshName, "mouse") or string.find(meshName, "kb") then
                        detectedType = "Keyboard"
                        foundType = true
                        break
                    elseif string.find(meshName, "pc") or string.find(meshName, "computer") or string.find(meshName, "case") then
                        detectedType = "PC"
                        foundType = true
                        break
                    end
                end
            end
        end
        if not name then
            for _, child in ipairs(heldModel:GetChildren()) do
                if child:IsA("MeshPart") or child:IsA("Part") then
                    local cleanName = string.gsub(child.Name, "%.%d+", "")
                    for k, v in pairs(ItemData) do
                        if string.find(k:lower(), cleanName:lower()) or string.find(cleanName:lower(), k:lower()) then
                            name = k
                            chance = v.Chance
                            break
                        end
                    end
                end
                if name then break end
            end
        end
        local cashVal = 0
        if name then
            if not chance then
                chance = getItemChance(detectedType, name)
            end
            cashVal = getItemCashValue(detectedType, name)
            if cashVal == 0 then cashVal = chance end
        end
        return name, chance, detectedType, cashVal
    end

    local function isMatchingPrompt(desc, heldType)
        if not desc:IsA("ProximityPrompt") then return false end
        local act = desc.ActionText:lower()
        local obj = desc.ObjectText:lower()
        local name = desc.Name:lower()
        if heldType == "PC" then
            return string.find(act, "pc") or string.find(act, "computer") or string.find(act, "case") or
                   string.find(obj, "pc") or string.find(obj, "computer") or string.find(obj, "case") or
                   string.find(name, "pc") or string.find(name, "computer") or string.find(name, "case")
        elseif heldType == "Monitor" then
            return string.find(act, "monitor") or string.find(act, "screen") or string.find(act, "display") or
                   string.find(obj, "monitor") or string.find(obj, "screen") or string.find(obj, "display") or
                   string.find(name, "monitor") or string.find(name, "screen") or string.find(name, "display")
        elseif heldType == "Keyboard" then
            return string.find(act, "keyboard") or string.find(act, "mouse") or string.find(act, "kb") or
                   string.find(obj, "keyboard") or string.find(obj, "mouse") or string.find(obj, "kb") or
                   string.find(name, "keyboard") or string.find(name, "mouse") or string.find(name, "kb")
        end
        return false
    end

    local function getUpgradeCosts(myPlot)
        local costs = {}
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not playerGui then return costs end

        if getgenv().XieroxConfig.AutoUpgrade then
            local upgradesUI = playerGui:FindFirstChild("UpgradesUI")
            if upgradesUI then
                local luckBtn = upgradesUI:FindFirstChild("UpgradeLuck")
                local cashBtn = upgradesUI:FindFirstChild("UpgradeCash")
                local luckCost = getUpgradeCost(luckBtn, "LuckImage")
                local cashCost = getUpgradeCost(cashBtn, "CashImage")
                if luckCost then table.insert(costs, {Cost = luckCost, Remote = UpgradesService.UpgradeLuckMultiplier, Button = luckBtn, Name = "LuckMultiplier"}) end
                if cashCost then table.insert(costs, {Cost = cashCost, Remote = UpgradesService.UpgradeCashMultiplier, Button = cashBtn, Name = "CashMultiplier"}) end
            end
            local spinUI = playerGui:FindFirstChild("SpinUpgradesUI")
            if spinUI then
                local luckBtn = spinUI:FindFirstChild("UpgradeLuck")
                local padBtn = spinUI:FindFirstChild("UpgradePad")
                local luckCost = getUpgradeCost(luckBtn, "LuckImage")
                local padCost = getUpgradeCost(padBtn, "PadImage")
                if luckCost then table.insert(costs, {Cost = luckCost, Remote = SpinService.UpgradeLuck, Button = luckBtn, Name = "SpinLuck"}) end
                if padCost then table.insert(costs, {Cost = padCost, Remote = SpinService.UnlockSpinPad, Button = padBtn, Name = "UnlockSpinPad"}) end
            end
        end
        return costs
    end

    local function autoUnlockTables()
        pcall(function()
            local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            if playerGui then
                local worldUIs = playerGui:FindFirstChild("WorldUIs")
                if worldUIs then
                    for _, child in ipairs(worldUIs:GetChildren()) do
                        if child.Enabled and string.find(child.Name, "UnlockUI_") and child:IsA("BillboardGui") then
                            local unlockBtn = child:FindFirstChild("UnlockButton")
                            if unlockBtn then
                                log("Auto Unboxing/Unlocking component: " .. child.Name)
                                clickButton(unlockBtn)
                                child.Enabled = false
                                local tableName, slotName = string.match(child.Name, "UnlockUI_(.+)_([^_]+)$")
                                if tableName and slotName then
                                    task.spawn(pcall, function()
                                        TableService.UnlockComponent:InvokeServer(tableName, slotName)
                                        invalidateTableCache()
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end

    local function isSlotLocked(tableName, slotName)
        local locked = false
        pcall(function()
            local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            local worldUIs = playerGui and playerGui:FindFirstChild("WorldUIs")
            if worldUIs then
                local uiName = "UnlockUI_" .. tableName .. "_" .. slotName
                local ui = worldUIs:FindFirstChild(uiName)
                if ui and ui.Enabled then
                    locked = true
                end
            end
        end)
        return locked
    end

    task.spawn(function()
        while task.wait(0.5) do
            autoUnlockTables()
        end
    end)

    local actionLocked = false
    local lastLoggedHeldItem = nil

    task.spawn(function()
        while task.wait(0.5) do
            if not actionLocked and (getgenv().XieroxConfig.AutoSpin or getgenv().XieroxConfig.AutoTake) then
                local myPlot = getMyPlot()
                if myPlot then
                    local char = LocalPlayer.Character
                    local held = char and char:FindFirstChild("HeldItem")
                    if held then
                        local heldName, heldChance, heldType, heldCashVal = getHeldItemInfo(held)
                        if heldName and heldChance then
                            log(string.format("Holding: %s (%d) | Value: %d | Type: %s", heldName, tonumber(heldChance) or 0, heldCashVal, heldType))
                            local targetTable = nil
                            local targetSlotPart = nil
                            local lowestPlacedCashVal = math.huge
                            local serverTables = getTableData()
                            local minRarity = tonumber(getgenv().XieroxConfig.MinRarity) or 1
                            local heldChanceVal = tonumber(heldChance) or 0
                            local tableKey = nil
                            local slotName = nil
                            if heldChanceVal >= minRarity then
                                for _, building in ipairs(myPlot.Buildings:GetChildren()) do
                                    if string.find(building.Name, "Table") and building:GetAttribute("Unlocked") == true then
                                        local tKey = getLogicalTableKey(building)
                                        if serverTables and serverTables[tKey] then
                                            local slotPart = nil
                                            local sName = nil
                                            if heldType == "PC" then
                                                slotPart = building:FindFirstChild("Positions") and building.Positions:FindFirstChild("PCs")
                                                sName = "PCs"
                                            elseif heldType == "Monitor" then
                                                slotPart = building:FindFirstChild("Positions") and building.Positions:FindFirstChild("Monitors")
                                                sName = "Monitors"
                                            elseif heldType == "Keyboard" then
                                                slotPart = building:FindFirstChild("Positions") and building.Positions:FindFirstChild("KeyboardMouse")
                                                sName = "KeyboardMouse"
                                            end
                                            if slotPart and sName and not isSlotLocked(tKey, sName) then
                                                local currentCashVal = getPlacedItemCashValue(building, heldType)
                                                if heldCashVal > currentCashVal and currentCashVal < lowestPlacedCashVal then
                                                    targetTable = building
                                                    targetSlotPart = slotPart
                                                    tableKey = tKey
                                                    slotName = sName
                                                    lowestPlacedCashVal = currentCashVal
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            if targetSlotPart then
                                local tableId = string.match(targetTable.Name, "%d+") or targetTable.Name
                                log(string.format("Target Table: %s (Current Value: %d)", tableId, lowestPlacedCashVal))
                                actionLocked = true
                                lastLoggedHeldItem = nil
                                local hrp = char:FindFirstChild("HumanoidRootPart")
                                if hrp then
                                    hrp.CFrame = targetSlotPart:GetPivot() + Vector3.new(0, 2, 0)
                                    task.wait(0.25)
                                end
                                if tableKey and slotName then
                                    log(string.format("Invoking ReplaceComponent for %s, slot %s", tableKey, slotName))
                                    task.spawn(pcall, function()
                                        TableService.ReplaceComponent:InvokeServer(tableKey, slotName)
                                    end)
                                end
                                task.spawn(function()
                                    local start = os.clock()
                                    while char:FindFirstChild("HeldItem") and os.clock() - start < 1.0 do
                                        local prompt = targetSlotPart:FindFirstChildOfClass("ProximityPrompt") or targetSlotPart:FindFirstChild("ReplacePrompt", true) or targetSlotPart:FindFirstChild("PlacePrompt", true)
                                        if not prompt then
                                            for _, desc in ipairs(targetTable:GetDescendants()) do
                                                if isMatchingPrompt(desc, heldType) then
                                                    prompt = desc
                                                    break
                                                end
                                            end
                                        end
                                        if prompt then
                                            fireproximityprompt(prompt)
                                        end
                                        task.wait(0.1)
                                    end
                                    local placementSucceeded = false
                                    if not char:FindFirstChild("HeldItem") then
                                        placementSucceeded = true
                                        pcall(function()
                                            if cachedTables and cachedTables[tableKey] then
                                                cachedTables[tableKey][slotName] = cleanItemName(heldName, heldType)
                                                log(string.format("Locally updated cache: %s.%s = %s", tableKey, slotName, cachedTables[tableKey][slotName]))
                                            end
                                        end)
                                    end
                                    if not placementSucceeded then
                                        invalidateTableCache()
                                    end
                                    actionLocked = false
                                    log("Placement action completed.")
                                end)
                            else
                                if lastLoggedHeldItem ~= heldName then
                                    log("No table needs this item as an upgrade.")
                                    lastLoggedHeldItem = heldName
                                end
                                if getgenv().XieroxConfig.AutoTrash then
                                    actionLocked = true
                                    log("Trashing held item via remote...")
                                    task.spawn(pcall, function()
                                        SpinService.TrashHeld:InvokeServer()
                                    end)
                                    task.spawn(function()
                                        local start = os.clock()
                                        while char:FindFirstChild("HeldItem") and os.clock() - start < 1.0 do
                                            task.wait(0.1)
                                        end
                                        actionLocked = false
                                        log("Trash action completed.")
                                    end)
                                end
                            end
                        else
                            log("Warning: Failed to parse held item name or chance.")
                        end
                    else
                        local best = nil
                        if getgenv().XieroxConfig.AutoTake and myPlot:FindFirstChild("SpinPads") then
                            local candidates = {}
                            for _, pad in ipairs(myPlot.SpinPads:GetChildren()) do
                                local takePrompt = pad:FindFirstChild("OutPart") and pad.OutPart:FindFirstChild("TakePrompt")
                                local infoUI = pad:FindFirstChild("OutPart") and pad.OutPart:FindFirstChild("InfoUI")
                                if takePrompt and takePrompt.Enabled and infoUI and infoUI:FindFirstChild("InfoFrame") then
                                    local nameText = infoUI.InfoFrame.NameText.Text
                                    local chanceText = infoUI.InfoFrame.ChanceText.Text
                                    local chance = parseChance(chanceText)
                                    local itemType = getItemType(nameText)
                                    local padItemCashVal = getItemCashValue(itemType, nameText)
                                    if padItemCashVal == 0 then padItemCashVal = chance end
                                    local isUpgrade = false
                                    local targetTable = nil
                                    local targetSlotPart = nil
                                    local tableKey = nil
                                    local slotName = nil
                                    local currentCashValVal = 0
                                    local serverTables = getTableData()
                                    local minRarity = tonumber(getgenv().XieroxConfig.MinRarity) or 1
                                    local chanceVal = tonumber(chance) or 0
                                    if chanceVal >= minRarity then
                                        for _, building in ipairs(myPlot.Buildings:GetChildren()) do
                                            if string.find(building.Name, "Table") and building:GetAttribute("Unlocked") == true then
                                                local tKey = getLogicalTableKey(building)
                                                if serverTables and serverTables[tKey] then
                                                    local sPart = nil
                                                    local sName = nil
                                                    if itemType == "PC" then
                                                        sPart = building:FindFirstChild("Positions") and building.Positions:FindFirstChild("PCs")
                                                        sName = "PCs"
                                                    elseif itemType == "Monitor" then
                                                        sPart = building:FindFirstChild("Positions") and building.Positions:FindFirstChild("Monitors")
                                                        sName = "Monitors"
                                                    elseif itemType == "Keyboard" then
                                                        sPart = building:FindFirstChild("Positions") and building.Positions:FindFirstChild("KeyboardMouse")
                                                        sName = "KeyboardMouse"
                                                    end
                                                    if sPart and sName and not isSlotLocked(tKey, sName) then
                                                        local currentCashVal = getPlacedItemCashValue(building, itemType)
                                                        if padItemCashVal > currentCashVal then
                                                            if currentCashVal < currentCashValVal or not targetTable then
                                                                targetTable = building
                                                                targetSlotPart = sPart
                                                                tableKey = tKey
                                                                slotName = sName
                                                                currentCashValVal = currentCashVal
                                                                isUpgrade = true
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                    if isUpgrade then
                                        table.insert(candidates, {
                                            Pad = pad,
                                            Prompt = takePrompt,
                                            Chance = chance,
                                            ItemType = itemType,
                                            Name = nameText,
                                            Current = currentCashValVal,
                                            CashVal = padItemCashVal,
                                            TargetTable = targetTable,
                                            TargetSlotPart = targetSlotPart,
                                            TableKey = tableKey,
                                            SlotName = slotName
                                        })
                                    end
                                end
                            end
                            if #candidates > 0 then
                                table.sort(candidates, function(a, b)
                                    return a.CashVal > b.CashVal
                                end)
                                best = candidates[1]
                            end
                        end
                        if best then
                            log(string.format("Best Pad Upgrade: %s (%d) | Type: %s | Target: %s -> %s (Current: %d)", best.Name, best.Chance, best.ItemType, best.TableKey, best.SlotName, best.Current))
                            actionLocked = true
                            firePromptAt(best.Prompt)
                            task.spawn(function()
                                local start = os.clock()
                                local heldItem = nil
                                while os.clock() - start < 1.5 do
                                    heldItem = char:FindFirstChild("HeldItem")
                                    if heldItem then break end
                                    task.wait(0.05)
                                end
                                if heldItem then
                                    log("Successfully picked up item. Teleporting to target slot...")
                                    local hrp = char:FindFirstChild("HumanoidRootPart")
                                    if hrp and best.TargetSlotPart then
                                        hrp.CFrame = best.TargetSlotPart:GetPivot() + Vector3.new(0, 2, 0)
                                        task.wait(0.25)
                                    end
                                    log(string.format("Invoking ReplaceComponent for %s, slot %s", best.TableKey, best.SlotName))
                                    task.spawn(pcall, function()
                                        TableService.ReplaceComponent:InvokeServer(best.TableKey, best.SlotName)
                                    end)
                                    local pStart = os.clock()
                                    while char:FindFirstChild("HeldItem") and os.clock() - pStart < 1.0 do
                                        local prompt = best.TargetSlotPart:FindFirstChildOfClass("ProximityPrompt") or best.TargetSlotPart:FindFirstChild("ReplacePrompt", true) or best.TargetSlotPart:FindFirstChild("PlacePrompt", true)
                                        if not prompt then
                                            for _, desc in ipairs(best.TargetTable:GetDescendants()) do
                                                if isMatchingPrompt(desc, best.ItemType) then
                                                    prompt = desc
                                                    break
                                                end
                                            end
                                        end
                                        if prompt then
                                            fireproximityprompt(prompt)
                                        end
                                        task.wait(0.1)
                                    end
                                    local placementSucceeded = false
                                    if not char:FindFirstChild("HeldItem") then
                                        placementSucceeded = true
                                        pcall(function()
                                            if cachedTables and cachedTables[best.TableKey] then
                                                cachedTables[best.TableKey][best.SlotName] = cleanItemName(best.Name, best.ItemType)
                                                log(string.format("Locally updated cache: %s.%s = %s", best.TableKey, best.SlotName, cachedTables[best.TableKey][best.SlotName]))
                                            end
                                        end)
                                    end
                                    if not placementSucceeded then
                                        invalidateTableCache()
                                    end
                                    log("Placement action completed.")
                                else
                                    log("Failed to pick up item within timeout.")
                                end
                                actionLocked = false
                            end)
                        elseif getgenv().XieroxConfig.AutoSpin then
                            local totalPads = 0
                            local occupiedPads = 0
                            if myPlot:FindFirstChild("SpinPads") then
                                for _, pad in ipairs(myPlot.SpinPads:GetChildren()) do
                                    local takePrompt = pad:FindFirstChild("OutPart") and pad.OutPart:FindFirstChild("TakePrompt")
                                    if takePrompt then
                                        totalPads = totalPads + 1
                                        if takePrompt.Enabled then
                                            occupiedPads = occupiedPads + 1
                                        end
                                    end
                                end
                            end
                            if occupiedPads < totalPads then
                                local spinPrompt = myPlot:FindFirstChild("SpinButton") and myPlot.SpinButton:FindFirstChild("Button") and myPlot.SpinButton.Button:FindFirstChild("SpinPrompt")
                                if spinPrompt then
                                    fireproximityprompt(spinPrompt)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    task.spawn(function()
        while task.wait(1.5) do
            if getgenv().XieroxConfig.AutoUpgrade then
                local myPlot = getMyPlot()
                if myPlot then
                    local upgrades = getUpgradeCosts(myPlot)
                    if #upgrades > 0 then
                        table.sort(upgrades, function(a, b)
                            return a.Cost < b.Cost
                        end)
                        local cheapest = upgrades[1]
                        local cashVal = LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Cash")
                        local cash = cashVal and cashVal.Value or 0
                        if cash >= cheapest.Cost then
                            log(string.format("Buying cheapest: %s (Cost: %d) | Current Cash: %d", cheapest.Name, cheapest.Cost, cash))
                            triggerUpgrade(cheapest)
                            task.wait(0.5)
                        end
                    end
                end
            end
        end
    end)

    task.spawn(function()
        while task.wait(5.0) do
            pcall(function()
                local mainRF = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.MainService.RF
                mainRF.ClaimGroupReward:InvokeServer()
            end)
            pcall(function()
                local dataRF = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.DataService.RF
                dataRF.ClaimOffline:InvokeServer()
            end)
        end
    end)
end)

if not initSuccess then
    log("CRITICAL SCRIPT RUNTIME ERROR: " .. tostring(initError))
end

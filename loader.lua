local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

local GITHUB_RAW = "https://raw.githubusercontent.com/Xierox28/XieroxHUB/main/"

local Games = {
    ["MyGamingCafe"] = {
        PlaceIds = {
            101736964164901
        },
        Name = "My Gaming Cafe",
        Load = function()
            local success, err = pcall(function()
                local content = nil
                pcall(function()
                    if readfile then
                        content = readfile("XieroxHUB/games/MyGamingCafe/main.lua")
                    end
                end)
                if not content or content == "" then
                    content = game:HttpGet(GITHUB_RAW .. "games/MyGamingCafe/main.lua")
                end
                if content and content ~= "" then
                    loadstring(content)()
                else
                    error("Could not fetch script content")
                end
            end)
            if not success then
                warn("[XieroxHUB] Loading warning: " .. tostring(err))
            end
        end
    }
}

local function Init()
    print("====================================")
    print("Welcome to XieroxHUB!")
    print("Initializing system...")
    print("Current PlaceId: " .. tostring(PlaceId))
    print("====================================")
    
    local found = false
    for _, gameData in pairs(Games) do
        if table.find(gameData.PlaceIds, PlaceId) then
            gameData.Load()
            found = true
            break
        end
    end
    
    if not found then
        warn("[XieroxHUB] Unsupported game! Loading Universal script...")
        local success, err = pcall(function()
            local content = nil
            pcall(function()
                if readfile then
                    content = readfile("XieroxHUB/games/Universal.lua")
                end
            end)
            if not content or content == "" then
                content = game:HttpGet(GITHUB_RAW .. "games/Universal.lua")
            end
            if content and content ~= "" then
                loadstring(content)()
            else
                error("Could not fetch Universal script")
            end
        end)
        if not success then
            warn("[XieroxHUB] Failed to load Universal script: " .. tostring(err))
        end
    end
end

task.spawn(Init)

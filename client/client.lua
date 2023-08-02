--- For more support join this discord where i can help you with you're issues and accept new idea's for it!
--- https://discord.gg/PwZuYuFUqC

local ESXClient = exports['es_extended']:getSharedObject()

---@type number
local currentRestaurantId
local LastPickupFood
local GetEntityCoords = GetEntityCoords
local PlayerPedId = PlayerPedId
local IsControlJustReleased = IsControlJustReleased
local DrawMarker = DrawMarker
local Config = Config
local Locales = Locales
local Wait = Wait
local CreateThread = Citizen.CreateThread
local TriggerServerEvent = TriggerServerEvent
local RegisterNetEvent = RegisterNetEvent
local GetScreenCoordFromWorldCoord = GetScreenCoordFromWorldCoord
local DrawSprite = DrawSprite
local SetTextCentre = SetTextCentre
local SetTextScale = SetTextScale
local SetTextEntry = SetTextEntry
local AddTextComponentString = AddTextComponentString
local DrawText = DrawText
local RequestStreamedTextureDict = RequestStreamedTextureDict
local table = table
local ipairs = ipairs
local pairs = pairs
local math = math
local ceil = math.ceil
local insert = table.insert
local icon_scale = 1.0
local text_scale = 0.25

---@param coords Vector3
---@param label string
---@param meters number
local function drawPickupMarker(coords, label, meters)
    local _, screenX, screenY = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
    RequestStreamedTextureDict("basejumping", false)
    DrawSprite("basejumping", "arrow_pointer", screenX, screenY - 0.015, 0.015 * icon_scale, 0.025 * icon_scale, 180.0, 102, 204, 255, 255)
    SetTextCentre(true)
    SetTextScale(0.0, text_scale)
    SetTextEntry("STRING")
    AddTextComponentString(label .. "\n" .. meters .. "m")
    DrawText(screenX, screenY)
end

local function openMenu()
    local restaurantId <const> = currentRestaurantId
    if not restaurantId then
        return
    end
    local restaurant <const> = Config.Restaurants[restaurantId]

    ---@type MenuOption[]
    local options <const> = {}

    for itemId, menuOption in ipairs(restaurant.menu) do
        insert(options, {
            label = menuOption.label,
            description = menuOption.description,
            value = menuOption.item,
            price = menuOption.price,
            time = menuOption.waitTime,
            itemId = itemId
        })
    end

    lib.registerMenu({
        id = 'RestaurantMenu',
        title = restaurant.name,
        position = 'top-right',
        onSelected = function(selected, secondary, args)
        end,
        options = options
    },
    function(selected, scrollIndex, args)
        if type(selected) == 'number' and selected ~= 0 then
            local selectedOption = options[(--[[---@type number]]selected)]
            if selectedOption then
                local itemId = selectedOption.itemId
                TriggerServerEvent("US_Restaurant:takeMoney", restaurantId, itemId)
                collectgarbage()
            end
        end
    end)

    lib.showMenu('RestaurantMenu')
end


-- fixme: refactor this loop later: create a resource for smart marker management
CreateThread(function()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = math.maxinteger
    local delay = 1000
    local r, g, b = 64, 64, 64
    ---@type Vector3
    local rCoords
    ---@type Vector3
    local pickupCoords
    while true do
        playerCoords = GetEntityCoords(PlayerPedId())
        delay = 1000
        for restaurantId, restaurant in pairs(Config.Restaurants) do
            rCoords = restaurant.rCoords
            pickupCoords = restaurant.pickupCoords
            distance = #(playerCoords - rCoords)
            if distance <= 3.0 then
                delay = 1
                if distance <= 1.0 then
                    r, g, b = 64, 64, 64
                    currentRestaurantId = restaurantId
                    LastPickupFood = pickupCoords
                    if IsControlJustReleased(0, 38) then
                        openMenu()
                    end
                else
                    r, g, b = 102, 204, 255
                    currentRestaurantId = 0
                end
                DrawMarker(6, rCoords.x, rCoords.y, rCoords.z - 1.0, 0, 0, 0.1, 0, 0, 0, 1.2, 1.2, 1.2, r, g, b, 0.8, false, false, 0, false)
                goto continue
            end
        end
        :: continue ::
        Wait(delay)
    end
end)

---@param restaurantId number
---@param itemId number
---@param time number
local function prepareFood(restaurantId, itemId, time)
    Wait(time)
    CreateThread(function()
        ---@type Vector3
        local pCoords
        local dist = 0
        local meters = 0
        while true do
            pCoords = GetEntityCoords(PlayerPedId())
            dist = #(LastPickupFood - pCoords)
            meters = ceil(dist * 1)

            drawPickupMarker(LastPickupFood, Locales['Main']['TakeOrder'], meters)

            if dist <= 1.0 and IsControlJustReleased(0, 38) then
                ---@type promise<boolean>
                local p = promise.new()
                ESXClient.TriggerServerCallback('US_Restaurant:giveItem', function(result)
                    p:resolve(result)
                end, restaurantId, itemId)
                local result = Citizen.Await(p)
                if result then
                    -- hide the marker, item has been taken
                    break
                end
            elseif dist > 10 then
                Wait(1000)
            else
                Wait(1)
            end
        end
    end)
end

RegisterNetEvent('US_Restaurant:prepareFood', prepareFood)
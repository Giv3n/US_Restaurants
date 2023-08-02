--- For more support join this discord where i can help you with you're issues and accept new idea's for it!
--- https://discord.gg/PwZuYuFUqC

ESX = exports['es_extended']:getSharedObject()
local currentRestaurant = nil
local LastPickupFood = nil

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        local playerCoords = GetEntityCoords(PlayerPedId())
        for _, restaurant in pairs(Config.Restaurants) do
            local distance = #(playerCoords - restaurant.rcoords)
            if distance <= 3.0 then
                DrawMarker(6, restaurant.rcoords.x, restaurant.rcoords.y, restaurant.rcoords.z-1.0, 0, 0, 0.1, 0, 0, 0, 1.2, 1.2, 1.2, 64, 64, 64, 0.8, 0, 0, 0, 0)
                if distance <= 1.0 then
                    DrawMarker(6, restaurant.rcoords.x, restaurant.rcoords.y, restaurant.rcoords.z-1.0, 0, 0, 0.1, 0, 0, 0, 1.2, 1.2, 1.2, 102, 204, 255, 0.8, 0, 0, 0, 0)
                    currentRestaurant = restaurant
                    LastPickupFood = restaurant.pickupcoords
                    if IsControlJustReleased(0, 38) then
                        OpenMenu()
                    end
                else
                    currentRestaurant = nil
                end
            end
        end
    end
end) 

RegisterNetEvent('US_Restaurant:PrepareFood')
AddEventHandler('US_Restaurant:PrepareFood', function(value, time)
    Wait(time)
    local pickupfood = true
    Citizen.CreateThread(function()
        while pickupfood == true do
            local pcoords = GetEntityCoords(PlayerPedId())
            local dist = #(LastPickupFood - pcoords)
            local meters = math.ceil(dist * 1)

            DrawDestination(LastPickupFood, Locales['Main']['TakeOrder'], meters)
            if dist <= 1.0 and IsControlJustReleased(0, 38) then
                pickupfood = false
                TriggerServerEvent('US_Restaurant:GiveItem', value)
            end
            Wait(1)
        end
    end)

end)

function DrawDestination(coords, label, meters)
    local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
    local icon_scale = 1.0
    local text_scale = 0.25
    RequestStreamedTextureDict("basejumping", false)
    DrawSprite("basejumping", "arrow_pointer", screenX, screenY - 0.015, 0.015 * icon_scale, 0.025 * icon_scale, 180.0, 102, 204, 255, 255)
    SetTextCentre(true)
    SetTextScale(0.0, text_scale)
    SetTextEntry("STRING")
    AddTextComponentString(label .. "\n".. meters .. "m")
    DrawText(screenX, screenY)
end

function OpenMenu()

    local restaurant = currentRestaurant

    local restaurantData = nil
    for _, r in pairs(Config.Restaurants) do
        if r.Name == restaurant.Name then
            restaurantData = r
            break
        end
    end

    local options = {}

    for _, menuOption in ipairs(restaurantData.menu) do
        table.insert(options, {
            label = menuOption.label,
            description = menuOption.description,
            value = menuOption.item,
            price = menuOption.price,
            time = menuOption.WaitTime
        })
    end

    lib.registerMenu({
        id = 'RestaurantMenu',
        title = restaurant.Name,
        position = 'top-right',
        onSelected = function(selected, secondary, args)
        end,
        options = options
    }, function(selected, scrollIndex, args)
        if selected then
            local selectedOption = options[selected]
            if selectedOption then
                local value = selectedOption.value
                local label = selectedOption.label
                local price = selectedOption.price
                local time = selectedOption.time
                TriggerServerEvent("US_Restaurant:TakeMoney", label, value, price, time)
            end
        end
    end)

    lib.showMenu('RestaurantMenu')
end






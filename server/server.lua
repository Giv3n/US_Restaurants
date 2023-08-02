--- For more support join this discord where i can help you with you're issues and accept new idea's for it!
--- https://discord.gg/PwZuYuFUqC

local ESXServer <const> = exports['es_extended']:getSharedObject()

local RegisterNetEvent = RegisterNetEvent
local TriggerClientEvent = TriggerClientEvent
local type = type

local Config = Config

---@type table<Player, table<string, number>
local pendingTakeItem <const> = {}

---@param restaurantId number
---@param itemId number
local function takeMoney(restaurantId, itemId)
    local _source <const> = source
    local xPlayer <const> = ESXServer.GetPlayerFromId(source)

    local item <const> = Config.Restaurants[restaurantId].menu[itemId]
    local price <const> = item.price
    local itemName <const> = item.item
    local time <const> = item.waitTime

    local money <const> = xPlayer.getMoney()

    if money >= price then
        xPlayer.removeMoney(price)
        TriggerClientEvent('ox_lib:notify', source, { description = Locales['Main']['OrderPreparing'], type = 'success' })

        if pendingTakeItem[_source] == nil then
            pendingTakeItem[_source] = {}
        end

        if type(pendingTakeItem[_source][itemName]) ~= 'number' then
            pendingTakeItem[_source][itemName] = 1
        else
            pendingTakeItem[_source][itemName] = pendingTakeItem[_source][itemName] + 1
        end
        TriggerClientEvent("US_Restaurant:prepareFood", source, restaurantId, itemId, time)
    else
        local rest <const> = price - money
        TriggerClientEvent('ox_lib:notify', source, { description = Locales['Main']['MissingMoney']:format(rest), type = 'success' })
    end

end

---@param source Player
---@param cb fun(success: boolean): void
---@param restaurantId number
---@param itemId number
local function giveItem(source, cb, restaurantId, itemId)
    local xPlayer <const> = ESXServer.GetPlayerFromId(source)

    if Config.Restaurants[restaurantId] == nil then
        return
    end
    if Config.Restaurants[restaurantId].menu[itemId] == nil then
        return
    end

    local item <const> = Config.Restaurants[restaurantId].menu[itemId]
    local itemName <const> = item.item

    if pendingTakeItem[source] == nil then
        return
    end
    if pendingTakeItem[source][itemName] == nil then
        return
    end
    if pendingTakeItem[source][itemName] <= 0 then
        return
    end

    if xPlayer.canCarryItem(itemName, 1) then
        pendingTakeItem[source][itemName] = pendingTakeItem[source][itemName] - 1
        xPlayer.addInventoryItem(itemName, 1)
        cb(true)
    else
        TriggerClientEvent('ox_lib:notify', source, { description = Locales['Main']['NoSpaceInInventory'], type = 'error' })
        cb(false)
    end
end

RegisterNetEvent('US_Restaurant:takeMoney', takeMoney)
ESXServer.RegisterServerCallback('US_Restaurant:giveItem', giveItem)
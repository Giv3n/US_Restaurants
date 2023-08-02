--- For more support join this discord where i can help you with you're issues and accept new idea's for it!
--- https://discord.gg/PwZuYuFUqC

ESX = exports['es_extended']:getSharedObject()


RegisterNetEvent('US_Restaurant:TakeMoney')
AddEventHandler('US_Restaurant:TakeMoney', function(label, value, price, time)
   local xPlayer = ESX.GetPlayerFromId(source)

   local pmoney = xPlayer.getMoney()
   local rest = price - pmoney

   
    if pmoney >= price then
        xPlayer.removeMoney(price)
        TriggerClientEvent('ox_lib:notify', source, { description = Locales['Main']['OrderPreparing'], type = 'success' })
        TriggerClientEvent("US_Restaurant:PrepareFood", source, value, time)
    else
        TriggerClientEvent('ox_lib:notify', source, { description = Locales['Main']['MissingMoney']:format(rest), type = 'success' })
    end

end)


RegisterNetEvent('US_Restaurant:GiveItem')
AddEventHandler('US_Restaurant:GiveItem', function(value)
    local xPlayer = ESX.GetPlayerFromId(source)


    if xPlayer.canCarryItem(value, 1) then
        xPlayer.addInventoryItem(value, 1)
    else
         TriggerClientEvent('ox_lib:notify', source, { description = Locales['Main']['NoSpaceInInventory'], type = 'error' })
    end
end)

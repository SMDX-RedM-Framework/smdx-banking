local SMDXCore = exports['smdx-core']:GetSMDX()
local banking = nil

---------------------------------
-- version checker
---------------------------------
local function versionCheckPrint(_type, log)
    local color = _type == 'success' and '^2' or '^1'

    print(('^5['..GetCurrentResourceName()..']%s %s^7'):format(color, log))
end

local function CheckVersion()
    PerformHttpRequest('', function(err, text, headers)
        local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version')

        if not text then 
            versionCheckPrint('error', 'Currently unable to run a version check.')
            return 
        end

        --versionCheckPrint('success', ('Current Version: %s'):format(currentVersion))
        --versionCheckPrint('success', ('Latest Version: %s'):format(text))
        
        if text == currentVersion then
            versionCheckPrint('success', 'You are running the latest version.')
        else
            versionCheckPrint('error', ('You are currently running an outdated version, please update to version %s'):format(text))
        end
    end)
end

---------------------------------
-- callback for bank balance
---------------------------------
SMDXCore.Functions.CreateCallback('smdx-banking:getBankingInformation', function(source, cb, bankid)

    local Player = SMDXCore.Functions.GetPlayer(source)
    if not Player then return cb(nil) end

    if bankid == 'bank' then
        banking = tonumber(Player.PlayerData.money['bank'])
    end

    if bankid == 'valbank' then
        banking = tonumber(Player.PlayerData.money['valbank'])
    end

    if bankid == 'rhobank' then
        banking = tonumber(Player.PlayerData.money['rhobank'])
    end

    if bankid == 'blkbank' then
        banking = tonumber(Player.PlayerData.money['blkbank'])
    end

    if bankid == 'armbank' then
        banking = tonumber(Player.PlayerData.money['armbank'])
    end

    cb(banking)
end)

---------------------------------
-- deposit & withdraw
---------------------------------
RegisterNetEvent('smdx-banking:server:transact', function(type, amount, bankid)
    local src = source
    local Player = SMDXCore.Functions.GetPlayer(source)
    local currentCash = Player.Functions.GetMoney('cash')
    local currentBank = Player.Functions.GetMoney(bankid)

    amount = tonumber(amount)
    if amount <= 0 then
        lib.notify(src, {title = Lang:t('server.lang_1'), type = 'error'})
        return
    end

    -- bank-withdraw
    if type == 1 then
        if currentBank >= amount then
            Player.Functions.RemoveMoney(bankid, tonumber(amount), 'bank-withdraw')
            Player.Functions.AddMoney('cash', tonumber(amount), 'bank-withdraw')
            local newBankBalance = Player.Functions.GetMoney(bankid)
            TriggerClientEvent('smdx-banking:client:UpdateBanking', src, newBankBalance, bankid)
        else
            lib.notify(src, {title = Lang:t('server.lang_2'), type = 'error'})
        end
    end

    -- bank-deposit
    if type == 2 then
        if currentCash >= amount then
            Player.Functions.RemoveMoney('cash', tonumber(amount), 'bank-deposit')
            Player.Functions.AddMoney(bankid, tonumber(amount), 'bank-deposit')
            local newBankBalance = Player.Functions.GetMoney(bankid)
            TriggerClientEvent('smdx-banking:client:UpdateBanking', src, newBankBalance, bankid)
        else
            lib.notify(src, {title = Lang:t('server.lang_2'), type = 'error'})
        end
    end

    -- create moneyclip
    if type == 3 then
        if currentBank >= amount then
            local info = { money = amount }
            Player.Functions.RemoveMoney(bankid, tonumber(amount), 'bank-moneyclip')
            Player.Functions.AddItem('moneyclip', 1, false, info)
            local newBankBalance = Player.Functions.GetMoney(bankid)
            TriggerClientEvent('smdx-banking:client:UpdateBanking', src, newBankBalance, bankid)
            lib.notify({ title = Lang:t('server.lang_9'), description = Lang:t('server.lang_10')..amount..Lang:t('server.lang_11'), type = 'success' })
        else
            lib.notify(src, {title = Lang:t('server.lang_2'), type = 'error'})
        end
    end

end)

---------------------------------
-- moneyclip made usable
---------------------------------
SMDXCore.Functions.CreateUseableItem('moneyclip', function(source, item)
    local src = source
    local Player = SMDXCore.Functions.GetPlayer(src)

    if not Player then return end

    local itemData = Player.Functions.GetItemBySlot(item.slot)

    if not itemData then return end

    local amount = itemData.info.money

    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        Player.Functions.AddMoney('cash', amount)
        lib.notify({ title = Lang:t('server.lang_3'), description = Lang:t('server.lang_4')..amount..Lang:t('server.lang_5'), type = 'success' })
    end
end)

---------------------------------
-- create moneyclip command
---------------------------------
SMDXCore.Commands.Add('moneyclip', Lang:t('server.lang_6'), {{ name = 'amount', help = Lang:t('server.lang_7') }}, true, function(source, args)
    local src = source
    local args1 = tonumber(args[1])

    if args1 <= 0 then
        lib.notify({ title = Lang:t('server.lang_2'), description = Lang:t('server.lang_8'), type = 'error' })
        return
    end

    local Player = SMDXCore.Functions.GetPlayer(src)

    if not Player then return end

    local money = Player.Functions.GetMoney('cash')

    if money and money >= args1 then
        if Player.Functions.RemoveMoney('cash', args1, 'give-money') then
            local info =
            {
                money = args1
            }

            Player.Functions.AddItem('moneyclip', 1, false, info)
            lib.notify({ title = Lang:t('server.lang_9'), description = Lang:t('server.lang_10')..args1..Lang:t('server.lang_11'), type = 'success' })
        end
    end
end, 'user')

---------------------------------
-- blood moneyclip made usable
---------------------------------
SMDXCore.Functions.CreateUseableItem('bloodmoneyclip', function(source, item)
    local src = source
    local Player = SMDXCore.Functions.GetPlayer(src)

    if not Player then return end

    local itemData = Player.Functions.GetItemBySlot(item.slot)

    if not itemData then return end

    local amount = itemData.info.money

    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        Player.Functions.AddMoney('bloodmoney', amount)
        lib.notify({ title = Lang:t('server.lang_12'), description = Lang:t('server.lang_4')..amount..Lang:t('server.lang_13'), type = 'success' })
    end
end)

---------------------------------
-- create blood moneyclip command
---------------------------------
SMDXCore.Commands.Add('bloodmoneyclip', Lang:t('server.lang_14'), {{ name = 'amount', help = Lang:t('server.lang_15') }}, true, function(source, args)
    local src = source
    local args1 = tonumber(args[1])

    if args1 <= 0 then
        lib.notify({ title = Lang:t('server.lang_2'), description = Lang:t('server.lang_8'), type = 'error' })
        return
    end

    local Player = SMDXCore.Functions.GetPlayer(src)

    if not Player then return end

    local money = Player.Functions.GetMoney('bloodmoney')

    if money and money >= args1 then
        if Player.Functions.RemoveMoney('bloodmoney', args1, 'give-blood-money') then
            local info =
            {
                money = args1
            }

            Player.Functions.AddItem('bloodmoneyclip', 1, false, info)
            lib.notify({ title = Lang:t('server.lang_16'), description = Lang:t('server.lang_10')..args1..Lang:t('server.lang_17'), type = 'success' })
        end
    end
end, 'user')

---------------------------------
-- start version check
---------------------------------
CheckVersion()

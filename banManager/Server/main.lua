banManager = BanManager:new()

exports('banPlayer', function(playerId, duration, durationUnit, reason, author, _source)
    banManager:banPlayer(playerId, duration, durationUnit, reason, author, _source)
end)

exports('unbanPlayer', function(id, callback)
    banManager:unbanPlayer(id, callback)
end)

exports('checkBan', function(id, callback)
    banManager:checkBan(id, callback)
end)

banManager:checkBanOnJoin()

RegisterCommand('ban', function (source, args, raw)
    local _source = source

    if #args < 4 then
        local message = 'Utilisation: /ban [playerId] [durée] [unité] [raison]'
        if _source == 0 then
            print("[^6Soneria^7] [^1Ban^7] " .. message)
        else
            TriggerClientEvent('esx:showNotification', _source, message, 'error', 5000)
        end
        return
    end

    local playerId = tonumber(args[1])
    local duration = tonumber(args[2])
    local durationUnit = args[3]:sub(1, 1) 
    local reason = table.concat(args, " ", 4)
    local author = _source == 0 and 'Console' or GetPlayerName(_source)

    local player = ESX.GetPlayerFromId(playerId)

    if player then 
        banManager:banPlayer(playerId, duration, durationUnit, reason, author, _source)
    else
        local message = 'Aucun joueur portant l\'ID ' .. playerId .. ' n\'est connecté.'
        if _source == 0 then
            print('[^6Soneria^7] [^1Ban^7] ' .. message)
        else
            TriggerClientEvent('esx:showNotification', _source, message, 'error', 5000)
        end
    end
end)

RegisterCommand('unban', function (source, args, raw)
    local _source = source

    if #args < 1 then
        local message = 'Utilisation: /unban [Ban ID]'
        if _source == 0 then
            print("[^6Soneria^7] [^1Unban^7] " .. message)
        else
            TriggerClientEvent('esx:showNotification', _source, message, 'error', 5000)
        end
        return
    end

    local id = tonumber(args[1])

    banManager:unbanPlayer(id, function (isUnbanned)
        local message = isUnbanned and 'Le joueur a été débanni !' or 'Le Ban ID est invalide !'
        if _source == 0 then
            print("[^6Soneria^7] [^2Unban^7] " .. message)
        else
            TriggerClientEvent('esx:showNotification', _source, message, isUnbanned and 'success' or 'error', 5000)
        end
    end)
end)
print("[^6Soneria^7] [^2Modules^7] Classe '^3banManager^7' initialized !")

BanManager = {}
BanManager.__index = BanManager

function BanManager:new()
    local self = setmetatable({}, BanManager)
    return self
end

---@param playerId number
---@return table
function BanManager:getPlayerIdentifiers(playerId)
    return {
        discord_id = GetPlayerIdentifier(playerId, 1) or 'Introuvable',
        token = GetPlayerToken(playerId) or 'Introuvable',
        ip = GetPlayerEndpoint(playerId) or 'Introuvable',
        license = GetPlayerIdentifier(playerId, 0) or 'Introuvable',
        fivem_id = GetPlayerIdentifier(playerId, 2) or 'Introuvable'
    }
end

---@param title string
---@param message string
---@param footer string
---@param color number
function BanManager:sendLogs(webhook, title, message, footer, color)
    local embed = {
        {
            color = color,
            title = title,
            description = message,
            footer = { text = footer }
        }
    }

    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({username = "Ban Manager", embeds = embed}), { ['Content-Type'] = 'application/json' })
end

---@param playerId number
---@param duration number
---@param durationUnit string
---@param reason string 
---@param author string
---@param _source number
function BanManager:banPlayer(playerId, duration, durationUnit, reason, author, _source)
    local identifiers = self:getPlayerIdentifiers(playerId)
    local bannedDate = os.time()
    local durationSeconds

    if durationUnit == 'd' then
        durationSeconds = duration * 86400
    elseif durationUnit == 'h' then
        durationSeconds = duration * 3600
    else
        local message = 'Unité de durée inconnue: ' .. durationUnit
        if _source == 0 then
            print("[^6Soneria^7] [^1Ban^7] " .. message)
        else
            TriggerClientEvent('esx:showNotification', _source, message, 'error', 5000)
        end
        return
    end

    local expirationDate = bannedDate + durationSeconds

    MySQL.Async.fetchAll('SELECT * FROM ban_data WHERE discord_id = @discord_id OR token = @token OR ip = @ip OR license = @license OR fivem_id = @fivem_id', {
        ['@discord_id'] = identifiers.discord_id,
        ['@token'] = identifiers.token,
        ['@ip'] = identifiers.ip,
        ['@license'] = identifiers.license,
        ['@fivem_id'] = identifiers.fivem_id
    }, function(results)
        local isUpdating = #results > 0
        local query = isUpdating and 
            'UPDATE ban_data SET ban_reason = @reason, expiration_date = @expiration_date, banned_date = @banned_date, author = @author WHERE id = @id' or 
            'INSERT INTO ban_data (discord_id, token, ip, license, fivem_id, ban_reason, expiration_date, banned_date, author) VALUES (@discord_id, @token, @ip, @license, @fivem_id, @reason, @expiration_date, @banned_date, @author)'

        MySQL.Async.execute(query, {
            ['@discord_id'] = identifiers.discord_id,
            ['@token'] = identifiers.token,
            ['@ip'] = identifiers.ip,
            ['@license'] = identifiers.license,
            ['@fivem_id'] = identifiers.fivem_id,
            ['@reason'] = reason,
            ['@expiration_date'] = expirationDate,
            ['@banned_date'] = bannedDate,
            ['@author'] = author,
            ['@id'] = isUpdating and results[1].id or nil
        })

        local timeMessage = self:formatTime(expirationDate - os.time())
        local durationMessage = string.format("%d %s", duration, durationUnit == 'd' and 'jour(s)' or 'heure(s)')
        
        self:sendLogs(Config.Logs.Ban, "Nouveau Banissement", ("Auteur: %s \n Temps: %s \n Banni: %s \n Raison: %s"):format(author, durationMessage, '<@' .. identifiers.discord_id:gsub("^discord:", "") .. '>', reason), 'Soneria Banissement', 16711680)

        local feedbackMessage = isUpdating and 
            "Le joueur " .. playerId .. " est déjà banni, mise à jour du bannissement." or
            "Le joueur " .. playerId .. " a été banni pour " .. durationMessage .. ". Temps restant: " .. timeMessage .. "."

        if _source == 0 then
            print("[^6Soneria^7] [^2Ban^7] " .. feedbackMessage)
        else
            TriggerClientEvent('esx:showNotification', _source, feedbackMessage, 'error', 5000)
        end

        DropPlayer(playerId, "Vous venez d'être banni de Soneria Rôleplay ! \nRaison: " .. reason .. "\nAuteur: " .. author .. "\nTemps restant: " .. timeMessage)
    end)
end

---@param seconds number
---@return string
function BanManager:formatTime(seconds)
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%d jours, %d heures, %d minutes et %d secondes", days, hours, minutes, secs)
end

function BanManager:checkBanOnJoin()
    AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
        local identifiers = self:getPlayerIdentifiers(source)

        deferrals.defer()

        MySQL.Async.fetchAll('SELECT * FROM ban_data WHERE discord_id = @discord_id OR token = @token OR ip = @ip OR license = @license OR fivem_id = @fivem_id', {
            ['@discord_id'] = identifiers.discord_id,
            ['@token'] = identifiers.token,
            ['@ip'] = identifiers.ip,
            ['@license'] = identifiers.license,
            ['@fivem_id'] = identifiers.fivem_id
        }, function(results)
            if #results > 0 then
                local banData = results[1]
                local remainingTime = banData.expiration_date - os.time()

                if remainingTime > 0 then
                    local timeMessage = self:formatTime(remainingTime)
                    deferrals.update("Vous êtes banni de Soneria Rôleplay ! \nRaison: " .. banData.ban_reason .. "\nTemps restant: " .. timeMessage .. "\nBan ID: " .. banData.id)
                else
                    MySQL.Async.execute('DELETE FROM ban_data WHERE id = @id', {
                        ['@id'] = banData.id
                    })
                    deferrals.done()
                end
            else
                deferrals.done()
            end
        end)
    end)
end

---@param id number
---@param callback function
function BanManager:checkBan(id, callback)
    MySQL.Async.fetchAll('SELECT * FROM ban_data WHERE id = @id', {
        ['@id'] = id
    }, function(results)
        callback(#results > 0)
    end)
end

---@param id number
---@param callback function
function BanManager:unbanPlayer(id, callback)
    self:checkBan(id, function(isBan)
        if isBan then
            MySQL.Async.execute('DELETE FROM ban_data WHERE id = @id', {
                ['@id'] = id
            })
            callback(true)
        else
            callback(false)
        end
    end)
end

# Atoshi Ban Manager

Utilisation :
exports['banManager']:banPlayer(playerId, duration, durationUnit, reason, author, source)

exports['banManager']:unbanPlayer(id, function(isUnbanned)
    if isUnbanned then
        print('Le joueur a été débanni !')
    else
        print('Le Ban ID est invalide !')
    end
end)

exports['banManager']:checkBan(id, function(isBanned)
    if isBanned then
        print('Le joueur est banni.')
    else
        print('Le joueur n\'est pas banni.')
    end
end)

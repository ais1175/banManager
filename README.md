# Atoshi Ban Manager
https://discord.gg/fivedev
## Utilisation :

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

## Commandes
D = Jour
H = Heure
- /ban 'ID' 'Temps' 'D or H' 'Raison'
- /unban 'Ban ID'

Les commandes sont utilisables coté client et serveur.

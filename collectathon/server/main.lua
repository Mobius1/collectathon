local Collectathon = {}
local MySQLReady = false
local dataFile = nil

if Config.MySQLLib == 'fivem-mysql-async' then
    MySQL.ready(function()
        MySQLReady = true
    end)
end

function Collectathon:GetCollected(src)
    local data = self:ReadData(src)

    TriggerClientEvent('collectathon:client:init', src, data)
end

function Collectathon:OnCollected(src, item, type, collectables)
    local identifier = GetPlayerID(src)

    if identifier then
        local collected = {}

        for k, collectables in pairs(collectables) do
            collected[k] = {}

            for _, v in ipairs(collectables.Items) do
                if v.collected then
                    table.insert(collected[k], v.ID)
                end
            end

            collectables.complete = self:IsComplete(collectables, collected[k])
        end

        if Config.MySQLLib == 'json' then
            local data = self:ReadData(src, true)

            data[identifier] = collected

            self:WriteData(data)
    
            TriggerClientEvent('collectathon:client:sync', src, false, true, item, type, collectables[type].complete)
        elseif Config.MySQLLib == 'ghmattimysql' then
            exports.ghmattimysql:execute('UPDATE user_collectables SET collected = @collected WHERE identifier = @identifier', {
                ['@identifier'] = identifier,
                ['@collected'] = json.encode(collected),
            }, function(ret)
                local success = ret and ret.affectedRows > 0
                TriggerClientEvent('collectathon:client:sync', src, false, success, item, type, collectables[type].complete)
            end)
        elseif Config.MySQLLib == 'fivem-mysql-async' then
            while not MySQLReady do Citizen.Wait(0) end

            MySQL.Async.execute('UPDATE user_collectables SET collected = @collected WHERE identifier = @identifier', {
                ['@identifier'] = identifier,
                ['@collected'] = json.encode(collected),
            }, function(ret)
                local success = ret > 0
                TriggerClientEvent('collectathon:client:sync', src, false, success, item, type, collectables[type].complete)
            end)
        end
    end
end

function Collectathon:IsComplete(collectables, collected)
    local itemsCount = table.len(collectables.Items)
    local collectedCount = table.len(collected)

    return itemsCount == collectedCount
end

function Collectathon:ReadData(src, full)
    local identifier = GetPlayerID(src)
    local resp, result = false, false

    if identifier then
        if Config.MySQLLib == 'json' then

            local file = assert(io.open("collectathon.json", "r"))
            local data = file:read("*all")

            file:close()

            if string.len(data) == 0 then
                data = "[]"
            end

            data = json.decode(data)

            if full then
                result = data
            else
                if data[identifier] == nil then
                    data[identifier] = {}
                end

                result = data[identifier]
            end

            resp = true
        
        elseif Config.MySQLLib == 'ghmattimysql' then
            exports.ghmattimysql:execute('SELECT collected FROM user_collectables WHERE identifier = @identifier', {
                ['@identifier'] = identifier,
            }, function(res)
                if #res == 0 then
                    exports.ghmattimysql:execute('INSERT INTO user_collectables (identifier) VALUES (@identifier)', {
                        ['@identifier'] = identifier,
                    }, function(res)
                        result = {}
                        resp = true
                    end)
                else
                    result = json.decode(res[1].collected)
                    resp = true
                end
            end)
        elseif Config.MySQLLib == 'fivem-mysql-async' then
            while not MySQLReady do Citizen.Wait(0) end
        
            MySQL.Async.fetchAll('SELECT collected FROM user_collectables WHERE identifier = @identifier', {
                ['@identifier'] = identifier,
            }, function(res)
                if #res == 0 then
                    MySQL.Async.execute('INSERT INTO user_collectables (identifier) VALUES (@identifier)', {
                        ['@identifier'] = identifier,
                    }, function(res)
                        result = {}
                        resp = true
                    end)
                else
                    result = json.decode(res[1].collected)
                    resp = true
                end
            end)      
        end
    end

    while not resp do Citizen.Wait(0) end

    return result
end

function Collectathon:WriteData(data)
    local file = io.open("collectathon.json", "w+")
    if file then    
        file:write(json.encode(data))
    end
    file:close()
end

RegisterNetEvent('collectathon:server:init')
AddEventHandler('collectathon:server:init', function(...) Collectathon:GetCollected(source, ...) end)

RegisterNetEvent('collectathon:server:collected')
AddEventHandler('collectathon:server:collected', function(...) Collectathon:OnCollected(source, ...) end)

RegisterCommand("collectReset", function(source, args, rawCommand)
    if source > 0 then
        -- if IsPlayerAceAllowed(source, "admin") then
            local type = args[1]
            local src = source
            local identifier = GetPlayerID(src)

            if Config.MySQLLib == 'json' then
                local data = Collectathon:ReadData(src, true)

                if type then
                    if not QuestExists(type) then
                        return
                    end

                    data[identifier][type] = {}
                else
                    data[identifier] = {}
                end
    
                Collectathon:WriteData(data)

                TriggerClientEvent('collectathon:client:sync', src, true, data[identifier])
            elseif Config.MySQLLib == 'ghmattimysql' then
                local data = {}

                if type and QuestExists(type) then
                    data = Collectathon:ReadData(src)

                    data[type] = {}
                end

                exports.ghmattimysql:execute('UPDATE user_collectables SET collected = @collected WHERE identifier = @identifier', {
                    ['@identifier'] = identifier,
                    ['@collected'] = json.encode(data)
                }, function(ret)
                    TriggerClientEvent('collectathon:client:sync', src, true, data)
                end)
            elseif Config.MySQLLib == 'fivem-mysql-async' then
                local data = {}

                if type and QuestExists(type) then
                    data = Collectathon:ReadData(src)

                    data[type] = {}
                end

                MySQL.Async.execute('UPDATE user_collectables SET collected = @collected WHERE identifier = @identifier', {
                    ['@identifier'] = identifier,
                    ['@collected'] = json.encode(data)
                }, function(ret)
                    TriggerClientEvent('collectathon:client:sync', src, true, data)
                end)
            end
        -- end
    end
end)

function QuestExists(type)
    return Config.Collectables[type] ~= nil
end
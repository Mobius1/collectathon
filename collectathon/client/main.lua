local Collectathon = {}
local Collectables = {}

if Config.Debug then
    TriggerServerEvent('collectathon:server:init')
end

-------------------- INITIALISE --------------------
function Collectathon:Init(data)
    self.cfg = Config
    self.quests = {}
    self.active = {}
    self.messages = {}
    self.player = {}
    self.player.ped = PlayerPedId()
    self.player.Coords = GetEntityCoords(self.player.ped)

    self.collectables = CloneTable(self.cfg.Collectables)

    for type, quest in pairs(self.collectables) do
        if quest.Enabled then
            self.quests[type] = self.collectables[type]
            self.quests[type].collected = {}
            self.active[type] = {}

            if data ~= nil and data[type] ~= nil then
                for _, item in ipairs(quest.Items) do
                    if InTable(data[type], item.ID) then
                        item.collected = true

                        table.insert(self.quests[type].collected, item.ID)
                    end
                end
            end
        end
    end

    self.ready = true 
end

-------------------- THREADS CALLBACKS --------------------
function Collectathon:Check()
    while true do
        if self.ready then
            for type, quest in pairs(self.quests) do
                if quest.Enabled then
                    -- Reset active table
                    self.active[type] = {}
            
                    local playerPed = PlayerPedId()
                    local pcoords = GetEntityCoords(playerPed)
            
                    local len = table.len(quest.Items)

                    for i = 1, len do
                        local item = quest.Items[i]
            
                        if not item.collected then
                            local dist = #(item.Coords - pcoords)

                            if self.cfg.Debug then
                                if self.quests[type].Blip ~= nil and not item.blip then
                                    self:AddDebugBlip(item, quest.blip, quest.Title)
                                end
                            else
                                if item.blip then
                                    self:RemoveDebugBlip(item)
                                end
                            end

                            if quest.Immediate and not item.spawned then
                                self:SpawnCollectable(item, type)
                            end
            
                            -- Add item to active table
                            if dist < self.cfg.DrawDistance then
                                table.insert(self.active[type], item)
                            end
                        end
                    end
                end
            end
        end
    
        Citizen.Wait(500)
    end    
end

function Collectathon:Update()
    -- Check the active table
    Citizen.CreateThread(function()
        while true do
            local letSleep = true

            if self.ready  then

                self.player.ped = PlayerPedId()
                self.player.Coords = GetEntityCoords(self.player.ped)

                for type, quest in pairs(self.active) do
                    local itemsCount = table.len(quest)
                    for i = 1, itemsCount do
                        local item = quest[i]

                        if not item.collected then
                            local dist = #(item.Coords - self.player.Coords)

                            -- Only do checks if player is in range
                            if dist < self.cfg.DrawDistance then
                                letSleep = false

                                -- spawn entity when player is in range
                                if not item.spawned then
                                    self:SpawnCollectable(item, type)
                                end 
    
                                -- Rotate item
                                if self.quests[type].Revolve or item.Revolve then
                                    if item.rotation == nil then
                                        item.rotation = 0.0
                                    end

                                    item.rotation = item.rotation + 1.0

                                    if item.rotation == 360.0 then
                                        item.rotation = 0.0
                                    end

                                    SetEntityRotation(item.entity, 0.0, 0.0, item.rotation, 1, true)
                                end

                                if self.cfg.Debug then
                                    self:ShowDebugMarker(item.Name or self.quests[type].Name, self.quests[type].ID, item)
                                end

                                if self.cfg.PickupType == 'auto' and dist < 1.2 then
                                    self:PickupCollectable(item, type)
                                elseif self.cfg.PickupType == 'manual' and dist < 2.0 then
                                    if self.cfg.PickupPrompt == 'help' then
                                        self:Prompt(self:FormatMessage('prompt_help_msg', item.Name or self.quests[type].Name))
                                    elseif self.cfg.PickupPrompt == 'floating' then
                                        self:Draw3DText(vector3(item.Coords.x, item.Coords.y, item.Coords.z + 1.0), self:FormatMessage('prompt_float_msg', item.Name or self.quests[type].Name), 1.0)
                                    end

                                    if IsControlJustPressed(0, 38) then
                                        self:PickupCollectable(item, type, true)
                                    end
                                end
                            end
                        end
                    end
                end
            end

            if letSleep then
                Citizen.Wait(1000)
            end

            Citizen.Wait(2)
        end
    end)
end


-------------------- COLLECTABLES --------------------
function Collectathon:PickupCollectable(item, type, prompt)
    local collectable = self.quests[type]
    item.collected = true
    
    table.insert(collectable.collected, item.ID)
    
    if prompt then
        local dict, anim = 'weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', 'plant_floor'
        self:RequestAnimDict(dict)
        TaskPlayAnim(PlayerPedId(), dict, anim, 8.0, 1.0, 1000, 16, 0.0, false, false, false)
        Citizen.Wait(1000)
    end

    -- Remove the item
    self:DeleteCollectable(item)    

    -- Play collection sound
    if self.cfg.PickupSound then
        PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
    end
    
    TriggerServerEvent("collectathon:server:collected", item, type, self.quests)
end

function Collectathon:SpawnCollectable(item, type)
    item.spawned = true

    local prop = item.Prop

    if prop == nil then
        prop = self.quests[type].Prop
    end

    self:SpawnProp(prop, item.Coords, function(entity)
        item.spawned = true
        item.entity = entity
        item.collected = false
    
        self:PlaceCollectable(entity, item, type)
    end)
end

function Collectathon:PlaceCollectable(entity, item, type)
    RequestCollisionAtCoord(item.Coords.x, item.Coords.y, item.Coords.z)

    while not HasCollisionLoadedAroundEntity(entity) do
        RequestCollisionAtCoord(item.Coords.x, item.Coords.y, item.Coords.z)
        Citizen.Wait(0)
    end

    if not self.quests[type].Grounded and not item.Grounded then
        SetEntityCoordsNoOffset(entity, item.Coords.x, item.Coords.y, item.Coords.z, 0.0, 0.0, 0.0)
    else
        PlaceObjectOnGroundProperly(entity)
    end
    
    FreezeEntityPosition(entity, true)
    SetEntityCollision(entity, false, true)
    SetEntityNoCollisionEntity(PlayerPedId(), entity, false)
    SetEntityAsMissionEntity(entity)    
end

function Collectathon:DeleteCollectable(item)
    item.spawned = false
    SetEntityAsMissionEntity(item.entity, false, true)
    DeleteObject(item.entity)

    if self.cfg.Debug then
        self:RemoveDebugBlip(item)
    end
end

-------------------- EVENT HANDLERS --------------------
function Collectathon:OnSpawned()
    TriggerServerEvent('collectathon:server:init')                                                                                                   
end

function Collectathon:OnSync(reset, success, item, type, complete)
    if reset then
        self:Reset(success)
    else
        if success then
            self:OnCollect(item, type)

            if complete then
                self:OnComplete(type)
            end
        else
            if not item.spawned then
                -- there was a problem so respawn item and remove it from collected table
                local index = 0
                for k, v in pairs(self.quests[type].collected) do
                    if item.ID == v.ID then
                        index = k
                        break
                    end
                end
        
                if index > 0 then
                    self.quests[type].collected[index] = nil
        
                    self:SpawnCollectable(item, type)
                end
            end
        end
    end
end

function Collectathon:OnCollect(item, type)

    if self.quests[type].OnCollect ~= nil then
        self.quests[type].OnCollect(item, self.quests[type])
    end

    if item.OnCollect ~= nil then
        for _, v in ipairs(self.quests[type].Items) do
            if item.ID == v.ID then
                v.OnCollect(item, self.quests[type])
            end
        end
    end    

    TriggerEvent("collectathon:client:collected", item, type, self.quests[type])

    if self.cfg.PickupMessage then
        local itemsCount = table.len(self.quests[type].Items)
        local collectedCount = table.len(self.quests[type].collected)

        self:ShowMessage(
            self:FormatMessage('found_title', item.Name or self.quests[type].Name),
            self:FormatMessage('found_msg', collectedCount, itemsCount, self.quests[type].Title),
            3
        )
    end
end

function Collectathon:OnComplete(type)
    self.quests[type].completed = true

    if self.quests[type].OnComplete ~= nil then
        self.quests[type].OnComplete()
    end
                    
    TriggerEvent("collectathon:client:completed", self.quests[type])    

    if self.cfg.PickupMessage then
        local itemsCount = table.len(self.quests[type].Items)

        self:ShowMessage(
            self:FormatMessage('completed_title', self.quests[type].Title),
            self:FormatMessage('completed_msg', itemsCount, self.quests[type].Title),
            5, true
        )
    end
end

function Collectathon:OnResourceStop()
    for k, quest in pairs(self.collectables) do
        if quest.Enabled then
            for _, item in ipairs(quest.Items) do
                if item.spawned and DoesEntityExist(item.entity) then
                    Collectathon:DeleteCollectable(item)
                end
            end
        end
    end

    self:CleanUp()
end

function Collectathon:OnDisplayStats()
    local str = 'Collectathon Progress\n'

    for k, quest in pairs(self.quests) do
        str = str .. string.format('- %s: %s / %s\n', quest.Title, table.len(quest.collected), table.len(quest.Items))
    end

    TriggerEvent('chat:addMessage', {
        color = { 255, 0, 0},
        multiline = true,
        args = {"SYSTEM", str}
    })    
end


-------------------- UI --------------------
function Collectathon:FormatMessage(key, ...)
    return string.format(self.cfg.Messages[key], ...)
end

function Collectathon:ShowMessage(title, msg, sec, completed)

    local data = {
        msg = msg, title = title, sec = sec, stop = false
    }

    table.insert(self.messages, data)

    if #self.messages > 1 then
        for i = 1, #self.messages - 1 do
            self.messages[i].stop = true
        end
    end

    if not completed then
        while self.scaleform do
            Citizen.Wait(0)
        end
    end

    self.scaleform = self:RequestScaleformMovie('MP_BIG_MESSAGE_FREEMODE')

    BeginScaleformMovieMethod(self.scaleform, 'SHOW_SHARD_CENTERED_TOP_MP_MESSAGE')
    PushScaleformMovieMethodParameterString(data.title)
    PushScaleformMovieMethodParameterString(data.msg)
    EndScaleformMovieMethod()

    while data.sec > 0 do
        if data.stop then break end
        Citizen.Wait(1)
        data.sec = data.sec - 0.01

        DrawScaleformMovieFullscreen(self.scaleform, 255, 255, 255, 255)
    end

    SetScaleformMovieAsNoLongerNeeded(self.scaleform)

    self.scaleform = false
end

function Collectathon:Prompt(msg, thisFrame, beep, duration)
    AddTextEntry('collectathonPrompt', msg)

    if thisFrame then
        DisplayHelpTextThisFrame('collectathonPrompt', false)
    else
        if beep == nil then beep = true end
        BeginTextCommandDisplayHelp('collectathonPrompt')
        EndTextCommandDisplayHelp(0, false, beep, duration or -1)
    end
end

function Collectathon:AddDebugBlip(item, blip, text)
    if blip==nil then blip={ID=66,Color=2,Scale=1.0}end

    item.blip = AddBlipForCoord(item.Coords.x, item.Coords.y, item.Coords.z)
    SetBlipSprite(item.blip, blip.ID)
    SetBlipAsShortRange(item.blip, true)
    SetBlipColour(item.blip, blip.Color)
    SetBlipScale(item.blip, blip.Scale)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(text)
    EndTextCommandSetBlipName(item.blip)    
end

function Collectathon:RemoveDebugBlip(item)
    if item.blip ~= nil then
        if DoesBlipExist(item.blip) then
            RemoveBlip(item.blip)
            item.blip = nil
        end
    end
end

function Collectathon:ShowDebugMarker(msg, id, item)
    local pos = 3 -- 1 = bottom, 2 = right, 3 = top, 4 = left
    local bgc = 2

    AddTextEntry('collectathon', msg)
    SetFloatingHelpTextWorldPosition(1, item.Coords.x, item.Coords.y, item.Coords.z + 0.5)
    SetFloatingHelpTextStyle(1, 1, bgc, -1, pos, 0)
    BeginTextCommandDisplayHelp('collectathon')
    EndTextCommandDisplayHelp(2, false, false, -1)
end

function Collectathon:Draw3DText(coords, text, size)
    local vector = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)

    local camCoords = GetGameplayCamCoords()
    local distance = #(vector - camCoords)

    if not size then size = 1 end

    local scale = (size / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    SetTextScale(0.0 * scale, 0.55 * scale)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(vector.xyz, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end


-------------------- STREAMING --------------------
function Collectathon:RequestModel(modelHash, cb)
    modelHash = (type(modelHash) == 'number' and modelHash or GetHashKey(modelHash))

    if not HasModelLoaded(modelHash) and IsModelInCdimage(modelHash) then
        RequestModel(modelHash)

        while not HasModelLoaded(modelHash) do
            Citizen.Wait(4)
        end
    end

    if cb ~= nil then
        cb()
    end
end

function Collectathon:RequestScaleformMovie(movie)
    local scaleform = RequestScaleformMovie(movie)

    while not HasScaleformMovieLoaded(scaleform) do
        Citizen.Wait(0)
    end

    return scaleform
end

function Collectathon:RequestAnimDict(animDict, cb)
    if not HasAnimDictLoaded(animDict) then
        RequestAnimDict(animDict)

        while not HasAnimDictLoaded(animDict) do
            Citizen.Wait(4)
        end
    end

    if cb ~= nil then
        cb()
    end
end

function Collectathon:SpawnProp(object, coords, cb)
    local model = type(object) == 'number' and object or GetHashKey(object)
    local vector = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)
    
    Citizen.CreateThread(function()
        self:RequestModel(model)
    
        local obj = CreateObject(model, vector.xyz, false, false, true)
        if cb then
            cb(obj)
        end
    end)
end

-------------------- UTILS --------------------
function Collectathon:Reset(data)
    for type, quest in pairs(self.quests) do
        if quest.Enabled then
            quest.completed = false
            quest.collected = {}
            for _, item in ipairs(quest.Items) do
                item.collected = false

                if item.spawned and DoesEntityExist(item.entity) then
                    if not quest.Immediate then
                        Collectathon:DeleteCollectable(item)
                    end
                end                 

                if data and data[type] and InTable(data[type], item.ID) then
                    item.collected = true

                    table.insert(quest.collected, item.ID)
                end
            end
        end
    end
end

function Collectathon:CleanUp()
    local objects = GetGamePool('CObject')
    local collected = {}

    for k, quest in pairs(self.cfg.Collectables) do
        table.insert(collected, quest.Prop)

        for _, item in ipairs(quest.Items) do
            if item.Prop then
                if not InTable(collected, item.Prop) then
                    table.insert(collected, item.Prop)
                end
            end
        end
    end

    for k, object in pairs(objects) do
        if HasHash(collected, GetEntityModel(object)) then
            SetEntityAsMissionEntity(object, false, true)
            DeleteObject(object)
        end
    end    
end

function Collectathon:SetConfig(key, val)
    if Config[key] ~= nil then
        Config[key] = val
    end    
end


-------------------- THREADS --------------------
Citizen.CreateThread(function(...) Collectathon:Update(...) end)
Citizen.CreateThread(function(...) Collectathon:Check(...) end)


-------------------- EVENTS --------------------
RegisterNetEvent('collectathon:client:init')
AddEventHandler('collectathon:client:init', function(...) Collectathon:Init(...) end)

RegisterNetEvent('collectathon:client:sync')
AddEventHandler('collectathon:client:sync', function(...) Collectathon:OnSync(...) end)

RegisterNetEvent('collectathon:client:setConfig')
AddEventHandler('collectathon:client:setConfig', function(...) Collectathon:SetConfig(...) end)

AddEventHandler("playerSpawned", function(...) Collectathon:OnSpawned(...) end)
AddEventHandler('onResourceStop', function(...) Collectathon:OnResourceStop(...) end)

RegisterCommand("collectStats", function(...) Collectathon:OnDisplayStats(...) end)
-- Spawn Selector
-- Standalone isolation of the NSL spawn-selection flow.

local kSelectedMarineSpawn
local kSelectedAlienSpawn
local kCustomTechPointData
local kSpawnConfigModes = { "AliensChoose" }
local kSpawnSelectorInitialized = false

local function UpdateWithCustomSpawnLocations(techPoints, teamNumber)
    if teamNumber == 1 and kCustomTechPointData then
        for _, tp in ipairs(techPoints) do
            local lowerLoc = string.lower(tp:GetLocationName())

            if kCustomTechPointData[lowerLoc] then
                tp.allowedTeamNumber = kCustomTechPointData[lowerLoc].allowedTeamNumber
                tp.chooseWeight = kCustomTechPointData[lowerLoc].chooseWeight
            else
                tp.allowedTeamNumber = 3
                tp.chooseWeight = 0
            end
        end
    end

    return techPoints
end

local function UpdateWithRemainingTechPoints(selectedTechPointLoc, techPoints, teamNumber)
    if teamNumber == 1 and kCustomTechPointData and kCustomTechPointData[selectedTechPointLoc] then
        for i = #techPoints, 1, -1 do
            if not table.contains(kCustomTechPointData[selectedTechPointLoc].enemySpawns, string.lower(techPoints[i]:GetLocationName())) then
                table.remove(techPoints, i)
            end
        end
    end

    return techPoints
end

local function SendAlienTeamMessage(messageType, locationName)
    local text
    if messageType == "choose_spawn" and locationName then
        text = string.format("Alien commander selected %s as the hive start.", locationName)
    else
        text = "Alien commander selected a random hive start."
    end

    local team = GetGamerules() and GetGamerules():GetTeam(kTeam2Index)
    if team and team.GetPlayers then
        local players = team:GetPlayers()

        if players then
            for _, player in ipairs(players) do
                local client = Server.GetOwner(player)
                if client and Server.SendNetworkMessage and kChatMessageType then
                    Server.SendNetworkMessage(client, "Chat", {
                        teamNumber = kTeam2Index,
                        teamOnly = true,
                        messageType = kChatMessageType.Team,
                        playerName = "",
                        playerId = Entity.invalidId,
                        message = text
                    }, true)
                end
            end
            return
        end
    end

    Shared.Message(text)
end

local originalNS2GRGetChooseTechPoint
originalNS2GRGetChooseTechPoint = Class_ReplaceMethod("NS2Gamerules", "ChooseTechPoint",
    function(self, techPoints, teamNumber)

        local techPoint

        if table.contains(kSpawnConfigModes, "AliensChoose") then
            if teamNumber == kTeam1Index then
                techPoint = kSelectedMarineSpawn
            elseif teamNumber == kTeam2Index then
                techPoint = kSelectedAlienSpawn
            end
        end

        if not techPoint and table.contains(kSpawnConfigModes, "CustomSpawns") and kCustomTechPointData then
            techPoint = originalNS2GRGetChooseTechPoint(self, UpdateWithCustomSpawnLocations(techPoints, teamNumber), teamNumber)
            techPoints = UpdateWithRemainingTechPoints(string.lower(techPoint:GetLocationName()), techPoints, teamNumber)
        end

        if not techPoint then
            techPoint = originalNS2GRGetChooseTechPoint(self, techPoints, teamNumber)
        end

        return techPoint
    end
)

local function OnGameEndClearSpawns()
    kSelectedMarineSpawn = nil
    kSelectedAlienSpawn = nil
    kSpawnSelectorInitialized = false

    local gameInfo = GetGameInfoEntity()
    if gameInfo then
        gameInfo:SetSpawnSelection(-1)
        gameInfo:SetSpawnSelectionEnabled(true)
    end
end

table.insert(gGameEndFunctions, OnGameEndClearSpawns)

local function BuildCustomTechPointDataFromOverrides()
    if not Server.spawnSelectionOverrides then
        return
    end

    local techPoints = EntityListToTable(Shared.GetEntitiesWithClassname("TechPoint"))
    local validSpawns = {}
    local spawnKey = {}
    local teamSpawns = {}
    local enemySpawns = {}

    for t = 1, #Server.spawnSelectionOverrides do
        local selectedSpawn = Server.spawnSelectionOverrides[t]
        local lowerMarine = string.lower(selectedSpawn.marineSpawn)
        local lowerAlien = string.lower(selectedSpawn.alienSpawn)

        if table.contains(validSpawns, lowerMarine) then
            if teamSpawns[spawnKey[lowerMarine]] == 2 or teamSpawns[spawnKey[lowerMarine]] == 0 then
                teamSpawns[spawnKey[lowerMarine]] = 0
            else
                teamSpawns[spawnKey[lowerMarine]] = 1
            end

            if not table.contains(enemySpawns[spawnKey[lowerMarine]], lowerAlien) then
                table.insert(enemySpawns[spawnKey[lowerMarine]], lowerAlien)
            end
        else
            table.insert(validSpawns, lowerMarine)
            spawnKey[lowerMarine] = #validSpawns
            teamSpawns[spawnKey[lowerMarine]] = 1
            enemySpawns[spawnKey[lowerMarine]] = { lowerAlien }
        end

        if table.contains(validSpawns, lowerAlien) then
            if teamSpawns[spawnKey[lowerAlien]] == 1 or teamSpawns[spawnKey[lowerAlien]] == 0 then
                teamSpawns[spawnKey[lowerAlien]] = 0
            else
                teamSpawns[spawnKey[lowerAlien]] = 2
            end

            if not table.contains(enemySpawns[spawnKey[lowerAlien]], lowerMarine) then
                table.insert(enemySpawns[spawnKey[lowerAlien]], lowerMarine)
            end
        else
            table.insert(validSpawns, lowerAlien)
            spawnKey[lowerAlien] = #validSpawns
            teamSpawns[spawnKey[lowerAlien]] = 2
            enemySpawns[spawnKey[lowerAlien]] = { lowerMarine }
        end
    end

    if #validSpawns > 0 then
        kCustomTechPointData = {}

        for _, currentTechPoint in ipairs(techPoints) do
            kCustomTechPointData[string.lower(currentTechPoint:GetLocationName())] = {
                allowedTeamNumber = 3,
                chooseWeight = 0,
                enemySpawns = {}
            }
        end

        for i = 1, #validSpawns do
            kCustomTechPointData[validSpawns[i]] = {
                allowedTeamNumber = teamSpawns[i],
                chooseWeight = 1,
                enemySpawns = enemySpawns[i]
            }
        end
    end
end

local function InitializeSpawnSelection()
    local gameInfo = GetGameInfoEntity()
    local techPoints = EntityListToTable(Shared.GetEntitiesWithClassname("TechPoint"))

    for _, tp in ipairs(techPoints) do
        tp:SetAllowedTeam(0)
    end

    if gameInfo then
        gameInfo:SetSpawnSelectionEnabled(true)
        gameInfo:SetSpawnSelection(-1)
    end

    if table.contains(kSpawnConfigModes, "AliensChoose") then
        if Server.spawnSelectionOverrides and not kCustomTechPointData then
            BuildCustomTechPointDataFromOverrides()
        end

        if kCustomTechPointData then
            for _, tp in ipairs(techPoints) do
                local lowerLoc = string.lower(tp:GetLocationName())

                if kCustomTechPointData[lowerLoc] then
                    tp.allowedTeamNumber = kCustomTechPointData[lowerLoc].allowedTeamNumber
                    tp.chooseWeight = kCustomTechPointData[lowerLoc].chooseWeight
                else
                    tp.allowedTeamNumber = 3
                    tp.chooseWeight = 0
                end
            end

            GetGamerules():ResetGame()
            Server.spawnSelectionOverrides = nil
        end
    end

    kSpawnSelectorInitialized = true
end

local function onSpawnSelectionMessage(client, message)
    local player = client:GetControllingPlayer()

    if player and message and player:GetIsCommander() and player:GetTeamNumber() == kTeam2Index then
        kSelectedAlienSpawn = nil
        kSelectedMarineSpawn = nil

        local tp = Shared.GetEntity(message.techPointId)
        local gameInfo = GetGameInfoEntity()

        if tp and tp:isa("TechPoint") and (tp:GetTeamNumberAllowed() == 0 or tp:GetTeamNumberAllowed() == 2) then
            kSelectedAlienSpawn = tp

            if gameInfo then
                gameInfo:SetSpawnSelection(tp:GetId())
            end
        end

        if kSelectedAlienSpawn then
            local alienTechPointName = string.lower(kSelectedAlienSpawn:GetLocationName())
            local techPoints = EntityListToTable(Shared.GetEntitiesWithClassname("TechPoint"))
            local marineTechPointNames = {}

            SendAlienTeamMessage("choose_spawn", kSelectedAlienSpawn:GetLocationName())

            if kCustomTechPointData then
                for _, currentTechPoint in ipairs(techPoints) do
                    local lowerLoc = string.lower(currentTechPoint:GetLocationName())

                    if kCustomTechPointData[lowerLoc] then
                        local enemySpawns = kCustomTechPointData[lowerLoc].enemySpawns

                        if enemySpawns and table.contains(enemySpawns, alienTechPointName) then
                            table.insertunique(marineTechPointNames, lowerLoc)
                        end
                    end
                end
            end

            if marineTechPointNames and #marineTechPointNames > 0 then
                local selectedName

                if #marineTechPointNames == 1 then
                    selectedName = marineTechPointNames[1]
                else
                    selectedName = marineTechPointNames[math.random(1, #marineTechPointNames)]
                end

                for _, currentTechPoint in ipairs(techPoints) do
                    if selectedName == string.lower(currentTechPoint:GetLocationName()) then
                        kSelectedMarineSpawn = currentTechPoint
                        break
                    end
                end
            end

            if not kSelectedMarineSpawn then
                local validTechPoints = {}
                local totalTechPointWeight = 0
                local gameRules = GetGamerules()

                for _, currentTechPoint in ipairs(techPoints) do
                    local teamNum = currentTechPoint:GetTeamNumberAllowed()

                    if (teamNum == 0 or teamNum == 1) and teamNum ~= 3 then
                        table.insert(validTechPoints, currentTechPoint)
                        totalTechPointWeight = totalTechPointWeight + currentTechPoint:GetChooseWeight()
                    end
                end

                if #validTechPoints > 0 and gameRules and gameRules.techPointRandomizer then
                    local chosenTechPointWeight = gameRules.techPointRandomizer:random(0, totalTechPointWeight)

                    for _, currentTechPoint in ipairs(validTechPoints) do
                        chosenTechPointWeight = chosenTechPointWeight - currentTechPoint:GetChooseWeight()

                        if chosenTechPointWeight >= 0 then
                            kSelectedMarineSpawn = currentTechPoint
                            break
                        end
                    end
                end
            end
        else
            kSelectedMarineSpawn = nil
            kSelectedAlienSpawn = nil

            if gameInfo then
                gameInfo:SetSpawnSelection(-1)
            end

            SendAlienTeamMessage("choose_random_spawn")
        end
    end
end

Server.HookNetworkMessage("SSSelectSpawn", onSpawnSelectionMessage)

local function LateInitializeSpawnSelection()
    if not kSpawnSelectorInitialized then
        InitializeSpawnSelection()
    end
end

Event.Hook("UpdateServer", LateInitializeSpawnSelection)
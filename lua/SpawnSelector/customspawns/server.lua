-- Spawn Selector

local kSpawnSelectorEnabled = true

local kSelectedMarineSpawn = nil
local kSelectedAlienSpawn = nil
local kSpawnSelectorInitialized = false

local kCustomTechPointData = kCustomTechPointData

local function GetTechPointName(tp)
    if tp and tp.GetLocationName then
        return tp:GetLocationName()
    end
    return "nil"
end

local function SendAlienSelectionMessage(tp)
    if tp then
        Shared.Message(string.format(
            "[SpawnSelector] Alien commander chose hive start: %s",
            tp:GetLocationName()
        ))
    else
        Shared.Message("[SpawnSelector] Alien commander chose random hive start.")
    end
end

local originalNS2GRGetChooseTechPoint
originalNS2GRGetChooseTechPoint = Class_ReplaceMethod("NS2Gamerules", "ChooseTechPoint",
    function(self, techPoints, teamNumber)

        if not kSpawnSelectorEnabled then
            return originalNS2GRGetChooseTechPoint(self, techPoints, teamNumber)
        end

        local techPoint = nil

        if teamNumber == kTeam1Index then
            techPoint = kSelectedMarineSpawn
        elseif teamNumber == kTeam2Index then
            techPoint = kSelectedAlienSpawn
        end

        if not techPoint then
            techPoint = originalNS2GRGetChooseTechPoint(self, techPoints, teamNumber)
        end

        return techPoint
    end
)

local function OnGameEndClearSpawns(gamerules)
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

local function InitializeSpawnSelection()

    local gameInfo = GetGameInfoEntity()
    local techPoints = EntityListToTable(Shared.GetEntitiesWithClassname("TechPoint"))

    for _, tp in ipairs(techPoints) do
        tp:SetAllowedTeam(0)
    end

    if gameInfo then
        gameInfo:SetSpawnSelectionEnabled(kSpawnSelectorEnabled)
        gameInfo:SetSpawnSelection(-1)
    end

    kSpawnSelectorInitialized = true
end

local function onSpawnSelectionMessage(client, message)
    local player = client and client:GetControllingPlayer()
    if not player or not message then
        return
    end

    if not player:GetIsCommander() or player:GetTeamNumber() ~= kTeam2Index then
        return
    end

    kSelectedAlienSpawn = nil
    kSelectedMarineSpawn = nil

    local gameInfo = GetGameInfoEntity()
    local tp = Shared.GetEntity(message.techPointId)

    if tp and tp:isa("TechPoint") and (tp:GetTeamNumberAllowed() == 0 or tp:GetTeamNumberAllowed() == 2) then
        kSelectedAlienSpawn = tp

        if gameInfo then
            gameInfo:SetSpawnSelection(tp:GetId())
        end
    end

    if kSelectedAlienSpawn then

        local alienTechPointName = string.lower(kSelectedAlienSpawn:GetLocationName())
        local techPoints = EntityListToTable(Shared.GetEntitiesWithClassname("TechPoint"))

        SendAlienSelectionMessage(kSelectedAlienSpawn)

        local marineTechPointNames = {}

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
        SendAlienSelectionMessage(nil)
        kSelectedMarineSpawn = nil
        kSelectedAlienSpawn = nil

        if gameInfo then
            gameInfo:SetSpawnSelection(-1)
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
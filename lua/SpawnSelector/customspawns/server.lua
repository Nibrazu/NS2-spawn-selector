-- Spawn Selector

local kSpawnSelectorEnabled = true

local kSelectedMarineSpawn
local kSelectedAlienSpawn

local originalNS2GRGetChooseTechPoint
originalNS2GRGetChooseTechPoint = Class_ReplaceMethod("NS2Gamerules", "ChooseTechPoint",
    function(self, techPoints, teamNumber)

        if not kSpawnSelectorEnabled then
            return originalNS2GRGetChooseTechPoint(self, techPoints, teamNumber)
        end

        local techPoint

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
end

local function onSpawnSelectionMessage(client, message)
    local player = client:GetControllingPlayer()
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
    else
        if gameInfo then
            gameInfo:SetSpawnSelection(-1)
        end
        return
    end

    local techPoints = EntityListToTable(Shared.GetEntitiesWithClassname("TechPoint"))
    local validTechPoints = { }
    local totalTechPointWeight = 0
    local gameRules = GetGamerules()

    for _, currentTechPoint in ipairs(techPoints) do
        local teamNum = currentTechPoint:GetTeamNumberAllowed()

        if (teamNum == 0 or teamNum == 1) and currentTechPoint:GetId() ~= kSelectedAlienSpawn:GetId() then
            table.insert(validTechPoints, currentTechPoint)
            totalTechPointWeight = totalTechPointWeight + currentTechPoint:GetChooseWeight()
        end
    end

    if #validTechPoints > 0 then
        local chosenTechPointWeight = gameRules.techPointRandomizer:random(0, totalTechPointWeight)

        for _, currentTechPoint in ipairs(validTechPoints) do
            chosenTechPointWeight = chosenTechPointWeight - currentTechPoint:GetChooseWeight()
            if chosenTechPointWeight >= 0 then
                kSelectedMarineSpawn = currentTechPoint
                break
            end
        end

        if not kSelectedMarineSpawn then
            kSelectedMarineSpawn = validTechPoints[1]
        end
    end
end

Server.HookNetworkMessage("SSSelectSpawn", onSpawnSelectionMessage)

local function LateInitializeSpawnSelection()
    InitializeSpawnSelection()
    return false
end

Event.Hook("UpdateServer", LateInitializeSpawnSelection)
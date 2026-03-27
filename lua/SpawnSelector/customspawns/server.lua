-- Spawn Selector

local kSpawnSelectorEnabled = true

local kSelectedMarineSpawn = nil
local kSelectedAlienSpawn = nil
local kSpawnSelectorInitialized = false

local function GetTechPointName(tp)
    if tp and tp.GetLocationName then
        return tp:GetLocationName()
    end
    return "nil"
end

local originalNS2GRGetChooseTechPoint
originalNS2GRGetChooseTechPoint = Class_ReplaceMethod("NS2Gamerules", "ChooseTechPoint",
    function(self, techPoints, teamNumber)

        if not kSpawnSelectorEnabled then
            return originalNS2GRGetChooseTechPoint(self, techPoints, teamNumber)
        end

        local techPoint = nil

        if teamNumber == kTeam1Index and kSelectedMarineSpawn then
            techPoint = kSelectedMarineSpawn
            Shared.Message(string.format("[SpawnSelector] Marine start forced to: %s", GetTechPointName(techPoint)))
        elseif teamNumber == kTeam2Index and kSelectedAlienSpawn then
            techPoint = kSelectedAlienSpawn
            Shared.Message(string.format("[SpawnSelector] Alien start forced to: %s", GetTechPointName(techPoint)))
        end

        if not techPoint then
            techPoint = originalNS2GRGetChooseTechPoint(self, techPoints, teamNumber)
            Shared.Message(string.format(
                "[SpawnSelector] Fallback random start for team %s: %s",
                tostring(teamNumber),
                GetTechPointName(techPoint)
            ))
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

    Shared.Message("[SpawnSelector] Cleared selected spawns on game end.")
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
    Shared.Message(string.format("[SpawnSelector] Initialized once. Tech points found: %s", tostring(#techPoints)))
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

        Shared.Message(string.format(
            "[SpawnSelector] Alien commander selected hive start: %s (id=%s)",
            GetTechPointName(tp),
            tostring(tp:GetId())
        ))

        -- Placeholder for team chat message.
        -- Original NSL uses NSLSendTeamMessage(...), which is not in this isolated mod.
    else
        if gameInfo then
            gameInfo:SetSpawnSelection(-1)
        end

        Shared.Message("[SpawnSelector] Invalid tech point received from SSSelectSpawn.")
        return
    end

    local techPoints = EntityListToTable(Shared.GetEntitiesWithClassname("TechPoint"))
    local validTechPoints = {}
    local totalTechPointWeight = 0
    local gameRules = GetGamerules()

    for _, currentTechPoint in ipairs(techPoints) do
        local teamNum = currentTechPoint:GetTeamNumberAllowed()

        if (teamNum == 0 or teamNum == 1) and currentTechPoint:GetId() ~= kSelectedAlienSpawn:GetId() then
            table.insert(validTechPoints, currentTechPoint)
            totalTechPointWeight = totalTechPointWeight + currentTechPoint:GetChooseWeight()
        end
    end

    if #validTechPoints > 0 and gameRules and gameRules.techPointRandomizer then
        local chosenTechPointWeight = gameRules.techPointRandomizer:random(0, totalTechPointWeight)

        for _, currentTechPoint in ipairs(validTechPoints) do
            chosenTechPointWeight = chosenTechPointWeight - currentTechPoint:GetChooseWeight()

            if chosenTechPointWeight <= 0 then
                kSelectedMarineSpawn = currentTechPoint
                break
            end
        end

        if not kSelectedMarineSpawn then
            kSelectedMarineSpawn = validTechPoints[#validTechPoints]
        end

        Shared.Message(string.format(
            "[SpawnSelector] Marine start paired to: %s",
            GetTechPointName(kSelectedMarineSpawn)
        ))
    else
        Shared.Message("[SpawnSelector] No valid marine tech points found.")
    end
end

Server.HookNetworkMessage("SSSelectSpawn", onSpawnSelectionMessage)

local function LateInitializeSpawnSelection()
    if not kSpawnSelectorInitialized then
        InitializeSpawnSelection()
    end
end

Event.Hook("UpdateServer", LateInitializeSpawnSelection)
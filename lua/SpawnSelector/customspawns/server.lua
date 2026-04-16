-- Spawn Selector

local kSelectedMarineSpawn
local kSelectedAlienSpawn
local kCustomTechPointData
local kSpawnConfigModes = { "AliensChoose", "CustomSpawns" }

local kSpawnSelectorInitialized = false

local kFriendlySpawnHelpers = {
    ns2_biodome = {
        top = "atmosphere exchange",
        right = "hydroponics",
        bottom = "reception",
        left = "platform",
        middle = "falls",
        center = "falls",
    },

    ns2_descent = {
        top = "fabrication",
        right = "monorail",
        bottom = "drone bay",
        left = "launch control",
        middle = "hydroanalysis",
        center = "hydroanalysis",
    },

    ns2_jambi = {
        ["top left"] = "pipeworks",
        top = { "pipeworks", "waste recycling" },
        ["top right"] = "waste recycling",
        right = "waste recycling",
        bottom = "docking bay",
        left = "electrical core",
        middle = "gravity",
        center = "gravity",
    },

    ns2_mineral = {
        ["top left"] = "drill site",
        top = { "drill site", "mineral processing" },
        ["top right"] = "mineral processing",
        right = "production",
        bottom = "surface",
    },

    ns2_nexus = {
        top = "silo",
        right = "receiving",
        bottom = "relay",
        left = "extraction",
    },

    ns2_summit = {
        top = "atrium",
        right = "data core",
        bottom = "sub access",
        left = "flight control",
        middle = "crossroads",
        center = "crossroads",
    },

    ns2_tram = {
        ["top left"] = "warehouse",
        top = { "warehouse", "server room" },
        ["top right"] = "server room",
        right = "elevator transfer",
        bottom = "shipping",
        left = "repair room",
    },

    ns2_veil = {
        top = "control",
        right = "pipeline",
        ["bottom right"] = "pipeline",
        bottom = "cargo",
        middle = "cargo",
        ["bottom left"] = "sub-sector",
        left = "sub-sector",
    },
}

local function LogSpawnSelector(message)
    Shared.Message(string.format("[SpawnSelector] %s", message))
end

local function HasConfigMode(modeName)
    return table.contains(kSpawnConfigModes, modeName)
end

local function GetConfigValue(key)
    if type(GetSpawnSelectorConfigValue) == "function" then
        return GetSpawnSelectorConfigValue(key)
    end

    return nil
end

local function RefreshSpawnConfigModes()
    local configuredModes = GetConfigValue("CustomSpawnModes")
    if type(configuredModes) == "table" and #configuredModes > 0 then
        kSpawnConfigModes = configuredModes
    end
end

local function GetMapSpecificSpawns()
    if not HasConfigMode("CustomSpawns") then
        return nil
    end

    local customSpawnData = GetConfigValue("CustomSpawns")
    if not customSpawnData then
        return nil
    end

    local mapName = Shared.GetMapName()
    local mapSpawnData = customSpawnData[mapName]
    if type(mapSpawnData) ~= "table" then
        return nil
    end

    local now = os.time()

    for _, tpData in ipairs(mapSpawnData) do
        if tpData.enabled ~= false then
            local effectiveOk = true
            local expiryOk = true

            if tpData.effectiveDate then
                effectiveOk = os.time(tpData.effectiveDate) <= now
            end

            if tpData.expiryDate then
                expiryOk = os.time(tpData.expiryDate) >= now
            end

            if effectiveOk and expiryOk and type(tpData.spawnData) == "table" and #tpData.spawnData > 0 then
                return tpData.spawnData
            end
        end
    end

    return nil
end

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
            if not table.contains(
                kCustomTechPointData[selectedTechPointLoc].enemySpawns,
                string.lower(techPoints[i]:GetLocationName())
            ) then
                table.remove(techPoints, i)
            end
        end
    end

    return techPoints
end

local function SendAlienTeamMessage(locationName)
    local text

    if locationName then
        text = string.format("Alien commander picked %s as Alien spawn.", locationName)
    else
        text = "Alien commander picked a random Alien spawn."
    end

    Shared.ConsoleCommand(string.format("sv_tsay 2 %q", text))
end

local originalNS2GRGetChooseTechPoint
originalNS2GRGetChooseTechPoint = Class_ReplaceMethod("NS2Gamerules", "ChooseTechPoint",
    function(self, techPoints, teamNumber)
        local techPoint

        if HasConfigMode("AliensChoose") then
            if teamNumber == kTeam1Index then
                techPoint = kSelectedMarineSpawn
            elseif teamNumber == kTeam2Index then
                techPoint = kSelectedAlienSpawn
            end
        end

        if not techPoint and HasConfigMode("CustomSpawns") and kCustomTechPointData then
            techPoint = originalNS2GRGetChooseTechPoint(
                self,
                UpdateWithCustomSpawnLocations(techPoints, teamNumber),
                teamNumber
            )

            if techPoint then
                techPoints = UpdateWithRemainingTechPoints(
                    string.lower(techPoint:GetLocationName()),
                    techPoints,
                    teamNumber
                )
            end
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

    local gameInfo = GetGameInfoEntity()
    if gameInfo then
        gameInfo:SetSpawnSelection(-1)
        gameInfo:SetSpawnSelectionEnabled(HasConfigMode("AliensChoose"))
    end
end
table.insert(gGameEndFunctions, OnGameEndClearSpawns)

local function UpdateEnemySpawnData(tpTable, currentLoc, enemySpawns)
    if not enemySpawns then
        return
    end

    for _, enemySpawn in ipairs(enemySpawns) do
        local loc

        if type(enemySpawn) == "table" then
            loc = string.lower(enemySpawn.name)
        else
            loc = string.lower(enemySpawn)
        end

        table.insert(tpTable[currentLoc].enemySpawns, loc)
    end
end

local function BuildEmptyTechPointData(techPoints)
    local tpTable = {}

    for _, tp in ipairs(techPoints) do
        tpTable[string.lower(tp:GetLocationName())] = {
            allowedTeamNumber = 3,
            chooseWeight = 0,
            enemySpawns = {},
        }
    end

    return tpTable
end

local function BuildCustomTechPointDataFromMapConfig()
    local customSpawnData = GetMapSpecificSpawns()
    if not customSpawnData or not HasConfigMode("CustomSpawns") then
        return false
    end

    local techPoints = EntityListToTable(Shared.GetEntitiesWithClassname("TechPoint"))
    local tpTable = BuildEmptyTechPointData(techPoints)

    local hasAlienSpawn = false
    local hasMarineSpawn = false
    local bothCount = 0

    for _, currentTechPoint in ipairs(techPoints) do
        local lowerLoc = string.lower(currentTechPoint:GetLocationName())

        for _, spawnEntry in ipairs(customSpawnData) do
            if string.lower(spawnEntry.name) == lowerLoc then
                local teamName = string.lower(spawnEntry.team or "")
                local chooseWeight = spawnEntry.chooseWeight or spawnEntry.weight or 1

                if teamName == "marines" then
                    tpTable[lowerLoc].allowedTeamNumber = 1
                    tpTable[lowerLoc].chooseWeight = chooseWeight
                    tpTable[lowerLoc].enemySpawns = {}
                    UpdateEnemySpawnData(tpTable, lowerLoc, spawnEntry.enemyspawns)
                    hasMarineSpawn = true

                elseif teamName == "aliens" then
                    tpTable[lowerLoc].allowedTeamNumber = 2
                    tpTable[lowerLoc].chooseWeight = chooseWeight
                    tpTable[lowerLoc].enemySpawns = {}
                    UpdateEnemySpawnData(tpTable, lowerLoc, spawnEntry.enemyspawns)
                    hasAlienSpawn = true

                elseif teamName == "both" then
                    tpTable[lowerLoc].allowedTeamNumber = 0
                    tpTable[lowerLoc].chooseWeight = chooseWeight
                    tpTable[lowerLoc].enemySpawns = {}
                    UpdateEnemySpawnData(tpTable, lowerLoc, spawnEntry.enemyspawns)

                    bothCount = bothCount + 1
                    if bothCount >= 2 then
                        hasAlienSpawn = true
                        hasMarineSpawn = true
                    end
                end
            end
        end
    end

    if (hasMarineSpawn and hasAlienSpawn)
        or (hasMarineSpawn and bothCount >= 1)
        or (hasAlienSpawn and bothCount >= 1) then

        kCustomTechPointData = tpTable
        Server.spawnSelectionOverrides = nil
        return true
    end

    LogSpawnSelector(string.format(
        "Invalid custom spawn data for map: %s",
        Shared.GetMapName()
    ))
    return false
end

local function BuildCustomTechPointDataFromOverrides()
    if not Server.spawnSelectionOverrides then
        return false
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
        kCustomTechPointData = BuildEmptyTechPointData(techPoints)

        for i = 1, #validSpawns do
            kCustomTechPointData[validSpawns[i]] = {
                allowedTeamNumber = teamSpawns[i],
                chooseWeight = 1,
                enemySpawns = enemySpawns[i],
            }
        end

        return true
    end

    return false
end

local function ApplyCustomTechPointDataToTechPoints(techPoints)
    if not kCustomTechPointData then
        return
    end

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

local function InitializeSpawnSelection()
    RefreshSpawnConfigModes()

    local gameInfo = GetGameInfoEntity()
    local techPoints = EntityListToTable(Shared.GetEntitiesWithClassname("TechPoint"))

    for _, tp in ipairs(techPoints) do
        tp:SetAllowedTeam(0)
    end

    if gameInfo then
        gameInfo:SetSpawnSelectionEnabled(HasConfigMode("AliensChoose"))
        gameInfo:SetSpawnSelection(-1)
    end

    kCustomTechPointData = nil

    if HasConfigMode("CustomSpawns") then
        local builtFromMapConfig = BuildCustomTechPointDataFromMapConfig()

        if not builtFromMapConfig and Server.spawnSelectionOverrides then
            BuildCustomTechPointDataFromOverrides()
        end

        if kCustomTechPointData then
            ApplyCustomTechPointDataToTechPoints(techPoints)
            LogSpawnSelector(string.format(
                "Applied custom spawn rules for map: %s",
                Shared.GetMapName()
            ))
            GetGamerules():ResetGame()
            Server.spawnSelectionOverrides = nil
        end
    end

    kSpawnSelectorInitialized = true
end

local function UpdateSpawnForMapSpecificSetups(teamSpawn)
    local mapName = Shared.GetMapName()

    if teamSpawn then
        teamSpawn = string.lower(teamSpawn)

        if kFriendlySpawnHelpers[mapName] and kFriendlySpawnHelpers[mapName][teamSpawn] then
            teamSpawn = kFriendlySpawnHelpers[mapName][teamSpawn]

            if type(teamSpawn) == "table" then
                teamSpawn = teamSpawn[math.random(1, #teamSpawn)]
            end
        end
    end

    return teamSpawn
end

local function onSpawnSelectionMessage(client, message)
    if not HasConfigMode("AliensChoose") then
        return
    end

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

            SendAlienTeamMessage(kSelectedAlienSpawn:GetLocationName())

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

            SendAlienTeamMessage(nil)
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
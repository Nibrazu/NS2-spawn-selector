-- Spawn Selector config loader

local kSpawnSelectorConfigDirectory = "lua/SpawnSelector/config/"
local kDefaultSpawnSelectorConfigFileName = kSpawnSelectorConfigDirectory .. "DEFAULT.json"
local kCustomConfigPattern = kSpawnSelectorConfigDirectory .. "*-CONFIG.json"

local SpawnSelectorConfig = {}

local kDefaultSpawnSelectorConfig = {
    CustomSpawnModes = {
        "AliensChoose",
        "CustomSpawns"
    },
    CustomSpawns = {}
}

local function LogConfig(message)
    Shared.Message(string.format("[SpawnSelector] %s", message))
end

local function DeepCopyTable(source)
    if type(source) ~= "table" then
        return source
    end

    local result = {}

    for k, v in pairs(source) do
        result[k] = DeepCopyTable(v)
    end

    return result
end

local function MergeTableDefaults(target, defaults)
    if type(target) ~= "table" then
        target = {}
    end

    for k, v in pairs(defaults) do
        if type(v) == "table" then
            if type(target[k]) ~= "table" then
                target[k] = DeepCopyTable(v)
            else
                MergeTableDefaults(target[k], v)
            end
        elseif target[k] == nil then
            target[k] = v
        end
    end

    return target
end

local function CountTableKeys(t)
    if type(t) ~= "table" then
        return 0
    end

    local count = 0

    for _ in pairs(t) do
        count = count + 1
    end

    return count
end

local function LoadJsonFile(fileName)
    local file = io.open(fileName, "r")

    if not file then
        return nil
    end

    local contents = file:read("*all")
    file:close()

    if not contents or contents == "" then
        LogConfig(string.format("Config file is empty: %s", fileName))
        return nil
    end

    local success, decoded = pcall(json.decode, contents)

    if not success or type(decoded) ~= "table" then
        LogConfig(string.format("Failed to decode config file: %s", fileName))
        return nil
    end

    return decoded
end

local function GetCustomConfigFiles()
    local files = {}

    if Shared and Shared.GetMatchingFileNames then
        local success = pcall(function()
            Shared.GetMatchingFileNames(kCustomConfigPattern, false, files)
        end)

        if not success then
            LogConfig("Failed to scan for custom *-CONFIG.json files.")
        end
    else
        LogConfig("Shared.GetMatchingFileNames unavailable. Cannot scan for custom *-CONFIG.json files.")
    end

    table.sort(files)

    return files
end

local function GetConfigLoadPriority()
    local configFiles = GetCustomConfigFiles()

    if #configFiles > 1 then
        LogConfig(string.format(
            "Multiple custom config files found. Loading first alphabetically: %s",
            configFiles[1]
        ))
    end

    table.insert(configFiles, kDefaultSpawnSelectorConfigFileName)

    return configFiles
end

local function LoadFirstAvailableConfig()
    local configLoadPriority = GetConfigLoadPriority()

    for _, fileName in ipairs(configLoadPriority) do
        local loadedConfig = LoadJsonFile(fileName)

        if type(loadedConfig) == "table" then
            LogConfig(string.format(
                "Loaded config file: %s (%s map config%s)",
                fileName,
                tostring(CountTableKeys(loadedConfig.CustomSpawns or {})),
                CountTableKeys(loadedConfig.CustomSpawns or {}) == 1 and "" or "s"
            ))

            return loadedConfig
        end
    end

    LogConfig("No valid config file found. Falling back to default in-memory config.")

    return DeepCopyTable(kDefaultSpawnSelectorConfig)
end

local function LoadSpawnSelectorConfig()
    local loadedConfig = LoadFirstAvailableConfig()

    SpawnSelectorConfig = MergeTableDefaults(loadedConfig, kDefaultSpawnSelectorConfig)
end

function GetSpawnSelectorConfigValue(key)
    if type(SpawnSelectorConfig) ~= "table" then
        return nil
    end

    return SpawnSelectorConfig[key]
end

function ReloadSpawnSelectorConfig()
    LoadSpawnSelectorConfig()
end

LoadSpawnSelectorConfig()
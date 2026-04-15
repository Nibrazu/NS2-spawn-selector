-- Spawn Selector config loader

local kSpawnSelectorConfigFileName = "configs/spawnselector/DEFAULT.json"
local SpawnSelectorConfig = {}

local kDefaultSpawnSelectorConfig = {
    CustomSpawnModes = {
        "AliensChoose",
        "CustomSpawns"
    },

    CustomSpawns = {}
}

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

local function LoadSpawnSelectorConfig()
    local loadedConfig = LoadConfigFile(kSpawnSelectorConfigFileName)

    if type(loadedConfig) ~= "table" then
        Shared.Message(string.format(
            "[SpawnSelector] Failed to load config file: %s. Falling back to default in-memory config.",
            kSpawnSelectorConfigFileName
        ))

        loadedConfig = DeepCopyTable(kDefaultSpawnSelectorConfig)
    end

    SpawnSelectorConfig = MergeTableDefaults(loadedConfig, kDefaultSpawnSelectorConfig)
    return SpawnSelectorConfig
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
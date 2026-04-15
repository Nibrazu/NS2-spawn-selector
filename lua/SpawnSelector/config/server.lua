-- Spawn Selector config loader

local kSpawnSelectorConfigFileName = "lua/SpawnSelector/config/DEFAULT.json"
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
        return nil
    end

    local success, decoded = pcall(json.decode, contents)
    if not success or type(decoded) ~= "table" then
        return nil
    end

    return decoded
end

local function LoadSpawnSelectorConfig()
    local loadedConfig = LoadJsonFile(kSpawnSelectorConfigFileName)

    if type(loadedConfig) ~= "table" then
        LogConfig(string.format(
            "Failed to load config file: %s. Falling back to default in-memory config.",
            kSpawnSelectorConfigFileName
        ))

        loadedConfig = DeepCopyTable(kDefaultSpawnSelectorConfig)
    else
        LogConfig(string.format(
            "Loaded config file: %s (%s map config%s)",
            kSpawnSelectorConfigFileName,
            tostring(CountTableKeys(loadedConfig.CustomSpawns or {})),
            CountTableKeys(loadedConfig.CustomSpawns or {}) == 1 and "" or "s"
        ))
    end

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
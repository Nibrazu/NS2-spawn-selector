-- Spawn Selector

local networkVars =
{
    spawnSelection = "boolean",
    spawnSelected = "entityid"
}

local originalGameInfoOnCreate
originalGameInfoOnCreate = Class_ReplaceMethod("GameInfo", "OnCreate",
    function(self)

        if originalGameInfoOnCreate then
            originalGameInfoOnCreate(self)
        end

        if Server then
            self.spawnSelection = false
            self.spawnSelected = -1
        end

    end
)

function GameInfo:GetSpawnSelectionEnabled()
    return self.spawnSelection
end

function GameInfo:GetSpawnSelection()
    return self.spawnSelected
end

if Server then

    function GameInfo:SetSpawnSelectionEnabled(state)
        self.spawnSelection = state and true or false
    end

    function GameInfo:SetSpawnSelection(techPointId)
        self.spawnSelected = techPointId
    end

end

Class_Reload("GameInfo", networkVars)
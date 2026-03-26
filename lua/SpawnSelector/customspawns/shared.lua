-- Spawn Selector

function TechPoint:SetAllowedTeam(teamNumber)
	teamNumber = teamNumber or 3
    self.allowedTeamNumber = Clamp(teamNumber, 0, 3)
end

function TechPoint:GetTeamNumberAllowed()
    return self.allowedTeamNumber
end

if Server then

	function TechPoint:Reset()
	    local previousAllowedTeam = self.allowedTeamNumber
	    self:OnInitialized()
	    self:ClearAttached()
	    self.allowedTeamNumber = previousAllowedTeam
	end

end

Class_Reload( "TechPoint", { allowedTeamNumber = "integer (0 to 3)" } )

local kSelectSpawnMessage =
{
	techPointId = "entityid"
}

Shared.RegisterNetworkMessage("SSSelectSpawn", kSelectSpawnMessage)
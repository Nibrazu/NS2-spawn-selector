-- Spawn Selector

gGameEndFunctions = { }

local originalNS2GameRulesEndGame
originalNS2GameRulesEndGame = Class_ReplaceMethod("NS2Gamerules", "EndGame",
    function(self, winningTeam, autoConceded)
        originalNS2GameRulesEndGame(self, winningTeam, autoConceded)

        for i = #gGameEndFunctions, 1, -1 do
            gGameEndFunctions[i](self, winningTeam)
        end
    end
)
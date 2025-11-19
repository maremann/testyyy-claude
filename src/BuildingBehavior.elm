module BuildingBehavior exposing (updateBuildingBehavior)
import GameStrings
import Types exposing (..)
updateBuildingBehavior : Float -> Building -> ( Building, Bool )
updateBuildingBehavior deltaSeconds building =
    case building.behavior of
        Idle -> ( building, False )
        UnderConstruction -> ( building, False )
        SpawnHouse ->
            let
                newTimer = building.behaviorTimer + deltaSeconds
            in
            if newTimer >= building.behaviorDuration then
                let
                    randomValue =
                        toFloat (modBy 15000 (building.id * 1000 + round (building.behaviorTimer * 1000)))
                            / 1000.0
                    newDuration = 30.0 + randomValue
                in
                ( { building | behaviorTimer = 0, behaviorDuration = newDuration }, True )
            else
                ( { building | behaviorTimer = newTimer }, False )
        GenerateGold ->
            let
                newTimer = building.behaviorTimer + deltaSeconds
            in
            if newTimer >= building.behaviorDuration then
                let
                    randomSeed = building.id * 1000 + round (building.behaviorTimer * 1000)
                    durationRandomValue = toFloat (modBy 30000 randomSeed) / 1000.0
                    newDuration = 15.0 + durationRandomValue
                    ( minGold, maxGold ) =
                        if building.buildingType == GameStrings.buildingTypeHouse then
                            ( 45, 90 )
                        else
                            ( 450, 900 )
                    goldRange = maxGold - minGold
                    goldRandomValue = modBy (goldRange + 1) (randomSeed + 12345)
                    goldAmount = minGold + goldRandomValue
                in
                ( { building | behaviorTimer = 0, behaviorDuration = newDuration, coffer = building.coffer + goldAmount }, False )
            else
                ( { building | behaviorTimer = newTimer }, False )
        BuildingDead -> ( building, False )
        BuildingDebugError _ -> ( building, False )

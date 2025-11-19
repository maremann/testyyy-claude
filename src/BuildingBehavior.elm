module BuildingBehavior exposing (updateBuildingBehavior)

import Types exposing (..)


-- BUILDING BEHAVIOR


{-| Update building behavior based on timer
Returns (Building, Bool) where Bool indicates if a house should be spawned
-}
updateBuildingBehavior : Float -> Building -> ( Building, Bool )
updateBuildingBehavior deltaSeconds building =
    case building.behavior of
        Idle ->
            ( building, False )

        UnderConstruction ->
            -- Not implemented yet
            ( building, False )

        SpawnHouse ->
            let
                newTimer =
                    building.behaviorTimer + deltaSeconds
            in
            if newTimer >= building.behaviorDuration then
                -- Time to spawn a house
                -- Reset timer with new pseudo-random duration (30-45s)
                let
                    -- Use building ID and current timer to generate pseudo-random duration
                    randomValue =
                        toFloat (modBy 15000 (building.id * 1000 + round (building.behaviorTimer * 1000)))
                            / 1000.0

                    newDuration =
                        30.0 + randomValue
                in
                ( { building | behaviorTimer = 0, behaviorDuration = newDuration }, True )

            else
                ( { building | behaviorTimer = newTimer }, False )

        GenerateGold ->
            let
                newTimer =
                    building.behaviorTimer + deltaSeconds
            in
            if newTimer >= building.behaviorDuration then
                -- Time to generate gold
                -- Reset timer with new pseudo-random duration (15-45s)
                let
                    -- Use building ID and current timer to generate pseudo-random values
                    randomSeed =
                        building.id * 1000 + round (building.behaviorTimer * 1000)

                    durationRandomValue =
                        toFloat (modBy 30000 randomSeed) / 1000.0

                    newDuration =
                        15.0 + durationRandomValue

                    -- Different gold amounts for House (45-90) vs Guild (450-900)
                    ( minGold, maxGold ) =
                        if building.buildingType == "House" then
                            ( 45, 90 )

                        else
                            ( 450, 900 )

                    goldRange =
                        maxGold - minGold

                    goldRandomValue =
                        modBy (goldRange + 1) (randomSeed + 12345)

                    goldAmount =
                        minGold + goldRandomValue
                in
                ( { building | behaviorTimer = 0, behaviorDuration = newDuration, coffer = building.coffer + goldAmount }, False )

            else
                ( { building | behaviorTimer = newTimer }, False )

        BuildingDead ->
            ( building, False )

        BuildingDebugError _ ->
            ( building, False )

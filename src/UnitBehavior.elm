module UnitBehavior exposing
    ( updateGarrisonSpawning
    , updateUnitBehavior
    )

import Types exposing (..)

-- Dummy implementation: No autonomous behavior
-- Returns (unit, needsPath)
updateUnitBehavior : Float -> List Building -> Unit -> ( Unit, Bool )
updateUnitBehavior deltaSeconds buildings unit =
    -- No behavior processing - units just exist
    ( unit, False )

-- Garrison spawning logic (kept - this is about spawning mechanics, not AI)
updateGarrisonSpawning : Float -> Building -> ( Building, List ( String, Int ) )
updateGarrisonSpawning deltaSeconds building =
    let
        ( updatedConfig, unitsToSpawn ) =
            List.foldl
                (\slot ( accConfig, accSpawn ) ->
                    if slot.currentCount < slot.maxCount then
                        let
                            newTimer = slot.spawnTimer + deltaSeconds
                        in
                        if newTimer >= 30.0 then
                            ( { slot | spawnTimer = 0, currentCount = slot.currentCount + 1 } :: accConfig
                            , ( slot.unitType, building.id ) :: accSpawn
                            )
                        else
                            ( { slot | spawnTimer = newTimer } :: accConfig
                            , accSpawn
                            )
                    else
                        ( slot :: accConfig
                        , accSpawn
                        )
                )
                ( [], [] )
                building.garrisonConfig

        totalOccupied =
            List.foldl (\slot acc -> acc + slot.currentCount) 0 updatedConfig
    in
    ( { building | garrisonConfig = List.reverse updatedConfig, garrisonOccupied = totalOccupied }
    , List.reverse unitsToSpawn
    )

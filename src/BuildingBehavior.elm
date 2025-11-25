module BuildingBehavior exposing (updateBuildingBehavior)

import GameStrings
import Types exposing (..)


{-| Update building behavior
Returns: (updated building, gold generated)
-}
updateBuildingBehavior : Float -> Building -> ( Building, Int )
updateBuildingBehavior deltaSeconds building =
    case building.buildingType of
        _ ->
            if building.buildingType == GameStrings.buildingTypeCastle then
                updateCastleBehavior deltaSeconds building

            else if building.buildingType == GameStrings.buildingTypeHouse then
                updateHouseBehavior deltaSeconds building

            else
                -- Other buildings: no behavior yet
                ( building, 0 )


{-| Castle behavior: generate gold and manage garrison spawning
-}
updateCastleBehavior : Float -> Building -> ( Building, Int )
updateCastleBehavior deltaSeconds building =
    -- Gold generation
    let
        newGoldTimer =
            building.behaviorTimer + deltaSeconds

        ( buildingAfterGold, goldGenerated ) =
            if newGoldTimer >= building.behaviorDuration then
                -- Generate gold and reset timer
                ( { building | behaviorTimer = 0 }, 2 )

            else
                -- Update timer
                ( { building | behaviorTimer = newGoldTimer }, 0 )
    in
    -- Garrison spawning (handled separately in UnitBehavior.elm)
    -- We just return the building with updated gold timer
    ( buildingAfterGold, goldGenerated )


{-| House behavior: accumulate gold in coffer
-}
updateHouseBehavior : Float -> Building -> ( Building, Int )
updateHouseBehavior deltaSeconds building =
    -- Gold accumulation
    let
        newGoldTimer =
            building.behaviorTimer + deltaSeconds

        buildingAfterGold =
            if newGoldTimer >= building.behaviorDuration then
                -- Add gold to coffer and reset timer
                { building | behaviorTimer = 0, coffer = building.coffer + 2 }

            else
                -- Update timer
                { building | behaviorTimer = newGoldTimer }
    in
    -- House doesn't generate gold for player directly (Tax Collectors collect from coffer)
    ( buildingAfterGold, 0 )

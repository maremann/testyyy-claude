module BuildingBehavior exposing (updateBuildingBehavior)

import Types exposing (..)

-- Dummy implementation: No autonomous behavior
-- Returns (building, shouldSpawnHouse)
updateBuildingBehavior : Float -> Building -> ( Building, Bool )
updateBuildingBehavior deltaSeconds building =
    -- No behavior processing - buildings just exist
    ( building, False )

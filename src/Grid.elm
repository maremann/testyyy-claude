module Grid exposing
    ( addBuildingGridOccupancy
    , addBuildingOccupancy
    , addUnitOccupancy
    , areBuildGridCellsOccupied
    , findAdjacentHouseLocation
    , findNearestUnoccupiedTile
    , getBuildingAreaCells
    , getBuildingEntrance
    , getBuildingGridCells
    , getBuildingGridCellsWithSpacing
    , getBuildingPathfindingCells
    , getCityActiveArea
    , getCitySearchArea
    , getUnitPathfindingCells
    , isPathfindingCellOccupied
    , isValidBuildingPlacement
    , removeBuildingGridOccupancy
    , removeBuildingOccupancy
    , removeUnitOccupancy
    )

import Dict exposing (Dict)
import Types exposing (..)


-- BUILDING GRID OCCUPANCY


{-| Get the build grid cells occupied by a building (includes 1-cell spacing requirement)
-}
getBuildingGridCellsWithSpacing : Building -> List ( Int, Int )
getBuildingGridCellsWithSpacing building =
    let
        sizeCells =
            buildingSizeToGridCells building.size

        -- Include 1-cell border for spacing requirement
        startX =
            building.gridX - 1

        startY =
            building.gridY - 1

        endX =
            building.gridX + sizeCells

        endY =
            building.gridY + sizeCells

        xs =
            List.range startX endX

        ys =
            List.range startY endY
    in
    List.concatMap (\x -> List.map (\y -> ( x, y )) ys) xs


{-| Get the build grid cells actually occupied by a building (no spacing)
-}
getBuildingGridCells : Building -> List ( Int, Int )
getBuildingGridCells building =
    let
        sizeCells =
            buildingSizeToGridCells building.size

        xs =
            List.range building.gridX (building.gridX + sizeCells - 1)

        ys =
            List.range building.gridY (building.gridY + sizeCells - 1)
    in
    List.concatMap (\x -> List.map (\y -> ( x, y )) ys) xs


{-| Add a building's occupancy to the building grid
-}
addBuildingGridOccupancy : Building -> Dict ( Int, Int ) Int -> Dict ( Int, Int ) Int
addBuildingGridOccupancy building occupancy =
    let
        cells =
            getBuildingGridCells building

        incrementCell cell dict =
            Dict.update cell
                (\maybeCount ->
                    case maybeCount of
                        Just count ->
                            Just (count + 1)

                        Nothing ->
                            Just 1
                )
                dict
    in
    List.foldl incrementCell occupancy cells


{-| Remove a building's occupancy from the building grid
-}
removeBuildingGridOccupancy : Building -> Dict ( Int, Int ) Int -> Dict ( Int, Int ) Int
removeBuildingGridOccupancy building occupancy =
    let
        cells =
            getBuildingGridCells building

        decrementCell cell dict =
            Dict.update cell
                (\maybeCount ->
                    case maybeCount of
                        Just count ->
                            if count <= 1 then
                                Nothing

                            else
                                Just (count - 1)

                        Nothing ->
                            Nothing
                )
                dict
    in
    List.foldl decrementCell occupancy cells


{-| Check if any build grid cells are occupied (for placement validation)
-}
areBuildGridCellsOccupied : List ( Int, Int ) -> Dict ( Int, Int ) Int -> Bool
areBuildGridCellsOccupied cells occupancy =
    List.any (\cell -> Dict.member cell occupancy) cells


{-| Check if a building placement is valid
-}
isValidBuildingPlacement : Int -> Int -> BuildingSize -> MapConfig -> GridConfig -> Dict ( Int, Int ) Int -> List Building -> Bool
isValidBuildingPlacement gridX gridY size mapConfig gridConfig buildingOccupancy buildings =
    let
        sizeCells =
            buildingSizeToGridCells size

        -- Check map bounds
        maxGridX =
            floor (mapConfig.width / gridConfig.buildGridSize)

        maxGridY =
            floor (mapConfig.height / gridConfig.buildGridSize)

        inBounds =
            gridX >= 0
                && gridY >= 0
                && (gridX + sizeCells) <= maxGridX
                && (gridY + sizeCells) <= maxGridY

        -- Check occupancy (including 1-cell spacing)
        tempBuilding =
            { id = 0
            , owner = Player
            , gridX = gridX
            , gridY = gridY
            , size = size
            , hp = 0
            , maxHp = 0
            , garrisonSlots = 0
            , garrisonOccupied = 0
            , buildingType = ""
            , behavior = Idle
            , behaviorTimer = 0
            , behaviorDuration = 0
            , coffer = 0
            , garrisonConfig = []
            , activeRadius = 192
            , searchRadius = 384
            , tags = [ BuildingTag ]
            }

        cellsWithSpacing =
            getBuildingGridCellsWithSpacing tempBuilding

        notOccupied =
            not (areBuildGridCellsOccupied cellsWithSpacing buildingOccupancy)

        -- Check if at least half the building tiles are within city search area
        buildingCells =
            getBuildingGridCells tempBuilding

        citySearchArea =
            getCitySearchArea buildings

        searchAreaSet =
            List.foldl (\cell acc -> Dict.insert cell () acc) Dict.empty citySearchArea

        tilesInSearchArea =
            List.filter (\cell -> Dict.member cell searchAreaSet) buildingCells
                |> List.length

        totalTiles =
            List.length buildingCells

        atLeastHalfInSearchArea =
            -- If there are no buildings yet, allow placement anywhere
            if List.isEmpty buildings then
                True

            else
                toFloat tilesInSearchArea >= toFloat totalTiles / 2
    in
    inBounds && notOccupied && atLeastHalfInSearchArea



-- PATHFINDING OCCUPANCY


{-| Calculate which pathfinding grid cells a building occupies.
Returns a list of (x, y) coordinates in pathfinding grid space.
-}
getBuildingPathfindingCells : GridConfig -> Building -> List ( Int, Int )
getBuildingPathfindingCells gridConfig building =
    let
        -- Building position in world pixels
        buildingWorldX =
            toFloat building.gridX * gridConfig.buildGridSize

        buildingWorldY =
            toFloat building.gridY * gridConfig.buildGridSize

        -- Building size in world pixels
        buildingSizeCells =
            buildingSizeToGridCells building.size

        buildingWorldWidth =
            toFloat buildingSizeCells * gridConfig.buildGridSize

        buildingWorldHeight =
            toFloat buildingSizeCells * gridConfig.buildGridSize

        -- Convert to pathfinding grid coordinates
        startPfX =
            floor (buildingWorldX / gridConfig.pathfindingGridSize)

        startPfY =
            floor (buildingWorldY / gridConfig.pathfindingGridSize)

        endPfX =
            floor ((buildingWorldX + buildingWorldWidth - 1) / gridConfig.pathfindingGridSize)

        endPfY =
            floor ((buildingWorldY + buildingWorldHeight - 1) / gridConfig.pathfindingGridSize)

        -- Generate all cells
        xs =
            List.range startPfX endPfX

        ys =
            List.range startPfY endPfY
    in
    List.concatMap (\x -> List.map (\y -> ( x, y )) ys) xs


{-| Get the entrance tile coordinates for a building in build grid space.
- Small (1x1): The tile itself (gridX, gridY)
- Medium (2x2): Bottom left tile (gridX, gridY + 1)
- Large (3x3): Bottom center tile (gridX + 1, gridY + 2)
- Huge (4x4): Bottom middle-left tile (gridX + 1, gridY + 3)
-}
getBuildingEntrance : Building -> ( Int, Int )
getBuildingEntrance building =
    case building.size of
        Small ->
            ( building.gridX, building.gridY )

        Medium ->
            ( building.gridX, building.gridY + 1 )

        Large ->
            ( building.gridX + 1, building.gridY + 2 )

        Huge ->
            ( building.gridX + 1, building.gridY + 3 )


{-| Find a valid adjacent location to spawn a House near existing buildings.
Returns Nothing if no valid location found.
-}
findAdjacentHouseLocation : MapConfig -> GridConfig -> List Building -> Dict ( Int, Int ) Int -> Maybe ( Int, Int )
findAdjacentHouseLocation mapConfig gridConfig buildings buildingOccupancy =
    let
        houseSize =
            Medium

        -- Get all cells adjacent to all buildings (with 1 cell spacing)
        adjacentCells =
            buildings
                |> List.concatMap (\b -> getBuildingAreaCells b 1)
                |> List.filter
                    (\( gx, gy ) ->
                        -- Check if this would be valid for a house
                        isValidBuildingPlacement gx gy houseSize mapConfig gridConfig buildingOccupancy buildings
                    )
                |> List.take 100

        -- Limit to first 100 candidates for performance
        -- Pick the first valid one (could randomize in future)
    in
    List.head adjacentCells


{-| Calculate all build grid cells within a certain distance (in build grid cells) of a building.
Returns a list of (gridX, gridY) coordinates.
-}
getBuildingAreaCells : Building -> Int -> List ( Int, Int )
getBuildingAreaCells building radiusInCells =
    let
        -- Get building center in build grid coordinates
        sizeCells =
            buildingSizeToGridCells building.size

        centerX =
            building.gridX + sizeCells // 2

        centerY =
            building.gridY + sizeCells // 2

        -- Generate all cells within radius
        minX =
            centerX - radiusInCells

        maxX =
            centerX + radiusInCells

        minY =
            centerY - radiusInCells

        maxY =
            centerY + radiusInCells

        allCells =
            List.concatMap
                (\x ->
                    List.map (\y -> ( x, y ))
                        (List.range minY maxY)
                )
                (List.range minX maxX)
    in
    allCells


{-| Calculate city active area: all build grid cells within 3 cells of any friendly building
-}
getCityActiveArea : List Building -> List ( Int, Int )
getCityActiveArea buildings =
    buildings
        |> List.filter (\b -> b.owner == Player)
        |> List.concatMap (\b -> getBuildingAreaCells b 3)
        |> List.foldl (\cell acc -> Dict.insert cell () acc) Dict.empty
        |> Dict.keys


{-| Calculate city search area: all build grid cells within 6 cells of any friendly building
-}
getCitySearchArea : List Building -> List ( Int, Int )
getCitySearchArea buildings =
    buildings
        |> List.filter (\b -> b.owner == Player)
        |> List.concatMap (\b -> getBuildingAreaCells b 6)
        |> List.foldl (\cell acc -> Dict.insert cell () acc) Dict.empty
        |> Dict.keys


{-| Add a building's occupancy to the pathfinding grid
-}
addBuildingOccupancy : GridConfig -> Building -> Dict ( Int, Int ) Int -> Dict ( Int, Int ) Int
addBuildingOccupancy gridConfig building occupancy =
    let
        cells =
            getBuildingPathfindingCells gridConfig building

        incrementCell cell dict =
            Dict.update cell
                (\maybeCount ->
                    case maybeCount of
                        Just count ->
                            Just (count + 1)

                        Nothing ->
                            Just 1
                )
                dict
    in
    List.foldl incrementCell occupancy cells


{-| Remove a building's occupancy from the pathfinding grid
-}
removeBuildingOccupancy : GridConfig -> Building -> Dict ( Int, Int ) Int -> Dict ( Int, Int ) Int
removeBuildingOccupancy gridConfig building occupancy =
    let
        cells =
            getBuildingPathfindingCells gridConfig building

        decrementCell cell dict =
            Dict.update cell
                (\maybeCount ->
                    case maybeCount of
                        Just count ->
                            if count <= 1 then
                                Nothing

                            else
                                Just (count - 1)

                        Nothing ->
                            Nothing
                )
                dict
    in
    List.foldl decrementCell occupancy cells


{-| Check if a pathfinding grid cell is occupied
-}
isPathfindingCellOccupied : ( Int, Int ) -> Dict ( Int, Int ) Int -> Bool
isPathfindingCellOccupied cell occupancy =
    case Dict.get cell occupancy of
        Just count ->
            count > 0

        Nothing ->
            False



-- UNIT OCCUPANCY


{-| Calculate which pathfinding grid cells a unit occupies.
Unit diameter is half a pathfinding cell (16 pixels when pathfinding cell is 32).
A unit occupies all cells it touches.
-}
getUnitPathfindingCells : GridConfig -> Float -> Float -> List ( Int, Int )
getUnitPathfindingCells gridConfig worldX worldY =
    let
        -- Unit radius is quarter of pathfinding grid (8 pixels)
        unitRadius =
            gridConfig.pathfindingGridSize / 4

        -- Bounding box of the unit
        minX =
            worldX - unitRadius

        maxX =
            worldX + unitRadius

        minY =
            worldY - unitRadius

        maxY =
            worldY + unitRadius

        -- Convert to pathfinding grid coordinates
        startPfX =
            floor (minX / gridConfig.pathfindingGridSize)

        endPfX =
            floor (maxX / gridConfig.pathfindingGridSize)

        startPfY =
            floor (minY / gridConfig.pathfindingGridSize)

        endPfY =
            floor (maxY / gridConfig.pathfindingGridSize)

        -- Generate all cells
        xs =
            List.range startPfX endPfX

        ys =
            List.range startPfY endPfY
    in
    List.concatMap (\x -> List.map (\y -> ( x, y )) ys) xs


{-| Add a unit's occupancy to the pathfinding grid
-}
addUnitOccupancy : GridConfig -> Float -> Float -> Dict ( Int, Int ) Int -> Dict ( Int, Int ) Int
addUnitOccupancy gridConfig worldX worldY occupancy =
    let
        cells =
            getUnitPathfindingCells gridConfig worldX worldY

        incrementCell cell dict =
            Dict.update cell
                (\maybeCount ->
                    case maybeCount of
                        Just count ->
                            Just (count + 1)

                        Nothing ->
                            Just 1
                )
                dict
    in
    List.foldl incrementCell occupancy cells


{-| Remove a unit's occupancy from the pathfinding grid
-}
removeUnitOccupancy : GridConfig -> Float -> Float -> Dict ( Int, Int ) Int -> Dict ( Int, Int ) Int
removeUnitOccupancy gridConfig worldX worldY occupancy =
    let
        cells =
            getUnitPathfindingCells gridConfig worldX worldY

        decrementCell cell dict =
            Dict.update cell
                (\maybeCount ->
                    case maybeCount of
                        Just count ->
                            if count <= 1 then
                                Nothing

                            else
                                Just (count - 1)

                        Nothing ->
                            Nothing
                )
                dict
    in
    List.foldl decrementCell occupancy cells


{-| Find the nearest unoccupied pathfinding cell to a given world position
-}
findNearestUnoccupiedTile : GridConfig -> MapConfig -> Dict ( Int, Int ) Int -> Float -> Float -> ( Float, Float )
findNearestUnoccupiedTile gridConfig mapConfig occupancy targetX targetY =
    let
        -- Convert target to pathfinding grid
        targetPfX =
            floor (targetX / gridConfig.pathfindingGridSize)

        targetPfY =
            floor (targetY / gridConfig.pathfindingGridSize)

        -- Search in expanding rings
        searchRadius maxRadius currentRadius =
            if currentRadius > maxRadius then
                -- Fallback to center if no unoccupied cell found
                ( targetX, targetY )

            else
                let
                    -- Generate cells in a ring at currentRadius
                    ringCells =
                        if currentRadius == 0 then
                            [ ( targetPfX, targetPfY ) ]

                        else
                            List.range -currentRadius currentRadius
                                |> List.concatMap
                                    (\dx ->
                                        List.range -currentRadius currentRadius
                                            |> List.filterMap
                                                (\dy ->
                                                    if abs dx == currentRadius || abs dy == currentRadius then
                                                        Just ( targetPfX + dx, targetPfY + dy )

                                                    else
                                                        Nothing
                                                )
                                    )

                    -- Find first unoccupied cell in ring
                    unoccupiedCell =
                        ringCells
                            |> List.filter
                                (\cell ->
                                    not (isPathfindingCellOccupied cell occupancy)
                                        && isWithinMapBounds gridConfig mapConfig cell
                                )
                            |> List.head
                in
                case unoccupiedCell of
                    Just ( pfX, pfY ) ->
                        -- Convert back to world coordinates (center of cell)
                        ( toFloat pfX * gridConfig.pathfindingGridSize + gridConfig.pathfindingGridSize / 2
                        , toFloat pfY * gridConfig.pathfindingGridSize + gridConfig.pathfindingGridSize / 2
                        )

                    Nothing ->
                        searchRadius maxRadius (currentRadius + 1)

        isWithinMapBounds : GridConfig -> MapConfig -> ( Int, Int ) -> Bool
        isWithinMapBounds gc mc ( pfX, pfY ) =
            let
                worldX =
                    toFloat pfX * gc.pathfindingGridSize

                worldY =
                    toFloat pfY * gc.pathfindingGridSize
            in
            worldX >= 0 && worldX < mc.width && worldY >= 0 && worldY < mc.height
    in
    searchRadius 50 0

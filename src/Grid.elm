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
getBuildingGridCellsWithSpacing : Building -> List ( Int, Int )
getBuildingGridCellsWithSpacing building =
    let
        sizeCells = buildingSizeToGridCells building.size
        startX = building.gridX - 1
        startY = building.gridY - 1
        endX = building.gridX + sizeCells
        endY = building.gridY + sizeCells
        xs = List.range startX endX
        ys = List.range startY endY
    in
    List.concatMap (\x -> List.map (\y -> ( x, y )) ys) xs
getBuildingGridCells : Building -> List ( Int, Int )
getBuildingGridCells building =
    let
        sizeCells = buildingSizeToGridCells building.size
        xs = List.range building.gridX (building.gridX + sizeCells - 1)
        ys = List.range building.gridY (building.gridY + sizeCells - 1)
    in
    List.concatMap (\x -> List.map (\y -> ( x, y )) ys) xs
addBuildingGridOccupancy : Building -> Dict ( Int, Int ) Int -> Dict ( Int, Int ) Int
addBuildingGridOccupancy building occupancy =
    let
        cells = getBuildingGridCells building
        incrementCell cell dict = Dict.update cell
                (\maybeCount ->
                    case maybeCount of
                        Just count -> Just (count + 1)
                        Nothing -> Just 1
                )
                dict
    in
    List.foldl incrementCell occupancy cells
removeBuildingGridOccupancy : Building -> Dict ( Int, Int ) Int -> Dict ( Int, Int ) Int
removeBuildingGridOccupancy building occupancy =
    let
        cells = getBuildingGridCells building
        decrementCell cell dict = Dict.update cell
                (\maybeCount ->
                    case maybeCount of
                        Just count ->
                            if count <= 1 then
                                Nothing
                            else
                                Just (count - 1)
                        Nothing -> Nothing
                )
                dict
    in
    List.foldl decrementCell occupancy cells
areBuildGridCellsOccupied : List ( Int, Int ) -> Dict ( Int, Int ) Int -> Bool
areBuildGridCellsOccupied cells occupancy = List.any (\cell -> Dict.member cell occupancy) cells
isValidBuildingPlacement : Int -> Int -> BuildingSize -> MapConfig -> GridConfig -> Dict ( Int, Int ) Int -> List Building -> Bool
isValidBuildingPlacement gridX gridY size mapConfig gridConfig buildingOccupancy buildings =
    let
        sizeCells = buildingSizeToGridCells size
        maxGridX = floor (mapConfig.width / gridConfig.buildGridSize)
        maxGridY = floor (mapConfig.height / gridConfig.buildGridSize)
        inBounds = gridX >= 0
                && gridY >= 0
                && (gridX + sizeCells) <= maxGridX
                && (gridY + sizeCells) <= maxGridY
        tempBuilding = { id = 0
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
        cellsWithSpacing = getBuildingGridCellsWithSpacing tempBuilding
        notOccupied =
            not (areBuildGridCellsOccupied cellsWithSpacing buildingOccupancy)
        buildingCells = getBuildingGridCells tempBuilding
        citySearchArea = getCitySearchArea buildings
        searchAreaSet =
            List.foldl (\cell acc -> Dict.insert cell () acc) Dict.empty citySearchArea
        tilesInSearchArea =
            List.filter (\cell -> Dict.member cell searchAreaSet) buildingCells
                |> List.length
        totalTiles = List.length buildingCells
        atLeastHalfInSearchArea =
            if List.isEmpty buildings then
                True
            else
                toFloat tilesInSearchArea >= toFloat totalTiles / 2
    in
    inBounds && notOccupied && atLeastHalfInSearchArea
getBuildingPathfindingCells : GridConfig -> Building -> List ( Int, Int )
getBuildingPathfindingCells gridConfig building =
    let
        buildingWorldX = toFloat building.gridX * gridConfig.buildGridSize
        buildingWorldY = toFloat building.gridY * gridConfig.buildGridSize
        buildingSizeCells = buildingSizeToGridCells building.size
        buildingWorldWidth = toFloat buildingSizeCells * gridConfig.buildGridSize
        buildingWorldHeight = toFloat buildingSizeCells * gridConfig.buildGridSize
        startPfX = floor (buildingWorldX / gridConfig.pathfindingGridSize)
        startPfY = floor (buildingWorldY / gridConfig.pathfindingGridSize)
        endPfX =
            floor ((buildingWorldX + buildingWorldWidth - 1) / gridConfig.pathfindingGridSize)
        endPfY =
            floor ((buildingWorldY + buildingWorldHeight - 1) / gridConfig.pathfindingGridSize)
        xs = List.range startPfX endPfX
        ys = List.range startPfY endPfY
    in
    List.concatMap (\x -> List.map (\y -> ( x, y )) ys) xs
getBuildingEntrance : Building -> ( Int, Int )
getBuildingEntrance building =
    case building.size of
        Small -> ( building.gridX, building.gridY )
        Medium -> ( building.gridX, building.gridY + 1 )
        Large -> ( building.gridX + 1, building.gridY + 2 )
        Huge -> ( building.gridX + 1, building.gridY + 3 )
findAdjacentHouseLocation : MapConfig -> GridConfig -> List Building -> Dict ( Int, Int ) Int -> Maybe ( Int, Int )
findAdjacentHouseLocation mapConfig gridConfig buildings buildingOccupancy =
    let
        houseSize = Medium
        adjacentCells = buildings
                |> List.concatMap (\b -> getBuildingAreaCells b 1)
                |> List.filter
                    (\( gx, gy ) ->
                        isValidBuildingPlacement gx gy houseSize mapConfig gridConfig buildingOccupancy buildings
                    )
                |> List.take 100
    in
    List.head adjacentCells
getBuildingAreaCells : Building -> Int -> List ( Int, Int )
getBuildingAreaCells building radiusInCells =
    let
        sizeCells = buildingSizeToGridCells building.size
        centerX = building.gridX + sizeCells // 2
        centerY = building.gridY + sizeCells // 2
        minX = centerX - radiusInCells
        maxX = centerX + radiusInCells
        minY = centerY - radiusInCells
        maxY = centerY + radiusInCells
        allCells = List.concatMap
                (\x -> List.map (\y -> ( x, y ))
                        (List.range minY maxY)
                )
                (List.range minX maxX)
    in
    allCells
getCityActiveArea : List Building -> List ( Int, Int )
getCityActiveArea buildings = buildings
        |> List.filter (\b -> b.owner == Player)
        |> List.concatMap (\b -> getBuildingAreaCells b 3)
        |> List.foldl (\cell acc -> Dict.insert cell () acc) Dict.empty
        |> Dict.keys
getCitySearchArea : List Building -> List ( Int, Int )
getCitySearchArea buildings = buildings
        |> List.filter (\b -> b.owner == Player)
        |> List.concatMap (\b -> getBuildingAreaCells b 6)
        |> List.foldl (\cell acc -> Dict.insert cell () acc) Dict.empty
        |> Dict.keys
addBuildingOccupancy : GridConfig -> Building -> Dict ( Int, Int ) Int -> Dict ( Int, Int ) Int
addBuildingOccupancy gridConfig building occupancy =
    let
        cells = getBuildingPathfindingCells gridConfig building
        incrementCell cell dict = Dict.update cell
                (\maybeCount ->
                    case maybeCount of
                        Just count -> Just (count + 1)
                        Nothing -> Just 1
                )
                dict
    in
    List.foldl incrementCell occupancy cells
removeBuildingOccupancy : GridConfig -> Building -> Dict ( Int, Int ) Int -> Dict ( Int, Int ) Int
removeBuildingOccupancy gridConfig building occupancy =
    let
        cells = getBuildingPathfindingCells gridConfig building
        decrementCell cell dict = Dict.update cell
                (\maybeCount ->
                    case maybeCount of
                        Just count ->
                            if count <= 1 then
                                Nothing
                            else
                                Just (count - 1)
                        Nothing -> Nothing
                )
                dict
    in
    List.foldl decrementCell occupancy cells
isPathfindingCellOccupied : ( Int, Int ) -> Dict ( Int, Int ) Int -> Bool
isPathfindingCellOccupied cell occupancy =
    case Dict.get cell occupancy of
        Just count -> count > 0
        Nothing -> False
getUnitPathfindingCells : GridConfig -> Float -> Float -> List ( Int, Int )
getUnitPathfindingCells gridConfig worldX worldY =
    let
        unitRadius = gridConfig.pathfindingGridSize / 4
        minX = worldX - unitRadius
        maxX = worldX + unitRadius
        minY = worldY - unitRadius
        maxY = worldY + unitRadius
        startPfX = floor (minX / gridConfig.pathfindingGridSize)
        endPfX = floor (maxX / gridConfig.pathfindingGridSize)
        startPfY = floor (minY / gridConfig.pathfindingGridSize)
        endPfY = floor (maxY / gridConfig.pathfindingGridSize)
        xs = List.range startPfX endPfX
        ys = List.range startPfY endPfY
    in
    List.concatMap (\x -> List.map (\y -> ( x, y )) ys) xs
addUnitOccupancy : GridConfig -> Float -> Float -> Dict ( Int, Int ) Int -> Dict ( Int, Int ) Int
addUnitOccupancy gridConfig worldX worldY occupancy =
    let
        cells = getUnitPathfindingCells gridConfig worldX worldY
        incrementCell cell dict = Dict.update cell
                (\maybeCount ->
                    case maybeCount of
                        Just count -> Just (count + 1)
                        Nothing -> Just 1
                )
                dict
    in
    List.foldl incrementCell occupancy cells
removeUnitOccupancy : GridConfig -> Float -> Float -> Dict ( Int, Int ) Int -> Dict ( Int, Int ) Int
removeUnitOccupancy gridConfig worldX worldY occupancy =
    let
        cells = getUnitPathfindingCells gridConfig worldX worldY
        decrementCell cell dict = Dict.update cell
                (\maybeCount ->
                    case maybeCount of
                        Just count ->
                            if count <= 1 then
                                Nothing
                            else
                                Just (count - 1)
                        Nothing -> Nothing
                )
                dict
    in
    List.foldl decrementCell occupancy cells
findNearestUnoccupiedTile : GridConfig -> MapConfig -> Dict ( Int, Int ) Int -> Float -> Float -> ( Float, Float )
findNearestUnoccupiedTile gridConfig mapConfig occupancy targetX targetY =
    let
        targetPfX = floor (targetX / gridConfig.pathfindingGridSize)
        targetPfY = floor (targetY / gridConfig.pathfindingGridSize)
        searchRadius maxRadius currentRadius =
            if currentRadius > maxRadius then
                ( targetX, targetY )
            else
                let
                    ringCells =
                        if currentRadius == 0 then
                            [ ( targetPfX, targetPfY ) ]
                        else
                            List.range -currentRadius currentRadius
                                |> List.concatMap
                                    (\dx -> List.range -currentRadius currentRadius
                                            |> List.filterMap
                                                (\dy ->
                                                    if abs dx == currentRadius || abs dy == currentRadius then
                                                        Just ( targetPfX + dx, targetPfY + dy )
                                                    else
                                                        Nothing
                                                )
                                    )
                    unoccupiedCell = ringCells
                            |> List.filter
                                (\cell -> not (isPathfindingCellOccupied cell occupancy)
                                        && isWithinMapBounds gridConfig mapConfig cell
                                )
                            |> List.head
                in
                case unoccupiedCell of
                    Just ( pfX, pfY ) ->
                        ( toFloat pfX * gridConfig.pathfindingGridSize + gridConfig.pathfindingGridSize / 2
                        , toFloat pfY * gridConfig.pathfindingGridSize + gridConfig.pathfindingGridSize / 2
                        )
                    Nothing -> searchRadius maxRadius (currentRadius + 1)
        isWithinMapBounds : GridConfig -> MapConfig -> ( Int, Int ) -> Bool
        isWithinMapBounds gc mc ( pfX, pfY ) =
            let
                worldX = toFloat pfX * gc.pathfindingGridSize
                worldY = toFloat pfY * gc.pathfindingGridSize
            in
            worldX >= 0 && worldX < mc.width && worldY >= 0 && worldY < mc.height
    in
    searchRadius 50 0

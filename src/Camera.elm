module Camera exposing
    ( MinimapConfig
    , centerCameraOnMinimapClick
    , constrainCamera
    , getMinimapScale
    , isClickOnViewbox
    , minimapClickOffset
    , minimapDragToCamera
    )

import Types exposing (Camera, MapConfig, Model, Position)


{-| Constrain camera to stay within map bounds with boundary buffer
-}
constrainCamera : MapConfig -> ( Int, Int ) -> Camera -> Camera
constrainCamera config ( winWidth, winHeight ) camera =
    let
        viewWidth =
            toFloat winWidth

        viewHeight =
            toFloat winHeight

        minX =
            0 - config.boundary

        maxX =
            config.width + config.boundary - viewWidth

        minY =
            0 - config.boundary

        maxY =
            config.height + config.boundary - viewHeight
    in
    { x = clamp minX maxX camera.x
    , y = clamp minY maxY camera.y
    }


type alias MinimapConfig =
    { width : Int
    , height : Int
    , padding : Float
    }


{-| Calculate minimap scale factor
-}
getMinimapScale : MinimapConfig -> MapConfig -> Float
getMinimapScale minimapConfig mapConfig =
    min ((toFloat minimapConfig.width - minimapConfig.padding * 2) / mapConfig.width) ((toFloat minimapConfig.height - minimapConfig.padding * 2) / mapConfig.height)


{-| Check if a click is on the minimap viewbox (camera indicator)
-}
isClickOnViewbox : Model -> MinimapConfig -> Float -> Float -> Bool
isClickOnViewbox model minimapConfig clickX clickY =
    let
        scale =
            getMinimapScale minimapConfig model.mapConfig

        ( winWidth, winHeight ) =
            model.windowSize

        viewboxLeft =
            minimapConfig.padding + (model.camera.x * scale)

        viewboxTop =
            minimapConfig.padding + (model.camera.y * scale)

        viewboxWidth =
            toFloat winWidth * scale

        viewboxHeight =
            toFloat winHeight * scale
    in
    clickX >= viewboxLeft && clickX <= viewboxLeft + viewboxWidth && clickY >= viewboxTop && clickY <= viewboxTop + viewboxHeight


{-| Calculate offset from viewbox corner when dragging starts
-}
minimapClickOffset : Model -> MinimapConfig -> Float -> Float -> Position
minimapClickOffset model minimapConfig clickX clickY =
    let
        scale =
            getMinimapScale minimapConfig model.mapConfig

        viewboxLeft =
            minimapConfig.padding + (model.camera.x * scale)

        viewboxTop =
            minimapConfig.padding + (model.camera.y * scale)

        offsetX =
            clickX - viewboxLeft

        offsetY =
            clickY - viewboxTop
    in
    { x = offsetX, y = offsetY }


{-| Center camera on a minimap click position
-}
centerCameraOnMinimapClick : Model -> MinimapConfig -> Float -> Float -> Camera
centerCameraOnMinimapClick model minimapConfig clickX clickY =
    let
        scale =
            getMinimapScale minimapConfig model.mapConfig

        ( winWidth, winHeight ) =
            model.windowSize

        -- Clamp click coordinates to terrain bounds on minimap
        terrainWidth =
            model.mapConfig.width * scale

        terrainHeight =
            model.mapConfig.height * scale

        clampedX =
            clamp minimapConfig.padding (minimapConfig.padding + terrainWidth) clickX

        clampedY =
            clamp minimapConfig.padding (minimapConfig.padding + terrainHeight) clickY

        worldX =
            (clampedX - minimapConfig.padding) / scale - (toFloat winWidth / 2)

        worldY =
            (clampedY - minimapConfig.padding) / scale - (toFloat winHeight / 2)
    in
    { x = worldX, y = worldY }


{-| Calculate camera position when dragging minimap viewbox
-}
minimapDragToCamera : Model -> Position -> Float -> Float -> Camera
minimapDragToCamera model offset clickX clickY =
    let
        minimapConfig =
            { width = 200
            , height = 150
            , padding = 10
            }

        scale =
            getMinimapScale minimapConfig model.mapConfig

        worldX =
            (clickX - minimapConfig.padding - offset.x) / scale

        worldY =
            (clickY - minimapConfig.padding - offset.y) / scale
    in
    { x = worldX, y = worldY }

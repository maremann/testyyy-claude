module BuildingTemplates exposing
    ( castleTemplate
    , houseTemplate
    , randomUnitColor
    , testBuildingTemplate
    , warriorsGuildTemplate
    )

import Random
import Types exposing (BuildingSize(..), BuildingTemplate)


-- BUILDING TEMPLATES


testBuildingTemplate : BuildingTemplate
testBuildingTemplate =
    { name = "Test Building"
    , size = Medium
    , cost = 500
    , maxHp = 500
    , garrisonSlots = 5
    }


castleTemplate : BuildingTemplate
castleTemplate =
    { name = "Castle"
    , size = Huge
    , cost = 10000
    , maxHp = 5000
    , garrisonSlots = 6
    }


houseTemplate : BuildingTemplate
houseTemplate =
    { name = "House"
    , size = Medium
    , cost = 0
    , maxHp = 500
    , garrisonSlots = 0
    }


warriorsGuildTemplate : BuildingTemplate
warriorsGuildTemplate =
    { name = "Warrior's Guild"
    , size = Large
    , cost = 1500
    , maxHp = 1000
    , garrisonSlots = 0
    }


{-| Generate a random color string for units
-}
randomUnitColor : Random.Generator String
randomUnitColor =
    let
        colors =
            [ "#FF6B6B"
            , "#4ECDC4"
            , "#45B7D1"
            , "#FFA07A"
            , "#98D8C8"
            , "#F7DC6F"
            , "#BB8FCE"
            , "#85C1E2"
            , "#F8B739"
            , "#52C41A"
            ]

        randomIndex =
            Random.int 0 (List.length colors - 1)
    in
    Random.map
        (\idx ->
            List.drop idx colors
                |> List.head
                |> Maybe.withDefault "#FF6B6B"
        )
        randomIndex

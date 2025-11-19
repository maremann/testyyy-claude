module BuildingTemplates exposing
    ( castleTemplate
    , houseTemplate
    , randomUnitColor
    , testBuildingTemplate
    , warriorsGuildTemplate
    )
import GameStrings
import Random
import Types exposing (BuildingSize(..), BuildingTemplate)
testBuildingTemplate : BuildingTemplate
testBuildingTemplate = { name = GameStrings.buildingTypeTestBuilding
    , size = Medium
    , cost = 500
    , maxHp = 500
    , garrisonSlots = 5
    }
castleTemplate : BuildingTemplate
castleTemplate = { name = GameStrings.buildingTypeCastle
    , size = Huge
    , cost = 10000
    , maxHp = 5000
    , garrisonSlots = 6
    }
houseTemplate : BuildingTemplate
houseTemplate = { name = GameStrings.buildingTypeHouse
    , size = Medium
    , cost = 0
    , maxHp = 500
    , garrisonSlots = 0
    }
warriorsGuildTemplate : BuildingTemplate
warriorsGuildTemplate = { name = GameStrings.buildingTypeWarriorsGuild
    , size = Large
    , cost = 1500
    , maxHp = 1000
    , garrisonSlots = 0
    }
randomUnitColor : Random.Generator String
randomUnitColor =
    let
        colors = [ "#FF6B6B"
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
        randomIndex = Random.int 0 (List.length colors - 1)
    in
    Random.map
        (\idx -> List.drop idx colors
                |> List.head
                |> Maybe.withDefault "#FF6B6B"
        )
        randomIndex

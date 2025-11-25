module Types exposing (..)
import Dict exposing (Dict)
import BehaviorEngine.UnitStates as UnitStates
type alias TooltipState = { elementId : String
    , hoverTime : Float
    , mouseX : Float
    , mouseY : Float
    }
type alias Model = { camera : Camera
    , dragState : DragState
    , windowSize : ( Int, Int )
    , decorativeShapes : List DecorativeShape
    , mapConfig : MapConfig
    , gameState : GameState
    , gold : Int
    , selected : Maybe Selectable
    , gridConfig : GridConfig
    , showBuildGrid : Bool
    , showPathfindingGrid : Bool
    , buildings : List Building
    , buildingOccupancy : Dict ( Int, Int ) Int
    , nextBuildingId : Int
    , goldInputValue : String
    , pathfindingOccupancy : Dict ( Int, Int ) Int
    , showPathfindingOccupancy : Bool
    , buildMode : Maybe BuildingTemplate
    , mouseWorldPos : Maybe ( Float, Float )
    , showBuildingOccupancy : Bool
    , simulationFrameCount : Int
    , accumulatedTime : Float
    , lastSimulationDeltas : List Float
    , simulationSpeed : SimulationSpeed
    , units : List Unit
    , nextUnitId : Int
    , debugTab : DebugTab
    , buildingTab : BuildingTab
    , showCityActiveArea : Bool
    , showCitySearchArea : Bool
    , tooltipHover : Maybe TooltipState
    }
type GameState
    = PreGame
    | Playing
    | GameOver
type SimulationSpeed
    = Pause
    | Speed1x
    | Speed2x
    | Speed10x
    | Speed100x
type DebugTab
    = StatsTab
    | VisualizationTab
    | ControlsTab
type BuildingTab
    = MainTab
    | InfoTab
type UnitBehavior
    = Dead
    | DebugError String
    | WithoutHome
    | LookingForTask
    | GoingToSleep
    | Sleeping
    | LookForBuildRepairTarget
    | MovingToBuildRepairTarget
    | Repairing
    | LookForTaxTarget
    | CollectingTaxes
    | ReturnToCastle
    | DeliveringGold
    -- New behavior tree system
    | CastleGuardPatrol UnitStates.CastleGuardPatrolState
type BuildingBehavior
    = Idle
    | UnderConstruction
    | GenerateGold
    | BuildingDead
    | BuildingDebugError String
type UnitKind
    = Hero
    | Henchman
type Tag
    = BuildingTag
    | HeroTag
    | HenchmanTag
    | GuildTag
    | ObjectiveTag
    | CofferTag
type Selectable
    = GlobalButtonDebug
    | GlobalButtonBuild
    | BuildingSelected Int
    | UnitSelected Int
type BuildingSize
    = Small
    | Medium
    | Large
    | Huge
type BuildingOwner
    = Player
    | Enemy
type alias GarrisonSlotConfig = { unitType : String
    , maxCount : Int
    , currentCount : Int
    , spawnTimer : Float
    }
type alias Building = { id : Int
    , owner : BuildingOwner
    , gridX : Int
    , gridY : Int
    , size : BuildingSize
    , hp : Int
    , maxHp : Int
    , garrisonSlots : Int
    , garrisonOccupied : Int
    , buildingType : String
    , behavior : BuildingBehavior
    , behaviorTimer : Float
    , behaviorDuration : Float
    , coffer : Int
    , garrisonConfig : List GarrisonSlotConfig
    , activeRadius : Float
    , searchRadius : Float
    , tags : List Tag
    }
type alias BuildingTemplate = { name : String
    , size : BuildingSize
    , cost : Int
    , maxHp : Int
    , garrisonSlots : Int
    }
type UnitLocation
    = OnMap Float Float
    | Garrisoned Int
type alias Unit = { id : Int
    , owner : BuildingOwner
    , location : UnitLocation
    , hp : Int
    , maxHp : Int
    , movementSpeed : Float
    , unitType : String
    , unitKind : UnitKind
    , color : String
    , path : List ( Int, Int )
    , behavior : UnitBehavior
    , behaviorTimer : Float
    , behaviorDuration : Float
    , thinkingTimer : Float
    , thinkingDuration : Float
    , homeBuilding : Maybe Int
    , carriedGold : Int
    , targetDestination : Maybe ( Int, Int )
    , activeRadius : Float
    , searchRadius : Float
    , tags : List Tag
    }
type alias Camera = { x : Float
    , y : Float
    }
type DragState
    = NotDragging
    | DraggingViewport Position
    | DraggingMinimap Position
type alias Position = { x : Float
    , y : Float
    }
type alias DecorativeShape = { x : Float
    , y : Float
    , size : Float
    , shapeType : ShapeType
    , color : String
    }
type ShapeType
    = Circle
    | Rectangle
type alias MapConfig = { width : Float
    , height : Float
    , boundary : Float
    }
type alias GridConfig = { buildGridSize : Float
    , pathfindingGridSize : Float
    }
buildingSizeToGridCells : BuildingSize -> Int
buildingSizeToGridCells size =
    case size of
        Small -> 1
        Medium -> 2
        Large -> 3
        Huge -> 4

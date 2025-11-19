module Message exposing (Msg(..))
import Browser.Dom as Dom
import Types exposing (BuildingTemplate, DecorativeShape, DebugTab, BuildingTab, Selectable, SimulationSpeed)
type Msg
    = WindowResize Int Int
    | MouseDown Float Float
    | MouseMove Float Float
    | MouseUp
    | MinimapMouseDown Float Float
    | MinimapMouseMove Float Float
    | ShapesGenerated (List DecorativeShape)
    | GotViewport Dom.Viewport
    | SelectThing Selectable
    | ToggleBuildGrid
    | TogglePathfindingGrid
    | GoldInputChanged String
    | SetGoldFromInput
    | TogglePathfindingOccupancy
    | EnterBuildMode BuildingTemplate
    | ExitBuildMode
    | WorldMouseMove Float Float
    | PlaceBuilding
    | ToggleBuildingOccupancy
    | ToggleCityActiveArea
    | ToggleCitySearchArea
    | TooltipEnter String Float Float
    | TooltipLeave
    | Frame Float
    | SetSimulationSpeed SimulationSpeed
    | SetDebugTab DebugTab
    | SetBuildingTab BuildingTab

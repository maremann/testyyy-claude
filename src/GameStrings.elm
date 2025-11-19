module GameStrings exposing (..)
unitTypePeasant : String
unitTypePeasant = "Peasant"
unitTypeTaxCollector : String
unitTypeTaxCollector = "Tax Collector"
unitTypeCastleGuard : String
unitTypeCastleGuard = "Castle Guard"
buildingTypeCastle : String
buildingTypeCastle = "Castle"
buildingTypeHouse : String
buildingTypeHouse = "House"
buildingTypeTestBuilding : String
buildingTypeTestBuilding = "Test Building"
buildingTypeWarriorsGuild : String
buildingTypeWarriorsGuild = "Warrior's Guild"
buildingBehaviorIdle : String
buildingBehaviorIdle = "Idle"
buildingBehaviorUnderConstruction : String
buildingBehaviorUnderConstruction = "Under Construction"
buildingBehaviorSpawnHouse : String
buildingBehaviorSpawnHouse = "Spawn House"
buildingBehaviorGenerateGold : String
buildingBehaviorGenerateGold = "Generate Gold"
buildingBehaviorDead : String
buildingBehaviorDead = "Dead"
unitBehaviorDead : String
unitBehaviorDead = "Dead"
unitBehaviorWithoutHome : String
unitBehaviorWithoutHome = "Without Home"
unitBehaviorLookingForTask : String
unitBehaviorLookingForTask = "Looking for Task"
unitBehaviorGoingToSleep : String
unitBehaviorGoingToSleep = "Going to Sleep"
unitBehaviorSleeping : String
unitBehaviorSleeping = "Sleeping"
unitBehaviorLookingForBuildRepair : String
unitBehaviorLookingForBuildRepair = "Looking for Build/Repair"
unitBehaviorMovingToBuilding : String
unitBehaviorMovingToBuilding = "Moving to Building"
unitBehaviorRepairing : String
unitBehaviorRepairing = "Repairing"
unitBehaviorLookingForTaxTarget : String
unitBehaviorLookingForTaxTarget = "Looking for Tax Target"
unitBehaviorCollectingTaxes : String
unitBehaviorCollectingTaxes = "Collecting Taxes"
unitBehaviorReturningToCastle : String
unitBehaviorReturningToCastle = "Returning to Castle"
unitBehaviorDeliveringGold : String
unitBehaviorDeliveringGold = "Delivering Gold"
tagBuilding : String
tagBuilding = "Building"
tagHero : String
tagHero = "Hero"
tagHenchman : String
tagHenchman = "Henchman"
tagGuild : String
tagGuild = "Guild"
tagObjective : String
tagObjective = "Objective"
tagCoffer : String
tagCoffer = "Coffer"
ownerPlayer : String
ownerPlayer = "Player"
ownerEnemy : String
ownerEnemy = "Enemy"
uiDebug : String
uiDebug = "Debug"
uiBuild : String
uiBuild = "Build"
uiStats : String
uiStats = "STATS"
uiVisual : String
uiVisual = "VISUAL"
uiControls : String
uiControls = "CONTROLS"
uiMain : String
uiMain = "Main"
uiInfo : String
uiInfo = "Info"
uiSpeed : String
uiSpeed = "Speed:"
uiGold : String
uiGold = "Gold:"
uiPaused : String
uiPaused = "PAUSED"
uiSiteYourCastle : String
uiSiteYourCastle = "Site your Castle"
uiGameOver : String
uiGameOver = "GAME OVER"
uiAmount : String
uiAmount = "Amount"
uiSet : String
uiSet = "SET"
uiBuildGrid : String
uiBuildGrid = "Build Grid"
uiPathfindingGrid : String
uiPathfindingGrid = "Pathfinding Grid"
uiPfOccupancy : String
uiPfOccupancy = "PF Occupancy"
uiBuildOccupancy : String
uiBuildOccupancy = "Build Occupancy"
uiCityActive : String
uiCityActive = "City Active"
uiCitySearch : String
uiCitySearch = "City Search"
uiSpeed0x : String
uiSpeed0x = "0x"
uiSpeed1x : String
uiSpeed1x = "1x"
uiSpeed2x : String
uiSpeed2x = "2x"
uiSpeed10x : String
uiSpeed10x = "10x"
uiSpeed100x : String
uiSpeed100x = "100x"
uiNoSelection : String
uiNoSelection = "No selection"
uiBuildingNotFound : String
uiBuildingNotFound = "Building not found"
uiUnitNotFound : String
uiUnitNotFound = "Unit not found"
uiCamera : String
uiCamera = "Camera: ("
uiSimFrame : String
uiSimFrame = "Sim Frame: "
uiAvgDelta : String
uiAvgDelta = "Avg Delta: "
uiMs : String
uiMs = "ms"
uiBehavior : String
uiBehavior = "Behavior: "
uiTimer : String
uiTimer = "Timer: "
uiCoffer : String
uiCoffer = "Coffer: "
uiGoldSuffix : String
uiGoldSuffix = " gold"
uiGarrisonCooldowns : String
uiGarrisonCooldowns = "Garrison Cooldowns:"
uiLocation : String
uiLocation = "Location: "
uiGarrisonedIn : String
uiGarrisonedIn = "Garrisoned in #"
uiFull : String
uiFull = "Full"
uiGarrison : String
uiGarrison = "Garrison"
uiCurrent : String
uiCurrent = "Current: "
uiCapacity : String
uiCapacity = "Capacity: "
uiNextUnit : String
uiNextUnit = "Next unit: Not implemented"
unitIconPeasant : String
unitIconPeasant = "P"
unitIconTaxCollector : String
unitIconTaxCollector = "T"
unitIconCastleGuard : String
unitIconCastleGuard = "G"
unitIconUnknown : String
unitIconUnknown = "?"
suffixUnderConstruction : String
suffixUnderConstruction = " (under construction)"
tooltipHp : String
tooltipHp = "HP: "
tooltipSize2x2 : String
tooltipSize2x2 = "Size: 2×2"
tooltipSize3x3 : String
tooltipSize3x3 = "Size: 3×3"
tooltipSize4x4 : String
tooltipSize4x4 = "Size: 4×4"
tooltipGarrison : String
tooltipGarrison = "Garrison: "
tooltipHenchmen : String
tooltipHenchmen = " henchmen"
tooltipMissionCritical : String
tooltipMissionCritical = "Mission-critical building"
tooltipGeneratesGold : String
tooltipGeneratesGold = "Generates gold"
tooltipTrainsWarriors : String
tooltipTrainsWarriors = "Trains warriors, generates gold"
tooltipIsBuilding : String
tooltipIsBuilding = "This is a building"
tooltipIsHero : String
tooltipIsHero = "This is a hero"
tooltipIsHenchman : String
tooltipIsHenchman = "This is a henchman"
tooltipGuildProducesHeroes : String
tooltipGuildProducesHeroes = "This building produces and houses Heroes"
tooltipObjectiveExplanation : String
tooltipObjectiveExplanation = "If this dies, the player loses the game"
tooltipHasGoldCoffer : String
tooltipHasGoldCoffer = "This building has a Gold Coffer"
tooltipBehaviorIdle : String
tooltipBehaviorIdle = "The building is not performing any actions"
tooltipBehaviorUnderConstruction : String
tooltipBehaviorUnderConstruction = "The building is under construction"
tooltipBehaviorSpawnHouse : String
tooltipBehaviorSpawnHouse = "The Castle is periodically spawning Houses for the kingdom"
tooltipBehaviorGenerateGold : String
tooltipBehaviorGenerateGold = "The building is generating gold into its coffer"
tooltipBehaviorThinking : String
tooltipBehaviorThinking = "The unit is pausing before deciding on next action"
tooltipBehaviorFindingTarget : String
tooltipBehaviorFindingTarget = "The unit is calculating a path to a random destination"
tooltipBehaviorMoving : String
tooltipBehaviorMoving = "The unit is following its path to the destination"

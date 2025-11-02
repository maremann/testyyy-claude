# First Draft Game Mechanics

# Tags

A list of tags that appear in the game:

* Building: This is a building.
* Guild: This building produces and houses Heroes.
* Hero: This is a hero unit.
* Henchman: This is a henchman unit.
* Objective: If this dies, the player loses the game.
* Coffer: This building has a Gold Coffer. A Tax Collector will pick up gold from this coffer and bring it to the Castle.

# Behaviours

Global behaviours inherent to every thing. Every Unit and Building has these behaviours in addition to the ones specified.

* Thinking: Idle for a random time between 0.5 and 1.0 seconds. This occurrs when a thing is created, and after any other Behaviour is completed.
* Dead: This thing is dead and can not do anything. The visuals show a grey colored version of this thing. This state lasts for a random time between 45 and 60 seconds, after which this thing is removed from the game.
* DebugError: This behaviour is entered when something goes wrong. The tooltip for this behaviour will show the error message.

# Garrison

Many buildings have garrison slots. For Henchmen, the garrison will accept any henchmen of its type. For Heroes, the Building which has space for heroes has a list of hero classes that it will accept. A unit can be either in the world or in a garrison. The building can be entered by a unit when it touches the entrance of the building. The building selection panel shows the number of occupied and maximum garrison slots (for henchmen), or a scrollable list of individual units that can be selected via double-click for buildings with heroes inside.

# Castle 

The player builds a kingdom which is sited around the Castle. The castle is the main building to defend. Loss condition: if the castle gets destroyed, the player loses. In that case, accept no more player inputs and only displays the text Game Over on the screen. The castle also houses the basic Henchmen that are needed to maintain the kingdom.

# Gold

The player has gold. Whenever gold is added to the player's gold, the number with a + sign should flash in green above the gold counter for 2.0 seconds. Whenever gold is removed from the player's gold, the number should show with a - sign in red.

## Building The castle and game start

At the start of the game, the text Site your Castle is displayed on the top right. The build menu only shows the castle button. the castle can be built anywhere. During this, the game is in "pre-game" state and no other simulation is performed. The game officially starts once the Castle has been built. At that time, the Castle vanishes from the build menu and the usual buildable buildings populate the build menu instead.

## Building other buildings

Other buildings except for the castle start as construction sites. When the player places the building, a construction site with 10% of the HP of the building is created. The graphics of the construction site is the same as the finished building, except gray. A peasant will come and build the building. The construction is finished when its current HP reaches its maximum HP. At that point, the construction site will be replaced by the actual, functional building.

## Castle Stats

This is the player's mission-critical building. It houses the basic Henchman needed for the kingdom to operate. It also tracks and spawns Houses for the kingdom.

Name: Castle
Tags: Building, Objective
Size: Huge
Max HP: 5000
Gold Cost: 10000
Max Garrison Slots:
   Castle Guard: 2
   Tax Collector: 1
   Peasant: 3
Special Stats:
    Max House Counter: The maximum number of houses the kingdom should have. This counter is calculated as follows: +3 for a castle, and +1 for every 3 alive Heroes.
Behaviours: 
    Spawn House: Wait for a random time between 30 and 45 seconds, and then spawn a House if the current number of houses in the kingdom is less than the max number of houses. The house is placed adjacent to any existing building of the kingdom (respecting usual placement rules) at a random location. If no suitable random location can be found, enter DebugError state and give information in the tooltip.  

## House

This is not a buildable building for the player, but instead spawned from the Castle. This weak building generates gold into its Coffer for collection by the Tax Collector.

Name: House
Tags: Building, Coffer
Max HP: 500
Size: Medium
Behaviours:
    Generate Gold: Wait a random time between 15 and 45 seconds, and then put a random amount of gold between 45-90 into this building's coffer.

## Warriror's guild

This is a Guild which creates and acts as home for heroes of the Warrior class.

Name: Warrior's guild
Tags: Building, Guild, Coffer
Max HP: 1000
Size: Large
Ability: 
    Recruit Warrior: (not yet implemented)
Behaviours:
    Generate Gold: Wait a random time between 15 and 45 seconds, and then put a random amount of gold between 450-900 into this building's coffer.

# Units

Units come in two varieties: Hero and Henchman.

## Hero

Todo

## Henchman

Henchman are associated with one building, their "home". The home will always try to spawn henchmen on a cooldown of 30 seconds, up to the maximum. If a henchman dies, the garrison slot in the home is freed up. If the home gets destroyed, the henchman goes into Without Home behaviour.

## All Henchman Behaviours

These Behaviours are common to all henchmen, in addition to all other behaviours applicable.

* Without Home: This henchman will die in a random time between 15-30 seconds.
* Looking for Task: This henchman will look for a Task to do and will enter its appropriate Task Behaviour.
* Going to Sleep: If no Task Behaviour was found, the henchman moves back to enter its home. At every intermediate waypoint, this behaviour is interrupted by Looking for Task.
* Sleeping: If the henchman is inside its home, it is considered Sleeping. This behaviour is interrupted by Looking for Task every 1 second. While Sleeping, the unit recovers 10% of its max HP per second.

## Henchman: Peasant

The peasant builds and repairs building. The debug graphics show an appropriate emoji, and a duration indicator whenever the build ability is on cooldown.

Name: Peasant
Tags: Henchman
Max HP: 50
Move Speed: 2
Ability: 
    Build: 0.15 seconds cooldown. When near a construction site or damaged building, add 5HP to its current HP.
Behaviours:
    Look for Build/Repair Target: search all kingdom buildings for any building or construction site which has less than its maximum hp. Choose the closest one. Move towards it. Once the target is reached, switch to Build or Repair behaviour.
    Build: If near a construction site, use the Build ability repeatedly until the construction is finished.
    Repair: If near a damaged building, use the Build ability repeatedly until the building is no longer damaged.

## Henchman: Tax Collector

The Tax Collector walks to the entrance of buildings and picks up the gold in their coffer, and brings it back to the castle, at which point its added to the player's gold.

Name: Tax Collector
Tags: Henchman
Max HP: 50
Move Speed: 1.5
Ability: 
    Carried Gold: This unit has a storage for carrying gold. Gold is added to this storage whenever it picks up gold from a coffer. The storage is emptied when it delivers the gold to the castle. Gold storage is shown in this unit's selection panel. The storage has a special value of 250, after which the unit should return to the castle.
Behaviours:
    Look for Tax Collection Target: search all kingdom buildings for any that has gold in its coffer, then move to the nearest. If adjacent to the target, enter Collecting Taxes.
    Collecting Taxes: Wait for a random time between 2.0 to 3.0 seconds, then transfer all gold from the building coffer to this unit's storage. if the storage special value is exceeded, Return to Castle, otherwise Look for Tax Collection Target.
    Return to Castle: move toward the home castle and enter it. As soon as home castle is entered, enter Deliver Gold.
    Deliver Gold: Wait 2.0 to 3.0 seconds and transfer the gold from this unit's storage to the player gold. 

## Henchman: Guard

(not yet implemented)


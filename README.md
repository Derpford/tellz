# TellZ
## A (mostly) universal attack telegraphing mod for GZDoom

### Attack what-graphing?
"Telegraphing", in combat, is the concept of showing what your attack will be before you actually attack. In games, good attack design often revolves around good telegraphing. This mod (ab)uses ZScript to add some visual indicators (inspired by Metal Gear Rising) to most monsters.

### How does it work?
At spawn, monsters are given an inventory item which checks for the monster's MELEE and MISSILE states and spawns appropriate particle effects. This item *also* creates a "dummy" target and sets the monster's target to that dummy temporarily, thus averting Doom's default behavior of letting monsters 180 quickscope you if you run behind them.

### What kind of tells are there?

Right now, ranged attacks are signalled with a red line and melee attacks are signalled with a yellow circle.

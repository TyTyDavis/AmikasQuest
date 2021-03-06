# AmikasQuest
Amkika's Quest is a procedurally generated dungeon crawler game for Pico 8. I programmed the game over the course of Summer 2021, and I designed all of the pixel art for the game. The music was composed by my friend Cory Shane Davis. The game can be played [here](https://tytydavis.itch.io/amikas-quest) on itch.io, and the cartridge file can be downloaded [here](https://www.lexaloffle.com/bbs/?tid=44570) on Pico 8's forums.

## Note: The technical limitations of Pico 8
Pico 8 is a "fantasy console," which is to say it is an emulator/game engine meant to recreate the feeling of retro gaming. It does this by imposing technical limitations, which I will summarize here to give the reader an understanding of how this game was built:
* Games must fit onto a compressed file size of 32k, in the form of a .png "cartridge."
* The game is displayed on a 128x128 with a limited, predefined color pallete.
* Games are coded in Lua, and can only use 8192 "tokens" (with a token being pretty much any word or symbol of code that does something)

I decided to work within Pico 8 for two reasons:
* I believe that limitations fuel the creative process, and help focus creators on finishing products rather than endlessly brainstorming.
* Working within these limitations would help me learn how to optimize my code.

After lots of optimizing, tweaking, and a few hard decisions, the game came in at just 64 tokens under the limit.

## Procedural Generation
Amika's Quest consists of three dungeons, each procedurally generated so that the experience is different each time you play. Based on the simple dungeons of the first Legend of Zelda game, I had X parameters that the dungeons needed to fit:
* A 5x4 grid of rooms that the dungeon exists within
* A main path from the room the player starts in (on the southernmost row) to the final room that the boss monster is found in (on the northernmost row)
* A locked door somewhere within that main path
* A path branching off of the main path before the locked door, ending in a room that contains a key
* A shop room where the player can buy items

The first step was to declare a sequence of twenty numbers, each representing a room in the dungeon, with the first number in the sequence representing the top left corner. Zeros represent ununused rooms.

![The dungeon sequence](https://i.imgur.com/CaOy6v0.png)

From there, the algorithm chooses a random room on the bottom row to be the first room, where the player will spawn. From there, the algorithm will choose a direction to move to next, using a function to create a list of directions that are valid to move to, removing East or West if the current room is already on the eastern or western edge of the grid, respectively. This will continue until the dungeon path makes it to the top row of the grid, where the path will end once the algorithm tries to place a room to the north.

![The main path](https://i.imgur.com/WlhsNxB.png)

Next, the algorithm chooses a room to place a locked door, somewhere before the final room.

![The lock room](https://i.imgur.com/Bq3OcoQ.png)

After that, a room will be chosen before that lock, and a branching path will be built off of it using pathing rules as the main path. That path will continue for a random amount of rooms, or until it runs into a dead end. The final room on that path will contain the key. Finally, a shop will be placed at random next to another room, anywhere along either the main path or the key path.

![The key path](https://i.imgur.com/jftFdQ2.png)

Now that the dungeons layout is set, we start actually building it. First, doors are placed to connect all of the rooms. Before the lock, all rooms on the main path are connected if they are adjacent, even if the adjacent room isn't the next room on the path. Rooms on the key path and after the lock are only connected to the next sequential room on the path. This makes the exploration and backtracking required to find the key path a little less tedious, and makes the dungeon feel more like an open explorable space.

![A complete dungeon](https://i.imgur.com/wTxQuYV.png)

Then, each room is filled from a randomly-chosen, premade template that decides where there will be blocks that the player can not walk, on, and where enemies will be placed. These templates were created using a separate Pico 8 cartridge I made that allows me to build a room in Pico 8's map editor tool and easily convert that room into a 168 character string. Each character in the string represents a tile in the room, starting at the upper left. If the character is a 1, that tile is set to a block. If it is a 2, it is set to a floor tile, and if it is an M, that tile is set to a floor tile and function is run to spawn a monster there.
These strings are then store in large comma separated strings which are split into sequences at run time, in order to save tokens.

## Enemies
The games enemy system was designed to create multiple enemy types with as little code as possible, saving more room on the cart for the game's procedural generation code. This was accomplished a few different ways:
*Each enemy has two frames of animation that it cycles between when moving
*There are two enemy types: those that move in the four cardinal directions, and those that move diagonally

Within those parameters there are a few changes that can be made to provide more variety. Some enemies pause after moving, while some continuously move. Some enemies move randomly, while some try to find the player.

Enemies are instantiated when rooms are created, and stored in one table. Each game tick, the game iterates through that table, updating every enemy that is in the same room as the player, checking its collisions with the player and player's items, and drawing it to the screen.




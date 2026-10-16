Galactic Dominion v0.15 redesigns the **main menu and pause screen** as a calmer, more polished command deck.

- Animated 3D preview of your actual configured ship, with an orbital planet and Pixlet companion.
- Clear Explore the Galaxy action, direct Peaceful Flight and Online Play access, and compact cards for battles, planet expeditions, sanctuary, hangar, discovery missions and online trading.
- Consistent dark surfaces, soft mint accents, clearer typography, quieter borders and keyboard focus states.
- Separate Settings / Flight Controls / Quit footer. The new controls panel explains flight, exploration and peaceful mode without covering the main menu.
- Dedicated pause/resume layout; online players are told that their session continues while menus are open.
- Shorter flight information preserves destination distances, raid timing and creature counts while reducing text over the scene.

**Play:** extract Galactic-Dominion-Windows.zip and run GalacticDominion.exe. On the welcome screen choose Explore the Galaxy for normal Free Roam, Peaceful Flight for calm solo exploration, or one of the activity cards. H still hides/restores the flight HUD; M opens the chart.

**Host:** extract Galactic-Dominion-Server-Windows.zip and run Start-Server-Windows.bat. Every online client and the host must update to v0.15. The package includes its engine and Python runtime; players need neither installed. Linux builds, the existing 38-model pack and checksums are included.

The local 444-check Godot regression includes 18 new functional menu checks. A native OpenGL menu render was inspected. Windows GUI execution remains untested on the Linux development machine. The seven-region map, session-based faction war, creature limits, existing art and solo surface exploration keep their previous scope. No gameplay balance or save-schema change is introduced.

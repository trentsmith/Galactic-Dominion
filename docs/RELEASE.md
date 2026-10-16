Galactic Dominion v0.16 adds **Orbitot** and **Glimbloom**, two original 3D fleet companions inspired by the supplied art references.

- Orbitot: pearl/gold armor, cyan face, two tilted orbital rails with six moving satellites and a ringed-planet crown. **Gravity Loop** fires tracking rings that deal 5 damage and slow maximum thrust speed by 35% for 1.5 seconds. The slow refreshes without stacking.
- Glimbloom: six faceted iridescent petals, a forehead prism and five orbiting crystals. **Prism Pulse** deals 8 direct damage plus 4 to nearby enemies within 14 m; obstacles block splash and allies are safe.
- Research either for **180 salvage** in the Hangar, then equip it in a ship's **Crew** slot. Both are uncommon. Existing saves and Legendary/Mythic rarity odds are preserved.
- Server-controlled damage and effects online, with replicated signature projectile meshes.
- **40 GLB + 40 self-contained Godot model scenes** in the separate model ZIP. Runtime orbital/wing/eye animations use GDScript; GLBs are static editable meshes.

**Play:** extract Galactic-Dominion-Windows.zip and run GalacticDominion.exe. Choose Hangar to research and equip your companion, then Explore the Galaxy or Fleet Royale. Peaceful Flight is available for relaxed solo exploration.

**Host:** extract Galactic-Dominion-Server-Windows.zip and run Start-Server-Windows.bat. Update all clients and the host to v0.16. The Windows host package includes portable Python. Linux builds and SHA256 checksums are also included.

Validation details are recorded in README.md. Actual native OpenGL reference renders were inspected. Windows GUI execution remains untested on the Linux development machine. This remains a six-player self-hosted alpha; online surface expeditions and a global public hosting service are not implemented.

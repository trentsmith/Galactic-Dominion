# Planet creature battles

On a solo planet expedition, select owned sanctuary residents with N and deploy with R (maximum three active). V attacks the current T-selected hunt within 45 m and line of sight; Z recalls. Esc has the same buttons and a creature selector. At the landing ship, Esc → Rest Creature Party recovers fainted companions. Capturing and delivering wildlife still expands your sanctuary normally.

Battles are real-time with autonomous movement, attacks, cooldowns and species abilities. Sanctuary creatures are never removed on fainting. Recall preserves health and ability cooldowns. Expedition-local combat health resets between expeditions. Earned XP is saved immediately after subduing wildlife, even before extracting cargo; cargo still requires extraction. Failed XP saves roll back progression. Each wild creature awards XP once per expedition, including across terrain tile unload/reload.

## Attributes and affinities

HP, attack, defense and movement speed vary by species. Levels increase HP, attack and defense; friendship bond improves HP, and friendship forms increase HP and attack. Levels are capped at 50. Level/XP default safely for older saves. The sanctuary sidebar and expedition HUD show combat attributes, moves and experience.

| Strong attacker | Weak defender |
| --- | --- |
| Grove | Tide |
| Tide | Ember |
| Ember | Grove |
| Dusk | Aether |
| Aether | Stone |
| Stone | Dusk |

Advantage is 1.75x damage; the reverse matchup is 0.6x. All others are neutral. Defense further reduces damage. Wildlife levels increase with distance from the landing site (up to 20), influencing damage and defense. These are original affinities and abilities.

| Species | Affinity | Automatic ability |
| --- | --- | --- |
| Ruby Antlerstag | Grove | Verdant Guard: party shielding |
| Duskwing Bat | Dusk | Night Chirp: disrupt opponent attacks |
| Nightfang Prowler | Ember | Flare Pounce: a heavy strike |
| Lantern Jelly | Tide | Pearl Mend: party healing |
| Prism Reefgrazer | Grove | Prism Ward: party shielding |
| Riftfin Hunter | Tide | Reef Lance: a heavy strike |
| Riftwisp | Aether | Rift Slip: disrupt opponents |
| Many-Eyed Watcher | Aether | Watcher's Focus: boost party attacks |
| Veilcrawler | Stone | Shell Crash: a heavy strike |

Abilities have seven-second cooldowns. Wild creatures also use these effects when engaged: shield themselves, heal themselves, disrupt companion attacks, gain focus or strike a nearby companion. Companion attacks floor wildlife health at 1 so it can be captured. Scan before pressing C and carry capture pods. This is a first combat balance pass, without a skill tree, status inventory or online planet battles.

## Space battles

No sanctuary creature armies or garrisons in space. Existing deployment RPCs are refused and creature snapshots are empty. Ships capture and contest orbital outposts. Faction raids remain ship battles. Crew robot companions are a separate existing system; this change moves wildlife/resident armies to planets.

# The Fractured Relay / v0.39

## Narrative direction

The Lantern Network records refugee routes, not just strategic coordinates. Marshal Rhaz Veyr intends to erase a relay because a returned ship's transmission may spread through it. Sera recognizes the lost Mnemosyne and her brother Ilyan's navigation marks. Astra authorized the original expedition and concealed the orders. Milo turns the investigation into practical equipment and insists on an exit plan. The Unnumbered Choir may preserve the crew's memories, but the story does not pretend that memory proves identity or harmless intent.

The climax asks what responsibility the commander will accept: Seal the local breach or Preserve a contained memory core. Both protect the relay and earn the same chapter reward. One leaves the voices beyond the passage; the other brings home evidence and a continuing containment duty. Different objectives, radio lines and epilogues make the choice playable. It is locked on first final-sortie launch. An older completed commander with no recorded choice may choose a protocol for their first enhanced finale replay.

## Authored sorties

| Sortie | Fleet battle | Additional objective | Failure |
|---|---|---|---|
| Lanterns over Varkhoss | 3v3 Crimson blockade | Clear hostiles, then G for 3 seconds within 95m of the relay | Fleet lost, relay integrity zero, eight-minute deadline |
| The ship that came home | 3v3 Eldritch wardens | Clear hostiles, then G for 4 seconds within 95m of Mnemosyne | Fleet lost or deadline; anomaly discharges cause real damage |
| A door, not a weapon / Seal | 10v10 mixed fleet | G for 2 seconds at each of three conduits within 95m; clear all hostiles | Fleet lost or deadline |
| A door, not a weapon / Preserve | 10v10 mixed fleet | Guide moving core within 150m to its beacon; clear all hostiles | Fleet lost, core destroyed or deadline |

All scans require clear scenery line of sight and reset when released/out of range. Nearby Interdictors drain the civilian relay through jamming (220m). The anomaly marks a 110m spherical field, warns for four seconds and then deals 12 damage to ships still inside, once per cycle; both teams face it. Preserve's core takes 35 guided, unjammed seconds to reach its beacon; enemies inside 110m stall and damage it. Escort distance follows the currently piloted ship, including fleet switching. Mission objects do not change combatant counts and are not extra targetable ships. The story zone contracts from 900m to 420m so mission goals remain reachable. Generic fleet rules are unchanged.

The relay's optional 70%-integrity commendation pays 25 salvage once per commander. First mission wins grant the same permanent Sprint Drive/Bloodforged and Dreaming Abyss appearances as before. Faction appearances are cosmetic; encounter AI stat tradeoffs and class abilities remain separate. Story fights use at least Standard difficulty, retaining Veteran if selected. Human calibration is still needed.

## Journal and radio

O opens a local pause. Online journals are read-only and never pause the server. The mission action and close control remain outside scrolling content. Briefing offers stage-specific dialogue from Astra, Sera and Milo, protocol consequences and concrete controls. Recordings show lines received during the current sortie and bounded saved debrief recordings. Decoded closing messages are delivered through results even if the radio queue had not displayed them before victory. Unheard chatter stays sealed. Dossiers unlock with campaign progress. Sortie record shows the last attempt, survivors, integrity, duration and replay buttons.

Replay unlocks follow existing commission flags. Replays do not reset progress or repeat component commissions/chapter payout; normal battle settlement remains available. A previously unearned Lantern Keeper commendation can be earned once on a replay. Replaying a lost sortie does not undo an earlier ending or successful campaign milestone. A failed sortie replaces the last-attempt metrics, but recovered transmissions are merged and retained; the ending is stored separately.

## Persistence and architecture

Schema 9 accepts prior schemas 1–8. Existing completion, fittings, inventory, creature progress and cargo remain intact. The original **story** dictionary remains independent. **ship_story** adds a whitelisted protocol, lock, ending, three bounded sortie reports and one commendation flag. Missing old fields receive safe defaults; no ending is invented for older completions. Back up saves before updating because older executables refuse schema 9.

`NexusStoryData` owns authored text and mission definitions. `ShipCampaign` owns state, migration, choice/reward transactions and replay eligibility. `NexusMissionDirector` owns local objectives and delegates normal damage/fleet results to BattleMatch. `NexusComms` queues readable, deduplicated text radio without pausing combat. `NexusMissionArt` builds real scene objects. `ShipStoryScreen` and StoryTracker present this state. No networking or marketplace authority is added.

A victory requires both hostile elimination and the mission objective. The generic finish path refuses premature success. Reports and commission rewards save atomically through the campaign transaction; a failed save restores that mutation and exposes retry status in results. Ordinary battle loot uses its existing separate settlement. Partial in-sortie progress is transient and restarts on retry; choices and completed milestones persist. Codex entries derive from verified milestones rather than repeated save writes.

## Companions and archived wildlife

`gameplay/companions_enabled=true` keeps orbiting bots active. `gameplay/creatures_enabled=false` keeps wildlife, surface capture, sanctuary activities and the biological story archived. Scripts, resources and saved residents remain preserved. For archived development mode, set gameplay/creatures_enabled true or launch processes with GD_ENABLE_CREATURES=1. Python uses that environment override for its reward eligibility. GD_ENABLE_COMPANIONS=0 independently disables orbiters; default is enabled.

## Validation

52 narrative checks exercise actual controller/raycast/health/escort paths in controlled battles, both endings, report/reward retry, radio pause/deduplication, migration, viewport placement and online read-only presentation. Nine regression suites bring local Godot checks to 320; 23 backend tests passed. Native Linux menu/journal/mission rendering was inspected. Scripted tests kill opponents deterministically to isolate objective rules; they do not claim human full-mission playtesting. Windows GUI, human difficulty and accessibility testing remain pending.

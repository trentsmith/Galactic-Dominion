# Nexus fleet campaign and archived creatures

## Release scope

v0.37 makes space ships and fleet combat the default experience. The Fractured Relay draws from the provided Crimson Dominion/Varkhoss Prime and Eldritch World/Ny'Zaroth lore. This is an original opening chapter with three actual ship encounters, recovery, fitting and NPC comms. It does not access a separate external Nexus archive service.

The Bloodforged and Dreaming Abyss appearances unlock from the first and second commission victories respectively, fit all five classes and retain their selected class abilities. Enemy campaign loadouts add faction tradeoffs: Crimson speed ×0.92, hull ×1.08, shield ×0.85, laser damage ×1.12; Eldritch speed ×1.12, hull ×0.90, shield ×0.80, shield regeneration ×1.40. These are encounter modifiers applied after ordinary difficulty tuning, not bonuses for owning cosmetic hulls. Standard/Veteran tuning still needs human playtesting.

## Reversible switch

`GameFeatures.creatures_enabled()` reads **Project Settings → gameplay/creatures_enabled**, default **false**, from `project.godot`. Set it true and run the project to restore the legacy creature menu, surface landing, sanctuary, pet cosmetics/reward eligibility, companion rendering and The Lantern Signal story. Build again to distribute that configuration.

For development/regression runs, the process environment variable `GD_ENABLE_CREATURES=1` enables the same switch. On a legacy self-hosted deployment, set that variable for both the Python service and the Godot server/client processes. This is an explicit development override, not an in-game settings toggle. Python uses the environment override for its pet reward pool; it does not read Godot Project Settings.

The scripts are guarded rather than commented out or deleted, so they continue to parse and their dependencies remain testable. The network server already excludes creature combatants from space; officer data is retained while orbiting visual companions are suppressed. The existing public marketplace remains available for ships/parts/officers; archived pet entries are hidden by the default client, with definitions retained for existing accounts and escrow.

## Saved data and rewards

Schema 8 adds **ship_story** alongside the existing **story** field. Old biological objectives, sanctuary residents/affection/habitats/materials, pending cargo, collectibles and fitted IDs remain saved. The new chapter starts independently on migration; an old chapter completion cannot skip ship fights. Default loadouts using an archived pet cosmetic render a faction hull without changing the saved cosmetic ID. Selecting an active replacement is an ordinary fitting action.

Faction schematics are local commission rewards; they do not enter online inventory. Ordinary cache rarity remains unchanged, and the two faction hulls cannot be obtained from the random cache component table. Components, hull appearance and mission AI stats remain separate data concerns.

Mission transactions snapshot campaign state, inventory, discovery records and salvage, restoring them if saving fails. Match settlement still runs through the existing battle system. A failed story save leaves the commission at its old objective so it can be retried. Repeating final debrief cannot mint another chapter reward. Back up saves before upgrading; old executables refuse schema 8.

## Validation

`tests/ship_campaign_test.gd` runs 30 checks against the default shipping mode: navigation guards, reward filtering, real mission launches/results, loss/retry, wrong-mission rejection, cache recovery, fitting, both faction meshes for five classes, the 10v10 finale, save rollback, reward idempotence, reload, schema-seven migration and unchanged creature records. Legacy story/menu/component tests run with `GD_ENABLE_CREATURES=1` in CI. Native Linux captures were inspected; Windows GUI/human balance testing is not claimed.

# The Lantern Signal

An original opening chapter linking the Crimson Dominion conflict to the Nexus Archives. Astra investigates an impossible message; Sera protects affected wildlife; Milo prepares the fleet to face the relay's defenders. The ending points toward Pelagia and Ny'Zaroth, whose later chapters are not yet implemented.

## Play

1. Choose Begin your story and accept Astra's mission (+2 capture pods, once).
2. Follow the gold Varkhoss waypoint in roaming space. Approach its outpost within 650m, leave nearby combat and press L to land. The story grants exploration clearance without requiring conquest. O resumes the same fleet while you are already roaming.
3. Find a wild creature. Hold G for two seconds within 12 metres with a clear view. Dangerous wildlife needs half health or lower; LMB is non-lethal. C captures within 8 metres, spending one pod.
4. Return to the landing ship and press E within 10 metres to deliver. Capture alone does not complete the rescue; Ruby does not count.
5. Open O and debrief with Sera. Her reserved kit funds the story Sprint Drive, even if other materials have been spent.
6. Ask Milo to craft the Sprint Drive, then click Fit Sprint Drive to F1. Ownership alone is insufficient. The fit takes effect next launch: +15% speed, +12% acceleration, -6% hull.
7. Launch the Crimson patrol through the journal. This named 3v3 uses at least Standard AI. Defeat allows retry; unrelated matches do not complete it.
8. Return to Astra and archive the signal for 75 salvage once. Normal battle rewards remain separate.

Secured cargo survives redeployment, but unbanked surveys do not. The journal refuses travel that would discard pending surveys. Save failures explain the problem and retain the pending action or cargo for retry. The journal shows the current objective; NPC help explains controls. Escape/O restores the previous pause and mouse state.

## Workshop and architecture

Sprint Drive: 4 ore, 2 fiber, 1 bloom (or reserved story kit). Renewal Array: 5 ore, 3 bloom. Deep Reserve: 3 ore, 3 fiber. Recipes unlock permanent existing component blueprints, not consumable copies. Repeated crafting cannot consume materials again. Sanctuary resources fund normal recipes. Fitting outside the journal remains available in the fleet hangar.

`StoryCampaign` owns progression, recipes, dialogue and transactional mutations. `StoryScreen` presents journal/comms/workshop actions. `StoryNPC` supplies placeholder holograms. `StoryTracker` shows the next objective. Surface visits and atomic sanctuary delivery report real milestones; only offline named patrol completion reports victory. Schema 6 stores sanitized chapter flags. Online story is read-only and never pauses server simulation.

Run `godot --headless --path . --script res://tests/story_campaign_test.gd --fixed-fps 60` for the automated chapter checks. These do not replace human playtesting.

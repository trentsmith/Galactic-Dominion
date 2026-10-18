# Creature art review and refinement

Chosen direction: original soft storybook wildlife, informed by the user's preference for Pokémon Snap. This is a design comparison, not a claim of a new external gameplay study.

| Reference | Useful principle | Application here |
| --- | --- | --- |
| Pokémon Snap | Species anatomy and behavior carry personality before decoration | Separate stag, bat, prowler and aquatic proportions; preserve distinctive habitat traits |
| Slime Rancher | Clear silhouettes, a restrained palette and readable expressions at distance | Smaller facial layers, cream accents, limited markings, matte bodies |
| Astroneer | Consistent materials tie different shapes together | Shared soft surface response; glossy eyes reserved as focal points |

## Problems observed in the actual v0.20 render

The land species shared nearly identical puppy faces. Oversized eye layers and pink cheeks overwhelmed anatomy. Decorative leaves and horns carried too much of the species identity. Aquatic faces had the same facial spacing as land animals. The renderer's dark background also made the violet species harder to judge.

## Implemented first refinement

- A leaner fawn-shaped stag body, a tapered longer face, smaller eyes and small pale flank markings.
- A smaller bat torso, wider face and taller ears, separated from the prowler's muzzle and mane.
- A low, broad crawler body and low head, rather than another upright mammal.
- Species-specific facial spacing and proportions for aquatic fauna and wisps.
- Reduced cheek accents and eye highlights; softer, matte body materials without the extra outline pass.
- Pupils and catchlights now close with the eyes during wild-fauna blinking.

The shared builder applies to wild fauna, sanctuary residents, growth forms and creature armies. Gameplay, species IDs, saves and capture requirements are unchanged.

## Remaining art work

This is a procedural model refinement, not a finished sculpted asset set. Dedicated skeletal rigs, walking/swimming cycles, hand-authored textures and stronger habitat staging remain necessary for the full storybook target. Existing movement is still largely whole-body motion. The review image is an actual Godot render, not concept art.

## Verification

Capture rescue: 37 checks passed. Sanctuary forms: 39 checks passed. Native OpenGL gallery rendered and inspected. Windows GUI has not been run for this change.

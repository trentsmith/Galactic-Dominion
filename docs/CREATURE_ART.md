# Living Wildlife art pass

The aim is stylized naturalism: recognizable animal anatomy with fantasy species and friendly proportions. The same species IDs, combat attributes, capture distances and resident saves remain valid.

## Faces and species

`FaunaFace` samples each actual loft profile to mount bilateral eyes on the surface. Each eye has lids, a wet socket/cornea, a colored iris, radial fibre geometry, a pupil and a small non-emissive catchlight. Grazer pupils are horizontal; most mammals use round pupils; alien crawlers/watchers and hunters use narrow pupils. Eye sizes remain slightly expressive.

Mammals have a nose, nostrils, philtrum and neutral lip seam. Stag and prowler muzzles have clearer proportions; bats retain a small nasal leaf and shorter ears. Fish/hunters have small lateral eyes, nares and a ventral mouth. Jelly/wisp sensory structures use their own anatomy; eldritch species do not inherit mammalian ears or button noses. Painted cheek dots and the universal smile are removed.

`FaunaSkin` shares body/head materials by species and palette. Soft noise breaks up coat patterns, while fine color variation and roughness distinguish fur, aquatic skin, eldritch skin and bells. GPU noise gives a surface impression; it is not strand-based fur. Muzzle shading is separate from the body coat. Original antlers, fins, wings and mature-form motifs remain.

## Motion and portability

`FaunaFace.eyes` caches the two nested assemblies. The common blink curve closes and reopens the entire assembly, keeping pupils, irises and highlights aligned. Wild animals start with varied phases; deployed and sanctuary animals offset by resident identity. Breathing and ear/tail motion remain procedural.

Godot scenes preserve skin shaders. `FaunaSkin.bake_model` makes a portable vertex-color approximation for glTF while preserving the facial geometry and roughness category. The exporter calls this shared helper. The roundtrip test writes and reloads actual GLB files for every species.

## Inspect and validate

Run `godot --headless --path . --script res://tests/fauna_polish_test.gd --fixed-fps 60` for geometry/contact, material, animation, sanctuary and export checks.

With a graphical display, run `godot --path . --script res://tests/render_fauna_portraits.gd -- /tmp/fauna.png` for a native nine-species contact sheet. Append `2` to render mature forms. These are actual Godot renders; no generated concept art is substituted for gameplay models.

Native Linux base/mature renders were inspected. Windows visual performance and human art preference still need hands-on testing. No paid assets or external art packages are required.

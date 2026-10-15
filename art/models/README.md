# Editable 3D models

Run `godot --headless --path . --script res://tools/export_models.gd` to generate seven complete models: Pixlet Pebble Scout, five ship classes and a pearl/gold docking station.

Every model is saved as both a `.tscn` Godot scene and a `.glb` glTF 2.0 file. Godot scenes include the original outline passes; GLB files use standard PBR materials, emissive lights, names and separate mesh parts. They can be opened in Blender, Godot or another glTF editor. GLB models are static meshes, with no skeleton; blinking/orbiting/attacking are game behaviors implemented separately.

The release's `Galactic-Dominion-3D-Models.zip` includes these generated files. Mesh construction is editable in `scripts/visuals/space_model_factory.gd`. No paid assets or external art packages are required. The models are constructed in 3D from the supplied Pixlet style reference rather than using the image as a flat sprite.

# Generate real, editable Godot scenes and portable glTF 2.0 models.
extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func own_children(node: Node, owner_node: Node) -> void:
 for child in node.get_children():
  child.owner = owner_node
  own_children(child,owner_node)
func save_model(model: Node3D, basename: String) -> void:
 root.add_child(model)
 own_children(model,model)
 var packed := PackedScene.new()
 if packed.pack(model) != OK or ResourceSaver.save(packed,"res://art/models/"+basename+".tscn",ResourceSaver.FLAG_BUNDLE_RESOURCES) != OK:
  push_error("Could not save Godot model: "+basename);failures+=1
 var document := GLTFDocument.new()
 var state := GLTFState.new()
 if document.append_from_scene(model,state) != OK or document.write_to_filesystem(state,"res://art/models/"+basename+".glb") != OK:
  push_error("Could not save GLB: "+basename);failures+=1
 model.queue_free()
 print("MODEL_EXPORTED "+basename)
func run() -> void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://art/models"))
 var pixlet := Node3D.new()
 pixlet.name = "PixletPebbleScout"
 SpaceModelFactory.companion(pixlet,CollectionCatalog.find("crew_pixlet"))
 save_model(pixlet,"pixlet_pebble_scout")
 for id in CollectionCatalog.SHIP_TYPES:
  var ship := Node3D.new()
  ship.name = str(id).capitalize()
  SpaceModelFactory.ship(ship,CollectionCatalog.SHIP_TYPES[id])
  save_model(ship,"ship_"+str(id))
 var station := Node3D.new()
 station.name = "PearlGoldStation"
 SpaceModelFactory.station(station)
 save_model(station,"pearl_gold_station")
 await process_frame
 print("MODEL_EXPORT_COMPLETE failures=%d" % failures)
 quit(1 if failures else 0)

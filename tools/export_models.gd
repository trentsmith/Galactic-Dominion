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
 var luna := Node3D.new()
 luna.name = "LunaflutterMoonMoth"
 SpaceModelFactory.companion(luna,CollectionCatalog.find("crew_lunaflutter"))
 save_model(luna,"lunaflutter_moon_moth")
 var scout := Node3D.new()
 scout.name = "LunaflutterScout"
 var lunar_stats: ShipStats = CollectionCatalog.SHIP_TYPES.interceptor.duplicate()
 lunar_stats.variant_style = "moon_moth"
 lunar_stats.color = Color(0.82,0.22,1)
 SpaceModelFactory.ship(scout,lunar_stats)
 save_model(scout,"ship_lunaflutter_scout")
 var cinderbit := Node3D.new()
 cinderbit.name = "CinderbitCometPup"
 SpaceModelFactory.companion(cinderbit,CollectionCatalog.find("crew_cinderbit"))
 save_model(cinderbit,"cinderbit_comet_pup")
 var cinder_scout := Node3D.new()
 cinder_scout.name = "CinderbitScout"
 var comet_stats: ShipStats = CollectionCatalog.SHIP_TYPES.interceptor.duplicate()
 comet_stats.variant_style = "comet_pup"
 comet_stats.color = Color(1,0.32,0.025)
 SpaceModelFactory.ship(cinder_scout,comet_stats)
 save_model(cinder_scout,"ship_cinderbit_scout")
 for id in CollectionCatalog.SHIP_TYPES:
  var ship := Node3D.new()
  ship.name = str(id).capitalize()
  SpaceModelFactory.ship(ship,CollectionCatalog.SHIP_TYPES[id])
  save_model(ship,"ship_"+str(id))
 for planet in PlanetCatalog.WORLDS:
  for species in planet.fauna:
   var animal := Node3D.new()
   animal.name = species.display_name.replace(" ", "")
   SurfaceArt.creature(animal,species)
   save_model(animal,"fauna_"+species.id)
   for stage in [1,2]:
    var form := Node3D.new()
    form.name = SanctuaryForms.form_name(species.id,stage).replace(" ","")
    SanctuaryFormArt.creature(form,species,stage)
    save_model(form,"fauna_"+species.id+("_kindred" if stage==1 else "_radiant"))
 var station := Node3D.new()
 station.name = "PearlGoldStation"
 SpaceModelFactory.station(station)
 save_model(station,"pearl_gold_station")
 await process_frame
 print("MODEL_EXPORT_COMPLETE failures=%d" % failures)
 quit(1 if failures else 0)

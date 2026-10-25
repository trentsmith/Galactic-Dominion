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
 bake_fauna_coats(model)
 var document := GLTFDocument.new()
 var state := GLTFState.new()
 if document.append_from_scene(model,state) != OK or document.write_to_filesystem(state,"res://art/models/"+basename+".glb") != OK:
  push_error("Could not save GLB: "+basename);failures+=1
 model.queue_free()
 print("MODEL_EXPORTED "+basename)
# Godot scenes retain the procedural skin. glTF receives a vertex-color bake.
func bake_fauna_coats(node: Node) -> void:
 for child in node.get_children():bake_fauna_coats(child)
 if not node is MeshInstance3D or not node.material_override is ShaderMaterial:return
 var shader: ShaderMaterial=node.material_override
 if shader.shader!=preload("res://resources/shaders/fauna_skin.gdshader"):return
 var coat: Color=shader.get_shader_parameter("coat")
 var marking: Color=shader.get_shader_parameter("marking")
 var pattern: float=shader.get_shader_parameter("pattern")
 var mesh:=ArrayMesh.new()
 for surface in range(node.mesh.get_surface_count()):
  var arrays: Array=node.mesh.surface_get_arrays(surface)
  var colors:=PackedColorArray()
  for p in arrays[Mesh.ARRAY_VERTEX]:
   var stripes:=pow(.5+.5*sin(p.z*18.+sin(p.y*9.)*1.8),12.)
   var cell:=Vector3(fposmod(p.x*8.,1.)-.5,fposmod(p.y*8.,1.)-.5,fposmod(p.z*8.,1.)-.5)
   var spots:=1.-smoothstep(.1,.24,cell.length())
   var blend: float=spots if pattern<.5 else stripes
   var belly: float=1.-smoothstep(.35,.95,p.y)
   colors.append(coat.lerp(marking,clampf(blend*.42+belly*.45,0,.75)))
  arrays[Mesh.ARRAY_COLOR]=colors;mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 var material:=StandardMaterial3D.new();material.vertex_color_use_as_albedo=true;material.roughness=.72;material.cull_mode=BaseMaterial3D.CULL_DISABLED
 node.mesh=mesh;node.material_override=material

func run() -> void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://art/models"))
 for id in ["orbitot","glimbloom"]:
  var companion := Node3D.new()
  companion.name = id.capitalize()+"FleetCompanion"
  SpaceModelFactory.companion(companion,CollectionCatalog.find("crew_"+id))
  save_model(companion,id+"_fleet_companion")
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
 for variant in CollectionCatalog.DEFINITIONS:
  if variant.kind!="variant" or variant.visual_style=="standard":continue
  for id in CollectionCatalog.SHIP_TYPES:
   # Preserve the original filenames for these two Interceptor exports.
   if id=="interceptor" and variant.id in ["variant_lunaflutter","variant_cinderbit"]:continue
   var model := Node3D.new()
   model.name=variant.display_name.replace(" ","")+str(id).capitalize()
   var fitted: ShipStats=CollectionCatalog.SHIP_TYPES[id].duplicate(true)
   fitted.variant_style=variant.visual_style;fitted.color=variant.color
   SpaceModelFactory.ship(model,fitted)
   save_model(model,"ship_"+variant.id.trim_prefix("variant_")+"_"+str(id))
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

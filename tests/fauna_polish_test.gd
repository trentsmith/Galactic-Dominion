extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1;print(("PASS: " if ok else "FAIL: ")+message)
 if not ok:failures+=1
func nearest_surface(mesh: MeshInstance3D,point: Vector3) -> float:
 var distance:=INF
 var faces:=mesh.mesh.get_faces()
 for i in range(0,faces.size(),3):
  var a: Vector3=faces[i];var b: Vector3=faces[i+1];var c: Vector3=faces[i+2]
  var normal: Vector3=(b-a).cross(c-a)
  if normal.length_squared()<.000000001:continue
  normal=normal.normalized()
  var projected:=point-normal*(point-a).dot(normal)
  if (b-a).cross(projected-a).dot(normal)>=0 and (c-b).cross(projected-b).dot(normal)>=0 and (a-c).cross(projected-c).dot(normal)>=0:
   distance=minf(distance,projected.distance_to(point))
  for edge in [[a,b],[b,c],[c,a]]:
   var near:=Geometry3D.get_closest_point_to_segment(point,edge[0],edge[1])
   distance=minf(distance,near.distance_to(point))
 return distance
func run() -> void:
 var gallery:=Node3D.new();root.add_child(gallery)
 for planet in PlanetCatalog.WORLDS:
  for d in planet.fauna:
   var model:=SurfaceArt.creature(gallery,d)
   var anchors:=model.find_children("EyeAnchor*","Node3D",true,false)
   var head:=model.find_child("SculptedHead",true,false) as MeshInstance3D
   var skin:=head if head!=null else model.find_child("FaunaBody",true,false) as MeshInstance3D
   var mounted:=anchors.size()==2
   var wet:=true
   for anchor in anchors:
    mounted=mounted and nearest_surface(skin,anchor.position)<.05
    var eye:=anchor.find_child("EyeSocket",true,false) as MeshInstance3D
    var material:=eye.material_override as StandardMaterial3D
    wet=wet and material.roughness<.2 and material.next_pass==null and material.shading_mode==BaseMaterial3D.SHADING_MODE_PER_PIXEL
   check(mounted,d.id+" eyes touch the actual head/body surface rather than floating in front")
   check(wet,d.id+" uses reflective eye materials without flat unshaded eye stickers")
   check(model.find_children("UpperLid*","MeshInstance3D",true,false).size()==2 and model.find_children("LowerLid*","MeshInstance3D",true,false).size()==2,d.id+" has upper and lower anatomical lids")
   check(model.find_children("IrisFibres*","MeshInstance3D",true,false).size()==2 and model.find_child("RosyCheek*",true,false)==null and model.find_child("LittleSmile",true,false)==null,d.id+" has detailed irises without painted cheeks or a pasted smile")
   var body:=model.find_child("FaunaBody",true,false) as MeshInstance3D
   check(body.material_override==FaunaSkin.material(d),d.id+" reuses the shared species skin material")
   var color:=FaunaSkin.bake_color(Vector3(.3,1.5,-1.1),body.material_override)
   check(is_finite(color.r) and color.r>=0 and color.r<=1 and color.a==1,d.id+" has a valid portable coat-color bake")
   if d.body_style in ["stag","wolf","bat"]:check(model.find_children("Nostril*","MeshInstance3D",true,false).size()==2 and model.find_child("Philtrum",true,false)!=null,d.id+" has a connected nose, nostrils and a neutral mouth seam")
   if d.body_style in ["fish","shark","watcher","crawler"]:check(model.find_child("LeafEar*",true,false)==null,d.id+" retains species anatomy rather than mammalian ears")
   FaunaSkin.bake_model(model)
   model.name="Export_"+d.id
   var document:=GLTFDocument.new();var state:=GLTFState.new()
   var path: String="/tmp/fauna-polish-"+d.id+".glb"
   var exported:=document.append_from_scene(model,state)==OK and document.write_to_filesystem(state,path)==OK
   var imported:=GLTFState.new();var reader:=GLTFDocument.new()
   var decoded:=exported and reader.append_from_file(path,imported)==OK
   var roundtrip: Node3D=reader.generate_scene(imported) if decoded else null
   check(roundtrip!=null and roundtrip.find_children("EyeAnchor*","Node3D",true,false).size()==2 and roundtrip.find_children("UpperLid*","MeshInstance3D",true,false).size()==2,d.id+" exports and reloads as portable glTF with facial geometry intact")
   if roundtrip!=null:roundtrip.free()
   if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
 var host=load("res://scenes/main.tscn").instantiate();host.profile_path="user://polish-%d.json"%Time.get_ticks_usec();root.add_child(host);await process_frame
 host.start_planet(0);await process_frame
 var animal: SurfaceFauna=host.surface.fauna[0]
 for member in host.surface.fauna:member.set_physics_process(false);member.set_process(false)
 check(animal.face_eyes.size()==2,"Wildlife discovers the two nested eye assemblies for blinking")
 animal.face_clock=0;animal._process(4.26)
 check(animal.face_eyes[0].scale.y<.1,"The whole eye assembly closes smoothly during a blink")
 animal._process(.2)
 check(animal.face_eyes[0].scale.y>.95,"The eye reopens without displaced pupils or catchlights")
 var resident:=SanctuaryFormArt.creature(gallery,animal.definition,2)
 check(resident.find_children("EyeAnchor*","Node3D",true,false).size()==2 and resident.find_child("KindredDetails",true,false)!=null,"Mature sanctuary forms inherit the same polished face")
 check(host.surface.party.deploy(1) and host.surface.party.units[1].eyes.size()==2,"Deployed creature parties retain the same nested facial animation")
 host.show_sanctuary();await process_frame
 var garden: SanctuaryGarden=host.sanctuary_scene
 check(garden.resident_eyes[1].size()==2,"Sanctuary residents cache their facial assemblies")
 garden.clock=4.26-.47;garden._process(0)
 check(garden.resident_eyes[1][0].scale.y<.1,"Sanctuary creatures use the same smooth blink as wild creatures")
 host.queue_free();gallery.queue_free();await process_frame;await process_frame
 print("FAUNA_POLISH_TEST: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)

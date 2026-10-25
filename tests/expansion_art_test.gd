extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1;print(("PASS: " if ok else "FAIL: ")+message)
 if not ok:failures+=1
func run() -> void:
 var signatures:={"bloodstag":"AntlerBlossom","duskbat":"WingVein","nightfang":"EmberRuff","sporehopper":"CrownFrond","prismgrazer":"ReefWhisker","thornmanta":"HunterSail","manyeye":"WatcherEyeStalk","veilcrawler":"VeilStilt","riftwisp":"VeilStreamer"}
 var scene:=Node3D.new();root.add_child(scene)
 for id in signatures:
  var model:=SurfaceArt.creature(scene,SanctuaryState.fauna(id))
  check(model.find_child(signatures[id]+"*",true,false)!=null,id+" has species-specific silhouette anatomy")
  var body:=model.find_child("FaunaBody",true,false) as MeshInstance3D
  check(body!=null and body.material_override is ShaderMaterial,id+" has a patterned habitat coat")
 var world:=SurfaceWorld.new();world.definition=PlanetCatalog.WORLDS[2];scene.add_child(world);await process_frame
 check(world.find_child("AbyssOssuary",true,false)!=null and world.find_child("AncientWatchingEye",true,false)!=null,"Ny'Zaroth contains the ribbed ossuary and distant watching eye")
 check(world.find_child("WhisperStalk*",true,false)!=null and world.find_child("HangingRoot*",true,false)!=null,"Eldritch vegetation and floating ruins have organic anatomy")
 var environment: WorldEnvironment=world.find_children("","WorldEnvironment",true,false)[0]
 check(environment.environment.background_mode==Environment.BG_SKY and environment.environment.ambient_light_energy<.5,"The abyss uses a dusk sky and restrained lighting")
 scene.queue_free();await process_frame
 print("EXPANSION_ART_TEST: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)

extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
 checks+=1
 if value:print("PASS: "+message)
 else:failures+=1;push_error("FAIL: "+message)
func key(code: int, pressed: bool) -> void:
 var event:=InputEventKey.new();event.physical_keycode=code;event.keycode=code;event.pressed=pressed;Input.parse_input_event(event)
func run() -> void:
 var path:="user://capture-rescue-%d.json"%Time.get_ticks_usec()
 var main: Node=load("res://scenes/main.tscn").instantiate();main.profile_path=path;root.add_child(main);await process_frame
 main.start_planet(0);await process_frame
 var expedition: PlanetExpedition=main.surface
 expedition.set_physics_process(false);expedition.bot.set_physics_process(false)
 for animal in expedition.fauna:animal.set_physics_process(false);animal.position=Vector3(500,5,500)
 # The headless display cannot capture a mouse; use the same input adapter
 # while still injecting real physical G/C key events into InputMap.
 if DisplayServer.get_name()=="headless":
  expedition.bot.input_provider=func():return {"scan":Input.is_action_pressed("scan"),"capture":Input.is_action_just_pressed("surface_capture")}
 if DisplayServer.get_name()!="headless":
  # Keep the real collisions and input window, but omit expensive scenery
  # draws on the software renderer. The art has its own native render check.
  expedition.world.visible=false
  Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
  var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;Input.parse_input_event(click)
  for i in range(2):await physics_frame
  click=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=false;Input.parse_input_event(click)
  check(Input.mouse_mode==Input.MOUSE_MODE_CAPTURED,"Clicking the native game window restores exploration input")
 var prey: SurfaceFauna=expedition.fauna[10]
 prey.position=Vector3(0,SurfaceWorld.height_at(0,-28)+.5,-28)
 expedition.bot.position=prey.position+Vector3(0,1,5)
 expedition.select_hunt(prey.definition.id)
 prey.set_physics_process(true)
 expedition.set_physics_process(true)
 key(KEY_G,true)
 for i in range(45):await physics_frame
 var locked:=expedition.scan_target
 var neighbor: SurfaceFauna=expedition.fauna[11]
 neighbor.position=expedition.bot.position+Vector3(2,0,0)
 for i in range(20):await physics_frame
 check(locked==prey and expedition.scan_target==prey,"A nearer moving individual cannot steal an active scan")
 neighbor.position=Vector3(500,5,500)
 for i in range(80):await physics_frame
 key(KEY_G,false)
 check(expedition.surveyed(prey),"Holding the actual G key completes a scan while passive AI is active")
 check(prey.alive and expedition.bot.position.distance_to(prey.position)<8,"A curious passive animal stays within capture reach during scanning")
 prey.set_physics_process(false);expedition.set_physics_process(false)
 var rival: SurfaceFauna=expedition.fauna[0]
 rival.position=expedition.bot.position+Vector3(3,0,-2)
 expedition.select_hunt(rival.definition.id)
 check(not expedition.capture_ready(rival) and expedition.capture_target()==prey,"An unscanned active hunt cannot block a nearby capture-ready creature")
 var pods: int=main.profile.sanctuary.materials.capture_pod
 expedition.set_physics_process(true);key(KEY_C,true)
 for i in range(3):await physics_frame
 key(KEY_C,false)
 for i in range(2):await physics_frame
 expedition.set_physics_process(false)
 check(not prey.alive and expedition.cargo_animals.size()==1,"The actual C key captures a live scanned creature")
 check(main.profile.sanctuary.materials.capture_pod==pods-1,"One key press spends exactly one capture pod")
 check(expedition.cargo_animals.size()>0 and expedition.cargo_animals[0]==prey.definition.id,"The captured species matches the displayed capture target")
 rival.position=expedition.bot.position+Vector3(0,0,-5)
 expedition.bot.yaw=0;expedition.bot.pitch=0
 for i in range(8):
  expedition.bot.cooldown=0;expedition.bot.fire()
 check(rival.alive and rival.health==1,"Repeated real defensive pulses cannot kill a capture target")
 check(rival.dazed_remaining>0,"A weakened predator is temporarily dazed for a capture window")
 check(expedition.survey_specimen(rival) and expedition.capture_nearest(),"A stunned scanned predator can be captured")
 var third: SurfaceFauna=expedition.fauna[11]
 third.position=expedition.bot.position+Vector3(0,0,-8)
 check(expedition.surveyed(third),"A completed species scan covers its other individuals")
 var wall:=StaticBody3D.new();wall.collision_layer=1
 var collider:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(4,6,1);collider.shape=box;wall.add_child(collider);expedition.add_child(wall)
 wall.position=expedition.bot.position+Vector3(0,0,-4)
 await physics_frame;await physics_frame
 var cargo_before:=expedition.cargo_animals.size()
 check(not expedition.capture_nearest() and expedition.cargo_animals.size()==cargo_before and "BLOCKED" in expedition.status_message,"A solid obstacle blocks capture without consuming cargo space")
 wall.queue_free();await physics_frame;await physics_frame
 main.profile.save_blocked=true
 var before_pods: int=main.profile.sanctuary.materials.capture_pod
 check(not expedition.capture_nearest() and third.alive and main.profile.sanctuary.materials.capture_pod==before_pods,"A failed capture save preserves both animal and pod")
 main.profile.save_blocked=false
 check(expedition.capture_nearest(),"The full eight-meter capture radius includes its boundary")
 expedition.bot.position=Vector3(0,1.5,5)
 var ore: int=main.profile.sanctuary.materials.ore
 var bloom: int=main.profile.sanctuary.materials.bloom
 var before_craft: int=main.profile.sanctuary.materials.capture_pod
 check(expedition.craft_capture_pod() and main.profile.sanctuary.materials.capture_pod==before_craft+1,"A replacement pod can be crafted at the landing refuge")
 check(main.profile.sanctuary.materials.ore==ore-1 and main.profile.sanctuary.materials.bloom==bloom-1,"Landing-site pod crafting charges its actual recipe")
 expedition.bot.position.z=-35
 check(not expedition.craft_capture_pod(),"Pod crafting requires returning to the ship")
 expedition.bot.position=Vector3(0,1.5,5)
 check(expedition.extract() and main.profile.sanctuary.residents.size()==4,"The captured passive and dangerous creatures all reach the sanctuary")
 var restored:=PlayerProfile.new(path);restored.load_profile()
 check(restored.sanctuary.residents.size()==4,"The repaired input-to-delivery flow survives save/reload")
 var gallery:=Node3D.new();root.add_child(gallery)
 for planet in PlanetCatalog.WORLDS:
  for species in planet.fauna:
   var model:=SurfaceArt.creature(gallery,species)
   check(model.find_children("EyeAnchor*","Node3D",true,false).size()==2 and model.find_children("UpperLid*","MeshInstance3D",true,false).size()==2,species.id+" has paired surface-mounted eyes and anatomical lids")
   check(model.find_child("RosyCheek*",true,false)==null and model.find_child("LittleSmile",true,false)==null,species.id+" uses natural facial anatomy rather than painted cheeks and a smile")
   model.free()
 gallery.queue_free();main.queue_free();await process_frame;await process_frame
 for suffix in ["", ".bak", ".tmp"]:
  if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
 print("CAPTURE RESCUE TEST: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)

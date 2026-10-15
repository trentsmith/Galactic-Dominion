extends SceneTree
var checks:=0
var failures:=0
var main: Node
var save_path:=""
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
 checks+=1
 if value:print("PASS: "+message)
 else:failures+=1;push_error("FAIL: "+message)
func frames(count: int=3) -> void:
 for i in range(count):await process_frame
func freeze(expedition: PlanetExpedition) -> void:
 expedition.set_physics_process(false);expedition.bot.set_physics_process(false)
 for animal in expedition.fauna:animal.set_physics_process(false)
func run() -> void:
 save_path="user://planet-test-%d.json" % Time.get_ticks_usec()
 main=load("res://scenes/main.tscn").instantiate();main.profile_path=save_path;root.add_child(main)
 await frames()
 main.show_planets();await frames()
 var selector: PlanetSelector=main.menu.get_child(0)
 check(selector.bot_ids==["crew_pixlet"],"A new player can deploy a loaner without owning an alien")
 check(not main.profile.owns("crew_pixlet"),"The loaner does not grant or consume collectible ownership")
 main.start_planet(0,"crew_pixlet");await frames()
 var expedition: PlanetExpedition=main.surface
 freeze(expedition)
 check(expedition.definition.id=="varkhoss" and expedition.definition.display_name.contains("Varkhoss"),"First planet follows the supplied Varkhoss Prime lore")
 check(expedition.fauna.size()==30 and expedition.definition.fauna.size()==3,"Planet contains thirty active creatures across three species")
 check(expedition.world.flora_nodes.size()==3 and expedition.specimens.size()==33,"Three flora species join scannable wildlife")
 check(expedition.bot.visual.eyes.size()==2 and expedition.bot.camera.current,"The bot is a real 3D character with a chase camera")
 var bot:=expedition.bot
 var before:=bot.global_position
 bot.input_provider=func():return {"move":Vector2(0,-1)}
 bot.set_physics_process(true)
 for i in range(20):await physics_frame
 bot.input_provider=Callable();bot.set_physics_process(false)
 check(Vector2(bot.position.x-before.x,bot.position.z-before.z).length()>1,"WASD input moves the bot over collidable terrain")
 check(bot.is_on_floor(),"The generated terrain supports the bot with working ground collision")
 bot.position=Vector3(20,3,10);bot.shield=35;bot.hull=60
 bot.hurt(10)
 check(bot.shield==25 and bot.hull==60,"Bot shields absorb wildlife damage first")
 bot.hurt(30)
 check(bot.shield==0 and bot.hull==55,"Damage exceeding shields reaches the bot hull")
 bot.position=Vector3(0,1.5,5);bot.hurt(100)
 check(bot.alive and bot.hull==55,"The landing refuge protects the bot")
 var predator: SurfaceFauna=expedition.fauna[20]
 predator.position=Vector3(20,1,12);bot.position=Vector3(20,1.5,18);predator.decide_timer=0
 predator._physics_process(.1)
 check(predator.state=="chase","Predators find and pursue a nearby exposed bot")
 var passive: SurfaceFauna=expedition.fauna[10]
 passive.position=Vector3(25,1,15);passive.decide_timer=0;passive._physics_process(.1)
 check(passive.state=="flee","Passive fauna flee instead of attacking the bot")
 predator.position=Vector3(20,1,10);predator.health=34;bot.yaw=0;bot.cooldown=0
 var target_health:=predator.health
 check(bot.fire() and predator.health<target_health,"A defensive pulse damages visible wildlife in front of the bot")
 check(not bot.fire(),"Defensive weapon cooldown prevents immediate repeat fire")
 var animal: SurfaceFauna=expedition.fauna[0]
 bot.position=Vector3(90,5,80)
 check(not expedition.survey_specimen(animal),"A specimen cannot be scanned remotely")
 bot.position=animal.position+Vector3(0,1,3)
 var salvage_before: int=main.profile.salvage
 check(expedition.survey_specimen(animal),"A living nearby animal can be surveyed")
 check(not expedition.survey_specimen(animal),"A known fauna species cannot create duplicate pending rewards")
 check(main.profile.salvage==salvage_before and main.profile.exploration_records.is_empty(),"Pending surveys remain unbanked until extraction")
 for node in [expedition.fauna[10],expedition.fauna[20],expedition.world.flora_nodes[0],expedition.world.flora_nodes[1],expedition.world.flora_nodes[2]]:
  bot.position=node.position+Vector3(0,1,3)
  check(expedition.survey_specimen(node),"Distinct fauna or flora species can be added to the survey")
 check(expedition.survey_count()==6,"All three fauna and three flora make a complete survey")
 check(not expedition.extract(),"Extraction requires returning to the landing ship")
 bot.position=Vector3(0,1.5,5)
 check(expedition.extract() and expedition.finished,"Returning to the ship extracts the bot")
 check(main.profile.salvage==salvage_before+175 and main.profile.owns(expedition.definition.survey_reward),"Extraction grants six surveys plus the one-time completed-planet reward")
 var earned: int=main.profile.salvage
 check(not expedition.extract() and main.profile.salvage==earned,"Repeated extraction cannot duplicate rewards")
 var restored:=PlayerProfile.new(save_path);restored.load_profile()
 check(restored.exploration_records.has("surface.varkhoss.complete"),"Extracted planet discoveries persist through save/reload")
 main.start_planet(1);await frames();expedition=main.surface;freeze(expedition)
 check(expedition.definition.aquatic and expedition.definition.display_name.contains("Pelagia"),"Second planet is the alien reef inspired by the marine reference")
 bot=expedition.bot;bot.position=Vector3(0,5,5);bot.velocity=Vector3.ZERO
 bot.input_provider=func():return {"vertical":1.0}
 bot._physics_process(.2);bot.input_provider=Callable()
 check(bot.velocity.y>0,"Underwater bots can swim vertically")
 var unknown: SurfaceFauna=expedition.fauna[0]
 bot.position=unknown.position+Vector3(0,1,3);expedition.survey_specimen(unknown)
 var records_before: int=main.profile.exploration_records.size()
 bot.position=Vector3(30,5,20);bot.hull=1;bot.shield=0;bot.hurt(100)
 check(expedition.finished and not bot.alive and expedition.pending.is_empty(),"Fauna damage can destroy the bot and lose unextracted surveys")
 check(main.profile.exploration_records.size()==records_before and main.profile.salvage==earned,"Failed expeditions preserve banked discoveries and do not grant salvage")
 main.start_planet(2);await frames();expedition=main.surface;freeze(expedition)
 check(expedition.definition.id=="nyzaroth" and expedition.definition.display_name.contains("Dreaming Abyss"),"Third planet uses Ny’Zaroth from the supplied Nexus lore")
 expedition.elapsed=23
 check(expedition.gravity_multiplier()==.3,"Reality fractures create a timed low-gravity exploration hazard")
 expedition.elapsed=31
 check(expedition.gravity_multiplier()==1,"Normal gravity returns after a fracture")
 expedition.toggle_pause()
 check(paused and expedition.hud.pause_panel.visible,"Surface pause freezes the expedition and opens its menu")
 expedition.toggle_pause()
 check(not paused and not expedition.hud.pause_panel.visible,"Resuming restores surface play")
 main.return_to_menu();await frames()
 check(not is_instance_valid(main.surface) and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"Returning to the main menu cleans up surface play")
 main.queue_free();await frames()
 for suffix in ["", ".bak", ".tmp"]:
  if FileAccess.file_exists(save_path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path+suffix))
 print("PLANET EXPEDITION TEST: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)

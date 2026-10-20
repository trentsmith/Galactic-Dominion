extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void:call_deferred("run")
func check(value: bool, message: String) -> void:
 checks+=1
 if value:print("PASS: "+message)
 else:failures+=1;push_error("FAIL: "+message)
func run() -> void:
 var profile := PlayerProfile.new("user://universal-liveries-%d.json"%Time.get_ticks_usec())
 profile.load_profile()
 for definition in CollectionCatalog.DEFINITIONS:profile.acquire(definition.id,"Test fixture")
 profile.equip(1,"crew","");profile.equip(2,"crew","");profile.equip(0,"crew","")
 var variants := CollectionCatalog.for_slot("variant","Guardian")
 check(variants.size()==10,"All ten livery selections are available for Guardians")
 for hull in CollectionCatalog.SHIP_TYPES:
  check(profile.set_ship_class(0,hull),"The player can select "+hull)
  var base: ShipStats = CollectionCatalog.SHIP_TYPES[hull]
  check(CollectionCatalog.for_slot("variant",base.class_name_text).size()==10,hull+" lists every livery")
  for variant in variants:
   profile.equip(0,"crew","")
   var fitted := profile.equip(0,"variant",variant.id)
   var stats := profile.configured_stats(0)
   check(fitted and stats.class_name_text==base.class_name_text and stats.ability==base.ability and stats.hull==base.hull and stats.shield==base.shield and stats.speed==base.speed and stats.laser_damage==base.laser_damage and stats.missile_damage==base.missile_damage,hull+" / "+variant.id+" keeps hull identity and combat stats")
   var model := Node3D.new()
   root.add_child(model)
   SpaceModelFactory.ship(model,stats)
   var valid := model.find_child("MainEngine",true,false)!=null and model.find_child("PilotCanopy",true,false)!=null and model.find_child("ShieldShell",true,false)!=null and model.find_child("MuzzleFlash",true,false)!=null
   if hull=="guardian":valid=valid and model.find_child("GuardianKeelArmor",true,false)!=null
   if hull=="support":valid=valid and model.find_child("RepairBeacon",true,false)!=null
   if variant.id=="variant_orbitot":valid=valid and model.find_child("ShipSatelliteOrbit",true,false)!=null
   if variant.id=="variant_glimbloom":valid=valid and model.find_children("PrismPetal*","Node3D",true,false).size()==6
   check(valid,hull+" / "+variant.id+" builds real geometry and retains gameplay attachments")
   model.free()
  var all_crew := true
  for definition in CollectionCatalog.DEFINITIONS:
   if definition.kind=="crew":all_crew=profile.equip(0,"crew",definition.id) and all_crew
  check(all_crew,hull+" accepts every discovered astronaut and companion")
 profile.equip(0,"crew","crew_orbitot")
 profile.equip(0,"variant","variant_glimbloom")
 check(profile.set_ship_class(0,"guardian") and profile.configured_stats(0).variant_style=="glimbloom" and profile.configured_stats(0).crew_id=="crew_orbitot","Changing hull preserves compatible livery and independently chosen crew")
 var restored := PlayerProfile.new(profile.save_path)
 restored.load_profile()
 check(restored.configured_stats(0).variant_style=="glimbloom" and restored.configured_stats(0).class_name_text=="Guardian","Universal fitting persists across save/reload")
 var live := CombatShip.new();live.stats=profile.configured_stats(0)
 root.add_child(live);live.set_physics_process(false)
 var orbit := live.livery_orbits[0]
 var start := orbit.quaternion
 live._process(0.5)
 check(not start.is_equal_approx(orbit.quaternion) and live.companion.definition.id=="crew_orbitot","Ship-skin crystals animate independently from the equipped companion")
 live.queue_free()
 var main: Node=load("res://scenes/main.tscn").instantiate()
 main.profile_path=profile.save_path;root.add_child(main)
 await process_frame
 main.show_hangar()
 await process_frame
 var hangar: HangarScreen=main.menu.get_child(0)
 for hull in CollectionCatalog.SHIP_TYPES:
  main.profile.set_ship_class(0,hull)
  hangar.selected_ship=0;hangar._refresh_fitting()
  var choice: OptionButton=hangar.fitting_rows.get_child(5).get_child(1)
  var selected := -1
  for index in range(choice.item_count):
   if choice.get_item_metadata(index)=="variant_orbitot":selected=index
  var valid := choice.item_count==10 and selected>=0
  if selected>=0:choice.item_selected.emit(selected)
  check(valid and main.profile.configured_stats(0).variant_style=="orbitot",hull+" exposes all skins in the actual Hangar and applies the selected skin")
 main.queue_free()
 await process_frame
 await process_frame
 for suffix in ["", ".bak", ".tmp"]:
  if FileAccess.file_exists(profile.save_path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(profile.save_path+suffix))
 print("UNIVERSAL LIVERIES TEST: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)

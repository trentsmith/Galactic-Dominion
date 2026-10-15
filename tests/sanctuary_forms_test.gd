extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
 checks+=1
 if value:print("PASS: "+message)
 else:failures+=1;push_error("FAIL: "+message)
func qualify(resident: Dictionary,stage: int) -> void:
 var goal: Dictionary=SanctuaryForms.REQUIREMENTS[stage]
 resident.bond=goal.friendship;resident.love=goal.love;resident.growth=goal.growth;resident.care_time=goal.care_time;resident.nutrition=80;resident.happiness=80
func run() -> void:
 var state:=SanctuaryState.defaults();var resident: Dictionary=state.residents[0]
 check(resident.form_stage==0 and resident.love==0,"New residents begin in their base form with affection to earn")
 check(not SanctuaryState.awaken(state,1),"A new creature cannot skip care requirements")
 SanctuaryState.care(state,1,"feed");SanctuaryState.care(state,1,"pet");SanctuaryState.care(state,1,"play")
 check(resident.bond>0 and resident.love>0,"Feeding, affection and play build friendship and love")
 var love: float=resident.love;var time: float=resident.care_time
 SanctuaryState.tick(state,5)
 check(resident.love>love and resident.care_time>time,"Happy, nourished time in a habitat builds lasting affection")
 resident.nutrition=10;time=resident.care_time;SanctuaryState.tick(state,5)
 check(resident.care_time==time,"Poor care cannot accumulate qualifying happy-care time")
 qualify(resident,0)
 var saved: Dictionary=resident.duplicate(true)
 for key in ["bond","love","growth","care_time"]:
  resident[key]=saved[key]-1
  check(not SanctuaryForms.ready(resident),"Kindred form requires sufficient "+key)
  resident[key]=saved[key]
 resident.habitat=0
 check(not SanctuaryForms.ready(resident),"A compatible home is required for awakening")
 resident.habitat=1;resident.happiness=20
 check(not SanctuaryForms.ready(resident),"An unhappy resident cannot awaken")
 resident.happiness=80;resident.nutrition=10
 check(not SanctuaryForms.ready(resident),"A hungry resident cannot awaken")
 resident.nutrition=80
 var materials: Dictionary=state.materials.duplicate(true)
 check(SanctuaryState.awaken(state,1) and resident.form_stage==1 and state.materials==materials,"Kindred awakening is a free, permanent care milestone")
 check(SanctuaryForms.form_name("bloodstag",1)=="Petalcrest Stag" and resident.name=="Ruby","The new form has an original name while preserving the resident nickname")
 check(not SanctuaryState.awaken(state,1),"Kindred requirements cannot immediately unlock Radiant form")
 qualify(resident,1)
 check(SanctuaryState.awaken(state,1) and resident.form_stage==2,"Radiant form requires the second set of care milestones")
 check(not SanctuaryState.awaken(state,1),"The final form cannot be awakened repeatedly")
 resident.bond=0;resident.love=0;resident.nutrition=0;resident.happiness=0;SanctuaryState.tick(state,5)
 check(resident.form_stage==2,"A creature does not lose an earned form when its mood changes")
 var base:=SanctuaryState.defaults();var kindred:=SanctuaryState.defaults();var radiant:=SanctuaryState.defaults()
 kindred.residents[0].form_stage=1;radiant.residents[0].form_stage=2
 SanctuaryState.tick(base,1);SanctuaryState.tick(kindred,1);SanctuaryState.tick(radiant,1)
 check(is_equal_approx(kindred.residents[0].clock/base.residents[0].clock,1.15) and is_equal_approx(radiant.residents[0].clock/base.residents[0].clock,1.35),"Kindred and Radiant forms improve production by 15% and 35%")
 var legacy:=SanctuaryState.defaults();legacy.residents[0].erase("form_stage");legacy.residents[0].erase("love");legacy.residents[0].erase("care_time");legacy.residents[0].bond=80
 var migrated:=SanctuaryState.sanitize(legacy)
 check(migrated.residents[0].form_stage==0 and migrated.residents[0].love==40 and migrated.residents[0].bond==80,"Older residents keep friendship and receive migration credit without free form unlocks")
 var corrupted:=SanctuaryState.defaults();corrupted.residents[0].form_stage=999;corrupted.residents[0].love=-9;corrupted.residents[0].care_time="invalid"
 var cleaned:=SanctuaryState.sanitize(corrupted)
 check(cleaned.residents[0].form_stage==2 and cleaned.residents[0].love==0 and cleaned.residents[0].care_time==0,"Saved form and affection data is validated")
 var names: Dictionary={};var species_count:=0
 for planet in PlanetCatalog.WORLDS:
  for definition in planet.fauna:
   species_count+=1
   var counts: Array[int]=[]
   for stage in [0,1,2]:
    var parent:=Node3D.new();root.add_child(parent)
    var model:=SanctuaryFormArt.creature(parent,definition,stage)
    counts.append(model.find_children("","MeshInstance3D",true,false).size())
    if stage>0:names[SanctuaryForms.form_name(definition.id,stage)]=true
    parent.free()
   check(counts[1]>counts[0] and counts[2]>counts[1],definition.display_name+" has additional 3D geometry in both new forms")
 check(species_count==9 and names.size()==18,"All nine species have eighteen distinct named growth forms")
 for stage in [1,2]:
  var document:=GLTFDocument.new();var gltf:=GLTFState.new()
  check(document.append_from_file("res://art/models/fauna_bloodstag"+("_kindred" if stage==1 else "_radiant")+".glb",gltf)==OK,"The grown form exports as a valid reusable GLB")
 var path:="user://forms-test-%d.json" % Time.get_ticks_usec()
 var profile:=PlayerProfile.new(path);profile.load_profile();profile.sanctuary=state;profile.save_profile()
 var restored:=PlayerProfile.new(path);restored.load_profile()
 check(restored.sanctuary.residents[0].form_stage==2 and restored.sanctuary.residents[0].name=="Ruby","Permanent form and nickname survive save/reload")
 var old:=profile.to_dict();old.version=3
 for key in ["form_stage","love","care_time"]:old.sanctuary.residents[0].erase(key)
 var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(old));file.close()
 restored=PlayerProfile.new(path);restored.load_profile()
 check(not restored.save_blocked and restored.sanctuary.residents[0].form_stage==0,"Schema-three profiles migrate safely to schema four")
 var main: Node=load("res://scenes/main.tscn").instantiate();main.profile_path=path;root.add_child(main);await process_frame
 main.show_sanctuary();await process_frame
 var garden: SanctuaryGarden=main.sanctuary_scene
 qualify(garden.state.residents[0],0);garden.panel.refresh_status()
 check(not garden.panel.awaken_button.disabled,"The garden enables awakening when the resident is ready")
 check(garden.awaken_resident() and garden.actors[1].get_meta("form_stage")==1,"Awakening replaces the displayed 3D resident with the earned form")
 check(garden.panel.form_info.text.contains("Auroracrown"),"The sidebar shows the next form and its progress")
 garden.state.residents[0].happiness=0;garden.panel.refresh_status()
 check(garden.panel.awaken_button.disabled,"The awakening button blocks unmet requirements")
 main.queue_free();await process_frame;await process_frame
 for suffix in ["", ".bak", ".tmp"]:
  if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
 print("SANCTUARY FORMS TEST: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)

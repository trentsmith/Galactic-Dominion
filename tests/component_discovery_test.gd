extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1;print(("PASS: " if ok else "FAIL: ")+message)
 if not ok:failures+=1
func run() -> void:
 var counts:={"uncommon":0,"rare":0,"legendary":0,"mythic":0}
 for i in range(65536):counts[ComponentDiscovery.tier(i)]+=1
 check(counts.mythic==1 and counts.legendary==16 and counts.rare==3260 and counts.uncommon==62259,"All 65,536 tickets have the advertised disjoint rarity allocation")
 var rng:=RandomNumberGenerator.new();rng.seed=16
 check(CollectionCatalog.find(ComponentDiscovery.item_for_ticket(0,rng)).rarity=="mythic" and CollectionCatalog.find(ComponentDiscovery.item_for_ticket(16,rng)).rarity=="legendary","Extreme tickets select actual equippable relic definitions")
 var no_research:=true
 for tier in ["legendary","mythic"]:
  for id in ComponentDiscovery.POOLS[tier]:
   var d:=CollectionCatalog.find(id)
   no_research=no_research and d.discovery_only and d.research_cost==0 and d.kind=="component"
 check(no_research,"The six relics are exploration-only with no research bypass")
 var battle_pool_safe:=true
 for i in range(1000):battle_pool_safe=battle_pool_safe and not CollectionCatalog.roll(rng).discovery_only
 check(battle_pool_safe,"Ordinary battle rewards exclude exploration-only components")
 var path:="user://components-%d.json"%Time.get_ticks_usec()
 var blocked:=PlayerProfile.new(path+"-blocked");blocked.save_blocked=true
 check(not ComponentDiscovery.recover(blocked,"space",0).ok and blocked.component_discovery.total==0,"A cache cannot grant anything before its seed can be saved")
 var profile:=PlayerProfile.new(path);profile.load_profile()
 var first:=ComponentDiscovery.recover(profile,"space",0)
 check(first.ok and first.new and CollectionCatalog.find(first.id).rarity=="uncommon" and profile.owns(first.id),"The first recovery permanently unlocks an uncommon fitting part")
 check(profile.equip(0,"engine",first.id),"A recovered engine is immediately selectable in the hangar")
 var count_before:=profile.inventory.size();var total_before: int=profile.component_discovery.total
 check(not ComponentDiscovery.recover(profile,"space",0).ok and profile.inventory.size()==count_before and profile.component_discovery.total==total_before,"An opened cache cannot be claimed twice")
 var predicted:=ComponentDiscovery.reward(profile,"space",1)
 var before:=profile.to_dict();profile.save_blocked=true
 check(not ComponentDiscovery.recover(profile,"space",1).ok and profile.to_dict()==before,"Failed saving rolls back both the reward and opened-cache state")
 profile.save_blocked=false
 check(ComponentDiscovery.recover(profile,"space",1).id==predicted,"Retrying a failed recovery keeps the same predetermined reward")
 var restored:=PlayerProfile.new(path);restored.load_profile()
 check(restored.component_discovery==profile.component_discovery and restored.owns(first.id),"Cache progress, seed and component ownership survive reload")
 var expected:=ComponentDiscovery.reward(restored,"space",2)
 restored.acquire(expected);restored.save_profile();var salvage:=restored.salvage
 var duplicate:=ComponentDiscovery.recover(restored,"space",2)
 check(duplicate.ok and not duplicate.new and restored.salvage==salvage+15,"Duplicates grant exactly fifteen salvage without losing the blueprint")
 for i in range(3,12):ComponentDiscovery.recover(restored,"space",i)
 check(ComponentDiscovery.state(restored,"space").generation==1 and ComponentDiscovery.state(restored,"space").opened.is_empty(),"Clearing all twelve caches starts a fresh batch without unbounded claim records")
 check(ComponentDiscovery.recover(restored,"space",0).ok,"A fresh batch allows continued exploration and new rarity rolls")
 var extreme:=PlayerProfile.new(path+"-extreme");extreme.load_profile();extreme.component_discovery.total=1
 var chosen_seed:=0
 var offset:=int("space".hash())*65599
 for seed_value in range(1,1000000):
  rng.seed=seed_value+offset
  if rng.randi_range(0,65535)==0:chosen_seed=seed_value;break
 check(chosen_seed>0,"A deterministic test seed reaches the real mythic recovery path")
 extreme.component_discovery.seed=chosen_seed;extreme.save_profile()
 var mythic:=ComponentDiscovery.recover(extreme,"space",0)
 check(mythic.ok and CollectionCatalog.find(mythic.id).rarity=="mythic" and extreme.owns(mythic.id),"A real cache recovery can award and save a mythic component")
 var all_fit:=true
 for class_id in CollectionCatalog.SHIP_TYPES:
  extreme.acquire("ship_"+str(class_id));extreme.ship_classes[0]=class_id
  for slot in ["engine","shield","weapon","utility"]:
   var id: String={"engine":"engine_voidwake","shield":"shield_eclipse","weapon":"weapon_singularity","utility":"utility_wayfinder"}[slot]
   if not extreme.owns(id):extreme.acquire(id)
   all_fit=all_fit and extreme.equip(0,slot,id)
 check(all_fit,"Relic components fit all five ship classes through the normal equipment API")
 var model:=CombatShip.new();model.stats=extreme.configured_stats(0);root.add_child(model);model.set_physics_process(false)
 check(model.find_child("RelicDriveCoil*",true,false)!=null and model.find_child("RelicWeaponRail*",true,false)!=null,"Equipped relics produce visible drive and weapon attachments")
 model.queue_free();await process_frame
 var old:=profile.to_dict();old.version=6;old.erase("component_discovery")
 var file:=FileAccess.open(path+"-legacy",FileAccess.WRITE);file.store_string(JSON.stringify(old));file.close()
 var migrated:=PlayerProfile.new(path+"-legacy");migrated.load_profile()
 check(not migrated.save_blocked and migrated.owns(first.id) and ComponentDiscovery.prepare(migrated),"Schema 6 profiles migrate with their existing fittings intact")
 var bad:=ComponentDiscovery.sanitize({"seed":"bad","total":-5,"worlds":{"space":{"generation":-1,"opened":[0,0,99,"bad"]},"unknown":{}}})
 check(ComponentDiscovery.valid_seed(bad.seed) and bad.total==0 and bad.worlds.space.opened==[0] and not bad.worlds.has("unknown"),"Malformed discovery state is sanitized without invalid cache indexes")
 var host=load("res://scenes/main.tscn").instantiate();host.profile_path=path+"-world";root.add_child(host);await process_frame
 host.start_free_roam(true);await process_frame;await physics_frame;await physics_frame
 var caches: ComponentSalvage=host.battle.find_children("","ComponentSalvage",true,false)[0];caches.set_physics_process(false)
 host.battle.set_physics_process(false);host.battle.pilot.set_physics_process(false)
 for ship in host.battle.ships:ship.set_physics_process(false)
 check(caches.caches.size()==12,"Free Roam contains twelve actual recoverable salvage objects")
 var pilot: CombatShip=host.battle.pilot.ship;pilot.position=caches.caches[0].position+Vector3(0,0,100)
 caches.tick(2.1,true)
 check(host.profile.component_discovery.total==0,"Holding recovery out of range cannot consume a cache")
 pilot.position=caches.caches[0].position+Vector3(0,0,10)
 var wall:=StaticBody3D.new();wall.collision_layer=2;wall.position=caches.caches[0].position+Vector3(0,.5,5)
 var box:=BoxShape3D.new();box.size=Vector3(20,20,2);var collision:=CollisionShape3D.new();collision.shape=box;wall.add_child(collision);host.battle.add_child(wall)
 await physics_frame;await physics_frame;caches.tick(2.1,true)
 check(host.profile.component_discovery.total==0 and caches.message.contains("BLOCKED"),"A blocked recovery ray gives a clear refusal without consuming the cache")
 wall.queue_free();await physics_frame;await physics_frame;caches.tick(2.1,true)
 check(host.profile.component_discovery.total==1 and not caches.caches[0].visible,"Holding recovery in range performs the actual in-world unlock")
 host.start_planet(0);await process_frame;await physics_frame;await physics_frame
 var ground: ComponentSalvage=host.surface.find_children("","ComponentSalvage",true,false)[0];ground.set_physics_process(false)
 host.surface.set_physics_process(false);host.surface.bot.set_physics_process(false)
 for animal in host.surface.fauna:animal.set_physics_process(false)
 host.surface.bot.position=ground.caches[0].position+Vector3(0,0,2)
 await physics_frame;await physics_frame
 var prior: int=host.profile.component_discovery.total;host.profile.save_blocked=true;ground.tick(2.1,true)
 check(host.profile.component_discovery.total==prior and ground.caches[0].visible and ground.message.contains("NOT SAVED"),"A failed in-world save keeps the cache visible and the recovery retryable")
 host.profile.save_blocked=false;ground.tick(2.1,true)
 check(host.profile.component_discovery.total==prior+1 and ground.context=="varkhoss","Planet expeditions use the same saved recovery loop")
 host.queue_free();await process_frame;await process_frame
 print("COMPONENT_DISCOVERY_TEST: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)

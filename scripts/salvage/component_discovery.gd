class_name ComponentDiscovery
extends RefCounted
const WORLDS=["space","varkhoss","viridia","nyzaroth"]
const BATCH_SIZE:=12
const POOLS={
 "uncommon":["engine_sprint","shield_bulwark","utility_reserve","weapon_focus"],
 "rare":["engine_vector","shield_recovery","weapon_swarm","utility_relay","weapon_lance","shield_crystal"],
 "legendary":["engine_solarweave","shield_eclipse","weapon_starforged","utility_wayfinder"],
 "mythic":["engine_voidwake","weapon_singularity"]}
static func defaults() -> Dictionary:
 var random:=RandomNumberGenerator.new();random.randomize()
 return {"seed":random.randi_range(1,2147483646),"total":0,"worlds":{}}
static func valid_seed(value: Variant) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and int(value)>=1 and int(value)<=2147483646
static func sanitize(value: Variant) -> Dictionary:
 var result:=defaults()
 if not value is Dictionary:return result
 if valid_seed(value.get("seed")):result.seed=int(value.seed)
 if value.get("total") is int or value.get("total") is float:
  if is_finite(float(value.total)):result.total=clampi(int(value.total),0,99999999)
 if not value.get("worlds") is Dictionary:return result
 for id in WORLDS:
  var world: Variant=value.worlds.get(id)
  if not world is Dictionary:continue
  var generation:=0
  if (world.get("generation") is int or world.get("generation") is float) and is_finite(float(world.generation)):generation=clampi(int(world.generation),0,9999999)
  var opened: Array[int]=[]
  if world.get("opened") is Array:
   for index in world.opened:
    if index is int or index is float:
     if is_finite(float(index)) and int(index)>=0 and int(index)<BATCH_SIZE and not int(index) in opened:opened.append(int(index))
  if opened.size()>=BATCH_SIZE:generation=mini(9999999,generation+1);opened.clear()
  result.worlds[id]={"generation":generation,"opened":opened}
 return result
static func state(profile: PlayerProfile,context: String) -> Dictionary:
 return profile.component_discovery.worlds.get(context,{"generation":0,"opened":[]})
static func cache_seed(profile: PlayerProfile,context: String,index: int) -> int:
 return int(profile.component_discovery.seed)+int(context.hash())*65599+int(state(profile,context).generation)*15485863+index*961748941
static func tier(ticket: int) -> String:
 if ticket==0:return "mythic"
 if ticket<=16:return "legendary"
 if ticket<=3276:return "rare"
 return "uncommon"
static func item_for_ticket(ticket: int,random: RandomNumberGenerator) -> String:
 var pool: Array=POOLS[tier(ticket)]
 return pool[random.randi_range(0,pool.size()-1)]
static func prepare(profile: PlayerProfile) -> bool:
 return profile.component_seed_persisted or profile.save_profile()
static func reward(profile: PlayerProfile,context: String,index: int) -> String:
 if int(profile.component_discovery.total)==0:
  for id in POOLS.uncommon:
   if not profile.owns(id):return id
  return "engine_sprint"
 var random:=RandomNumberGenerator.new();random.seed=cache_seed(profile,context,index)
 return item_for_ticket(random.randi_range(0,65535),random)
static func recover(profile: PlayerProfile,context: String,index: int) -> Dictionary:
 if not context in WORLDS or index<0 or index>=BATCH_SIZE:return {"ok":false,"message":"Invalid salvage cache."}
 if not prepare(profile):return {"ok":false,"message":"RECOVERY NOT SAVED / "+profile.save_error+" / cache retained; retry K"}
 var world:=state(profile,context)
 if index in world.opened:return {"ok":false,"message":"Cache already recovered. Search for another beacon."}
 var before_state:=profile.component_discovery.duplicate(true)
 var before_inventory:=profile.inventory.duplicate(true)
 var before_records:=profile.exploration_records.duplicate(true)
 var before_salvage:=profile.salvage
 var id:=reward(profile,context,index)
 var result:=profile.acquire(id,"Salvage / "+context)
 var next:=world.duplicate(true);next.opened.append(index)
 if next.opened.size()>=BATCH_SIZE:next={"generation":int(next.generation)+1,"opened":[]}
 profile.component_discovery.worlds[context]=next
 profile.component_discovery.total+=1
 if result.new:profile.exploration_records["component."+id]={"name":CollectionCatalog.find(id).display_name,"discovered_at":int(Time.get_unix_time_from_system())}
 if not profile.save_profile():
  profile.component_discovery=before_state;profile.inventory=before_inventory;profile.exploration_records=before_records;profile.salvage=before_salvage
  return {"ok":false,"message":"RECOVERY NOT SAVED / "+profile.save_error+" / reward and cache unchanged; retry K"}
 profile.changed.emit()
 var item:=CollectionCatalog.find(id)
 return {"ok":true,"id":id,"new":result.new,"message":"%s COMPONENT / %s / %s"%[item.rarity.to_upper(),item.display_name,"PERMANENT UNLOCK · fit in Hangar" if result.new else "DUPLICATE · +15 salvage"]}
static func odds_text() -> String:
 return "First recovery: an uncommon part. Later caches: Legendary 1/4096 · Mythic 1/65536 (tier odds, independent per cache)."

class_name FrontierState
extends RefCounted
## Bounded local progression; online contract rewards live in the account service.
const FACTIONS={"frontier":"Frontier Council","crimson":"Crimson Dominion","pelagian":"Pelagian Concord","eldritch":"Eldritch Host"}
const ROLES=["striker","scout","guardian","engineer"]
const FACILITIES={"repair":{"name":"Repair dock","description":"Repairs fleet hulls outside combat in solo Free Roam (+0.6 hull/s per level)."},"observatory":{"name":"Observatory & collection gallery","description":"Extends salvage bearings and distress sensing; displays fitted ships at your home."},"workshop":{"name":"Fabrication workshop","description":"Craft permanent standard component blueprints using sanctuary materials."}}
const RECIPES={"engine_sprint":{"ore":4,"fiber":2},"shield_recovery":{"ore":5,"bloom":3},"utility_reserve":{"ore":3,"fiber":3}}
static func defaults() -> Dictionary:
 var rng:=RandomNumberGenerator.new();rng.randomize()
 return {"seed":rng.randi_range(1,2147483646),"generation":0,"done":[],"completed":0,"intel":0,"reputation":{"frontier":0,"crimson":0,"pelagian":0,"eldritch":0},"role":"striker","facilities":{"repair":0,"observatory":0,"workshop":0},"log":[]}
static func integer(value: Variant,low: int,high: int) -> int:
 return clampi(int(value),low,high) if (value is int or value is float) and is_finite(float(value)) else clampi(0,low,high)
static func sanitize(value: Variant) -> Dictionary:
 var result:=defaults()
 if not value is Dictionary:return result
 result.seed=integer(value.get("seed",result.seed),1,2147483646)
 for field in ["generation","completed","intel"]:result[field]=integer(value.get(field,0),0,999999)
 if value.get("done") is Array:
  for id in value.done:
   if (id is int or id is float) and int(id) in range(5) and not int(id) in result.done:result.done.append(int(id))
 if result.done.size()==5:result.generation+=1;result.done.clear()
 if value.get("reputation") is Dictionary:
  for faction in FACTIONS:result.reputation[faction]=integer(value.reputation.get(faction,0),-100,100)
 if value.get("role") in ROLES:result.role=value.role
 if value.get("facilities") is Dictionary:
  for id in FACILITIES:result.facilities[id]=integer(value.facilities.get(id,0),0,3)
 if value.get("log") is Array:
  for entry in value.log:
   if entry is String and result.log.size()<12:result.log.append(entry.left(180))
 return result
static func transaction(profile: PlayerProfile,change: Callable) -> bool:
 var before:=profile.frontier.duplicate(true);var inventory:=profile.inventory.duplicate(true);var sanctuary:=profile.sanctuary.duplicate(true);var salvage:=profile.salvage
 change.call()
 if not profile.save_profile():
  profile.frontier.clear();profile.frontier.merge(before,true);profile.inventory=inventory;profile.sanctuary.clear();profile.sanctuary.merge(sanctuary,true);profile.salvage=salvage
  return false
 profile.changed.emit();return true
static func pay(profile: PlayerProfile,generation: int,slot: int,faction: String,title: String,amount: int) -> bool:
 if not faction in FACTIONS or slot not in range(5) or generation!=int(profile.frontier.generation) or slot in profile.frontier.done:return false
 return transaction(profile,func():
  profile.salvage+=amount;profile.frontier.completed+=1;profile.frontier.intel=mini(999999,int(profile.frontier.intel)+1)
  profile.frontier.reputation[faction]=clampi(int(profile.frontier.reputation[faction])+8,-100,100)
  profile.frontier.done.append(slot);profile.frontier.log.push_front("%s / +%d salvage / %s +8"%[title,amount,FACTIONS[faction]])
  if profile.frontier.log.size()>12:profile.frontier.log.resize(12)
  if profile.frontier.done.size()==5:profile.frontier.generation+=1;profile.frontier.done.clear())
static func role(profile: PlayerProfile,id: String) -> bool:
 if not id in ROLES:return false
 return transaction(profile,func():profile.frontier.role=id)
static func build(profile: PlayerProfile,id: String) -> bool:
 if not FACILITIES.has(id) or int(profile.frontier.facilities[id])>=3:return false
 var cost:=50*(int(profile.frontier.facilities[id])+1)
 if profile.salvage<cost:return false
 return transaction(profile,func():profile.salvage-=cost;profile.frontier.facilities[id]+=1)
static func craft(profile: PlayerProfile,id: String) -> bool:
 if int(profile.frontier.facilities.workshop)<1 or not RECIPES.has(id) or profile.owns(id):return false
 for key in RECIPES[id]:
  if int(profile.sanctuary.materials.get(key,0))<int(RECIPES[id][key]):return false
 return transaction(profile,func():
  for key in RECIPES[id]:profile.sanctuary.materials[key]-=RECIPES[id][key]
  profile.acquire(id,"Frontier fabrication workshop"))
static func standing(points: int) -> String:
 return "ALLIED" if points>=24 else "TRUSTED" if points>=8 else "WANTED" if points<=-20 else "NEUTRAL"

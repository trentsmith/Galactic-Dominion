class_name JourneyState
extends RefCounted
## Optional personal progress. No online inventory or rare-drop odds are changed.
const GOALS={
 "pathfinder":{"title":"New horizons","help":"Visit three different space regions. J opens the star chart.","metric":"regions","need":3,"reward":35},
 "cartographer":{"title":"The seven wonders","help":"Survey all seven named landmarks: G within 100m.","metric":"landmarks","need":7,"reward":100},
 "prospector":{"title":"From stone to starlight","help":"Mine three resource veins, then use the materials at home.","metric":"mined","need":3,"reward":40},
 "collector":{"title":"Useful discoveries","help":"Recover four component caches. K at a gold beacon.","metric":"components","need":4,"reward":50},
 "naturalist":{"title":"Life among the stars","help":"Deliver surveys of three different creature species from planet expeditions.","metric":"fauna","need":3,"reward":40},
 "caretaker":{"title":"A place to belong","help":"House three different creature species in your sanctuary.","metric":"residents","need":3,"reward":50},
 "captain":{"title":"Answering the call","help":"Complete five optional Frontier jobs from O.","metric":"jobs","need":5,"reward":75},
 "builder":{"title":"A home worth returning to","help":"Construct a repair dock, observatory and workshop.","metric":"facilities","need":3,"reward":60}}
static func defaults() -> Dictionary:
 return {"claimed":[],"goal":"","waypoint":{},"bookmarks":[],"resume":{},"mining":{"generation":0,"opened":[],"total":0}}
static func number(value: Variant,low: float,high: float,fallback: float=0) -> float:
 return clampf(float(value),low,high) if (value is int or value is float) and is_finite(float(value)) else clampf(fallback,low,high)
static func coordinates(value: Variant) -> Array:
 if not value is Array or value.size()!=3:return []
 var result: Array=[]
 for axis in value:
  if not (axis is int or axis is float) or not is_finite(float(axis)):return []
  result.append(clampf(float(axis),-40000,40000))
 return result
static func vector(value: Array) -> Vector3:
 return Vector3(value[0],value[1],value[2]) if value.size()==3 else Vector3.ZERO
static func pack(value: Vector3) -> Array:return [value.x,value.y,value.z]
static func marker(value: Variant) -> Dictionary:
 if not value is Dictionary:return {}
 var position:=coordinates(value.get("at",[]))
 if position.is_empty():return {}
 return {"id":str(value.get("id","beacon")).left(80),"name":str(value.get("name","Personal beacon")).left(64),"at":position,"kind":str(value.get("kind","beacon")).left(24)}
static func sanitize(value: Variant) -> Dictionary:
 var result:=defaults()
 if not value is Dictionary:return result
 if value.get("claimed") is Array:
  for id in value.claimed:
   if id in GOALS and not id in result.claimed:result.claimed.append(id)
 if value.get("goal") in GOALS:result.goal=value.goal
 result.waypoint=marker(value.get("waypoint"))
 if value.get("bookmarks") is Array:
  var ids: Dictionary={}
  for bookmark in value.bookmarks:
   var entry:=marker(bookmark)
   if not entry.is_empty() and not ids.has(entry.id) and result.bookmarks.size()<12:result.bookmarks.append(entry);ids[entry.id]=true
 var mining: Variant=value.get("mining",{})
 if mining is Dictionary:
  result.mining.generation=int(number(mining.get("generation",0),0,999999))
  result.mining.total=int(number(mining.get("total",0),0,99999999))
  if mining.get("opened") is Array:
   for slot in mining.opened:
    if (slot is int or slot is float) and is_finite(float(slot)) and int(slot) in range(12) and not int(slot) in result.mining.opened:result.mining.opened.append(int(slot))
  if result.mining.opened.size()==12:result.mining.generation+=1;result.mining.opened.clear()
 var resume: Variant=value.get("resume",{})
 if resume is Dictionary and not resume.is_empty():
  result.resume={"region":int(number(resume.get("region",0),0,6)),"peaceful":resume.get("peaceful",false)==true,"saved_at":int(number(resume.get("saved_at",0),0,4102444800)),"job":sanitize_job(resume.get("job",{}))}
 return result
static func sanitize_job(value: Variant) -> Dictionary:
 if not value is Dictionary:return {}
 var data: Variant=value.get("active",{})
 if not data is Dictionary or not data.get("kind") in FrontierData.HELP or not data.get("faction") in FrontierState.FACTIONS:return {}
 var at:=coordinates(data.get("at",[]))
 if at.is_empty():return {}
 var active:={"kind":data.kind,"faction":data.faction,"at":at,"slot":int(number(data.get("slot",0),0,4)),"generation":int(number(data.get("generation",0),0,999999)),"region":int(number(data.get("region",0),0,6)),"title":str(data.get("title","Distress signal")).left(100),"id":str(data.get("id","")).left(80),"reward":0,"stage":"flight"}
 # Payouts come from the board slot, never from edited checkpoint text.
 active.reward=45+int(active.slot)*10
 for field in ["cache","cache_generation"]:
  if data.has(field):active[field]=int(number(data[field],0,11 if field=="cache" else 9999999))
 var result:={"active":active,"elapsed":number(value.get("elapsed",0),0,360),"progress":number(value.get("progress",0),0,4),"integrity":number(value.get("integrity",100),0,100,100),"escort":number(value.get("escort",0),0,1),"completed":value.get("completed",false)==true}
 if value.get("anchors") is Array and value.anchors.size()==3:result.anchors=value.anchors.map(func(hp):return number(hp,0,40,40))
 result.hull_ratio=number(value.get("hull_ratio",1),.01,1,1);result.shield_ratio=number(value.get("shield_ratio",1),0,1,1)
 return result
static func transaction(profile: PlayerProfile,change: Callable) -> bool:
 var before:=profile.journey.duplicate(true);var sanctuary:=profile.sanctuary.duplicate(true);var salvage:=profile.salvage
 change.call()
 if not profile.save_profile():
  profile.journey.clear();profile.journey.merge(before,true);profile.sanctuary.clear();profile.sanctuary.merge(sanctuary,true);profile.salvage=salvage;return false
 profile.changed.emit();return true
static func metrics(profile: PlayerProfile) -> Dictionary:
 var result:={"regions":0,"landmarks":0,"fauna":0,"residents":0,"facilities":0,"jobs":int(profile.frontier.completed),"components":int(profile.component_discovery.total),"mined":int(profile.journey.mining.total)}
 for key in profile.exploration_records:
  if str(key).begins_with("open.region.") and str(key).split(".").size()==3:result.regions+=1
  if str(key).begins_with("open.landmark."):result.landmarks+=1
  if str(key).begins_with("surface.") and ".fauna." in str(key):result.fauna+=1
 var species: Dictionary={}
 for resident in profile.sanctuary.residents:species[resident.species]=true
 result.residents=species.size()
 for id in FrontierState.FACILITIES:
  if int(profile.frontier.facilities[id])>0:result.facilities+=1
 return result
static func claim(profile: PlayerProfile,id: String) -> bool:
 if not GOALS.has(id) or id in profile.journey.claimed:return false
 var goal: Dictionary=GOALS[id]
 if int(metrics(profile)[goal.metric])<int(goal.need):return false
 return transaction(profile,func():profile.journey.claimed.append(id);profile.salvage+=int(goal.reward))
static func pin(profile: PlayerProfile,id: String) -> bool:
 if not id.is_empty() and not id in GOALS:return false
 return transaction(profile,func():profile.journey.goal=id)
static func set_waypoint(profile: PlayerProfile,value: Dictionary) -> bool:
 var clean:=marker(value)
 if not value.is_empty() and clean.is_empty():return false
 return transaction(profile,func():profile.journey.waypoint=clean)
static func bookmark(profile: PlayerProfile,at: Vector3,title: String) -> bool:
 if profile.journey.bookmarks.size()>=12 or not at.is_finite():return false
 var entry:=marker({"id":"beacon-%d"%Time.get_ticks_usec(),"name":title,"kind":"beacon","at":pack(at)})
 return transaction(profile,func():profile.journey.bookmarks.append(entry);profile.journey.waypoint=entry.duplicate(true))
static func remove_bookmark(profile: PlayerProfile,id: String) -> bool:
 var index:=-1
 for i in range(profile.journey.bookmarks.size()):
  if profile.journey.bookmarks[i].id==id:index=i;break
 if index<0:return false
 return transaction(profile,func():
  profile.journey.bookmarks.remove_at(index)
  if profile.journey.waypoint.get("id","")==id:profile.journey.waypoint={})

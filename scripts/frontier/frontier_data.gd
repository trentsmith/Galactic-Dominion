class_name FrontierData
extends RefCounted
const PATRONS=["frontier","crimson","pelagian","eldritch","pelagian","crimson","eldritch"]
const TYPES=["rescue","repair","escort","wreck","rumor"]
const TITLES={"rescue":["A light still burning","Escape pod in the belt","The missing surveyor"],"repair":["Dead engines, live crew","The quiet relay","A courier without power"],"escort":["One freighter, one chance","The long way home","Convoy under interference"],"wreck":["The sealed cargo hold","A ship without a registry","Black-box recovery"],"rumor":["The archivist's bearing","A miner's unfinished map","Resonance in the salvage field"],"boss":["Bloodforged siege captain","The carrier in the ash field","A warship with three hearts"]}
const HELP={"rescue":"Hold F within 90m of the pod for three seconds. The rescued crew transmit a payment receipt immediately.","repair":"Hold F within 90m for four seconds to repair the disabled ship. Stay clear of its ion discharge.","escort":"Stay within 150m to guide the courier to its beacon. Hostiles inside 110m jam and damage it; clear them before the hull fails.","wreck":"Approach within 100m outside combat and press F to board. Explore with your bot, restore power, recover the black box, then E at the airlock returns to your ship.","rumor":"Follow the recovered bearing to an actual component cache. Recover it with K. Rumors preserve the original component rarity odds; they do not guarantee a rare part.","boss":"Destroy the three exposed amber hardpoints to remove 80% damage reduction, then defeat the siege ship. The guns accelerate once its anchors fail."}
static func offers(profile: PlayerProfile,peaceful: bool=false) -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 var rng:=RandomNumberGenerator.new();rng.seed=int(profile.frontier.seed)+int(profile.frontier.generation)*7919
 for slot in range(5):
  var region:=rng.randi_range(0,6)
  if slot==0 and int(profile.frontier.completed)==0:region=0
  var kind: String=TYPES[slot]
  if slot==2 and not peaceful and int(profile.frontier.completed)>=3:kind="boss"
  var title: String=TITLES[kind][rng.randi_range(0,2)]
  var offset:=Vector3(rng.randf_range(-650,650),rng.randf_range(-120,180),rng.randf_range(-650,650))
  if slot==0 and int(profile.frontier.completed)==0:offset=Vector3(-260,45,-300)
  result.append({"generation":int(profile.frontier.generation),"slot":slot,"id":"%d:%d"%[profile.frontier.generation,slot],"kind":kind,"region":region,"title":title,"faction":PATRONS[region],"at":FreeRoamWorld.CENTERS[region]+offset,"reward":45+slot*10})
 return result

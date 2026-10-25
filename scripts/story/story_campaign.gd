class_name StoryCampaign
extends RefCounted
const TITLES := ["Answer Astra's signal","Discover Varkhoss Prime","Rescue a new creature","Debrief with Warden Sera","Upgrade your lead ship","Break the Crimson blockade","Return to Astra","The Lantern Signal complete"]
const HINTS := [
 "Open Comms and agree to investigate the Lantern Signal. Two capture pods are supplied once.",
 "Fly to the gold Varkhoss landing waypoint, then press L to land. O resumes the same flight. Your loaner Pixlet is available even without collectible crew.",
 "T tracks wildlife. Hold G within 12m to scan; weaken dangerous fauna to half health. C within 8m captures; E at the ship delivers to sanctuary.",
 "Speak with Sera about your rescue and accept her reserved engine-parts kit.",
 "Ask Milo to craft a Sprint Drive using the kit, then fit it to F1. An existing Sprint Drive also counts. +15% speed / -6% hull.",
 "Defeat the Crimson Interdiction Patrol in a dedicated 3v3 encounter. It uses at least Standard AI; Veteran stays Veteran. Defeat allows a retry.",
 "The relay is safe. Speak with Astra to archive the signal and claim the chapter reward once.",
 "The next signal points toward Pelagia and Ny'Zaroth. Continue exploring; this opening chapter is complete."
]
const RECIPES := {"engine_sprint":{"ore":4,"fiber":2,"bloom":1},"shield_recovery":{"ore":5,"bloom":3},"utility_reserve":{"ore":3,"fiber":3}}
static func defaults() -> Dictionary:
 return {"accepted":false,"visited":[],"rescued":false,"debriefed":false,"kit":false,"interdiction_won":false,"complete":false}
static func sanitize(value: Variant) -> Dictionary:
 var result:=defaults()
 if not value is Dictionary:return result
 for key in ["accepted","rescued","debriefed","kit","interdiction_won","complete"]:
  result[key]=value.get(key,false) if value.get(key,false) is bool else false
 if value.get("visited") is Array:
  for id in value.visited:
   if id in ["varkhoss","viridia","nyzaroth"] and not id in result.visited:result.visited.append(id)
 return result
static func stage(profile: PlayerProfile) -> int:
 var state: Dictionary=profile.story
 if state.complete:return 7
 if not state.accepted:return 0
 if not "varkhoss" in state.visited:return 1
 if not state.rescued:return 2
 if not state.debriefed:return 3
 if state.interdiction_won:return 6
 if not profile.owns("engine_sprint") or profile.loadouts[0].engine!="engine_sprint":return 4
 if not state.interdiction_won:return 5
 if not state.complete:return 6
 return 7
static func transaction(profile: PlayerProfile,change: Callable) -> bool:
 var state: Dictionary=profile.story.duplicate(true)
 var sanctuary: Dictionary=profile.sanctuary.duplicate(true)
 var inventory: Dictionary=profile.inventory.duplicate(true)
 var loadouts: Array=profile.loadouts.duplicate(true)
 var records: Dictionary=profile.exploration_records.duplicate(true)
 var salvage: int=profile.salvage
 change.call()
 if not profile.save_profile():
  profile.story.clear();profile.story.merge(state,true)
  profile.sanctuary.clear();profile.sanctuary.merge(sanctuary,true)
  profile.inventory=inventory;profile.loadouts.assign(loadouts);profile.exploration_records=records;profile.salvage=salvage
  profile.story_message="STORY NOT SAVED / "+profile.save_error+" / progress and costs unchanged; retry"
  return false
 profile.story_message="Progress saved."
 profile.changed.emit()
 return true
static func accept(profile: PlayerProfile) -> bool:
 if profile.story.accepted:profile.story_message="The mission is already active. Check the next objective.";return false
 return transaction(profile,func():
  profile.story.accepted=true
  profile.sanctuary.materials.capture_pod=mini(999,int(profile.sanctuary.materials.capture_pod)+2)
  # Existing verified discoveries count, but the starter sanctuary pet is not a rescue.
  for id in profile.exploration_records:
   if str(id).begins_with("surface.varkhoss.") and not "varkhoss" in profile.story.visited:profile.story.visited.append("varkhoss"))
static func visit(profile: PlayerProfile,id: String) -> bool:
 if not profile.story.accepted or id in profile.story.visited:return false
 return transaction(profile,func():profile.story.visited.append(id))
static func debrief(profile: PlayerProfile) -> bool:
 if stage(profile)!=3:profile.story_message="First deliver a newly captured creature at the landing ship.";return false
 return transaction(profile,func():profile.story.debriefed=true;profile.story.kit=true)
static func craft(profile: PlayerProfile,id: String) -> bool:
 if not RECIPES.has(id):profile.story_message="Milo has no recipe for that component.";return false
 if profile.owns(id):profile.story_message="Blueprint already owned. Fit it in the hangar; no materials spent.";return false
 var kit: bool=id=="engine_sprint" and profile.story.kit
 var recipe: Dictionary=RECIPES[id]
 if not kit:
  for material in recipe:
   if int(profile.sanctuary.materials.get(material,0))<int(recipe[material]):
    profile.story_message="NEED MATERIALS / "+recipe_text(id)+". Produce or craft supplies in your sanctuary; Sera reserves a kit for the story engine.";return false
 return transaction(profile,func():
  if kit:profile.story.kit=false
  else:
   for material in recipe:profile.sanctuary.materials[material]-=recipe[material]
  profile.acquire(id,"Milo's workshop"))
static func fit_engine(profile: PlayerProfile) -> bool:
 if not profile.owns("engine_sprint"):profile.story_message="Craft or research a Sprint Drive first.";return false
 return transaction(profile,func():profile.loadouts[0].engine="engine_sprint";profile.story.kit=false)
static func victory(profile: PlayerProfile) -> bool:
 if stage(profile)!=5:return false
 return transaction(profile,func():profile.story.interdiction_won=true)
static func complete(profile: PlayerProfile) -> bool:
 if stage(profile)!=6:profile.story_message="Finish the current objective before the final debrief.";return false
 return transaction(profile,func():
  profile.story.complete=true;profile.salvage+=75
  profile.exploration_records["story.lantern_signal"]={"name":"Nexus Archives / The Lantern Signal","discovered_at":int(Time.get_unix_time_from_system())})
static func recipe_text(id: String) -> String:
 var parts: PackedStringArray=[]
 for material in RECIPES[id]:parts.append("%d %s"%[RECIPES[id][material],material])
 return " + ".join(parts)
static func dialogue(npc: String,topic: String,progress: int) -> String:
 if topic=="lore":
  match npc:
   "astra":return "The Nexus Archives are fragments, not a complete map. One fragment calls itself the Lantern Signal. It crossed a sealed Crimson relay from Varkhoss Prime—and it knew your bot's name. We investigate carefully. A signal can be a plea, a warning, or bait."
   "sera":return "Varkhoss is more than the Dominion's factories. Life still shelters beneath its crimson forests. We rescue what we can and build habitats suited to each species. A frightened animal is not an enemy to conquer. Scan, subdue only when necessary, then bring it home."
   _:return "Crimson Overdrive burns defensive power for speed and force. Our Sprint Drive is a modest, serviceable alternative: faster flight and acceleration, at the cost of some hull reinforcement. Eldritch engines are different. Some of them seem to dream before their pilots do."
 if topic=="help":
  match npc:
   "astra":return "O opens this journal. Follow the highlighted objective; it updates from actual visits, deliveries, fittings and the named encounter. You can explore freely between objectives. Comms pause solo play, but never pause an online server."
   "sera":return "Hold G for two seconds within twelve metres. Dangerous fauna must reach half health; your bot's LMB pulse is non-lethal. Capture with C inside eight metres, then deliver with E at the ship. Secured cargo survives redeployment. In sanctuary, feed, pet and play; assign a suitable habitat for production."
   _:return "A crafted component is a permanent blueprint you can fit to compatible fleet ships. Recipes consume sanctuary materials once. Sera's reserved kit pays for your first story Sprint Drive so you cannot spend those mission parts on another building. Fit it to F1 before taking on the patrol."
 match npc:
  "astra":return ["Commander, this is Astra. A Crimson relay is broadcasting a signal the Dominion wants buried. Help us find out why. I have authorized two capture pods for the expedition.","Varkhoss Prime is our first lead. Take Pixlet down to the frontier; keep your ship's departure route open.","Study the wildlife before you act. Sera believes the signal is changing how these creatures respond to our bots.","Your transport is safe. Let Sera examine what you brought home.","Milo needs a faster lead ship to slip through the relay's closing defense pattern.","The Crimson Interdiction Patrol has found our relay. This is a full fleet fight, not a survey. Upgrade first and expect at least Standard resistance.","The patrol is gone. The relay transmitted one final phrase: 'Return what you remember.' I will preserve it in the Archives. Archive this lead and I will release 75 salvage for your next expedition.","The archive points toward Pelagia's deep reefs, then Ny'Zaroth. We have an opening, not an answer. Keep your companions safe."][clampi(progress,0,7)]
  "sera":
   if progress>=4:return "Your rescue has a home here. Keep exploring, and care for its habitat. Milo can help you prepare the fleet."
   return "You are building a refuge, not a trophy room. "+("Your new rescue is safe. I have reserved an engine-parts kit with Milo; take it before your next sortie." if progress>=3 else "Bring a newly captured creature to sanctuary through the landing ship. Ruby, our starter resident, still needs care too.")
  _:
   if progress>=5:return "The Sprint Drive is fitted. Watch your hull: speed trades some reinforcement. The workshop stays open for your next upgrade."
   return "Milo here. "+("Sera's kit is ready for the workshop. Craft the Sprint Drive, then fit it to your first ship. We need that speed for the relay approach." if progress>=4 else "Bring your first rescue home and speak with Sera. Until then, I can explain our component recipes.")

class_name ShipCampaign
extends RefCounted
## Independent chapter: never overwrites the archived creature campaign.
const TITLES=["Answer the Nexus distress call","Break the Crimson blockade","Recover a component cache","Refit your lead ship","Investigate the Dreaming Abyss","Seal the warfront","Debrief with Astra","The Fractured Relay complete"]
const HINTS=["Speak with Commander Astra and accept a fleet commission.","Launch the 3v3 Crimson Interdiction fight. Defeat all three warships; a loss can be retried.","Enter solo Free Roam. Follow a gold COMPONENT SALVAGE bearing, approach within 60m and hold K for two seconds. Recover one cache after accepting this commission.","Open Fleet Hangar and fit any non-standard engine to F1. The blockade supplied a permanent Sprint Drive: +15% speed with a hull tradeoff. Fittings apply on launch.","Launch a 3v3 encounter at Ny'Zaroth. Defeat the fast, regenerating Eldritch ships and preserve the relay telemetry.","Launch the 10v10 Rift Warfront. Hold the line against a mixed Crimson/Eldritch fleet. The last fleet standing wins.","Return to Commander Astra to archive the Nexus transmission and claim 100 salvage once.","The relay is secure. Explore, recover rare components, customize your fleet or choose an Armada matchup."]
const MISSIONS={1:"nexus_blockade",4:"nexus_abyss",5:"nexus_warfront"}
static func defaults() -> Dictionary:
 return {"accepted":false,"crimson":false,"eldritch":false,"rift":false,"complete":false,"cache_baseline":0}
static func sanitize(value: Variant) -> Dictionary:
 var result:=defaults()
 if value is Dictionary:
  for key in ["accepted","crimson","eldritch","rift","complete"]:result[key]=value.get(key,false) if value.get(key) is bool else false
  var baseline: Variant=value.get("cache_baseline",0)
  if (baseline is int or baseline is float) and is_finite(float(baseline)):result.cache_baseline=clampi(int(baseline),0,99999999)
 return result
static func stage(profile: PlayerProfile) -> int:
 var state: Dictionary=profile.ship_story
 if state.complete:return 7
 if not state.accepted:return 0
 if not state.crimson:return 1
 if int(profile.component_discovery.total)<=int(state.cache_baseline):return 2
 if str(profile.loadouts[0].engine) in ["","engine_standard"]:return 3
 if not state.eldritch:return 4
 if not state.rift:return 5
 return 6
static func transaction(profile: PlayerProfile,change: Callable) -> bool:
 var previous: Dictionary=profile.ship_story.duplicate(true)
 var inventory: Dictionary=profile.inventory.duplicate(true)
 var records: Dictionary=profile.exploration_records.duplicate(true)
 var salvage: int=profile.salvage
 change.call()
 if not profile.save_profile():
  profile.ship_story=previous;profile.inventory=inventory;profile.exploration_records=records;profile.salvage=salvage
  profile.story_message="COMMISSION NOT SAVED / no rewards consumed; fix saving and retry. "+profile.save_error
  return false
 profile.story_message="Commission progress saved.";profile.changed.emit();return true
static func accept(profile: PlayerProfile) -> bool:
 if stage(profile)!=0:return false
 return transaction(profile,func():profile.ship_story.accepted=true;profile.ship_story.cache_baseline=int(profile.component_discovery.total))
static func victory(profile: PlayerProfile,mission: String) -> bool:
 var current:=stage(profile)
 if str(MISSIONS.get(current,""))!=mission:return false
 return transaction(profile,func():
  if current==1:
   profile.ship_story.crimson=true;profile.acquire("engine_sprint","Crimson blockade commission");profile.acquire("variant_nexus_crimson","Nexus Archives / Varkhoss Prime")
  elif current==4:profile.ship_story.eldritch=true;profile.acquire("variant_nexus_eldritch","Nexus Archives / Ny'Zaroth")
  elif current==5:profile.ship_story.rift=true)
static func complete(profile: PlayerProfile) -> bool:
 if stage(profile)!=6:return false
 return transaction(profile,func():
  profile.ship_story.complete=true;profile.salvage+=100
  profile.exploration_records["story.fractured_relay"]={"name":"Nexus Archives / The Fractured Relay","discovered_at":int(Time.get_unix_time_from_system())})
static func dialogue(npc: String,topic: String,step: int) -> String:
 if topic=="lore":
  if npc=="astra":return "The Crimson Dominion built its empire on conquest. Varkhoss Prime burns beneath volcanic mountains, crimson oceans and vast shipyards. Its Bloodforged fleets now cross a gateway they cannot control. Peace is an illusion, their warlords say. We intend to prove them wrong."
  if npc=="sera":return "Ny'Zaroth is the Dreaming Abyss. Its islands drift through dark energy; its living ships regenerate and respond to thought. A Dominion expedition returned with its hull transformed into tissue. We must preserve the telemetry before the war consumes the relay."
  return "Crimson vessels favor heavy armor and aggressive firepower. Eldritch vessels trade defenses for mobility and regeneration. Each class keeps its own ability. Faction hulls and fitted components let you build a recognizable fleet without losing your chosen role."
 if topic=="help":return "O opens comms. Launch the highlighted encounter, recover salvage with K, then refit in Fleet Hangar. M launches missiles after a target lock; R uses your class ability. F1–F3 switch ships; 1–5 issue fleet orders. Defeat does not complete a commission. The journal never pauses an online server."
 if npc=="milo":return "The blockade pays a permanent Sprint Drive schematic. Fit it to F1 in Fleet Hangar before launching again. Gold salvage caches can unlock more parts; duplicates become salvage. Legendary and mythic relics are exploration-only."
 if npc=="sera":return "I am Sera, your Nexus archivist for this operation. We will record Varkhoss Prime and Ny'Zaroth through their ships, transmissions and battles. The old biological expedition records remain sealed and safe."
 return ["Commander, the Nexus relay is trapped between a Bloodforged fleet and a dimensional fracture. Accept this commission and lead three ships through the Crimson blockade.","The Interdictors are armored, aggressive and slower to turn. Keep the fleet together and use missiles after a lock. Break their blockade to recover an engine schematic.","The wrecks point to scattered component caches. Recover one in free space. We need reliable equipment before following the signal beyond the gateway.","Milo has issued the Sprint Drive. Fit an upgraded engine to your lead ship; the next enemy moves faster than the Interdictors.","The relay opens onto Ny'Zaroth. Living vessels have followed its transmission. Their hulls mend quickly but their shields are fragile. Focus your fleet's fire.","Crimson forces have crossed the fracture. Ten ships on each side now contest the relay. Mixed enemy formations will test every role in your fleet.","The warfront has fallen silent. The transmission says: 'Beyond the stars, something ancient remembers your existence.' Archive the signal. Your fleet has earned 100 salvage.","The Fractured Relay is archived. The Crimson-Eldritch War continues beyond this sector. Prepare your fleet and choose your next engagement."][clampi(step,0,7)]

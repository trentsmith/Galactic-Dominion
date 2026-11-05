class_name ShipCampaign
extends RefCounted
## Independent of the preserved biological campaign. Replays never repay commissions.
const TITLES=["Answer the Lantern Network","Lanterns over Varkhoss","Find Mnemosyne's trail","Give the fleet a way home","The ship that came home","A door, not a weapon","Debrief / what we carry home","The Fractured Relay complete"]
const HINTS=["Speak with Astra. Accept a commission to save the frontier's evacuation relay.","Defeat three Crimson Interdictors, then hold G for three seconds within 95m of the civilian relay. Keep its integrity above zero.","Enter solo Free Roam. Follow a gold COMPONENT SALVAGE bearing. Hold K for two seconds within 60m to recover a cache after accepting the commission.","Milo traced the lost ship's engine signature. In Fleet Hangar, fit any non-standard engine to F1. Your recovered Sprint Drive is already owned; fittings apply on launch.","Defeat Mnemosyne's three wardens. Avoid the telegraphed anomaly, then hold G for four seconds within 95m of the returned vessel to decode its memory.","Choose SEAL or PRESERVE in the briefing. Complete that protocol and defeat the mixed enemy fleet in a 10v10 warfront. Launching locks this chapter's choice.","Read the sortie debrief and speak with Astra to archive the transmission. The one-time chapter reward is 100 salvage.","Your ending and sortie records are in this journal. Completed encounters can be replayed; commission unlocks and the chapter payout are not granted again."]
const MISSIONS={1:"nexus_blockade",4:"nexus_abyss",5:"nexus_warfront"}
const REPLAY_FLAGS={"nexus_blockade":"crimson","nexus_abyss":"eldritch","nexus_warfront":"rift"}
static func defaults() -> Dictionary:
 return {"accepted":false,"crimson":false,"eldritch":false,"rift":false,"complete":false,"cache_baseline":0,"decision":"","ending":"","decision_locked":false,"reports":{},"honors":[]}
static func sanitize_report(value: Variant) -> Dictionary:
 if not value is Dictionary:return {}
 var result:={"success":value.get("success")==true,"allies":0,"integrity":100.0,"seconds":0,"choice":"","heard":[]}
 for key in ["allies","seconds","integrity"]:
  var number: Variant=value.get(key,0)
  if (number is int or number is float) and is_finite(float(number)):result[key]=clampf(float(number),0,10 if key=="allies" else 100 if key=="integrity" else 480)
 if value.get("choice") in ["seal","preserve"]:result.choice=value.choice
 if value.get("heard") is Array:
  for id in value.heard:
   if id in NexusStoryData.RADIO and not id in result.heard:result.heard.append(id)
 return result
static func merge_report(previous: Dictionary,value: Dictionary) -> Dictionary:
 var result:=sanitize_report(value)
 for id in previous.get("heard",[]):
  if id in NexusStoryData.RADIO and not id in result.heard:result.heard.append(id)
 return result
static func sanitize(value: Variant) -> Dictionary:
 var result:=defaults()
 if not value is Dictionary:return result
 for key in ["accepted","crimson","eldritch","rift","complete","decision_locked"]:result[key]=value.get(key,false) if value.get(key) is bool else false
 var baseline: Variant=value.get("cache_baseline",0)
 if (baseline is int or baseline is float) and is_finite(float(baseline)):result.cache_baseline=clampi(int(baseline),0,99999999)
 if value.get("decision") in ["seal","preserve"]:result.decision=value.decision
 if value.get("ending") in ["seal","preserve"]:result.ending=value.ending
 if result.decision.is_empty():result.decision_locked=false
 if value.get("reports") is Dictionary:
  for id in REPLAY_FLAGS:
   var report:=sanitize_report(value.reports.get(id))
   if not report.is_empty():result.reports[id]=report
 if value.get("honors") is Array and "lantern_keeper" in value.honors:result.honors=["lantern_keeper"]
 return result
static func stage(profile: PlayerProfile) -> int:
 var state: Dictionary=profile.ship_story
 if state.complete:return 7
 if not state.accepted:return 0
 if state.rift:return 6
 if state.eldritch:return 5
 if not state.crimson:return 1
 if int(profile.component_discovery.total)<=int(state.cache_baseline):return 2
 if str(profile.loadouts[0].engine) in ["","engine_standard"]:return 3
 return 4
static func transaction(profile: PlayerProfile,change: Callable) -> bool:
 var previous: Dictionary=profile.ship_story.duplicate(true)
 var inventory: Dictionary=profile.inventory.duplicate(true)
 var records: Dictionary=profile.exploration_records.duplicate(true)
 var salvage: int=profile.salvage
 change.call()
 if not profile.save_profile():
  profile.ship_story=previous;profile.inventory=inventory;profile.exploration_records=records;profile.salvage=salvage
  profile.story_message="COMMISSION NOT SAVED / progress and rewards restored; fix saving and retry. "+profile.save_error
  return false
 profile.story_message="Commission progress saved.";profile.changed.emit();return true
static func accept(profile: PlayerProfile) -> bool:
 if stage(profile)!=0:return false
 return transaction(profile,func():profile.ship_story.accepted=true;profile.ship_story.cache_baseline=int(profile.component_discovery.total))
static func choose(profile: PlayerProfile,decision: String) -> bool:
 if stage(profile) not in [5,7] or not decision in ["seal","preserve"] or profile.ship_story.decision_locked:return false
 return transaction(profile,func():profile.ship_story.decision=decision)
static func lock_decision(profile: PlayerProfile) -> bool:
 if not profile.ship_story.decision in ["seal","preserve"]:profile.story_message="Choose a fracture protocol before launching.";return false
 if profile.ship_story.decision_locked:return true
 return transaction(profile,func():profile.ship_story.decision_locked=true)
static func can_replay(profile: PlayerProfile,mission: String) -> bool:
 return REPLAY_FLAGS.has(mission) and bool(profile.ship_story[REPLAY_FLAGS[mission]])
static func resolve(profile: PlayerProfile,mission: String,report: Dictionary,replay: bool=false) -> bool:
 var current:=stage(profile)
 if replay:
  if not can_replay(profile,mission):return false
 elif str(MISSIONS.get(current,""))!=mission:return false
 return transaction(profile,func():
  if not report.is_empty():profile.ship_story.reports[mission]=merge_report(profile.ship_story.reports.get(mission,{}),report)
  if not replay:
   profile.ship_story[REPLAY_FLAGS[mission]]=true
   if current==1:
    profile.acquire("engine_sprint","Lantern Network / civilian relay");profile.acquire("variant_nexus_crimson","Nexus Archives / Varkhoss Prime")
   elif current==4:profile.acquire("variant_nexus_eldritch","Nexus Archives / Mnemosyne")
  if mission=="nexus_warfront" and report.get("choice") in ["seal","preserve"]:profile.ship_story.ending=report.choice
  if mission=="nexus_blockade" and float(report.get("integrity",0))>=70 and not "lantern_keeper" in profile.ship_story.honors:
   profile.ship_story.honors.append("lantern_keeper");profile.salvage+=25)
static func victory(profile: PlayerProfile,mission: String) -> bool:
 return resolve(profile,mission,{})
static func record_failure(profile: PlayerProfile,mission: String,report: Dictionary) -> bool:
 if not REPLAY_FLAGS.has(mission):return false
 return transaction(profile,func():profile.ship_story.reports[mission]=merge_report(profile.ship_story.reports.get(mission,{}),report))
static func complete(profile: PlayerProfile) -> bool:
 if stage(profile)!=6:return false
 return transaction(profile,func():
  profile.ship_story.complete=true;profile.salvage+=100
  profile.exploration_records["story.fractured_relay"]={"name":"Nexus Archives / The Fractured Relay","discovered_at":int(Time.get_unix_time_from_system())})
static func dialogue(npc: String,topic: String,step: int) -> String:
 if topic=="lore":return str(NexusStoryData.character(npc).bio)
 if topic=="help":return "O opens comms. M fires a missile after target lock; R uses your class ability. F1–F3 switch ships; 1–5 give fleet orders. G interfaces with marked mission objects, K recovers space salvage. Sorties last at most eight minutes. A defeat or failed save can be retried. Online servers do not pause for this journal."
 var lines: Array
 match npc:
  "sera":lines=["The new signal carries a navigation mark from Mnemosyne. The Dominion lost that ship inside a gateway. My brother was aboard. I am asking for evidence, Commander—not a miracle.","Veyr calls the relay contaminated. Its manifests belong to living people. Whatever Mnemosyne became, those families deserve a route out.","Milo found a clock offset in the Interdictors' command link. Eleven minutes. Ilyan complained about that clock in his last message. Recover a cache; the engine logs may tell us why it is still running.","An upgraded engine gives us an exit if Ny'Zaroth changes the rules. Please fit it before we go. Hope is a poor replacement for a departure plan.","If the voice says my name, do not stop recording. I can want my brother back and still need to know what is speaking.","The Choir has his memories. That does not tell us whether it is him. Seal the passage and we protect the frontier. Preserve the core and we accept a duty to watch it. I will stand with either decision, if we make it honestly.","I have kept the raw recording, including the pauses. History has a habit of cutting away the parts where people were afraid. We should leave those in.","There are names we can speak again. Some belong to the living. Some may not. I intend to keep listening without pretending the difference is easy."]
  "milo":lines=["A relay full of refugee routes, a fleet full of red guns. At least this problem has parts I recognize. Bring the ships home; I will handle what still bolts together.","Those Interdictors dump heat into their jamming masts. Clear them before the relay buffer runs out. Once they are down, get close and hold G. A victory screen cannot send a manifest.","Their command link had an engine pattern older than their hulls. Gold salvage beacons carry the matching parts. Get within sixty metres and hold K; I need something I can put on a bench.","Your Sprint Drive schematic is ready. Fleet Hangar, lead ship, ENGINE. It buys speed with a little hull reinforcement. I design exits before entrances.","That wreck is drawing breath without an atmosphere. The pulse is readable, though: a warning, then a discharge. Leave the marked field when it brightens.","Seal needs three short conduit handshakes. Preserve needs you near the moving core and enemy jammers far away. Both need an intact fleet. Pick the promise you are willing to maintain.","I named the replacement drive Hearth. No, it does not get another damage bonus. Some things can mean something without being better at killing.","The fleet is repaired. The route is recorded. For once, the empty chair in the workshop means someone made it home."]
  _:lines=["The Lantern Network is losing an evacuation relay above Varkhoss Prime. Marshal Veyr wants its memory erased. Accept this commission. We save the routes first; then we find out why he fears a missing ship.","Veyr can argue his case after the civilians have a way out. Defeat his three Interdictors, then transmit the manifests from the gold relay. Keep its integrity above zero.","The routes are safe. The engine signature is not. Follow the salvage trail in Free Roam; I will keep the patrols away while Milo identifies what came back.","Milo's engine is our way home from the Abyss. Fit it to your lead ship. I will not order another expedition through that gateway without an exit.","I signed Mnemosyne's expedition order. I told Sera the command files were lost. They were sealed by my authority. We go in to recover the truth, including what I did.","Veyr has a fleet in the breach. He intends to erase the relay and everyone who knows what it recorded. Choose our fracture protocol. I will command the line; you decide what we carry across it.","The battle is over. The account of it is not mine to edit. Archive the transmission with every name and every order intact. The frontier deserves the truth we were afraid to give it.","The Lantern Network is transmitting again. The war continues beyond this sector. What changes now is that the record belongs to the people who lived it."]
 return str(lines[clampi(step,0,7)])

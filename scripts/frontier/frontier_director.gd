class_name FrontierDirector
extends Node3D
## Optional repeatable jobs; local authority or a trusted online host drives them.
signal shared_completed(event_id,kind,contributors)
signal boarding_requested
var battle: FreeRoamMatch
var profile: PlayerProfile
var cooperative:=false
var offers: Array[Dictionary]=[]
var active: Dictionary={}
var point: Node3D
var goal: Node3D
var boss: BossWeakpoints
var enemy: CombatShip
var hint: Label
var message:=""
var message_time:=0.0
var serial:=0
var progress:=0.0
var integrity:=100.0
var escort:=0.0
var elapsed:=0.0
var completed:=false
var credited:=false
var contributors: Array[int]=[]
var requests: Dictionary={}
var retired: Dictionary={}
var timer:=0.0
var pending_shared:=""
var intercepted: Dictionary={}
func _ready() -> void:
 if battle.network_role=="offline":
  profile=battle.profile
  if profile!=null:
   profile.save_profile();refresh_offers();apply_reputation()
   var ending: String=profile.ship_story.ending
   if ending in ["seal","preserve"]:
    NexusMissionArt.beacon(self,Vector3(240,60,-160),"Relay reconstruction tender" if ending=="seal" else "Contained memory echo / Frontier watch", "JumpBeacon" if ending=="seal" else "MemoryVessel")
 if battle.network_role!="server":
  var layer:=CanvasLayer.new();layer.layer=7;add_child(layer)
  hint=Label.new();hint.position=Vector2(390,265);hint.custom_minimum_size.x=500;hint.size=Vector2(500,100);hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;hint.add_theme_font_size_override("font_size",15);hint.add_theme_color_override("font_outline_color",Color(.01,.02,.03));hint.add_theme_constant_override("outline_size",4);layer.add_child(hint)
func refresh_offers() -> void:
 if profile!=null:offers=FrontierData.offers(profile,battle.peaceful)
func accept(slot: int) -> bool:
 if battle.network_role=="client" or not active.is_empty():return false
 refresh_offers()
 if slot not in range(offers.size()) or slot in profile.frontier.done:return false
 var offer: Dictionary=offers[slot]
 if offer.kind=="rumor" and int(profile.frontier.intel)<1 and int(profile.frontier.facilities.observatory)<1:message="Recover one distress job or build an observatory to decode this rumor.";message_time=5;return false
 if not profile.save_profile():message="JOB NOT STARTED / "+profile.save_error;message_time=5;return false
 start(offer);return true
func start_shared(kind: String,pilot: CombatShip=null) -> bool:
 if battle.network_role!="server" or not cooperative or not active.is_empty() or not kind in ["rescue","repair","escort"]:return false
 serial+=1
 var at: Vector3=(pilot if pilot!=null else battle.ships[0]).position+Vector3(-240,25,-220)
 start({"kind":kind,"id":"shared-%d"%serial,"generation":serial,"slot":0,"title":FrontierData.TITLES[kind][serial%3],"faction":"frontier","region":FreeRoamWorld.nearest_region(at),"at":at,"reward":50})
 return true
func start(data: Dictionary) -> void:
 active=data.duplicate(true);progress=0;integrity=100;escort=0;elapsed=0;completed=false;credited=false;contributors.clear();requests.clear();pending_shared=""
 if active.kind=="rumor":
  for child in battle.get_children():
   if child is ComponentSalvage:
    for i in range(child.caches.size()):
     if child.caches[i].visible:
      active.at=child.caches[i].global_position;active.cache=i;active.cache_generation=ComponentDiscovery.state(profile,"space").generation;break
 point=NexusMissionArt.beacon(self,active.at,active.title,"ArchiveCore" if active.kind=="rescue" else "MemoryVessel" if active.kind=="wreck" else "RelayConduit")
 if active.kind=="escort":goal=NexusMissionArt.beacon(self,active.at+Vector3(0,0,300),"COURIER JUMP BEACON","JumpBeacon")
 if active.kind in ["rescue","repair","escort","wreck"]:call_deferred("place_clear")
 if active.kind=="boss":
  var group: Dictionary=battle.encounters[int(active.region)%battle.encounters.size()]
  enemy=group.ships[0];enemy.redeploy(active.at);enemy.team=2;enemy.callsign="Crimson Siege Captain";enemy.set_meta("frontier_enemy",active.id)
  boss=BossWeakpoints.new();boss.ship=enemy;enemy.add_child(boss)
  enemy.health.max_hull*=2;enemy.health.hull=enemy.health.max_hull
  point.hide()
 message="DISTRESS ACCEPTED / "+str(active.title);message_time=7
func cancel() -> bool:
 if battle.network_role=="client" or not pending_shared.is_empty() or active.get("stage","")=="boarding":return false
 clear_actors();active.clear();message="Job abandoned / no reward claimed";message_time=4;return true
func clear_actors() -> void:
 if is_instance_valid(point):point.queue_free()
 if is_instance_valid(goal):goal.queue_free()
 if is_instance_valid(boss):
  boss.dispose()
 point=null;goal=null;boss=null;enemy=null
func place_clear() -> void:
 if not is_inside_tree() or battle.network_role=="client" or not is_instance_valid(point):return
 var probe:=PhysicsShapeQueryParameters3D.new();var shape:=SphereShape3D.new();shape.radius=14;probe.shape=shape;probe.collision_mask=2
 for attempt in range(20):
  probe.transform=Transform3D(Basis.IDENTITY,point.global_position)
  if get_world_3d().direct_space_state.intersect_shape(probe,1).is_empty():break
  point.position.y+=35
 active.at=point.position
 if is_instance_valid(goal):goal.position=point.position+Vector3(0,0,300)
func request_use(index: int) -> void:
 if battle.network_role!="server" or index not in range(6) or not battle.ships[index].alive:return
 requests[index]=.4
func _physics_process(delta: float) -> void:
 if battle.network_role!="client":tick(delta,Input.is_action_pressed("frontier_use") and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED)
 update_hint(delta)
func participants() -> Array[CombatShip]:
 var result: Array[CombatShip]=[]
 if battle.network_role=="server":
  for i in range(mini(6,battle.ships.size())):
   if battle.ships[i].player_controlled and battle.ships[i].alive:result.append(battle.ships[i])
 elif is_instance_valid(battle.pilot.ship) and battle.pilot.ship.alive:result.append(battle.pilot.ship)
 return result
func tick(delta: float,held: bool) -> void:
 timer-=delta
 if timer<=0:
  timer=.5
  if profile!=null:
   apply_reputation();wanted_interception()
   var repair:=float(profile.frontier.facilities.repair)*.6
   if profile.ship_story.ending=="seal" and battle.pilot.ship.position.distance_to(Vector3(240,60,-160))<500:repair+=.6
   for ship in battle.fleet.ships:
    if ship.alive and ship.health.regen_delay<=0:ship.health.hull=minf(ship.health.max_hull,ship.health.hull+repair*.5)
 for index in requests.keys():
  requests[index]-=delta
  if requests[index]<=0:requests.erase(index)
 if active.is_empty() or active.get("stage","")=="boarding":return
 if credited:return
 if completed:finish_reward();return
 elapsed+=delta
 if elapsed>=360 or integrity<=0:
  message="DISTRESS LOST / window expired or courier destroyed. Accept another job.";message_time=8;clear_actors();active.clear();return
 var people:=participants()
 var near: CombatShip
 var any_using:=false
 var at: Vector3=point.position
 if active.kind=="boss":
  if not is_instance_valid(enemy) or not enemy.alive:completed=true
 elif active.kind=="rumor":
  var state:=ComponentDiscovery.state(profile,"space")
  completed=int(state.generation)>int(active.cache_generation) or (int(state.generation)==int(active.cache_generation) and int(active.cache) in state.opened)
 elif active.kind=="escort":
  var jammers:=0
  for ship in battle.ships:
   if ship.alive and ship.team>1 and ship.position.distance_to(at)<110:jammers+=1
  integrity=maxf(0,integrity-jammers*.6*delta)
  for ship in people:
   if ship.position.distance_to(at)<=150:
    near=ship
    if not battle.ships.find(ship) in contributors:contributors.append(battle.ships.find(ship))
  if near!=null and jammers==0:escort=minf(1,escort+delta/30)
  point.position=(active.at as Vector3).lerp(goal.position,escort)
  completed=escort>=1
 elif active.kind=="wreck":
  if held and can_board():active.stage="boarding";boarding_requested.emit();return
 else:
  for ship in people:
   if ship.position.distance_to(at)<=90 and clear_path(ship,at):
    near=ship
    var index:=battle.ships.find(ship)
    if held or requests.has(index):
     any_using=true
     if not index in contributors:contributors.append(index)
  progress=progress+delta if any_using else 0
  completed=progress>=(4 if active.kind=="repair" else 3)
 if completed:finish_reward()
func clear_path(ship: CombatShip,at: Vector3) -> bool:
 return battle.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ship.global_position,at,2)).is_empty()
func can_board() -> bool:
 return battle.network_role=="offline" and active.get("kind","")=="wreck" and is_instance_valid(point) and battle.pilot.ship.alive and battle.pilot.ship.position.distance_to(point.position)<100 and battle.safe_to_service(battle.pilot.ship)
func return_boarding(success: bool) -> void:
 if active.get("stage","")!="boarding":return
 active.stage="flight"
 if success:completed=true;finish_reward()
 else:message="Wreck attempt ended / approach again to redeploy your bot";message_time=7
func finish_reward() -> void:
 if active.is_empty() or credited:return
 if battle.network_role=="server":
  if pending_shared.is_empty():
   pending_shared=active.id
   for ship in participants():
    if ship.position.distance_to(point.position)<1000 and not battle.ships.find(ship) in contributors:contributors.append(battle.ships.find(ship))
   shared_completed.emit(active.id,active.kind,contributors.duplicate())
  return
 if FrontierState.pay(profile,int(active.generation),int(active.slot),str(active.faction),str(active.title),int(active.reward)):
  credited=true;message="JOB COMPLETE / +%d salvage / %s +8 standing"%[active.reward,FrontierState.FACTIONS[active.faction]];message_time=10
  clear_actors();active.clear();refresh_offers()
 else:message="REWARD NOT SAVED / keep flying; reward will retry. "+profile.save_error;message_time=5
func shared_saved(ok: bool) -> void:
 if ok:credited=true;clear_actors();active.clear();pending_shared="";message="CO-OP JOB COMPLETE / individual rewards saved online";message_time=8
 else:pending_shared="";message="ONLINE REWARD PENDING / host will retry safely";message_time=5
func apply_reputation() -> void:
 if profile==null or battle.network_role!="offline":return
 for group in battle.encounters:
  var faction: String=FrontierData.PATRONS[int(group.region)]
  var allied:=int(profile.frontier.reputation[faction])>=24
  for ship in group.ships:
   if ship.has_meta("frontier_enemy") or not ship.alive:continue
   var original: int=FreeRoamWorld.FACTIONS[int(group.region)]
   var wanted_team:=0 if allied or battle.peaceful else original
   if ship.team!=wanted_team:ship.team=wanted_team;ship.targeting.select(null)
func update_hint(delta: float) -> void:
 if hint==null:return
 message_time=maxf(0,message_time-delta);hint.visible=not battle.scenic_hud and not battle.map_panel.visible
 if message_time>0:hint.text=message
 elif active.is_empty():hint.text="FRONTIER / O: jobs, rumors, bot protocols and reputation"
 else:
  var at: Vector3=enemy.position if active.kind=="boss" and is_instance_valid(enemy) else point.position if is_instance_valid(point) else active.at
  var distance:=int(battle.pilot.ship.position.distance_to(at))
  hint.text="%s / %s / %dm\n"%[active.title,FreeRoamWorld.NAMES[int(active.region)],distance]
  var offset: Vector3=battle.camera.global_basis.inverse()*(at-battle.pilot.ship.position).normalized()
  hint.text+=("BEHIND" if offset.z>0 else "LEFT" if offset.x<-.2 else "RIGHT" if offset.x>.2 else "AHEAD")+(" / ABOVE" if offset.y>.3 else " / BELOW" if offset.y<-.3 else "")+" · "
  match str(active.kind):
   "escort":hint.text+="Stay within 150m / clear 110m jammers · %d%% · hull %d%%"%[int(escort*100),int(integrity)]
   "boss":hint.text+="Exposed anchors: %d / then defeat the siege ship"%(boss.remaining() if is_instance_valid(boss) else 0)
   "rumor":hint.text+="K / recover the marked component cache (original rarity odds)"
   "wreck":hint.text+="F / board within 100m outside combat"
   _:hint.text+="Hold F within 90m · %d%%"%int(progress/(4 if active.kind=="repair" else 3)*100)
  if completed:hint.text+="\nREWARD SAVE PENDING / retrying"
func snapshot() -> Dictionary:
 var value:=active.duplicate(true)
 if value.has("at"):value.at=[value.at.x,value.at.y,value.at.z]
 return {"active":value,"position":[point.position.x,point.position.y,point.position.z] if is_instance_valid(point) else [],"goal":[goal.position.x,goal.position.y,goal.position.z] if is_instance_valid(goal) else [],"progress":progress,"integrity":integrity,"escort":escort,"completed":completed,"message":message if message_time>0 else ""}
func apply_snapshot(data: Dictionary) -> void:
 if battle.network_role!="client":return
 var received: Dictionary=data.get("active",{}).duplicate(true)
 if received.is_empty():
  if not active.is_empty():clear_actors();active.clear()
  message=str(data.get("message",""));message_time=1;return
 var coordinates: Array=received.get("at",[0,0,0]);received.at=Vector3(coordinates[0],coordinates[1],coordinates[2])
 if active.get("id","")!=received.get("id",""):clear_actors();start(received)
 progress=float(data.get("progress",0));integrity=float(data.get("integrity",100));escort=float(data.get("escort",0));completed=bool(data.get("completed",false))
 var position_now: Array=data.get("position",[])
 if position_now.size()==3:point.position=Vector3(position_now[0],position_now[1],position_now[2])
 if is_instance_valid(goal):
  var destination: Array=data.get("goal",[])
  if destination.size()==3:goal.position=Vector3(destination[0],destination[1],destination[2])
func record_destruction(victim: CombatShip,attacker: CombatShip) -> void:
 if profile==null or not is_instance_valid(attacker) or not attacker in battle.fleet.ships:return
 for group in battle.encounters:
  if not victim in group.ships:continue
  var faction: String=FrontierData.PATRONS[int(group.region)]
  if not FrontierState.transaction(profile,func():profile.frontier.reputation[faction]=maxi(-100,int(profile.frontier.reputation[faction])-4)):
   message="Standing change could not save. "+profile.save_error;message_time=5
  return
func wanted_interception() -> void:
 if profile==null or battle.peaceful or not is_instance_valid(battle.pilot.ship):return
 var region:=FreeRoamWorld.nearest_region(battle.pilot.ship.position)
 var faction: String=FrontierData.PATRONS[region]
 if intercepted.has(region) or int(profile.frontier.reputation[faction])>-20:return
 intercepted[region]=true
 for group in battle.encounters:
  if int(group.region)!=region:continue
  var i:=0
  for patrol in group.ships:
   if not patrol.alive or patrol.has_meta("frontier_enemy"):continue
   patrol.position=battle.pilot.ship.position+Vector3(700+i*45,100,100);patrol.velocity=Vector3.ZERO
   patrol.brain.roam_center=battle.pilot.ship.position;patrol.brain.command="attack";patrol.targeting.select(battle.pilot.ship);i+=1
  message="WANTED / "+FrontierState.FACTIONS[faction]+" interception group inbound";message_time=8

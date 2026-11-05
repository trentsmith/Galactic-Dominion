class_name NexusMissionDirector
extends Node3D
## Local authored objectives. Does not alter generic fleet or network rules.
var battle: BattleMatch
var mission:=""
var choice:="seal"
var integrity:=100.0
var scan_progress:=0.0
var active_scan:=-1
var completed_points: Array[int]=[]
var escort_progress:=0.0
var actors: Array[Node3D]=[]
var points: Array[Vector3]=[]
var goal: Node3D
var comms: NexusComms
var layer: CanvasLayer
var status: Label
var health_bar: ProgressBar
var anomaly: MeshInstance3D
var hazard_clock:=0.0
var hazard_warned:=false
var low_warned:=false
var clear_announced:=false
var settled:=false
var placement_pending:=true
var message:=""
var message_time:=0.0
var archive_start:=Vector3(0,0,-120)
var archive_end:=Vector3(0,0,260)
func _ready() -> void:
 mission=battle.story_mission
 var data: Dictionary=NexusStoryData.MISSIONS[mission]
 if battle.profile!=null and battle.profile.ship_story.decision in ["seal","preserve"]:choice=battle.profile.ship_story.decision
 layer=CanvasLayer.new();layer.layer=6;add_child(layer)
 var panel:=PanelContainer.new();panel.position=Vector2(24,174);panel.custom_minimum_size.x=320;panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(panel)
 var box:=VBoxContainer.new();panel.add_child(box)
 var title:=Label.new();title.text=data.title;title.add_theme_font_size_override("font_size",15);title.add_theme_color_override("font_color",Color(1,.8,.4));box.add_child(title)
 status=Label.new();status.custom_minimum_size.x=310;status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.add_theme_font_size_override("font_size",14);box.add_child(status)
 health_bar=ProgressBar.new();health_bar.custom_minimum_size=Vector2(310,14);health_bar.show_percentage=false;box.add_child(health_bar)
 comms=NexusComms.new();comms.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP);comms.position=Vector2(-250,112);comms.custom_minimum_size=Vector2(500,95);layer.add_child(comms)
 if mission=="nexus_blockade":
  points=[Vector3(0,5,0)];comms.enqueue("b_start");comms.enqueue("b_veyr")
 elif mission=="nexus_abyss":
  points=[Vector3(0,15,0)];comms.enqueue("a_start");comms.enqueue("a_choir")
  var mesh:=TorusMesh.new();mesh.inner_radius=108;mesh.outer_radius=110;mesh.rings=96;mesh.ring_segments=6
  anomaly=SpaceModelFactory.mesh(self,mesh,Vector3.ZERO,Color(.48,.2,.85),"AnomalyBoundary",true);anomaly.rotation.x=PI/2
  for axis in [0,1]:
   var ring:=SpaceModelFactory.mesh(anomaly,mesh,Vector3.ZERO,Color(.48,.2,.85),"AnomalyLatitude",true);ring.rotation=Vector3(PI/2 if axis==0 else 0,0,PI/2 if axis==1 else 0);ring.material_override=anomaly.material_override
 else:
  points.assign([Vector3(-170,35,10),Vector3(170,-35,30),Vector3(0,100,-150)] if choice=="seal" else [archive_start])
  comms.enqueue("w_start");comms.enqueue("w_veyr");comms.enqueue("w_"+choice)
 for i in range(points.size()):
  var kind: String="MemoryVessel" if mission=="nexus_abyss" else "ArchiveCore" if mission=="nexus_warfront" and choice=="preserve" else "RelayConduit"
  actors.append(NexusMissionArt.beacon(self,points[i],str(data.object) if points.size()==1 else "PHASE CONDUIT %d / HOLD G"%(i+1),kind))
 if mission=="nexus_warfront" and choice=="preserve":
  goal=NexusMissionArt.beacon(self,archive_end,"ARCHIVE JUMP BEACON","JumpBeacon")
 var foes: Array=battle.ships.filter(func(s):return s.team==1)
 if not foes.is_empty():
  foes[-1].callsign="Marshal Veyr / Iron Testament" if mission!="nexus_abyss" else "Mnemosyne / Last Warden"
  foes[-1].health.max_hull*=1.15;foes[-1].health.hull=foes[-1].health.max_hull
 refresh_status()
func _physics_process(delta: float) -> void:
 tick(delta,Input.is_action_pressed("scan") and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED)
func place_clear() -> void:
 var query:=PhysicsShapeQueryParameters3D.new();var shape:=SphereShape3D.new();shape.radius=26;query.shape=shape;query.collision_mask=2
 for i in range(actors.size()):
  for attempt in range(16):
   query.transform=Transform3D(Basis.IDENTITY,actors[i].global_position)
   if get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():break
   actors[i].position=points[i]+Vector3(0,(attempt+1)*18,0)
  points[i]=actors[i].position
 if mission=="nexus_warfront" and choice=="preserve":archive_start=points[0]
 if anomaly!=null:anomaly.position=points[0]
func tick(delta: float,scan_held: bool) -> void:
 if battle.finished:return
 if placement_pending:placement_pending=false;place_clear()
 var actor:=battle.pilot.ship
 if not is_instance_valid(actor) or not actor.alive:return
 message_time=maxf(0,message_time-delta)
 var enemies:=battle.living(1)
 if mission=="nexus_blockade":
  var jammers:=nearby_foes(points[0],220)
  integrity=maxf(0,integrity-jammers*.16*delta)
  if battle.elapsed>=12:comms.enqueue("b_milo")
  if enemies==0:scan(delta,scan_held,3.0)
 elif mission=="nexus_abyss":
  hazard_clock+=delta
  var phase:=fmod(hazard_clock,26.0)
  var warning:=phase>=20 and phase<24
  var field_color:=Color(1,.35,.25) if warning else Color(.4,.2,.7)
  anomaly.material_override.albedo_color=field_color;anomaly.material_override.emission=field_color
  if warning:comms.enqueue("a_warning")
  if phase>=24 and hazard_clock>24 and not hazard_warned:
   hazard_warned=true
   for ship in battle.ships:
    if ship.alive and ship.position.distance_to(points[0])<110:ship.health.damage(12,null,"memory discharge")
  if phase<20:hazard_warned=false
  if enemies==0:scan(delta,scan_held,4.0)
 elif choice=="seal":scan(delta,scan_held,2.0)
 else:
  var position_now:=archive_start.lerp(archive_end,escort_progress)
  var jammers:=nearby_foes(position_now,110)
  integrity=maxf(0,integrity-jammers*.6*delta)
  if jammers==0 and actor.position.distance_to(position_now)<=150:escort_progress=minf(1,escort_progress+delta/35.0)
  actors[0].position=archive_start.lerp(archive_end,escort_progress)
  points[0]=actors[0].position
 if integrity<=0:battle.finish(1,"Civilian relay erased" if mission=="nexus_blockade" else "Archive core destroyed");return
 if integrity<35 and not low_warned:
  low_warned=true;comms.enqueue("b_milo" if mission=="nexus_blockade" else "w_low")
 if enemies==0 and not clear_announced:
  clear_announced=true;comms.enqueue("b_clear" if mission=="nexus_blockade" else "a_clear" if mission=="nexus_abyss" else "w_clear")
 check_end();refresh_status()
func nearby_foes(at: Vector3,distance: float) -> int:
 var count:=0
 for ship in battle.ships:
  if ship.team==1 and ship.alive and ship.position.distance_to(at)<distance:count+=1
 return count
func scan(delta: float,held: bool,duration: float) -> void:
 var index:=-1;var distance:=INF
 for i in range(points.size()):
  if i in completed_points:continue
  var next: float=battle.pilot.ship.position.distance_to(points[i])
  if next<distance:distance=next;index=i
 if index!=active_scan:active_scan=index;scan_progress=0
 if index<0:return
 if not held or distance>95:scan_progress=0;return
 var query:=PhysicsRayQueryParameters3D.create(battle.pilot.ship.global_position,global_position+points[index],2)
 if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
  scan_progress=0;message="SIGNAL BLOCKED / move around the obstacle";message_time=1;return
 scan_progress+=delta
 if scan_progress>=duration:
  completed_points.append(index);scan_progress=0
  for halo in actors[index].find_children("ObjectiveHalo*","MeshInstance3D",true,false):halo.hide()
  for label in actors[index].find_children("*","Label3D",true,false):label.text="CONDUIT OFFLINE" if mission=="nexus_warfront" else "TRANSMISSION COMPLETE"
  SpaceEffects.burst(self,points[index],Color(.4,1,.75),5);SpaceAudio.play("shield")
func objectives_complete() -> bool:
 if mission=="nexus_warfront" and choice=="preserve":return escort_progress>=1 and integrity>0
 return completed_points.size()==points.size() and integrity>0
func check_end() -> void:
 if battle.finished:return
 if battle.living(0)==0:battle.finish(1,"Vanguard fleet lost");return
 if battle.living(1)==0 and objectives_complete():
  settled=true
  # Include the decisive transmission in the persistent debrief even if combat
  # ended before its radio queue had time to display it.
  comms.enqueue("b_done" if mission=="nexus_blockade" else "a_done" if mission=="nexus_abyss" else "w_done_"+choice)
  if mission=="nexus_abyss":comms.enqueue("a_astra")
  battle.finish(0,"Civilian routes transmitted" if mission=="nexus_blockade" else "Mnemosyne memory decoded" if mission=="nexus_abyss" else "Breach sealed" if choice=="seal" else "Archive core evacuated")
func timeout() -> void:
 battle.finish(1,"Relay window expired / eight-minute sortie limit")
func report(success: bool) -> Dictionary:
 var heard: Array=comms.history.duplicate()
 # The final decoded recordings are delivered in the results/journal.
 if success:
  var ending: String="b_done" if mission=="nexus_blockade" else "a_done" if mission=="nexus_abyss" else "w_done_"+choice
  if not ending in heard:heard.append(ending)
  if mission=="nexus_abyss" and not "a_astra" in heard:heard.append("a_astra")
 return {"success":success,"allies":battle.living(0),"integrity":integrity,"seconds":int(battle.elapsed),"choice":choice if mission=="nexus_warfront" else "","heard":heard}
func waypoint() -> Dictionary:
 if battle.finished:return {}
 var index:=0
 if not (mission=="nexus_warfront" and choice=="preserve"):
  index=-1
  for i in range(points.size()):
   if i in completed_points:continue
   if index<0 or battle.pilot.ship.position.distance_squared_to(points[i])<battle.pilot.ship.position.distance_squared_to(points[index]):index=i
 if index<0:return {}
 return {"at":global_position+points[index],"from":battle.pilot.ship.position,"camera":battle.camera,"text":"ESCORT / WITHIN 150m" if mission=="nexus_warfront" and choice=="preserve" else "MISSION SIGNAL / HOLD G WITHIN 95m"}
func refresh_status() -> void:
 var enemies:=battle.living(1)
 if mission=="nexus_warfront" and choice=="preserve":status.text="PRESERVE / core %d%% · integrity %d%%\nStay within 150m · clear 110m jammers\nHostiles remaining: %d"%[int(escort_progress*100),int(integrity),enemies]
 else:
  var task: String="Transmit routes" if mission=="nexus_blockade" else "Decode memory" if mission=="nexus_abyss" else "SEAL / conduits %d / 3"%completed_points.size()
  var duration:=3.0 if mission=="nexus_blockade" else 4.0 if mission=="nexus_abyss" else 2.0
  status.text=task+" / HOLD G · %d%%\n"%int(scan_progress/duration*100)+("Clear remaining hostiles: %d"%enemies if enemies>0 and mission!="nexus_warfront" else "Approach marked signal within 95m")
  if mission=="nexus_warfront":
   if objectives_complete():status.text="SEAL / all conduits offline"
   status.text+="\nHostiles remaining: %d"%enemies
  if mission=="nexus_blockade":status.text+="\nRelay integrity: %d%%"%int(integrity)
  if mission=="nexus_abyss" and fmod(hazard_clock,26.0)>=20 and fmod(hazard_clock,26.0)<24:status.text+="\nDISCHARGE WARNING / leave the 110m ring"
 if message_time>0:status.text+="\n"+message
 health_bar.value=integrity;health_bar.visible=mission!="nexus_abyss";layer.visible=not battle.finished

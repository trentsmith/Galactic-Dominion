class_name NavigationBeacon
extends Node3D
var battle: FreeRoamMatch
var transient: Dictionary={}
var marker: Node3D
var label: Label3D
var hint: Label
var goals: Label
var clock:=0.0
func _ready() -> void:
 marker=Node3D.new();add_child(marker)
 SpaceModelFactory.ring(marker,Vector3.ZERO,12,.35,Color(.45,1,.8),"PersonalRoute",true)
 label=Label3D.new();label.position.y=20;label.pixel_size=.04;label.font_size=28;label.no_depth_test=true;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;marker.add_child(label);marker.hide()
 if battle.network_role=="server":set_process(false);return
 var layer:=CanvasLayer.new();layer.layer=7;add_child(layer)
 hint=make_label(layer,Vector2(390,175),15);goals=make_label(layer,Vector2(390,625),13)
func make_label(parent: Node,at: Vector2,font_size: int) -> Label:
 var item:=Label.new();item.position=at;item.size=Vector2(500,65);item.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;item.add_theme_font_size_override("font_size",font_size);item.add_theme_constant_override("outline_size",5);parent.add_child(item);return item
func route() -> Dictionary:
 return battle.profile.journey.waypoint if battle.profile!=null and battle.network_role=="offline" else transient
func set_route(value: Dictionary) -> bool:
 if battle.network_role=="offline" and battle.profile!=null:return JourneyState.set_waypoint(battle.profile,value)
 transient=JourneyState.marker(value);return true
func _process(delta: float) -> void:
 clock-=delta
 if clock>0:return
 clock=.15
 var visible_hud:=not battle.scenic_hud and not battle.map_panel.visible
 hint.visible=visible_hud;goals.visible=visible_hud;marker.visible=visible_hud and not route().is_empty()
 var target:=route()
 if target.is_empty():hint.text=""
 elif is_instance_valid(battle.pilot.ship):
  var at:=JourneyState.vector(target.at)
  if target.id=="active-job" and not battle.frontier.active.is_empty():at=battle.frontier.enemy.position if is_instance_valid(battle.frontier.enemy) else battle.frontier.point.position
  marker.position=at;var ship:=battle.pilot.ship;var offset:=at-ship.position;var distance:=offset.length();var local:=battle.camera.global_basis.inverse()*offset.normalized()
  var bearing: String="BEHIND" if local.z>0 else "LEFT" if local.x<-.2 else "RIGHT" if local.x>.2 else "AHEAD"
  bearing+=" / ABOVE" if local.y>.3 else " / BELOW" if local.y<-.3 else ""
  var closing:=ship.velocity.dot(offset.normalized())
  var eta: String="ETA %ds"%int(distance/closing) if closing>1 else "TURN TOWARD YOUR COURSE"
  var arrived:=distance<(180 if target.kind=="station" else 100 if target.kind=="landmark" else 75)
  label.text=str(target.name)+" / %dm"%int(distance)
  var interactions: Dictionary={"station":"G: service at station","landmark":"G: survey the landmark","mineral":"Laser: fracture · hold F: collect cracked seam","salvage":"Hold K: recover components","job":"Follow the active job instructions","fauna":"L: land outside combat · T: track the species","beacon":"Personal destination reached"}
  hint.text="COURSE / %s / %dm\n%s · %s"%[target.name,int(distance),bearing,str(interactions.get(target.kind,"Destination reached")) if arrived else eta]
 goals.text=""
 if battle.profile!=null and battle.network_role=="offline":
  var id: String=battle.profile.journey.goal
  if JourneyState.GOALS.has(id):
   var goal: Dictionary=JourneyState.GOALS[id];var progress:=mini(int(JourneyState.metrics(battle.profile)[goal.metric]),int(goal.need))
   goals.text="OPTIONAL / %s · %d/%d · O: Journey\n%s"%[goal.title,progress,goal.need,"READY TO CLAIM" if progress>=int(goal.need) else goal.help]

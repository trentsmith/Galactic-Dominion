class_name ComponentSalvage
extends Node3D
## Reusable local-world recovery actor. K avoids scan/capture/landing bindings.
var profile: PlayerProfile
var host: Node3D
var context:="space"
var ground:=false
var caches: Array[Node3D]=[]
var labels: Array[Label3D]=[]
var generation:=-1
var progress:=0.0
var active:=-1
var message:=""
var message_time:=0.0
var hint: Label
func is_local() -> bool:
 return (ground and host is PlanetExpedition) or (not ground and host is FreeRoamMatch and host.network_role=="offline")
func _ready() -> void:
 if not is_local():set_physics_process(false);return
 ComponentDiscovery.prepare(profile)
 var layer:=CanvasLayer.new();layer.layer=5;add_child(layer)
 hint=Label.new();hint.mouse_filter=Control.MOUSE_FILTER_IGNORE;hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT);hint.position=Vector2(390,-250);hint.custom_minimum_size.x=500;hint.size=Vector2(500,100);hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;hint.add_theme_font_size_override("font_size",15);hint.add_theme_color_override("font_color",Color(1,.82,.5));hint.add_theme_color_override("font_outline_color",Color(.01,.015,.025));hint.add_theme_constant_override("outline_size",4);layer.add_child(hint)
 refresh()
func refresh() -> void:
 for cache in caches:remove_child(cache);cache.queue_free()
 caches.clear();labels.clear();generation=int(ComponentDiscovery.state(profile,context).generation)
 for i in range(ComponentDiscovery.BATCH_SIZE):
  var random:=RandomNumberGenerator.new();random.seed=ComponentDiscovery.cache_seed(profile,context,i)+1000
  var cache:=Node3D.new();cache.name="ComponentCache%d"%i;add_child(cache);caches.append(cache)
  if ground:
   var angle:=random.randf()*TAU;var distance:=random.randf_range(22,115)
   cache.position=Vector3(cos(angle)*distance,0,sin(angle)*distance)
   if i==0:cache.position=Vector3(16,0,-12)
   cache.position.y=SurfaceWorld.height_at(cache.position.x,cache.position.z)+.9
  else:
   cache.position=FreeRoamWorld.CENTERS[i%FreeRoamWorld.CENTERS.size()]+Vector3(random.randf_range(-700,700),random.randf_range(-140,140),random.randf_range(-850,650))
   if i==0:cache.position=Vector3(-80,10,-220)
  var box:=BoxMesh.new();box.size=Vector3(1.2,.7,1.0) if ground else Vector3(8,5,10)
  SpaceModelFactory.mesh(cache,box,Vector3.ZERO,Color(.18,.26,.3),"SalvageContainer")
  var scale_value:=1.0 if ground else 7.0
  SpaceModelFactory.ring(cache,Vector3(0,.6*scale_value,0),.65*scale_value,.03*scale_value,Color(1,.72,.2),"RecoveryBeacon",true)
  var label:=Label3D.new();label.text="COMPONENT SALVAGE\nHOLD K";label.position.y=2.3 if ground else 18;label.font_size=32;label.pixel_size=.012 if ground else .035;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.visibility_range_end=65 if ground else 1000;cache.add_child(label);labels.append(label)
  cache.visible=not i in ComponentDiscovery.state(profile,context).opened
 call_deferred("settle_positions",generation)
func settle_positions(expected_generation: int) -> void:
 await get_tree().physics_frame
 if not is_inside_tree() or generation!=expected_generation:return
 var shape:=SphereShape3D.new();shape.radius=.7 if ground else 9.0
 var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1 if ground else 2
 for i in range(caches.size()):
  var cache:=caches[i]
  var original:=cache.position
  for attempt in range(24):
   query.transform=Transform3D(Basis.IDENTITY,cache.global_position+Vector3.UP*(.8 if ground else 0))
   if get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():break
   var angle:=attempt*2.399
   cache.position=original+Vector3(cos(angle)*(attempt+1)*(2 if ground else 30),0 if ground else (attempt+1)*35,sin(angle)*(attempt+1)*(2 if ground else 30))
   if ground:cache.position.y=SurfaceWorld.height_at(cache.position.x,cache.position.z)+.9
func explorer() -> Node3D:
 return host.bot if ground else host.pilot.ship
func _physics_process(delta: float) -> void:
 tick(delta,Input.is_action_pressed("recover_component") and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED and not get_tree().paused)
func tick(delta: float,held: bool) -> void:
 if not is_local():return
 var actor:=explorer()
 if not is_instance_valid(actor) or not actor.alive or host.finished:hint.hide();return
 if int(ComponentDiscovery.state(profile,context).generation)!=generation:refresh()
 message_time=maxf(0,message_time-delta)
 var selected:=-1;var distance:=INF
 for i in range(caches.size()):
  if i in ComponentDiscovery.state(profile,context).opened:caches[i].visible=false;continue
  var next:=actor.global_position.distance_to(caches[i].global_position)
  if next<distance:distance=next;selected=i
 if selected!=active:active=selected;progress=0
 var range_value:=6.0 if ground else 60.0
 if held and selected>=0 and distance<=range_value:
  var query:=PhysicsRayQueryParameters3D.create(actor.global_position+Vector3.UP,caches[selected].global_position+Vector3.UP*.5,1 if ground else 2)
  if get_world_3d().direct_space_state.intersect_ray(query).is_empty():
   progress+=delta
   if progress>=2:recover(selected);progress=0
  else:progress=0;message="SALVAGE BLOCKED / move around the obstacle";message_time=1
 else:progress=0
 var scenic: bool=host is FreeRoamMatch and host.scenic_hud
 for label in labels:label.visible=not scenic
 hint.visible=Input.mouse_mode==Input.MOUSE_MODE_CAPTURED and not scenic
 if message_time>0:hint.text=message
 elif selected>=0 and distance<(65 if ground else 1000):
  var camera: Camera3D=host.bot.camera if ground else host.camera
  var local:=camera.global_basis.inverse()*(caches[selected].global_position-actor.global_position).normalized()
  var bearing: String="BEHIND" if local.z>0 else "LEFT" if local.x<-.2 else "RIGHT" if local.x>.2 else "AHEAD"
  bearing+=" / ABOVE" if local.y>.3 else " / BELOW" if local.y<-.3 else ""
  hint.text="COMPONENT SALVAGE / %s / %dm / %s"%[bearing,int(distance),"HOLD K · %d%%"%int(progress/2*100) if distance<=range_value else "APPROACH WITHIN %dm"%int(range_value)]
 else:hint.text="FIND SHIP PARTS / hold K at gold salvage beacons"
 if message_time<=0 and hint.get_theme_color("font_color")!=Color(1,.82,.5):hint.add_theme_color_override("font_color",Color(1,.82,.5))
func recover(index: int) -> Dictionary:
 if not is_local():return {"ok":false,"message":"Component recovery is currently solo exploration only."}
 var result:=ComponentDiscovery.recover(profile,context,index)
 message=result.message;message_time=9
 if result.ok:
  caches[index].visible=false
  var item:=CollectionCatalog.find(result.id)
  hint.add_theme_color_override("font_color",item.rarity_color())
  SpaceEffects.burst(self,caches[index].global_position,item.rarity_color(),2.0 if ground else 12.0)
  SpaceAudio.play("click")
  if ground:host.status_message=message
  else:host.log_label.text=message
 return result

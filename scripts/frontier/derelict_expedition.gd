class_name DerelictExpedition
extends PlanetExpedition
## A local walkable interior using the existing survey-bot controller.
var secured:=false
var terminal_index:=0
var terminal_progress:=0.0
var terminals: Array[Vector3]=[Vector3(-6,1,-5),Vector3(6,1,-21),Vector3(0,1,-44)]
var doors: Array[StaticBody3D]=[]
var readout: Label
var screen: CanvasLayer
var pause_box: PanelContainer
var terminal_art: Array[Node3D]=[]
var security_grid: MeshInstance3D
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_PAUSABLE
 definition=PlanetDefinition.new();definition.id="derelict";definition.display_name="Abandoned survey carrier";definition.biome="derelict"
 if bot_definition==null:bot_definition=CollectionCatalog.find("crew_pixlet")
 var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color(.006,.014,.027);env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color(.45,.6,.75);env.environment.ambient_light_energy=.7;add_child(env)
 var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-55,25,0);light.light_energy=1.1;add_child(light)
 wall(Vector3(0,-.25,-20),Vector3(18,.5,58),Color(.12,.19,.23))
 for side in [-1,1]:wall(Vector3(side*9,2.5,-20),Vector3(.5,5,58),Color(.055,.09,.13))
 for z in [9,-49]:wall(Vector3(0,2.5,z),Vector3(18,5,.5),Color(.08,.13,.17))
 for z in [-10,-26]:
  for side in [-1,1]:wall(Vector3(side*5.5,2.5,z),Vector3(7,5,.5),Color(.1,.16,.2))
  doors.append(wall(Vector3(0,2.5,z),Vector3(4,5,.5),Color(.2,.3,.36)))
 for i in range(terminals.size()):
  var console:=Node3D.new();console.position=terminals[i];add_child(console);terminal_art.append(console)
  var shape:=BoxMesh.new();shape.size=Vector3(1.2,1.4,.7);SpaceModelFactory.mesh(console,shape,Vector3.ZERO,Color(.2,.36,.4),"Console")
  SpaceModelFactory.ball(console,Vector3(0,.4,.45),Vector3(.4,.22,.035),Color(.25,.9,1),"ConsoleScreen",true)
  var text:=Label3D.new();text.text=["01 / RESTORE POWER","02 / RELEASE SECURITY DOOR","03 / RECOVER BLACK BOX"][i]+"\nHOLD G WITHIN 4m";text.position.y=2;text.pixel_size=.015;text.billboard=BaseMaterial3D.BILLBOARD_ENABLED;console.add_child(text)
 for z in range(-46,8,5):
  var strip:=BoxMesh.new();strip.size=Vector3(1.5,.025,.25);SpaceModelFactory.mesh(self,strip,Vector3(0,.02,z),Color(.15,.65,.9),"FloorGuide",true)
 for z in range(-46,8,8):
  for side in [-1,1]:
   var rib:=BoxMesh.new();rib.size=Vector3(.35,4.7,.65);SpaceModelFactory.mesh(self,rib,Vector3(side*8.6,2.3,z),Color(.2,.3,.36),"HullRib")
   var lamp:=BoxMesh.new();lamp.size=Vector3(.08,1.2,.14);SpaceModelFactory.mesh(self,lamp,Vector3(side*8.4,3.4,z),Color(.3,.7,.9),"WallGuide",true)
 var grid_mesh:=BoxMesh.new();grid_mesh.size=Vector3(12,2.8,.08);security_grid=SpaceModelFactory.mesh(self,grid_mesh,Vector3(0,1.4,-18),Color(1,.35,.1),"SecurityGrid",true)
 security_grid.material_override=security_grid.material_override.duplicate();security_grid.material_override.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;security_grid.hide()
 bot=SurfaceBot.new();bot.definition=bot_definition;bot.expedition=self;bot.position=Vector3(0,1.5,4);add_child(bot)
 screen=CanvasLayer.new();screen.layer=8;screen.process_mode=Node.PROCESS_MODE_ALWAYS;add_child(screen)
 readout=Label.new();readout.position=Vector2(24,24);readout.custom_minimum_size.x=650;readout.add_theme_font_size_override("font_size",19);readout.add_theme_constant_override("outline_size",5);screen.add_child(readout)
 pause_box=PanelContainer.new();pause_box.position=Vector2(450,270);pause_box.theme=CartoonStyle.ui_theme();screen.add_child(pause_box)
 var column:=VBoxContainer.new();pause_box.add_child(column)
 var resume:=Button.new();resume.text="RESUME EXPLORATION";resume.pressed.connect(toggle_pause);column.add_child(resume)
 var leave:=Button.new();leave.text="RETURN TO ORBIT / KEEP ONLY SECURED DATA";leave.pressed.connect(func():get_tree().paused=false;return_requested.emit());column.add_child(leave);pause_box.hide()
 Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
 print("GALACTIC_DERELICT_READY terminals=3")
func wall(at: Vector3,size_value: Vector3,color: Color) -> StaticBody3D:
 var body:=StaticBody3D.new();body.position=at;body.collision_layer=1;body.collision_mask=2;add_child(body)
 var collision:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size_value;collision.shape=shape;body.add_child(collision)
 var mesh:=BoxMesh.new();mesh.size=size_value;SpaceModelFactory.mesh(body,mesh,Vector3.ZERO,color,"InteriorBulkhead");return body
func _physics_process(delta: float) -> void:
 if finished:return
 elapsed+=delta
 var controls:=bot.read_controls()
 if terminal_index<terminals.size():
  var close:=bot.position.distance_to(terminals[terminal_index])<4
  terminal_progress=terminal_progress+delta if close and bool(controls.get("scan",false)) else 0
  if terminal_progress>=2:
   if terminal_index<doors.size():
    doors[terminal_index].hide()
    for shape in doors[terminal_index].get_children():
     if shape is CollisionShape3D:shape.set_deferred("disabled",true)
   terminal_index+=1;terminal_progress=0;SpaceAudio.play("shield")
   if terminal_index==3:secured=true
 var phase:=fmod(elapsed,6.0)
 security_grid.visible=phase>3.7
 security_grid.material_override.albedo_color=Color(1,.15,.08,.3) if phase>4.5 else Color(1,.7,.1,.15)
 if phase>4.5 and absf(bot.position.z+18)<1.5 and absf(bot.position.x)<6:bot.hurt(10*delta)
 readout.text="DERELICT / BLACK-BOX EXPEDITION\nHull %d · Shield %d · Data %s\n"%[int(bot.hull),int(bot.shield),"SECURED" if secured else "%d / 3 consoles"%terminal_index]
 readout.text+="Return to the airlock and press E within 6m." if secured else "Follow the blue floor guides. Hold G for 2s within 4m of the next console.\nConsole handshake: %d%%"%int(terminal_progress/2*100)
 readout.text+="\nSECURITY GRID: "+("DISCHARGING / stay out of the middle corridor" if phase>4.5 else "warning lights pulse before each discharge")+"\nWASD move · Mouse look · Space jump · Esc pause/return"
 if bool(controls.get("extract",false)) and bot.position.distance_to(Vector3(0,1,4))<6:return_requested.emit()
func finish(_success: bool) -> void:
 finished=true;bot.set_physics_process(false);pause_box.show();get_tree().paused=true;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 readout.text="SURVEY BOT DISABLED / return to orbit and redeploy. Unsecured wreck data was lost.";secured=false
func toggle_pause() -> void:
 if finished:return
 get_tree().paused=not get_tree().paused;pause_box.visible=get_tree().paused;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if get_tree().paused else Input.MOUSE_MODE_CAPTURED

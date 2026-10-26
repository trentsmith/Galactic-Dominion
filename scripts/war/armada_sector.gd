class_name ArmadaSector
extends Node3D
const RADIUS:=5200.0
const SENSOR:=1100.0
var seed_value:=0
var battle: BattleMatch
var hazards: Array[Dictionary]=[]
var anchors: Array[Vector3]=[]
var fields: Array[Vector3]=[]
var relics: Array[Vector3]=[]
var rng:=RandomNumberGenerator.new()
var asteroid_count:=0
var rock_meshes: Array[ArrayMesh]=[]
func _ready() -> void:
 generate()
 build_visuals()
func generate() -> void:
 rng.seed=seed_value
 hazards.clear();anchors.clear();fields.clear();relics.clear()
 var angle:=rng.randf()*TAU
 for i in range(4):
  var a:=angle+i*TAU/4+rng.randf_range(-.2,.2)
  var at:=Vector3(cos(a)*rng.randf_range(1300,2600),rng.randf_range(-300,300),sin(a)*rng.randf_range(1300,2600))
  hazards.append({"position":at,"kind":"star" if i<2 else "black hole","influence":650.0 if i<2 else 800.0,"core":110.0 if i<2 else 65.0})
 for team in range(2):
  for squad in range(20):
   var a:=angle+team*PI+rng.randf_range(-.95,.95)
   var at:=Vector3(cos(a)*rng.randf_range(2600,3900),rng.randf_range(-650,650),sin(a)*rng.randf_range(2600,3900))
   if not safe(at,400):at=at.normalized()*4300
   anchors.append(at)
 for i in range(16):
  var at:=random_point(3800)
  fields.append(at)
 for i in range(8):
  var at:=random_point(2200)
  while not safe(at,300):at=random_point(2200)
  relics.append(at)
func random_point(radius: float) -> Vector3:
 var a:=rng.randf()*TAU;var r:=sqrt(rng.randf())*radius
 return Vector3(cos(a)*r,rng.randf_range(-650,650),sin(a)*r)
func safe(at: Vector3,margin: float) -> bool:
 for hazard in hazards:
  if at.distance_to(hazard.position)<float(hazard.influence)+margin:return false
 return true
func spawn_position(team: int,slot: int) -> Vector3:
 var squad:=slot/10
 return anchors[team*20+squad]+Vector3((slot%5-2)*45,(slot%2)*38,(slot%10/5)*55)
func search_position(ship: CombatShip,time: float) -> Vector3:
 var a:=float(ship.fleet_slot/10)*2.399+time*.012
 var reach:=minf(1800,battle.zone.radius*.65)
 return Vector3(cos(a)*reach,sin(a*1.7)*250,sin(a)*reach)
func gravity(at: Vector3) -> Vector3:
 var acceleration:=Vector3.ZERO
 for hazard in hazards:
  var offset: Vector3=hazard.position-at
  var distance:=offset.length()
  if distance>=float(hazard.influence) or distance<.01:continue
  var weight:=pow(1.0-distance/float(hazard.influence),2)
  var radial:=offset/distance
  acceleration+=radial*(100 if hazard.kind=="black hole" else 42)*weight
  if hazard.kind=="star":acceleration+=radial.cross(Vector3.UP)*32*weight
 return acceleration.limit_length(100)
func avoidance(at: Vector3) -> Vector3:
 var result:=Vector3.ZERO
 for hazard in hazards:
  var offset: Vector3=at-hazard.position
  var distance:=offset.length()
  if distance<float(hazard.influence)*.75 and distance>.01:result+=offset/distance*3
 return result
func tick(delta: float) -> void:
 for ship in battle.ships:
  if not ship.alive:continue
  ship.movement.external_acceleration=gravity(ship.position)
  for hazard in hazards:
   var distance:=ship.position.distance_to(hazard.position)
   if distance<float(hazard.core):ship.health.damage(100000 if hazard.kind=="black hole" else 55*delta,null,"black hole" if hazard.kind=="black hole" else "stellar corona")
func warning(at: Vector3) -> String:
 for hazard in hazards:
  if at.distance_to(hazard.position)<float(hazard.influence):return "DANGER / "+str(hazard.kind).to_upper()+" GRAVITY / BOOST AWAY FROM CORE"
 return "J: SECTOR CHART / CONTACTS WITHIN 1100m ONLY"
func build_visuals() -> void:
 for i in range(8):rock_meshes.append(SpaceEnvironmentArt.asteroid_mesh(seed_value+i))
 var rock_material:=ShaderMaterial.new();rock_material.shader=SpaceEnvironmentArt.ROCK_SHADER
 # Shared mesh variants and one material, with real static collision bodies.
 for field in fields:
  for i in range(28):
   var at:=field+Vector3(rng.randf_range(-520,520),rng.randf_range(-250,250),rng.randf_range(-520,520))
   var clear:=true
   for anchor in anchors:
    if at.distance_squared_to(anchor)<180*180:clear=false;break
   if not clear or not safe(at,50):continue
   var radius:=rng.randf_range(8,38)
   var body:=StaticBody3D.new();body.collision_layer=2;body.collision_mask=1;body.position=at;add_child(body)
   var visual:=MeshInstance3D.new();visual.mesh=rock_meshes[i%8];visual.material_override=rock_material;visual.scale=Vector3(radius,radius*.8,radius*1.1);visual.visibility_range_end=2300;body.add_child(visual)
   var shape:=SphereShape3D.new();shape.radius=radius
   var collision:=CollisionShape3D.new();collision.shape=shape;body.add_child(collision);asteroid_count+=1
 for hazard in hazards:
  var at: Vector3=hazard.position
  var root:=Node3D.new();root.position=at;add_child(root)
  var star: bool=hazard.kind=="star"
  var core:=SphereMesh.new();core.radius=hazard.core;core.height=hazard.core*2;core.radial_segments=32;core.rings=16
  SpaceModelFactory.mesh(root,core,Vector3.ZERO,Color(1,.57,.15) if star else Color(.001,.001,.003),"StellarCore" if star else "EventHorizon",star)
  for i in range(3):
   var ring:=SpaceModelFactory.ring(root,Vector3.ZERO,float(hazard.core)*(1.3+i*.3),5.0 if star else 9.0,Color(1,.35+.12*i,.12) if star else Color(.75,.25+.15*i,1),"Corona" if star else "AccretionDisk",true)
   ring.rotation=Vector3(.3,0,.15)
  var danger:=Label3D.new();danger.text=("STELLAR DRIFT" if star else "BLACK HOLE / LETHAL CORE");danger.position.y=float(hazard.core)+60;danger.billboard=BaseMaterial3D.BILLBOARD_ENABLED;danger.pixel_size=1;danger.font_size=32;danger.visibility_range_end=1800;root.add_child(danger)

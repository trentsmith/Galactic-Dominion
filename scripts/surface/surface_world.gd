class_name SurfaceWorld
extends Node3D
var definition: PlanetDefinition
var landing_stats: ShipStats
var rng:=RandomNumberGenerator.new()
var flora_nodes: Array[Node3D]=[]
const RADIUS:=2000.0
static func height_at(x: float,z: float) -> float:
 var distance:=Vector2(x,z).length()
 var hills:=(sin(x*.009)*cos(z*.011)*9+sin((x-z)*.017)*3)*smoothstep(120,260,distance)
 return hills+(sin(x*.045)*cos(z*.055)*2.4+sin((x+z)*.11)*.55)*smoothstep(9,22,distance)
func _ready() -> void:
 rng.seed=definition.seed_value
 var background:=WorldEnvironment.new()
 var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=definition.sky_color
 env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color=definition.glow_color.lightened(.6);env.ambient_light_energy=.60
 if definition.biome=="eldritch":env.ambient_light_color=Color(.39,.5,.48);env.ambient_light_energy=.42
 if definition.biome=="eldritch":
  var sky:=Sky.new();var sky_material:=ProceduralSkyMaterial.new()
  sky_material.sky_top_color=Color(.005,.012,.018);sky_material.sky_horizon_color=Color(.075,.13,.135);sky_material.ground_horizon_color=Color(.075,.13,.135);sky_material.ground_bottom_color=Color(.01,.02,.025);sky_material.sky_energy_multiplier=.55
  sky.sky_material=sky_material;env.sky=sky;env.background_mode=Environment.BG_SKY
 env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
 env.fog_enabled=true;env.fog_light_color=definition.sky_color.lightened(.08);env.fog_density=.008 if not definition.aquatic else .018
 background.environment=env;add_child(background)
 var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-40,-30,0);sun.light_energy=1.15
 if definition.biome=="eldritch":sun.light_energy=.7;sun.light_color=Color(.57,.69,.72)
 sun.shadow_enabled=true;sun.directional_shadow_max_distance=180
 sun.light_color=Color(.75,.85,1) if definition.biome!="vampire" else Color(1,.55,.6)
 add_child(sun)
 _terrain()
 for index in range(150):
  var angle:=rng.randf()*TAU;var distance:=rng.randf_range(16,108)
  var at:=Vector3(cos(angle)*distance,0,sin(angle)*distance);at.y=height_at(at.x,at.z)
  # Keep a broad route from landing site to the initial survey stations.
  if absf(at.x)<5 and at.z<0:continue
  var plant:=SurfaceArt.plant(self,definition.biome,at,definition.foliage_color,definition.glow_color,index)
  plant.scale=Vector3.ONE*rng.randf_range(.6,1.5)
  if index%3==0:_obstacle(at+Vector3.UP*1.3,.7,2.6)
 for index in range(3):
  var at:=Vector3([-24.0,0.0,26.0][index],0,[-20.0,-39.0,-25.0][index]);at.y=height_at(at.x,at.z)
  var plant:=SurfaceArt.plant(self,definition.biome,at,definition.foliage_color.lightened(.25),definition.glow_color,index)
  plant.set_meta("scan_id","flora.%d" % index);plant.set_meta("scan_name",definition.flora[index]);flora_nodes.append(plant)
  SpaceModelFactory.ring(plant,Vector3(0,.2,0),2.5,.035,definition.glow_color,"SurveyRing",true).rotation=Vector3.ZERO
 for index in range(25):
  var at:=Vector3(rng.randf_range(-100,100),0,rng.randf_range(-100,100))
  if Vector2(at.x,at.z).length()<18:continue
  at.y=height_at(at.x,at.z)
  var stone:=SpaceModelFactory.mesh(self,SpaceEnvironmentArt.asteroid_mesh(index+definition.seed_value),at+Vector3.UP*.7,definition.ground_color.lightened(.12),"WeatheredStone")
  stone.scale=Vector3(1.6,1,1.3)
  _obstacle(stone.position,1.2,1.6)
 _landmarks()
func _terrain() -> void:
 build_terrain_tile(self,Vector3.ZERO,240,72)
func build_terrain_tile(parent: Node3D,center: Vector3,width: float,grid: int) -> void:
 var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 var step:=width/grid
 for x in range(grid):
  for z in range(grid):
   for offset in [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
    var px:float=center.x-width*.5+(x+offset.x)*step;var pz:float=center.z-width*.5+(z+offset.y)*step
    surface.set_color(definition.ground_color.lightened((sin(px*.13)*cos(pz*.1)+1)*.025))
    surface.add_vertex(Vector3(px,height_at(px,pz),pz))
 surface.generate_normals()
 var mesh:=surface.commit();var visual:=MeshInstance3D.new();visual.mesh=mesh
 var mat:=CartoonStyle.material(Color.WHITE);mat.vertex_color_use_as_albedo=true;mat.next_pass=null;mat.roughness=1;mat.metallic=0;mat.diffuse_mode=BaseMaterial3D.DIFFUSE_BURLEY;mat.cull_mode=BaseMaterial3D.CULL_DISABLED
 var ground_material:=ShaderMaterial.new();ground_material.shader=preload("res://resources/shaders/planet_ground.gdshader")
 ground_material.set_shader_parameter("ground_color",definition.ground_color)
 ground_material.set_shader_parameter("biome",0 if definition.biome=="vampire" else 1 if definition.aquatic else 2)
 visual.material_override=ground_material;parent.add_child(visual)
 var body:=StaticBody3D.new();body.collision_layer=1;body.collision_mask=0
 var collision:=CollisionShape3D.new();collision.shape=mesh.create_trimesh_shape();body.add_child(collision);parent.add_child(body)
func _obstacle(at: Vector3,radius: float,height: float) -> void:
 var body:=StaticBody3D.new();body.position=at;body.collision_layer=1;body.collision_mask=0
 var shape:=CylinderShape3D.new();shape.radius=radius;shape.height=height
 var collision:=CollisionShape3D.new();collision.shape=shape;body.add_child(collision);add_child(body)
func _landmarks() -> void:
 # Landing refuge: wildlife stays outside this ring.
 SpaceModelFactory.ring(self,Vector3(0,.15,0),10,.08,Color(.3,.9,1),"LandingSafeRing",true).rotation=Vector3.ZERO
 var landing:=Node3D.new();landing.name="LandedShip";landing.position=Vector3(0,2.4,0);landing.scale=Vector3.ONE*.9
 SpaceModelFactory.ship(landing,landing_stats if landing_stats!=null else CollectionCatalog.SHIP_TYPES.interceptor);add_child(landing)
 landing.set_meta("ship_class",landing_stats.class_name_text if landing_stats!=null else "Interceptor")
 for side in [-1,1]:
  for z in [-1.0,1.0]:SurfaceArt.post(self,Vector3(side*1.0,1.0,z),.09,2.0,Color(.3,.36,.4))
 var sign:=Label3D.new();sign.text="LANDING SHIP / SAFE REFUGE\nE: DELIVER CAPTURES · B: CHANGE BOT";sign.position=Vector3(0,7,0);sign.font_size=38;sign.pixel_size=.012;add_child(sign)
 if definition.biome=="vampire":
  SpaceEnvironmentArt.planet(self,Vector3(35,27,-94),10,Color(.45,.08,.12),77)
  for i in range(4):
   var ridge:=SpaceModelFactory.mesh(self,SpaceEnvironmentArt.asteroid_mesh(77+i),Vector3(-70+i*45,4,-100),Color(.11,.06,.09),"VolcanicRidge")
   ridge.scale=Vector3(20,22,15)
   SurfaceArt.ball(self,Vector3(-70+i*45,22,-100),Vector3(2.5,1,2.5),Color(1,.18,.03),true)
  for side in [-1,1]:
   for i in range(3):
    var at:=Vector3(side*(35+i*9),0,-60-i*10);at.y=height_at(at.x,at.z)
    SurfaceArt.post(self,at+Vector3.UP*6,1.2,12,Color(.12,.07,.16))
    SceneryArt.tower(self,at+Vector3.UP*4,Color(.18,.07,.10),definition.glow_color)
    SurfaceArt.ball(self,at+Vector3.UP*9+Vector3(0,0,-2.6),Vector3(.5,1,.2),definition.glow_color,true)
 elif definition.aquatic:
  for index in range(12):
   var at:=Vector3(sin(index*1.9)*78,5+index%3*3,cos(index*1.9)*78)
   SurfaceArt.post(self,at,2,18,definition.ground_color.darkened(.3))
   SurfaceArt.ball(self,at+Vector3.UP*8,Vector3(3,1,3),definition.glow_color,true)
 else:
  EldritchArt.build(self)
  for index in range(10):
   var at:=Vector3(sin(index*1.7)*65,14+index%4*5,-25-cos(index*2.1)*40)
   var shard:=SpaceModelFactory.mesh(self,SpaceEnvironmentArt.asteroid_mesh(910+index),at,Color(.18,.22,.22),"SuspendedOssuary")
   shard.scale=Vector3(3,1.4,3);EldritchArt.stone(shard)
   ArtGeometry.sweep(self,[at,at+Vector3(1,-4,.4),at+Vector3(-1,-7,1)],[.4,.17,.01],Color(.13,.2,.19),"HangingRoot")
  for side in [-1,1]:
   var stream:=SurfaceTool.new();stream.begin(Mesh.PRIMITIVE_TRIANGLES)
   for i in range(20):
    var t:=float(i)/20;var n:=float(i+1)/20
    var a:=Vector3(side*(12+t*22),12-t*11,-78+t*38)
    var b:=Vector3(side*(12+n*22),12-n*11,-78+n*38)
    for point in [a+Vector3(-1.5,0,0),b+Vector3(-1.5,0,0),a+Vector3(1.5,0,0),a+Vector3(1.5,0,0),b+Vector3(-1.5,0,0),b+Vector3(1.5,0,0)]:stream.add_vertex(point)
   stream.generate_normals()
   var water:=SpaceModelFactory.mesh(self,stream.commit(),Vector3.ZERO,Color(.1,.34,.34),"PaleDreamStream",false)
   (water.material_override as StandardMaterial3D).cull_mode=BaseMaterial3D.CULL_DISABLED

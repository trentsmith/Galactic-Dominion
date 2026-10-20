class_name WildernessStream
extends Node
## Deterministic nearby tiles keep terrain, wildlife and foliage bounded.
const TILE:=240.0
const REACH:=1
var expedition: PlanetExpedition
var chunks: Dictionary={}
var memories: Dictionary={}
var active:=false
var cell:=Vector2i(999,999)
var queue: Array[Vector2i]=[]
func _process(_delta: float) -> void:
 if not is_instance_valid(expedition.bot) or expedition.finished:return
 if not active and Vector2(expedition.bot.position.x,expedition.bot.position.z).length()<85:return
 active=true
 update_center(expedition.bot.position)
 if not queue.is_empty():load_tile(queue.pop_front())
func update_center(at: Vector3) -> void:
 var next:=Vector2i(roundi(at.x/TILE),roundi(at.z/TILE))
 if next==cell:return
 cell=next;queue.clear()
 for key in chunks.keys():
  if absi(key.x-cell.x)>REACH or absi(key.y-cell.y)>REACH:unload_tile(key)
 for x in range(cell.x-REACH,cell.x+REACH+1):
  for z in range(cell.y-REACH,cell.y+REACH+1):
   var key:=Vector2i(x,z)
   if key==Vector2i.ZERO or chunks.has(key):continue
   if Vector2(key.x*TILE,key.y*TILE).length()>SurfaceWorld.RADIUS+TILE:continue
   queue.append(key)
 queue.sort_custom(func(a: Vector2i,b: Vector2i):return a.distance_squared_to(cell)<b.distance_squared_to(cell))
func load_tile(key: Vector2i) -> void:
 if chunks.has(key):return
 var tile:=Node3D.new();tile.name="Wilderness_%d_%d"%[key.x,key.y];expedition.world.add_child(tile)
 chunks[key]={"node":tile,"animals":[],"plants":[]}
 var at:=Vector3(key.x*TILE,0,key.y*TILE)
 expedition.world.build_terrain_tile(tile,at,TILE,40)
 var random:=RandomNumberGenerator.new();random.seed=tile_seed(key)
 var definition:=expedition.definition
 ground_cover(tile,at,random)
 for i in range(22):
  var pos:=at+Vector3(random.randf_range(-110,110),0,random.randf_range(-110,110));pos.y=SurfaceWorld.height_at(pos.x,pos.z)
  var plant:=SurfaceArt.plant(tile,definition.biome,pos,definition.foliage_color.lightened(random.randf_range(0,.15)),definition.glow_color,i+absi(key.x*7+key.y*13))
  plant.scale=Vector3.ONE*random.randf_range(.55,1.8)
  if i<3:
   plant.set_meta("scan_id","flora.%d"%i);plant.set_meta("scan_name",definition.flora[i]);expedition.world.flora_nodes.append(plant);expedition.specimens.append(plant);chunks[key].plants.append(plant)
 for i in range(4):
  var id:="%d:%d:%d"%[key.x,key.y,i]
  var animal:=SurfaceFauna.new();animal.expedition=expedition;animal.definition=definition.fauna[random.randi_range(0,definition.fauna.size()-1)].duplicate(true)
  animal.definition.size*=random.randf_range(.8,1.18)
  animal.definition.color=animal.definition.color.lightened(random.randf_range(0,.12))
  animal.position=at+Vector3(random.randf_range(-85,85),0,random.randf_range(-85,85));animal.position.y=SurfaceWorld.height_at(animal.position.x,animal.position.z)+(4 if definition.aquatic else .5)
  animal.set_meta("wilderness_id",id)
  expedition.add_child(animal)
  if memories.has(id):
   animal.health=memories[id].health;animal.alive=memories[id].alive;animal.visible=animal.alive;animal.collision_layer=4 if animal.alive else 0
   # Captures/deaths stay absent for the rest of this expedition, including reloads.
   if not animal.alive:animal.respawn_timer=1.0e9
  expedition.fauna.append(animal);expedition.specimens.append(animal);chunks[key].animals.append(animal)
 var landmark:=at+Vector3(65,0,-60);landmark.y=SurfaceWorld.height_at(landmark.x,landmark.z)
 if posmod(key.x+key.y,3)==0:
  var wreck:=Node3D.new();wreck.position=landmark;tile.add_child(wreck);SceneryArt.wreck(wreck,Vector3(13,4,22))
  obstacle(tile,landmark+Vector3.UP*2,Vector3(13,4,22))
 else:
  for i in range(3):
   var rock:=SpaceModelFactory.mesh(tile,SpaceEnvironmentArt.asteroid_mesh(tile_seed(key)+i),landmark+Vector3(i*8,5,0),definition.ground_color.lightened(.15),"TrailStone")
   rock.scale=Vector3(5,8+i*2,5)
   obstacle(tile,landmark+Vector3(i*8,4,0),Vector3(6,8,6))
func unload_tile(key: Vector2i) -> void:
 var chunk: Dictionary=chunks[key]
 for animal in chunk.animals:
  memories[str(animal.get_meta("wilderness_id"))]={"health":animal.health,"alive":animal.alive}
  expedition.fauna.erase(animal);expedition.specimens.erase(animal);animal.queue_free()
 for plant in chunk.plants:
  expedition.world.flora_nodes.erase(plant);expedition.specimens.erase(plant)
 chunk.node.queue_free();chunks.erase(key)
func tile_seed(key: Vector2i) -> int:
 return expedition.definition.seed_value+key.x*73856093+key.y*19349663

func obstacle(parent: Node3D,at: Vector3,size: Vector3) -> void:
 var body:=StaticBody3D.new();body.position=at;body.collision_layer=1;body.collision_mask=0
 var shape:=BoxShape3D.new();shape.size=size
 var collider:=CollisionShape3D.new();collider.shape=shape;body.add_child(collider);parent.add_child(body)

func ground_cover(parent: Node3D,center: Vector3,random: RandomNumberGenerator) -> void:
 # Hundreds of simple leaf tufts share a single draw instance per tile.
 var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for angle in [0.0,PI/3,PI*2/3]:
  var across:=Vector3(cos(angle),0,sin(angle))*.32
  for point in [-across,across,Vector3(.12,1.2,.08)]:
   surface.set_normal(Vector3.UP);surface.add_vertex(point)
 var instances:=MultiMesh.new();instances.transform_format=MultiMesh.TRANSFORM_3D;instances.use_colors=true;instances.mesh=surface.commit();instances.instance_count=700
 for i in range(instances.instance_count):
  var at:=center+Vector3(random.randf_range(-119,119),0,random.randf_range(-119,119));at.y=SurfaceWorld.height_at(at.x,at.z)
  var size:=random.randf_range(.5,1.7)
  instances.set_instance_transform(i,Transform3D(Basis(Vector3.UP,random.randf()*TAU).scaled(Vector3.ONE*size),at))
  instances.set_instance_color(i,expedition.definition.foliage_color.lightened(random.randf_range(0,.2)))
 var node:=MultiMeshInstance3D.new();node.name="InstancedMeadow";node.multimesh=instances;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var mat:=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.roughness=1;mat.cull_mode=BaseMaterial3D.CULL_DISABLED
 node.material_override=mat;parent.add_child(node)

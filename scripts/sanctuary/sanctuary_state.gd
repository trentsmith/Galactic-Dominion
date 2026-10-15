class_name SanctuaryState
extends RefCounted
const MATERIALS=["food","bloom","fiber","ore","pearl","alloy","essence","crystal","capture_pod"]
const HABITATS={"meadow":{"title":"Meadow Garden","cost":{"ore":4,"fiber":2}},"reef":{"title":"Reef Lagoon","cost":{"ore":4,"bloom":3}},"rift":{"title":"Dream Conservatory","cost":{"ore":5,"pearl":3}}}
const PRODUCE={"bloodstag":"bloom","duskbat":"fiber","nightfang":"ore","sporehopper":"pearl","prismgrazer":"food","thornmanta":"alloy","riftwisp":"essence","manyeye":"crystal","veilcrawler":"alloy"}
const FLIGHT_RECIPES=[{"title":"Survey Anchor","cost":{"ore":8,"fiber":6,"bloom":6}},{"title":"Lift Engines","cost":{"ore":15,"alloy":10,"pearl":6}},{"title":"Rift Drive","cost":{"alloy":18,"essence":12,"crystal":10}}]
static func defaults() -> Dictionary:
 return {"name":"Little Star Sanctuary","palette":0,"materials":{"food":12,"bloom":3,"fiber":2,"ore":4,"pearl":0,"alloy":0,"essence":0,"crystal":0,"capture_pod":3},"habitats":[{"id":1,"kind":"meadow","x":-1,"z":0,"level":1},{"id":2,"kind":"planter","x":1,"z":0,"level":1}],"residents":[new_resident(1,"bloodstag","Ruby")],"plants":[{"id":"starter.berry","name":"Starberry Bush","growth":0.0,"stored":0,"clock":0.0}],"seeds":{},"flight_stage":0,"location":3,"next_id":2,"time":0.0}
static func new_resident(id: int,species: String,nickname: String="") -> Dictionary:
 return {"id":id,"species":species,"name":nickname,"nutrition":75.0,"happiness":70.0,"energy":80.0,"growth":0.0,"bond":0.0,"love":0.0,"care_time":0.0,"form_stage":0,"production":0,"clock":0.0,"pet_cooldown":0.0,"habitat":1 if species=="bloodstag" else 0}
static func fauna(id: String) -> FaunaDefinition:
 for planet in PlanetCatalog.WORLDS:
  for item in planet.fauna:
   if item.id==id:return item
 return null
static func habitat_for(species: String) -> String:
 for planet in PlanetCatalog.WORLDS:
  for item in planet.fauna:
   if item.id==species:return "reef" if planet.aquatic else "rift" if planet.biome=="eldritch" else "meadow"
 return "meadow"
static func number(value: Variant,minimum: float,maximum: float,fallback: float=0) -> float:
 if (not value is int and not value is float) or not is_finite(float(value)):return fallback
 return clampf(float(value),minimum,maximum)
static func sanitize(value: Variant) -> Dictionary:
 var state:=defaults()
 if not value is Dictionary or value.is_empty():return state
 state.name=str(value.get("name",state.name)).strip_edges().left(32)
 if state.name.is_empty():state.name="Little Star Sanctuary"
 state.palette=int(number(value.get("palette",0),0,2))
 var raw_materials: Variant=value.get("materials",{})
 if raw_materials is Dictionary:
  for key in MATERIALS:state.materials[key]=int(number(raw_materials.get(key,state.materials[key]),0,99999))
 state.flight_stage=int(number(value.get("flight_stage",0),0,3));state.location=int(number(value.get("location",3),0,3));state.time=number(value.get("time",0),0,99999999)
 state.habitats=[]
 var occupied: Dictionary={};var habitat_ids: Dictionary={}
 var raw_habitats: Variant=value.get("habitats",[])
 if raw_habitats is Array:
  for entry in raw_habitats:
   if not entry is Dictionary or state.habitats.size()>=24:continue
   var kind:=str(entry.get("kind",""));var id:=int(number(entry.get("id",0),1,999999))
   var x:=int(number(entry.get("x",0),-2,2));var z:=int(number(entry.get("z",0),-2,2));var key:="%d,%d" % [x,z]
   if (not HABITATS.has(kind) and kind!="planter") or (x==0 and z==0) or occupied.has(key) or habitat_ids.has(id):continue
   occupied[key]=true;habitat_ids[id]=true
   state.habitats.append({"id":id,"kind":kind,"x":x,"z":z,"level":int(number(entry.get("level",1),1,3))})
 if state.habitats.is_empty():state.habitats=defaults().habitats
 state.residents=[];var resident_ids: Dictionary={}
 var raw_residents: Variant=value.get("residents",[])
 if raw_residents is Array:
  for entry in raw_residents:
   if not entry is Dictionary or state.residents.size()>=48:continue
   var species:=str(entry.get("species",""));var id:=int(number(entry.get("id",0),1,999999))
   if fauna(species)==null or resident_ids.has(id):continue
   resident_ids[id]=true
   var resident:=new_resident(id,species,str(entry.get("name","")).left(24))
   for key in ["nutrition","happiness","energy","growth","bond"]:resident[key]=number(entry.get(key,resident[key]),0,100)
   resident.love=number(entry.get("love",minf(50,resident.bond*.5)),0,100)
   resident.care_time=number(entry.get("care_time",0),0,99999999)
   resident.form_stage=int(number(entry.get("form_stage",0),0,2))
   resident.clock=number(entry.get("clock",0),0,60);resident.production=int(number(entry.get("production",0),0,12));resident.pet_cooldown=number(entry.get("pet_cooldown",0),0,5)
   resident.habitat=int(number(entry.get("habitat",0),0,999999));state.residents.append(resident)
 state.plants=[]
 var raw_plants: Variant=value.get("plants",[])
 if raw_plants is Array:
  for entry in raw_plants:
   if not entry is Dictionary or state.plants.size()>=12:continue
   var id:=str(entry.get("id",""))
   if not valid_seed(id):continue
   state.plants.append({"id":id,"name":seed_name(id),"growth":number(entry.get("growth",0),0,100),"stored":int(number(entry.get("stored",0),0,12)),"clock":number(entry.get("clock",0),0,30)})
 state.seeds={}
 var raw_seeds: Variant=value.get("seeds",{})
 if raw_seeds is Dictionary:
  for id in raw_seeds:
   if valid_seed(str(id)):state.seeds[str(id)]=int(number(raw_seeds[id],0,99))
 var next_id:=2
 for resident in state.residents:next_id=maxi(next_id,resident.id+1)
 state.next_id=next_id
 assign_residents(state)
 return state
static func valid_seed(id: String) -> bool:
 if id=="starter.berry":return true
 for planet in PlanetCatalog.WORLDS:
  for index in range(planet.flora.size()):
   if id=="%s.%d" % [planet.id,index]:return true
 return false
static func seed_name(id: String) -> String:
 if id=="starter.berry":return "Starberry Bush"
 for planet in PlanetCatalog.WORLDS:
  for index in range(planet.flora.size()):
   if id=="%s.%d" % [planet.id,index]:return planet.flora[index]
 return "Unknown"
static func pay(state: Dictionary,cost: Dictionary) -> bool:
 for key in cost:
  if not MATERIALS.has(key) or int(state.materials.get(key,0))<int(cost[key]):return false
 for key in cost:state.materials[key]-=int(cost[key])
 return true
static func assign_residents(state: Dictionary) -> void:
 var occupancy: Dictionary={}
 for resident in state.residents:
  var previous:=int(resident.habitat);resident.habitat=0
  for pass_index in range(2):
   for habitat in state.habitats:
    if pass_index==0 and habitat.id!=previous:continue
    if habitat.kind!=habitat_for(resident.species):continue
    if int(occupancy.get(habitat.id,0))>=2+habitat.level*2:continue
    resident.habitat=habitat.id;occupancy[habitat.id]=int(occupancy.get(habitat.id,0))+1;break
   if resident.habitat!=0:break
static func build(state: Dictionary,kind: String,x: int,z: int) -> bool:
 if abs(x)>2 or abs(z)>2 or (x==0 and z==0):return false
 for habitat in state.habitats:
  if habitat.x==x and habitat.z==z:return false
 if kind!="planter" and not HABITATS.has(kind):return false
 var cost: Dictionary={"ore":3,"bloom":2} if kind=="planter" else HABITATS[kind].cost
 if not pay(state,cost):return false
 var id:=1
 for habitat in state.habitats:id=maxi(id,habitat.id+1)
 state.habitats.append({"id":id,"kind":kind,"x":x,"z":z,"level":1});assign_residents(state);return true
static func move_habitat(state: Dictionary,id: int,x: int,z: int) -> bool:
 if abs(x)>2 or abs(z)>2 or (x==0 and z==0):return false
 for habitat in state.habitats:
  if habitat.x==x and habitat.z==z:return false
 for habitat in state.habitats:
  if habitat.id==id:habitat.x=x;habitat.z=z;return true
 return false
static func upgrade(state: Dictionary,id: int) -> bool:
 for habitat in state.habitats:
  if habitat.id==id:
   if habitat.level>=3 or not pay(state,{"ore":habitat.level*4,"bloom":habitat.level*3}):return false
   habitat.level+=1;assign_residents(state);return true
 return false
static func intake(state: Dictionary,animals: Array,seeds: Array) -> Dictionary:
 var accepted:=0
 for species in animals:
  if state.residents.size()>=48 or fauna(str(species))==null:continue
  state.residents.append(new_resident(state.next_id,str(species)));state.next_id+=1;accepted+=1
 for id in seeds:
  if valid_seed(str(id)):state.seeds[str(id)]=mini(99,int(state.seeds.get(str(id),0))+1)
 assign_residents(state)
 return {"animals":accepted,"seeds":seeds.size()}
static func care(state: Dictionary,id: int,action: String) -> bool:
 for resident in state.residents:
  if resident.id!=id:continue
  if action=="feed":
   if resident.nutrition>=100 or not pay(state,{"food":1}):return false
   resident.nutrition=minf(100,resident.nutrition+30);resident.energy=minf(100,resident.energy+12);resident.bond=minf(100,resident.bond+2);resident.love=minf(100,resident.love+3)
  elif action=="pet":
   if resident.pet_cooldown>0:return false
   resident.happiness=minf(100,resident.happiness+12);resident.bond=minf(100,resident.bond+4);resident.pet_cooldown=5;resident.love=minf(100,resident.love+4)
  elif action=="play":
   if resident.energy<12:return false
   resident.energy-=12;resident.happiness=minf(100,resident.happiness+20);resident.growth=minf(100,resident.growth+3);resident.bond=minf(100,resident.bond+5);resident.love=minf(100,resident.love+5)
  else:return false
  return true
 return false
static func tick(state: Dictionary,delta: float) -> void:
 var dt:=clampf(delta,0,5);state.time+=dt
 for resident in state.residents:
  resident.pet_cooldown=maxf(0,resident.pet_cooldown-dt)
  resident.nutrition=maxf(0,resident.nutrition-dt*.025);resident.happiness=maxf(0,resident.happiness-dt*.008)
  resident.energy=minf(100,resident.energy+dt*.2)
  if resident.habitat==0 or resident.nutrition<20 or resident.happiness<20:continue
  if resident.nutrition>=60 and resident.happiness>=65:
   resident.care_time+=dt;resident.love=minf(100,resident.love+dt*.015)
  resident.growth=minf(100,resident.growth+dt*.06)
  var level:=1
  for habitat in state.habitats:
   if habitat.id==resident.habitat:level=habitat.level
  resident.clock+=dt*(1+(level-1)*.25)*(1+resident.growth/200)*(1+resident.bond/200)*SanctuaryForms.production_multiplier(resident.form_stage)
  if resident.clock>=45:
   resident.clock-=45;resident.production=mini(12,resident.production+1)
 var planter_level:=0
 for habitat in state.habitats:
  if habitat.kind=="planter":planter_level+=habitat.level
 for plant in state.plants:
  if planter_level==0:continue
  plant.growth=minf(100,plant.growth+dt*.5)
  plant.clock+=dt*(1+planter_level*.2)*(1+plant.growth/200)
  if plant.clock>=25:plant.clock-=25;plant.stored=mini(12,plant.stored+1)
static func collect(state: Dictionary) -> int:
 var total:=0
 for resident in state.residents:
  var amount:=int(resident.production);var material: String=PRODUCE[resident.species]
  state.materials[material]=mini(99999,state.materials[material]+amount);total+=amount;resident.production=0
 for plant in state.plants:
  var amount:=int(plant.stored);state.materials.food=mini(99999,state.materials.food+amount);state.materials.bloom=mini(99999,state.materials.bloom+amount);total+=amount*2;plant.stored=0
 return total
static func plant_seed(state: Dictionary,id: String) -> bool:
 var capacity:=0
 for habitat in state.habitats:
  if habitat.kind=="planter":capacity+=habitat.level*3
 if state.plants.size()>=capacity or not valid_seed(id) or int(state.seeds.get(id,0))<=0:return false
 state.seeds[id]-=1;state.plants.append({"id":id,"name":seed_name(id),"growth":0.0,"stored":0,"clock":0.0});return true
static func craft(state: Dictionary,kind: String) -> bool:
 var recipes:={"capture_pod":{"ore":1,"bloom":1},"ore":{"food":3,"bloom":1},"fiber":{"food":2,"bloom":2},"food":{"bloom":2}}
 if not recipes.has(kind) or not pay(state,recipes[kind]):return false
 state.materials[kind]=mini(99999,state.materials[kind]+(2 if kind=="food" else 1));return true
static func advance_flight(state: Dictionary) -> bool:
 if state.flight_stage>=FLIGHT_RECIPES.size():return false
 if not pay(state,FLIGHT_RECIPES[state.flight_stage].cost):return false
 state.flight_stage+=1;return true
static func launch(state: Dictionary,destination: int) -> bool:
 if state.flight_stage<3 or destination<0 or destination>2 or state.location==destination:return false
 if not pay(state,{"pearl":3,"essence":3,"food":5}):return false
 state.location=destination;return true

static func awaken(state: Dictionary,id: int) -> bool:
 for resident in state.residents:
  if resident.id!=id:continue
  if not SanctuaryForms.ready(resident):return false
  resident.form_stage+=1;return true
 return false

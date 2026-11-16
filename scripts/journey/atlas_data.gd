class_name AtlasData
extends RefCounted
## Navigation uses real scene positions; surveys and discoveries keep their original rewards.
static func entries(battle: FreeRoamMatch) -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 for region in range(7):
  result.append({"id":"station-%d"%region,"name":FreeRoamWorld.NAMES[region]+" / station","at":JourneyState.pack(FreeRoamWorld.CENTERS[region]+Vector3(0,0,150)),"kind":"station","region":region,"known":true})
 for landmark in battle.world.landmarks:
  result.append({"id":"landmark-%d"%landmark.region,"name":landmark.name,"at":JourneyState.pack(landmark.position),"kind":"landmark","region":landmark.region,"known":battle.profile!=null and battle.profile.exploration_records.has("open.landmark.%d"%landmark.region)})
 if not battle.frontier.active.is_empty() and is_instance_valid(battle.frontier.point):
  var director:=battle.frontier
  var at: Vector3=director.enemy.position if is_instance_valid(director.enemy) else director.point.position
  result.append({"id":"active-job","name":director.active.title,"at":JourneyState.pack(at),"kind":"job","region":director.active.region,"known":true})
 for child in battle.get_children():
  if child is ComponentSalvage:
   for index in range(child.caches.size()):
    if child.caches[index].visible and battle.pilot.ship.position.distance_to(child.caches[index].position)<=child.bearing_range():result.append({"id":"cache-%d-%d"%[child.generation,index],"name":"Component cache %d"%(index+1),"at":JourneyState.pack(child.caches[index].position),"kind":"salvage","region":FreeRoamWorld.nearest_region(child.caches[index].position),"known":true})
 if is_instance_valid(battle.mining):
  for vein in battle.mining.veins:
   if vein.visible and battle.pilot.ship.position.distance_to(vein.position)<=battle.mining.sensor_range():result.append({"id":"vein-%d-%d"%[vein.generation,vein.slot],"name":vein.title(),"at":JourneyState.pack(vein.position),"kind":"mineral","region":FreeRoamWorld.nearest_region(vein.position),"known":true})
 if battle.profile!=null:
  for world_index in range(PlanetCatalog.WORLDS.size()):
   var world: PlanetDefinition=PlanetCatalog.WORLDS[world_index]
   for fauna in world.fauna:
    if not battle.profile.exploration_records.has("surface.%s.fauna.%s"%[world.id,fauna.id]):continue
    var region: int=[0,2,3][world_index]
    result.append({"id":"fauna-"+fauna.id,"name":fauna.display_name+" / "+world.display_name,"at":JourneyState.pack(FreeRoamWorld.CENTERS[region]+Vector3(-1000,-200,-1400)),"kind":"fauna","region":region,"known":true,"detail":fauna.description+" / "+CreatureCombat.affinity(fauna.id)+" / Approach the planet outside combat, L to land; T selects a species to track."})
  for bookmark in battle.profile.journey.bookmarks:
   var entry: Dictionary=bookmark.duplicate(true);entry.region=FreeRoamWorld.nearest_region(JourneyState.vector(entry.at));entry.known=true;result.append(entry)
 return result

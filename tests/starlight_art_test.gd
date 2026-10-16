extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
 checks+=1
 if value:print("PASS: "+message)
 else:failures+=1;push_error(message)
func run() -> void:
 var model:=Node3D.new();root.add_child(model)
 var body:=ArtGeometry.part(model,[Vector4(.05,.05,-1,0),Vector4(.5,.4,0,0),Vector4(.05,.05,1,0)],Color.WHITE,"Profile")
 check(body.mesh is ArrayMesh and body.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()>100,"Shaped hulls use real editable vertex geometry")
 var branch:=ArtGeometry.sweep(model,[Vector3.ZERO,Vector3(.2,1,0),Vector3(.5,2,.3)],[.2,.1,.01],Color.WHITE)
 var data:=branch.mesh.surface_get_arrays(0)
 var vertices: PackedVector3Array=data[Mesh.ARRAY_VERTEX]
 var normals: PackedVector3Array=data[Mesh.ARRAY_NORMAL]
 var indices: PackedInt32Array=data[Mesh.ARRAY_INDEX]
 var a:=indices[0];var b:=indices[1];var c:=indices[2]
 check((vertices[b]-vertices[a]).cross(vertices[c]-vertices[a]).dot(normals[a])<0,"Sculpted branches have correct clockwise winding and outward normals")
 var planet:=SpaceEnvironmentArt.planet(model,Vector3.ZERO,20,Color(.1,.3,.2),2,true)
 check(planet.get_node("PlanetaryRing").mesh is ArrayMesh,"Planetary rings are layered annular meshes rather than tubes")
 check(planet.get_node("TerrainGlobe").visibility_range_end==200,"Distant planets are culled before becoming tiny marbles")
 var tree:=FoliageArt.build(model,"vampire",Vector3.ZERO,Color(.5,.1,.2),Color.RED,0)
 check(tree.find_children("","MultiMeshInstance3D",true,false).size()>0,"Tree canopies use shaped instanced foliage")
 var wreck:=Node3D.new();model.add_child(wreck);SceneryArt.wreck(wreck,Vector3(12,8,20))
 check(wreck.find_children("","MeshInstance3D",true,false).size()>4,"Wrecks contain hulls, ribs, armor plates and warning lamps")
 var main: Node=load("res://scenes/main.tscn").instantiate();main.profile_path="user://starlight-test.json";root.add_child(main);await process_frame
 main.start_free_roam(true);await process_frame
 var roam: FreeRoamMatch=main.battle
 roam.set_physics_process(false);roam.army.set_physics_process(false);roam.pilot.set_physics_process(false)
 for ship in roam.ships:ship.set_physics_process(false)
 var friendly:=true
 for ship in roam.ships:friendly=friendly and ship.team==0
 for unit in roam.army.units.values():friendly=friendly and unit.team==0
 check(roam.peaceful and friendly,"Peaceful exploration has no hostile ship or creature teams")
 roam._physics_process(70)
 check(roam.war.dispatches==0,"Peaceful exploration does not dispatch faction invasions")
 var ship:=roam.pilot.ship
 ship.position=roam.world.hazards[0].position;ship.set_meta("spawn_protection",0);ship.health.protection=1
 var hp:=ship.health.hull+ship.health.shield
 roam._physics_process(1)
 check(ship.health.hull+ship.health.shield==hp,"Ion scenery does not harm peaceful explorers")
 check(roam.safe_to_service(ship),"Harmless ion mist does not block peaceful warp")
 check(InputMap.has_action("scenic_hud"),"The scenic HUD action is configured")
 var action:=InputEventAction.new();action.action="scenic_hud";action.pressed=true
 roam._unhandled_input(action)
 check(roam.scenic_hud and not roam.hud.visible and not roam.info.get_parent().visible,"H hides flight HUD and instructions")
 check(not roam.army.labels[0].visible,"Scenic viewing hides floating world labels")
 roam._unhandled_input(action)
 check(not roam.scenic_hud and roam.hud.visible,"H restores the normal HUD")
 main.start_free_roam();await process_frame
 check(not main.battle.peaceful and main.battle.ships[3].team!=0,"Normal free roam retains its hostile factions")
 main.queue_free();model.queue_free();await process_frame;await process_frame
 print("STARLIGHT ART TEST: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)

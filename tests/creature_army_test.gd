extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
 checks+=1
 if value:print("PASS: "+message)
 else:failures+=1;push_error(message)
func run() -> void:
 var battle:=FreeRoamMatch.new();battle.profile=PlayerProfile.new();root.add_child(battle)
 battle.set_physics_process(false);battle.army.set_physics_process(false)
 for ship in battle.ships:ship.set_physics_process(false)
 var army:=battle.army
 check(army.units.is_empty() and army.worlds.size()==3,"Space outposts have no creature garrisons")
 check(army.spawn("bloodstag",0,1,Vector3.ZERO)==-1,"Direct authority spawning cannot create space creatures")
 check(army.deploy(1,battle.pilot.ship,0).contains("planets") and army.units.is_empty(),"Old deployment requests explain surface-only deployment")
 check(not army.command(1,battle.pilot.ship,"assault"),"Old space army commands are disabled")
 for ship in battle.ships:ship.position=Vector3(50000,0,0)
 var ship:=battle.pilot.ship;ship.position=army.worlds[0].position
 army.worlds[0].owner=2
 army.tick(31)
 check(army.worlds[0].owner==ship.team,"Ships can capture an unopposed outpost without creatures")
 battle.ships[3].team=2;battle.ships[3].position=army.worlds[1].position;ship.position=army.worlds[1].position
 army.worlds[1].owner=3;army.tick(31)
 check(army.worlds[1].owner==3,"Opposing ships contest outpost capture")
 battle.war.dispatch();check(army.units.is_empty(),"War raids spawn only ships")
 check(army.snapshot().units.is_empty(),"Online snapshots contain no creature combatants")
 battle.network_role="client";army.apply_snapshot({"units":[{"id":1,"species":"bloodstag"}],"worlds":army.worlds.duplicate(true)})
 check(army.units.is_empty(),"Client snapshots reject legacy creature payloads")
 battle.queue_free();await process_frame
 print("CREATURE ARMY TEST: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)

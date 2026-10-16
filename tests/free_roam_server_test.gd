# Controlled integration fixture: only this test script injects damage.
# Production clients have no RPC or HTTP route for client-authored damage.
extends SceneTree
var main: Node
var elapsed := 0.0
var stage := 0
var original_a := -1
var original_b := -1
var injected_at := 0.0
var gravity_seen := false
var travel_observed_at := 0.0
func _initialize() -> void: call_deferred("run")
func run() -> void:
 main = load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
func _process(delta: float) -> bool:
 elapsed += delta
 if elapsed > 55:
  push_error("ROAM_SERVER_TIMEOUT stage=%d" % stage);quit(1);return false
 if not is_instance_valid(main) or not main.network.arena is FreeRoamMatch: return false
 var session: OnlineSession = main.network
 var roam: FreeRoamMatch = session.arena
 if stage == 0 and session.loading_peers.is_empty():
  for index in range(6,roam.ships.size()): roam.ships[index].position += Vector3(0,3000,0)
  stage = 1
  print("ROAM_WORLD_READY")
 for index in range(roam.ships.size()):
  if session.slot_owners[index] == 0: roam.ships[index].set_physics_process(false)
 # Keep travel setup independent of random patrol shots/companion fire.
 if stage<2:
  for index in range(mini(6,roam.ships.size())):
   roam.ships[index].health.regen_delay=0
   if is_instance_valid(roam.ships[index].companion):roam.ships[index].companion.set_physics_process(false)
 if stage == 1 and session.members.size() == 2:
  var ids := session.members.keys()
  original_a = session._controlled_index(ids[0])
  original_b = session._controlled_index(ids[1])
  if roam.ships[original_a].position.distance_to(FreeRoamWorld.CENTERS[2]) < 250 and roam.ships[original_b].position.distance_to(FreeRoamWorld.CENTERS[6]) < 250:
   roam.ships[original_a].position = FreeRoamWorld.CENTERS[2] + Vector3(0,0,100)
   roam.ships[original_a].velocity = Vector3.ZERO
   roam.ships[original_a].health.regen_delay = 0
   roam.ships[original_a].health.hull -= 10
   stage = 2
   travel_observed_at=elapsed
   print("ROAM_DROP_IN_AND_WARP_PASS")
 # Leave enough snapshots for both clients to observe arrival before staged combat.
 if stage == 2 and elapsed-travel_observed_at>1.0 and roam.ships[original_a].health.hull == roam.ships[original_a].health.max_hull:
  var attacker: CombatShip = roam.ships[original_a]
  var npc: CombatShip = roam.ships[6]
  npc.position = attacker.position + Vector3(10,2,-40)
  npc.health.protection = 1
  npc.health.shield = 0
  npc.health.hull = 6
  if OS.get_environment("GD_TEST_COMPANION")=="crew_glimbloom":
   roam.ships[7].position = npc.position+Vector3(8,0,0)
   roam.ships[7].health.shield=0
   roam.ships[7].health.hull=20
   roam.ships[7].health.protection=1
  attacker.set_meta("spawn_protection",0.0)
  attacker.targeting.select(npc)
  attacker.companion.attack_cooldown = 0
  attacker.companion.set_physics_process(true)
  stage = 3
 if stage==3 and roam.ships[6].movement.slow_remaining>0:gravity_seen=true
 if stage == 3 and not roam.ships[6].alive:
  if OS.get_environment("GD_TEST_COMPANION")=="crew_orbitot" and not gravity_seen:
   push_error("Gravity Loop did not slow its target");quit(1);return false
  if OS.get_environment("GD_TEST_COMPANION")=="crew_glimbloom" and roam.ships[7].health.hull>=20:
   push_error("Prism Pulse did not splash its neighbor");quit(1);return false
  var attacker: CombatShip = roam.ships[original_a]
  if attacker.companion.attacks < 1:
   push_error("Companion did not fire");quit(1);return false
  print("ROAM_COMPANION_REAL_SHOT_PASS")
  roam.ships[original_b].health.protection = 1
  roam.ships[original_b].health.damage(100000,attacker)
  attacker.health.protection = 1
  attacker.health.damage(100000,null)
  injected_at = elapsed
  stage = 4
  print("ROAM_AUTHORITY_PVE_PVP_DAMAGE_PASS")
 if stage == 4 and elapsed-injected_at > 13:
  if roam.ships[original_a].alive and roam.ships[original_b].alive and roam.ships[6].alive and not roam.finished:
   stage = 5
   print("ROAM_SERVER_PASS: live join, authoritative travel, repair, companion attacks, PvE/PvP damage, respawn and continuous world")
 return false

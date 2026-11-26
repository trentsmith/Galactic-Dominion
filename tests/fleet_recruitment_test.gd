extends SceneTree
var checks := 0
var failures := 0
var main: Node

func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
 checks += 1
 if value: print("PASS: " + message)
 else:
  failures += 1
  push_error("FAIL: " + message)

func fixture() -> Dictionary:
 var data := {"user_id":"fixture", "commander_name":"Admiral", "salvage":1000,"wins":0,"battles":0,
  "inventory":{},"fleet_roster":[],"active_ships":[],"battle_fleet":[],"ship_classes":[],"loadouts":[]}
 for item in CollectionCatalog.DEFINITIONS:
  data.inventory[item.id] = {"count":1}
 var classes := CollectionCatalog.SHIP_TYPES.keys()
 for index in range(51):
  var fitting := {"engine":"engine_sprint" if index==49 else "engine_standard","shield":"shield_standard", "weapon":"weapon_standard", "utility":"utility_standard", "crew":"", "variant":"variant_nexus_eldritch" if index==49 else "variant_standard"}
  var ship := {"id":"ship-%d"%index,"name":"Vessel %02d"%index,"hull":classes[index%classes.size()],"loadout":fitting}
  data.fleet_roster.append(ship)
  if index<50:data.battle_fleet.append(ship.id)
  if index<3:
   data.active_ships.append(ship.id);data.ship_classes.append(ship.hull);data.loadouts.append(fitting.duplicate())
 return data

func run() -> void:
 main = load("res://scenes/main.tscn").instantiate()
 main.profile_path = "user://fleet-test.json"
 root.add_child(main)
 await process_frame
 main.network.set_physics_process(false)
 var data := fixture()
 main.online_api.account = data
 main.show_online()
 await process_frame
 var hub: OnlineHub = main.menu.find_children("", "OnlineHub", true, false)[0] if not main.menu.find_children("", "OnlineHub", true, false).is_empty() else null
 # Script classes do not appear as native node types in find_children.
 if hub == null:
  for node in main.menu.get_children():
   if node is OnlineHub: hub = node
 check(hub != null, "Recruitment is reachable through the existing Online menu")
 if hub == null: quit(1);return
 check(hub.battle_roster.item_count==51 and hub.hull_choice.item_count==51, "All owned ships are selectable without cloning hull classes")
 check(hub.battle_count.text.contains("50 OF 50") and hub.battle_count.text.contains("1 IN RESERVE"), "Deployment count distinguishes the fifty-ship lineup from reserves")
 hub.battle_roster.select(49);hub._update_vessel()
 check(hub.vessel_details.text.contains("Vessel 49") and hub.vessel_details.text.contains("LASER") and hub.vessel_details.text.contains("MISSILE"), "Every wingmate exposes its actual configured stats")
 var vessel: Dictionary = data.fleet_roster[49]
 var configured := FleetManifest.vessel_stats(data,vessel)
 var base: ShipStats = CollectionCatalog.SHIP_TYPES[vessel.hull]
 check(configured.speed>base.speed and configured.variant_style=="nexus_eldritch", "Reserve ship stats apply owned components and appearance")
 check(hub.vessel_item.get_item_metadata(hub.vessel_item.selected)==vessel.loadout.engine,"Fitting selector displays the ship’s currently installed component")
 check(FleetManifest.battle_vessels(data).size()==50, "The manifest contains exactly the selected ships")
 var states: Array = []
 for i in range(100):
  states.append({"position":Vector3(i*10,2,-30),"rotation":Quaternion(Vector3.UP,.3),"velocity":Vector3(1,2,-60),"hull":77.5,"shield":40.25,"boost":63.,"boosting":true,"boost_recovering":true,"alive":i!=99,"laser":.15,"missile":2.,"ability":3.,"recharge":4.,"target":99,"lock":1.2,"flash":.1,"taken":Vector3(10,20,3)})
 var decoded := FleetSnapshotCodec.decode_states(FleetSnapshotCodec.encode_states(states,96,8))
 check(decoded.size()==4 and decoded[3].position==states[99].position and not decoded[3].alive, "Partial final packet preserves the hundredth ship")
 check(decoded[0].boost_recovering and decoded[0].taken==Vector3(10,20,3) and decoded[0].target==99, "Packed snapshots preserve health feedback, boost and targeting")
 var controls := PackedInt32Array([2147483646,0,2147483645,50])
 var payload := ["receive_fleet_snapshot",92,FleetSnapshotCodec.encode_states(states,0,8),controls,480.,1800.,"MISSILE OUT OF RANGE / APPROACH WITHIN 600m"]
 check(var_to_bytes(payload).size()<1150,"Eight-ship packet stays below the transport budget including pilot lock text")
 var bullet := {"position":Vector3(1,2,3),"direction":Vector3.FORWARD,"team":1,"target":99,"missile":true,"companion":true,"color":Color(.1,.8,.4,1),"style":"gravity_loop","speed":240.}
 var bullets: Array = []
 for i in range(12):bullets.append(bullet)
 var packed_bullets := FleetSnapshotCodec.encode_bullets(bullets)
 var restored := FleetSnapshotCodec.decode_bullets(packed_bullets)
 check(restored.size()==12 and restored[0].target==99 and restored[0].style=="gravity_loop" and restored[0].speed==240., "Missile and companion presentation survive packed transport")
 check(var_to_bytes(["receive_fleet_projectiles",PackedInt64Array(range(12)),packed_bullets]).size()<1100,"Projectile batches fit within the transport budget")
 var arena := BattleMatch.new()
 arena.network_role="client";arena.fleet_duel=true;arena.team_size=50;arena.enemy_team_size=50;arena.name="Arena"
 for team in range(2):
  for ship in FleetManifest.battle_vessels(data): arena.preconfigured_stats.append(FleetManifest.vessel_stats(data,ship))
 main.network.add_child(arena)
 main.network.arena=arena;main.network.match_mode="fleet_duel";main.network.peer_id=8
 main.network.slot_owners.resize(100);main.network.slot_owners.fill(0);main.network.slot_owners[50]=8
 main.network._choose_client_ship()
 check(arena.ships.size()==100 and arena.living(0)==50 and arena.living(1)==50,"Network duel spawns the full 50 versus 50")
 check(arena.mode_name()=="FLEET DUEL 50v50" and arena.fleet.ships.size()==50 and arena.local_team()==1,"Team-two commander sees their own fifty-ship fleet")
 check(arena.ships[99].stats.variant_style=="nexus_eldritch" and is_equal_approx(arena.ships[99].stats.speed,configured.speed),"Opponent fittings and visuals are preserved without faction overrides")
 check(main.network.fleet_span(99)==Vector2i(50,100),"Switching bounds cover every friendly ship and exclude the opponent")
 main.network.receive_fleet_snapshot(96,FleetSnapshotCodec.encode_states(states,96,8),PackedInt32Array([7,0,8,99]),35.,1700.,"KEEP TARGET AHEAD TO LOCK")
 check(arena.pilot.ship==arena.ships[99] and main.network.desired_states[99].target==99,"Batched ownership transfers control into the final vessel")
 # Use a living state for the controlled ship, then exercise results separately.
 check(arena.ships[99].health.dead and arena.ships[99].health.hull==77.5,"Batched health state reaches a ship beyond the old six-slot limit")
 var painter := HUDPainter.new();painter.battle=arena
 check(painter.can_cycle_fleet() and painter.fleet_binding(49,arena.ships[99])=="50","HUD advertises survivor cycling and the correct large-fleet slot")
 painter.free()
 main.network.fleet_commanders.assign([7,8]);main.network.metrics={7:{"kills":0.,"damage":0.},8:{"kills":0.,"damage":0.}}
 main.network.ship_totals.resize(100);main.network.ship_totals.fill(Vector2.ZERO)
 arena.ships[98].kills=4;arena.ships[98].damage_dealt=425
 main.network._collect_metrics();main.network._collect_metrics()
 check(main.network.metrics[8].kills==4 and main.network.metrics[8].damage==425 and main.network.metrics[7].kills==0,"Wingmate combat credit reaches its commander exactly once")
 main.queue_free()
 await process_frame
 print("FLEET_RECRUITMENT_TEST: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)

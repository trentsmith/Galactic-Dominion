extends SceneTree
var main: Node
var clock:=0.0
var launched:=false
var seen:=false
var origin:=Vector3.ZERO
var switch_sent:=false
var last_seen:=false
var returned:=false
var moved:=false
var feedback_seen:=false
var finishing:=false
var leaving:=false
var role:=""
func _initialize() -> void:call_deferred("run")
func run() -> void:
 role=OS.get_environment("GD_TEST_USER")
 main=load("res://scenes/main.tscn").instantiate();main.profile_path="user://duel-"+role+".json";root.add_child(main)
 await process_frame
 main.online_api.base_url=OS.get_environment("GD_API_URL")
 var reply: Dictionary=await main.online_api.sign_in(role,"fleet-duel-password")
 if reply.has("error"):push_error(str(reply));quit(1);return
 main.network.lobby_changed.connect(_lobby)
 await main.network.join_server("127.0.0.1",int(OS.get_environment("GD_TEST_PORT")))
func _lobby(data: Dictionary) -> void:
 print("DUEL_LOBBY_READY ",role)
 var ready:=false
 var all_ready: bool=data.players.size()==2
 for p in data.players:
  if p.peer==main.network.peer_id:ready=p.ready
  all_ready=all_ready and p.ready
 if not ready and not launched:main.network.ready_up.rpc_id(1,true)
 if all_ready and data.leader==main.network.peer_id and not launched:
  launched=true;main.network.request_start.rpc_id(1,"fleet_duel")
func _process(delta: float) -> bool:
 clock+=delta
 if clock>50:push_error("DUEL_CLIENT_TIMEOUT "+role);quit(1);return false
 if leaving or not is_instance_valid(main) or not is_instance_valid(main.network.arena):return false
 var arena: BattleMatch=main.network.arena
 var left:=int(OS.get_environment("GD_TEST_DUEL_LEFT"))
 var right:=int(OS.get_environment("GD_TEST_DUEL_RIGHT"))
 var count:=left if role=="Admiral_A" else right
 var base:=0 if role=="Admiral_A" else left
 if not seen:
  seen=true
  if not arena.fleet_duel or arena.ships.size()!=left+right or arena.fleet.ships.size()!=count:
   push_error("DUEL_CLIENT_MANIFEST_COUNT "+role);quit(1);return false
  var vessels:=FleetManifest.battle_vessels(main.online_api.account)
  for i in range(vessels.size()):
   var expected:=FleetManifest.vessel_stats(main.online_api.account,vessels[i])
   if not is_equal_approx(arena.ships[base+i].stats.speed,expected.speed) or not is_equal_approx(arena.ships[base+i].stats.laser_damage,expected.laser_damage) or arena.ships[base+i].stats.variant_style!=expected.variant_style:
    push_error("DUEL_CLIENT_FITTING_MISMATCH "+role);quit(1);return false
  origin=arena.pilot.ship.position
  main.network.input_provider=func():return {"thrust":Vector3(0,0,-1),"steering":Vector2.ZERO,"roll":0.,"boost":false,"laser":false}
  print("DUEL_CLIENT_MANIFEST_PASS ",role," · ",count," fitted vessels")
 if arena.ships[base].position.distance_to(origin)>3:moved=true
 if arena.ships[base].health.damage_sequence>0:feedback_seen=true
 if OS.get_environment("GD_TEST_DUEL_PACKAGED")=="1":
  for ship in arena.ships:
   if ship.health.shield_damage+ship.health.hull_damage>0:feedback_seen=true
 if arena.elapsed>1 and moved and not switch_sent:
  switch_sent=true
  main.network.ship_event.rpc_id(1,"switch",count-1)
  main.network.ship_event.rpc_id(1,"switch",count) # Must not take the opposing fleet.
 if main.network._controlled_index(main.network.peer_id)==base+count-1:
  last_seen=true
 if last_seen and arena.elapsed>2 and not returned:
  returned=true;main.network.ship_event.rpc_id(1,"switch",0)
 if OS.get_environment("GD_TEST_DUEL_FORFEIT")=="1" and role=="Admiral_B" and arena.elapsed>3 and last_seen:
  leaving=true;depart();return false
 if arena.finished and not finishing:
  finishing=true;complete()
 return false
func depart() -> void:
 main.network.disconnect_session()
 await create_timer(.7).timeout
 await wait_for_reward()
func complete() -> void:
 if OS.get_environment("GD_TEST_DUEL_PACKAGED")!="1" and main.network.arena.winner!=0:push_error("DUEL_CLIENT_WRONG_WINNER");quit(1);return
 await wait_for_reward()
func wait_for_reward() -> void:
 var deadline:=Time.get_ticks_msec()+15000
 while Time.get_ticks_msec()<deadline:
  var reply: Dictionary=await main.online_api.refresh()
  if reply.has("data") and int(main.online_api.account.battles)==1:
   if not moved or not last_seen or not returned or not feedback_seen:
    push_error("DUEL_CLIENT_CONTROLS: moved=%s last=%s returned=%s feedback=%s"%[moved,last_seen,returned,feedback_seen]);quit(1);return
   print("DUEL_CLIENT_PASS: ",role," / fitted fleet, batched motion/health, last-ship takeover, opponent ownership and permanent settlement")
   if not leaving:
    main.network.disconnect_session();await create_timer(.7).timeout
   main.queue_free();await process_frame;quit(0);return
  await create_timer(.25).timeout
 push_error("DUEL_CLIENT_REWARD_TIMEOUT");quit(1)

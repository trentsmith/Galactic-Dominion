extends SceneTree
class RecordingAPI extends OnlineAPI:
 signal release
 var packets: Array[Dictionary]=[]
 var hold:=false
 var fail_first:=false
 var contract_calls:=0
 func request(path: String,data: Dictionary={},_method: int=HTTPClient.METHOD_POST,_key: String="") -> Dictionary:
  packets.append({"path":path,"data":data.duplicate(true)})
  if path=="/server/roam/contract":
   contract_calls+=1
   if hold:await release
   if fail_first and contract_calls==1:return {"error":"Simulated unavailable response"}
  return {"data":{}}
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,words: String) -> void:
 checks+=1
 if ok:print("PASS: "+words)
 else:failures+=1;print("FAIL: "+words)
func frames() -> void:await process_frame;await physics_frame;await process_frame
func freeze(roam: FreeRoamMatch) -> void:
 roam.set_physics_process(false);roam.frontier.set_physics_process(false)
 for ship in roam.ships:
  ship.set_physics_process(false)
  if ship.companion!=null:ship.companion.set_physics_process(false)
func run() -> void:
 var main: Node=load("res://scenes/main.tscn").instantiate();main.profile_path="user://settlement-%d.json"%Time.get_ticks_usec();root.add_child(main);await frames()
 var session: OnlineSession=main.network;session.set_physics_process(false);session.server_mode=true;session.match_mode="co_op";session.match_id="settlement-test"
 var api:=RecordingAPI.new();main.add_child(api);session.api=api
 var roam:=FreeRoamMatch.new();roam.network_role="server";roam.cooperative=true
 for i in range(6):roam.preconfigured_stats.append(BattleMatch.CLASSES[i%3])
 session.add_child(roam);session.arena=roam;roam.frontier.shared_completed.connect(session._frontier_completed);roam.ended.connect(session._server_finished);freeze(roam)
 session.members={11:{"profile":{"user_id":"A"},"index":0},22:{"profile":{"user_id":"B"},"index":3}}
 session.slot_owners=[11,0,0,22,0,0]
 for ship in roam.ships:ship.position=Vector3(40000,40000,40000);ship.player_controlled=false
 roam.ships[0].player_controlled=true;roam.ships[3].player_controlled=true;roam.ships[0].position=Vector3(0,5000,0)
 roam.frontier.start_shared("repair",roam.ships[0]);await frames();roam.frontier.contribute(roam.ships[0])
 check(roam.frontier.contributors==["A"],"Shared participation records account identity rather than a mutable ship index")
 session.members.erase(11);session.members[33]={"profile":{"user_id":"C"},"index":0};session.slot_owners[0]=33
 roam.ships[0].position=roam.frontier.point.position+Vector3(700,0,0);roam.ships[3].position=roam.frontier.point.position+Vector3(0,0,40)
 roam.frontier.contribute(roam.ships[3]);roam.frontier.completed=true;roam.frontier.finish_reward()
 check(api.packets.size()==1 and api.packets[0].data.participants==["B"],"A replacement pilot does not inherit the departing pilot's contribution or a distant proximity reward")
 check(roam.frontier.active.is_empty(),"A successful saved contract closes the shared job")
 api.packets.clear();api.contract_calls=0;api.hold=true;api.fail_first=true
 session.members={11:{"profile":{"user_id":"A"},"index":0},22:{"profile":{"user_id":"B"},"index":3}};session.slot_owners=[11,0,0,22,0,0]
 roam.ships[0].position=Vector3(0,6000,0);roam.ships[0].player_controlled=true;roam.ships[3].player_controlled=true
 roam.frontier.start_shared("repair",roam.ships[0]);await frames();roam.ships[0].position=roam.frontier.point.position+Vector3(0,0,40);roam.ships[3].position=roam.frontier.point.position+Vector3(30,0,40)
 roam.frontier.contribute(roam.ships[0]);roam.frontier.contribute(roam.ships[3]);roam.frontier.completed=true;roam.frontier.finish_reward()
 check(session.contract_busy and api.packets.size()==1,"A pending account response retains the exact reward request")
 session._peer_disconnected(22);session._peer_disconnected(11);freeze(roam)
 check(session.deferred_roam_leaves.size()==2 and session.pending_roam_ends.size()==1 and api.packets.size()==1,"Participant disconnects defer leave and session closure until rewards settle")
 check(roam.finished,"A world can finish while its final reward remains pending")
 api.hold=false;api.release.emit();await frames()
 check(not session.contract_payload.is_empty() and session.contract_retry>0 and api.packets.size()==1,"An unavailable reply schedules a retry without losing accounts or closing their session")
 session._physics_process(5.1);await frames()
 check(api.contract_calls==2 and session.contract_payload.is_empty(),"Reward retries continue after the arena has finished")
 var paths:=api.packets.map(func(packet):return packet.path)
 check(paths==["/server/roam/contract","/server/roam/contract","/server/roam/leave","/server/roam/leave","/server/roam/end"],"Both participant departures and session closure follow successful reward settlement")
 check(session.deferred_roam_leaves.is_empty() and session.pending_roam_ends.is_empty() and not session.settlement_busy,"Settlement drains all pending work before another match can launch")
 main.queue_free();await frames();print("COOP_SETTLEMENT_TEST: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)

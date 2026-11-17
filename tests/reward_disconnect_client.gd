extends "res://tests/frontier_network_client.gd"
var departing:=false
func _process(delta: float) -> bool:
 var result:=super._process(delta)
 if role=="Coop_B" and not departing and is_instance_valid(main) and main.network.arena is FreeRoamMatch:
  if main.network.arena.frontier.completed:
   departing=true;call_deferred("leave_during_settlement")
 return result
func leave_during_settlement() -> void:
 Input.action_release("frontier_use");main.network.disconnect_session()
 await create_timer(.7).timeout
 print("COOP_EARLY_LEAVE_PASS: disconnected while the account response was pending")
 main.queue_free();await process_frame;quit(0)

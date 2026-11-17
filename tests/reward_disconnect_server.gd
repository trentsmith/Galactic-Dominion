extends "res://tests/frontier_network_server.gd"
func _process(delta: float) -> bool:
 var result:=super._process(delta)
 if stage==2 and is_instance_valid(main) and main.network.arena is FreeRoamMatch:
  if main.network.arena.frontier.active.is_empty() and main.network.contract_payload.is_empty():
   print("COOP_SERVER_PASS: disconnected participant and retry settled once");stage=3
 return result

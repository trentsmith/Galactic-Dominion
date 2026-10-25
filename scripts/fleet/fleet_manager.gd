class_name FleetManager
extends Node
signal control_changed(ship)
signal command_changed(command)

var ships: Array[CombatShip] = []
var pilot: PlayerPilot
var current_command := "follow"

func _unhandled_input(event: InputEvent) -> void:
 if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
  return
 for slot in range(mini(ships.size(), 10)):
  if event.is_action_pressed("ship_%d" % (slot + 1)):
   switch_to(slot)
 if ships.size()>10:
  if event.is_action_pressed("fleet_next"):cycle_control(1)
  elif event.is_action_pressed("fleet_previous"):cycle_control(-1)
 var commands := ["follow", "attack", "defend", "regroup", "retreat"]
 for index in range(commands.size()):
  if event.is_action_pressed("command_%d" % (index + 1)):
   issue_command(commands[index])

func switch_to(slot: int) -> bool:
 if slot < 0 or slot >= ships.size() or not ships[slot].alive:
  return false
 if is_instance_valid(pilot.ship) and pilot.ship!=ships[slot]:pilot.ship.demote_visual()
 ships[slot].promote_visual()
 pilot.take_control(ships[slot])
 for ship in ships:
  ship.brain.leader = ships[slot]
 control_changed.emit(ships[slot])
 return true

func issue_command(command: String) -> void:
 current_command = command
 for ship in ships:
  ship.brain.command = command
  ship.brain.commanded_target = pilot.ship.targeting.target if is_instance_valid(pilot.ship) else null
 command_changed.emit(command)

func on_eliminated(ship: CombatShip, _attacker: CombatShip) -> void:
 if pilot.ship == ship:
  for candidate in ships:
   if candidate.alive:
    switch_to(candidate.fleet_slot)
    return

func living_count() -> int:
 var count := 0
 for ship in ships:
  if ship.alive:
   count += 1
 return count

func cycle_control(direction: int) -> bool:
 if not is_instance_valid(pilot.ship) or ships.is_empty():return false
 var start:=ships.find(pilot.ship)
 for offset in range(1,ships.size()+1):
  var index:=posmod(start+offset*direction,ships.size())
  if ships[index].alive:return switch_to(index)
 return false

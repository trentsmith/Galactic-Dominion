class_name BattleSpatialIndex
extends RefCounted
## One shared, conservative broad phase replaces repeated whole-fleet scans.
const CELL:=600.0
var cells: Dictionary={}
var generation:=0
func rebuild(ships: Array[CombatShip]) -> void:
 cells.clear();generation+=1
 for ship in ships:
  if not ship.alive:continue
  var key:=cell(ship.position)
  if not cells.has(key):cells[key]=[]
  cells[key].append(ship)
func cell(at: Vector3) -> Vector3i:
 return Vector3i(floori(at.x/CELL),floori(at.y/CELL),floori(at.z/CELL))
func nearby(at: Vector3,radius: float) -> Array[CombatShip]:
 var result: Array[CombatShip]=[]
 # Extra margin covers movement between 10 Hz rebuilds; exact tests follow.
 var reach:=radius+80.0
 var low:=cell(at-Vector3.ONE*reach);var high:=cell(at+Vector3.ONE*reach)
 for x in range(low.x,high.x+1):
  for y in range(low.y,high.y+1):
   for z in range(low.z,high.z+1):
    for ship in cells.get(Vector3i(x,y,z),[]):
     if is_instance_valid(ship) and ship.alive:result.append(ship)
 return result

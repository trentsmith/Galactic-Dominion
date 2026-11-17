class_name ShipTargeting
extends Node

var ship: CombatShip
var target: CombatShip
var lock_time := 0.0
var lock_duration:=1.2
var selection_range := INF
var enforce_range:=false
const LOCK_RANGE:=600.0
const LOCK_DOT:=0.90
var lock_reason:=""
var sight_clock:=0.0
var sight_clear:=false
var cycle_age:=10.0
var cycle_order: Array[CombatShip]=[]

func valid_enemy(candidate: Variant) -> bool:
 return is_instance_valid(candidate) and candidate is CombatShip and candidate!=ship and candidate.alive and candidate.team!=ship.team and candidate.get_parent()==ship.get_parent()

func muzzle_position() -> Vector3:
 return ship.global_position-ship.global_basis.z*5.0

func clear_line(point: Vector3,candidate: CombatShip=null) -> bool:
 if not ship.is_inside_tree():return false
 var query:=PhysicsRayQueryParameters3D.create(muzzle_position(),point,3)
 var excluded: Array[RID]=[ship.get_rid()]
 if is_instance_valid(candidate):excluded.append(candidate.get_rid())
 query.exclude=excluded
 var hit:=ship.get_world_3d().direct_space_state.intersect_ray(query)
 return hit.is_empty() or (is_instance_valid(candidate) and candidate.is_ancestor_of(hit.collider))

func geometry_refusal() -> String:
 if not valid_enemy(target):return "SELECT A TARGET TO LOCK"
 if ship.global_position.distance_to(target.global_position)>=LOCK_RANGE:return "MISSILE OUT OF RANGE / APPROACH WITHIN 600m"
 if (-ship.global_basis.z).dot(ship.global_position.direction_to(target.global_position))<=LOCK_DOT:return "KEEP TARGET AHEAD TO LOCK"
 return ""

func update_gate(force: bool=false) -> String:
 var reason:=geometry_refusal()
 if reason.is_empty():
  if force or sight_clock<=0:
   sight_clear=clear_line(target.global_position,target);sight_clock=.12
  if not sight_clear:reason="TARGET OBSCURED / MOVE AROUND COVER"
 lock_reason=reason
 return reason

func missile_refusal() -> String:
 var reason:=update_gate(true)
 if not reason.is_empty():return reason
 return "KEEP TARGET AHEAD TO LOCK" if lock_time<lock_duration else ""

func tick(delta: float) -> void:
 cycle_age+=delta;sight_clock-=delta
 if not valid_enemy(target):
  select(null)
  return
 if enforce_range and ship.position.distance_squared_to(target.position)>selection_range*selection_range:
  select(null);return
 if update_gate().is_empty():
  lock_time = minf(lock_duration, lock_time + delta)
 else:
  lock_time = maxf(0.0, lock_time - delta * 2.0)

func locked() -> bool:
 return lock_time>=lock_duration and lock_reason.is_empty() and geometry_refusal().is_empty()

func select(candidate: CombatShip) -> void:
 if not valid_enemy(candidate):candidate=null
 if target != candidate:
  target = candidate
  lock_time = 0.0;sight_clock=0;sight_clear=false;lock_reason=""
 if target==null:lock_time=0;lock_reason="SELECT A TARGET TO LOCK"

func acquisition_score(candidate: CombatShip) -> float:
 var offset:=candidate.global_position-ship.global_position
 return (1.0-(-ship.global_basis.z).dot(offset.normalized()))*3.0+minf(offset.length()/2000.0,2.0)*.15

func cycle() -> void:
 # Keep quick repeated presses stable while reacquiring by aim after a pause.
 cycle_order=cycle_order.filter(func(candidate):return valid_enemy(candidate) and ship.global_position.distance_to(candidate.global_position)<=selection_range)
 if cycle_age>2.0 or cycle_order.is_empty() or not target in cycle_order:
  cycle_order.clear()
  for node in get_tree().get_nodes_in_group("ships"):
   if node is CombatShip and valid_enemy(node) and ship.global_position.distance_to(node.global_position)<=selection_range:cycle_order.append(node)
  cycle_order.sort_custom(func(a,b):
   var first:=acquisition_score(a);var second:=acquisition_score(b)
   return first<second if not is_equal_approx(first,second) else a.get_instance_id()<b.get_instance_id())
  if not cycle_order.is_empty() and cycle_order[0]!=target:
   select(cycle_order[0]);cycle_age=0;return
 cycle_age=0
 if cycle_order.is_empty():
  select(null)
  return
 var index:=cycle_order.find(target)
 select(cycle_order[(index+1)%cycle_order.size()])

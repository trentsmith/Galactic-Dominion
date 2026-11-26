class_name FleetSnapshotCodec
extends RefCounted
## Fixed-size presentation packets. Eight ships fit below a 1,200-byte budget;
## snapshots are disposable, while spawn/results/ownership use reliable RPCs.
const STATE_FLOATS := 24
const CHUNK_SHIPS := 8
const BULLET_FLOATS := 15
const CHUNK_BULLETS := 12
const STYLES := ["", "gravity_loop", "prism_pulse"]

static func encode_states(states: Array, start: int, count: int) -> PackedFloat32Array:
 var packed := PackedFloat32Array()
 for index in range(start, mini(start + count, states.size())):
  var s: Dictionary = states[index]
  var p: Vector3 = s.position
  var q: Quaternion = s.rotation
  var v: Vector3 = s.velocity
  var t: Vector3 = s.get("taken", Vector3.ZERO)
  var flags := int(s.alive) | (int(s.boosting) << 1) | (int(s.get("boost_recovering", false)) << 2)
  packed.append_array(PackedFloat32Array([p.x, p.y, p.z, q.x, q.y, q.z, q.w, v.x, v.y, v.z,
   s.hull, s.shield, s.boost, s.laser, s.missile, s.ability, s.recharge, s.lock, s.flash,
   t.x, t.y, t.z, s.target, flags]))
 return packed

static func decode_states(packed: PackedFloat32Array) -> Array[Dictionary]:
 var result: Array[Dictionary] = []
 if packed.size() % STATE_FLOATS != 0: return result
 for offset in range(0, packed.size(), STATE_FLOATS):
  var flags := int(packed[offset + 23])
  result.append({"position": Vector3(packed[offset], packed[offset+1], packed[offset+2]),
   "rotation": Quaternion(packed[offset+3], packed[offset+4], packed[offset+5], packed[offset+6]).normalized(),
   "velocity": Vector3(packed[offset+7], packed[offset+8], packed[offset+9]),
   "hull": packed[offset+10], "shield": packed[offset+11], "boost": packed[offset+12],
   "laser": packed[offset+13], "missile": packed[offset+14], "ability": packed[offset+15],
   "recharge": packed[offset+16], "lock": packed[offset+17], "flash": packed[offset+18],
   "taken": Vector3(packed[offset+19], packed[offset+20], packed[offset+21]),
   "target": int(packed[offset+22]), "alive": (flags & 1) != 0,
   "boosting": (flags & 2) != 0, "boost_recovering": (flags & 4) != 0})
 return result

static func encode_bullets(bullets: Array) -> PackedFloat32Array:
 var packed := PackedFloat32Array()
 for b in bullets:
  var p: Vector3 = b.position
  var d: Vector3 = b.direction
  var c: Color = b.get("color", Color.TRANSPARENT)
  var flags := int(b.missile) | (int(b.get("companion", false)) << 1)
  packed.append_array(PackedFloat32Array([p.x,p.y,p.z,d.x,d.y,d.z,b.team,b.get("target",-1),
   b.get("speed",125.0),c.r,c.g,c.b,c.a,flags,maxi(0,STYLES.find(str(b.get("style",""))))]))
 return packed

static func decode_bullets(packed: PackedFloat32Array) -> Array[Dictionary]:
 var result: Array[Dictionary] = []
 if packed.size() % BULLET_FLOATS != 0: return result
 for o in range(0, packed.size(), BULLET_FLOATS):
  var flags := int(packed[o+13])
  result.append({"position":Vector3(packed[o],packed[o+1],packed[o+2]),
   "direction":Vector3(packed[o+3],packed[o+4],packed[o+5]),"team":int(packed[o+6]),
   "target":int(packed[o+7]),"speed":packed[o+8],"color":Color(packed[o+9],packed[o+10],packed[o+11],packed[o+12]),
   "missile":(flags & 1)!=0,"companion":(flags & 2)!=0,"style":STYLES[clampi(int(packed[o+14]),0,STYLES.size()-1)]})
 return result

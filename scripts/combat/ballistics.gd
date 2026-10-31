class_name Ballistics
extends RefCounted
## Projectiles do not inherit shooter velocity: solve |relative + target_velocity*t| = speed*t.
static func intercept_time(relative: Vector3,velocity: Vector3,speed: float,max_time: float=INF) -> float:
 if speed<=0:return -1
 var a:=velocity.length_squared()-speed*speed
 var b:=2*relative.dot(velocity)
 var c:=relative.length_squared()
 if c<.000001:return 0
 var time: float=-1
 if absf(a)<.000001:
  if absf(b)>.000001:time=-c/b
 else:
  var discriminant:=b*b-4*a*c
  if discriminant<0:return -1
  var root:=sqrt(discriminant)
  var first:=(-b-root)/(2*a);var second:=(-b+root)/(2*a)
  if first>0:time=first
  if second>0 and (time<0 or second<time):time=second
 return time if time>=0 and time<=max_time else -1
static func aim_point(origin: Vector3,position: Vector3,velocity: Vector3,speed: float,lifetime: float) -> Vector3:
 var time:=intercept_time(position-origin,velocity,speed,lifetime)
 return position+velocity*maxf(0,time)

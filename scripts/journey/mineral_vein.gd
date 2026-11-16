class_name MineralVein
extends StaticBody3D
var field: MiningField
var slot:=0
var generation:=0
var material_id:="ore"
var health:=30.0
var label: Label3D
var tint:=Color(1,.62,.2)
func title() -> String:return {"ore":"Ferric ore vein","crystal":"Prismatic crystal vein","alloy":"Ancient alloy seam"}[material_id]
func _ready() -> void:
 collision_layer=2;collision_mask=0
 tint={"ore":Color(1,.63,.2),"crystal":Color(.3,.85,1),"alloy":Color(.6,.95,.65)}[material_id]
 var collision:=CollisionShape3D.new();var shape:=SphereShape3D.new();shape.radius=7;collision.shape=shape;add_child(collision)
 var rock:=SphereMesh.new();rock.radius=7;rock.height=13;rock.radial_segments=9;rock.rings=5
 SpaceModelFactory.mesh(self,rock,Vector3.ZERO,Color(.17,.22,.26),"ResourceAsteroid")
 var rng:=RandomNumberGenerator.new();rng.seed=slot+generation*121
 for i in range(6):
  var shard:=PrismMesh.new();shard.size=Vector3(1.8,3.5,1.8)
  var offset:=Vector3(rng.randf_range(-5,5),rng.randf_range(-5,5),rng.randf_range(-5,5)).normalized()*6.5
  var mesh:=SpaceModelFactory.mesh(self,shard,offset,tint,"MineralCrystal",true);mesh.rotation=offset.normalized()*1.8
 label=Label3D.new();label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.position.y=11;label.pixel_size=.035;label.visibility_range_end=700;label.modulate=tint;add_child(label);refresh_label()
func refresh_label() -> void:
 label.text=title()+"\n"+("F: COLLECT WITHIN 75m" if health<=0 else "LASER TO FRACTURE / %d%%"%int(health/30*100))
func strike(amount: float,attacker: CombatShip) -> bool:
 if not is_instance_valid(attacker) or not attacker.player_controlled or not attacker in field.battle.fleet.ships or field.battle.network_role!="offline" or not visible:return false
 health=maxf(0,health-maxf(0,amount));refresh_label();SpaceEffects.burst(get_parent(),global_position,tint,1.3);return true

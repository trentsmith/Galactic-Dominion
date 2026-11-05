class_name NexusFaction
extends RefCounted
static func configure(stats: ShipStats,mission: String,slot: int) -> void:
 var eldritch:=mission=="nexus_abyss" or (mission=="nexus_warfront" and slot%2==1)
 stats.variant_style="nexus_eldritch" if eldritch else "nexus_crimson"
 stats.variant_name="Dreaming Abyss Living Hull" if eldritch else "Bloodforged War Hull"
 if not mission.begins_with("nexus_"):return
 if eldritch:
  stats.speed*=1.12;stats.hull*=.9;stats.shield*=.8;stats.shield_regen*=1.4
 else:
  stats.speed*=.92;stats.hull*=1.08;stats.shield*=.85;stats.laser_damage*=1.12

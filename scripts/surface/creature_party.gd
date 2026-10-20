class_name CreatureParty
extends Node3D
## Expedition-local combat state; never removes sanctuary ownership on fainting.
const PARTY_CAP:=3
var expedition: PlanetExpedition
var selected_id:=0
var units: Dictionary={}
var exhausted: Dictionary={}
var health_memory: Dictionary={}
var ability_memory: Dictionary={}
var target: SurfaceFauna
func residents() -> Array:
 return expedition.profile.sanctuary.residents
func selected() -> Dictionary:
 for resident in residents():
  if int(resident.id)==selected_id:return resident
 return {}
func cycle() -> void:
 var choices:=residents()
 if choices.is_empty():return
 var index:=-1
 for i in range(choices.size()):
  if int(choices[i].id)==selected_id:index=i
 selected_id=int(choices[(index+1)%choices.size()].id)
 expedition.status_message="CREATURE SELECTED / "+str(selected().name)
func deploy(id: int=-1) -> bool:
 if expedition.finished or not expedition.bot.alive:return false
 if id>=0:selected_id=id
 if selected().is_empty():
  if id>=0:return false
  cycle()
 var resident:=selected()
 if resident.is_empty():expedition.status_message="Capture and deliver a creature to your sanctuary first.";return false
 var key:=int(resident.id)
 if units.has(key):expedition.status_message="This creature is already deployed.";return false
 if units.size()>=PARTY_CAP:expedition.status_message="PARTY FULL / recall a creature first.";return false
 if exhausted.has(key):expedition.status_message="This creature fainted / rest at the landing ship before deploying again.";return false
 var definition:=SanctuaryState.fauna(str(resident.species))
 var actor:=SanctuaryFormArt.creature(self,definition,int(resident.form_stage));actor.scale=Vector3.ONE*definition.size*.75
 actor.global_position=expedition.bot.global_position+Vector3(2,0,2)
 var badge:=Label3D.new();badge.position.y=3;badge.billboard=BaseMaterial3D.BILLBOARD_ENABLED;badge.font_size=24;badge.pixel_size=.01;actor.add_child(badge)
 var stats:=CreatureCombat.attributes(resident)
 var hp: float=stats.hp
 units[key]={"actor":actor,"badge":badge,"resident":resident.duplicate(true),"hp":float(health_memory.get(key,hp)),"max_hp":hp,"cooldown":0.0,"power":5.0+int(resident.form_stage)*2,"style":definition.body_style,"stats":stats,"ability_cooldown":float(ability_memory.get(key,0)),"shield":0.0,"focus":0.0}
 badge.text="%s · Lv%d %s\n%d / %d"%[resident.name,stats.level,stats.affinity,int(units[key].hp),int(hp)]
 expedition.status_message="DEPLOYED / "+str(resident.name);return true
func recall() -> void:
 for key in units.keys():
  ability_memory[key]=units[key].ability_cooldown
  health_memory[key]=units[key].hp;units[key].actor.queue_free()
 units.clear();target=null
 expedition.status_message="CREATURE PARTY RECALLED / health preserved."
func rest() -> bool:
 if not expedition.at_landing_ship():expedition.status_message="Rest your creatures at the landing ship.";return false
 recall();exhausted.clear();health_memory.clear();ability_memory.clear();expedition.status_message="CREATURES RESTED / ready to deploy.";return true
func attack() -> bool:
 var chosen:=expedition.tracked_animal()
 if units.is_empty() or not is_instance_valid(chosen) or not chosen.alive:return false
 if chosen.global_position.distance_to(expedition.bot.global_position)>45 or not expedition.clear_line(expedition.bot.global_position,chosen.global_position):
  expedition.status_message="CREATURE BATTLE / approach your hunt within 45m with a clear view.";return false
 target=chosen;expedition.status_message="CREATURE PARTY / attack "+chosen.definition.display_name;return true
func _physics_process(delta: float) -> void:
 for key in ability_memory:
  if not units.has(key):ability_memory[key]=maxf(0,float(ability_memory[key])-delta)
 if expedition.finished or not expedition.bot.alive:
  if not units.is_empty():recall()
  return
 if is_instance_valid(target) and (not target.alive or target.global_position.distance_to(expedition.bot.global_position)>60):target=null
 var incoming: Dictionary={}
 for key in units.keys():
  var unit: Dictionary=units[key]
  var actor: Node3D=unit.actor
  unit.cooldown=maxf(0,unit.cooldown-delta)
  unit.ability_cooldown=maxf(0,unit.ability_cooldown-delta);unit.focus=maxf(0,unit.focus-delta)
  var destination:=expedition.bot.global_position+Vector3(cos(key)*3,0,sin(key)*3)
  if is_instance_valid(target):destination=target.global_position
  var offset:=destination-actor.global_position
  var distance:=offset.length()
  if distance>55:
   actor.global_position=expedition.bot.global_position+Vector3(2,0,2)
  elif distance>3:
   var direction:=offset.normalized()
   var query:=PhysicsRayQueryParameters3D.create(actor.global_position+Vector3.UP,actor.global_position+Vector3.UP+direction*2,1)
   if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():direction=direction.rotated(Vector3.UP,1.2)
   actor.global_position+=direction*minf(distance-3,delta*float(unit.stats.speed))
   actor.rotation.y=lerp_angle(actor.rotation.y,atan2(-direction.x,-direction.z),delta*8)
  var floating: bool=unit.style in ["bat","fish","shark","jelly","wisp"]
  actor.global_position.y=SurfaceWorld.height_at(actor.global_position.x,actor.global_position.z)+(2.8 if floating or expedition.definition.aquatic else .2)
  if is_instance_valid(target) and distance<5 and unit.cooldown<=0 and expedition.clear_line(actor.global_position,target.global_position):
   unit.cooldown=1.1
   var amount:=CreatureCombat.damage(float(unit.stats.attack)*(.7 if unit.focus<=0 else 1.1),float(CreatureCombat.wild_level(target))*2,unit.stats.affinity,CreatureCombat.affinity(target.definition.id))
   target.hit(amount,true)
   if target.health<=1:complete_battle()
  if is_instance_valid(target) and distance<12 and unit.ability_cooldown<=0:
   use_ability(key)
  if is_instance_valid(target) and target.health<=1:complete_battle()
  unit.badge.text="%s · Lv%d %s\n%d / %d · %s"%[unit.resident.name,int(unit.stats.level),unit.stats.affinity,int(unit.hp),int(unit.max_hp),unit.stats.ability]
 # Wild animals choose nearby party members as opponents, including passive defenders.
 for animal in expedition.fauna:
  if not is_instance_valid(animal) or not animal.alive or animal.dazed_remaining>0:continue
  if animal!=target and animal.definition.damage<=0:continue
  var nearest:=-1;var distance:=5.0
  for key in units:
   var next:=animal.global_position.distance_to(units[key].actor.global_position)
   if next<distance and expedition.clear_line(animal.global_position,units[key].actor.global_position):distance=next;nearest=key
  if nearest<0:continue
  animal.state="creature_battle";animal.destination=animal.position
  if animal.attack_timer<=0:
   animal.attack_timer=1.2;incoming[nearest]=float(incoming.get(nearest,0))+CreatureCombat.damage((maxf(5,animal.definition.damage)+CreatureCombat.wild_level(animal))*(1.3 if animal.fury_remaining>0 else 1.0),float(units[nearest].stats.defense),CreatureCombat.affinity(animal.definition.id),units[nearest].stats.affinity)
 for key in incoming:hurt_ally(key,float(incoming[key]))

func hurt_ally(key: int,amount: float) -> void:
 if not units.has(key):return
 var absorbed:=minf(float(units[key].shield),amount);units[key].shield-=absorbed
 units[key].hp=maxf(0,units[key].hp-(amount-absorbed))
 SpaceEffects.burst(self,units[key].actor.global_position,Color(1,.5,.6),.5)
 if units[key].hp<=0:
  exhausted[key]=true;units[key].actor.queue_free();units.erase(key)
  expedition.status_message="CREATURE FAINTED / still owned. Rest at your landing ship."

func wild_skill(animal: SurfaceFauna) -> void:
 if not animal.alive or units.is_empty():return
 var kind: Dictionary=CreatureCombat.ROSTER[animal.definition.id]
 match str(kind.effect):
  "heal":animal.health=minf(animal.definition.health,animal.health+8)
  "shield":animal.guard_remaining=3
  "focus":animal.fury_remaining=5
  "disrupt":
   for unit in units.values():unit.cooldown=maxf(unit.cooldown,1.8)
  "strike":
   var nearest: int=units.keys()[0]
   for key in units:
    if animal.global_position.distance_to(units[key].actor.global_position)<animal.global_position.distance_to(units[nearest].actor.global_position):nearest=key
   if animal.global_position.distance_to(units[nearest].actor.global_position)<12:
    hurt_ally(nearest,CreatureCombat.damage(float(kind.power),float(units[nearest].stats.defense),str(kind.affinity),str(units[nearest].stats.affinity)))
 SpaceEffects.burst(self,animal.global_position,animal.definition.glow,1.0)
 expedition.status_message=animal.definition.display_name+" / "+str(kind.ability)

func use_ability(key: int) -> void:
 if not units.has(key) or not is_instance_valid(target):return
 var unit: Dictionary=units[key]
 unit.ability_cooldown=7.0
 match str(unit.stats.effect):
  "heal":
   for friend in units.values():friend.hp=minf(float(friend.max_hp),float(friend.hp)+12+int(unit.stats.level))
  "shield":
   for friend in units.values():friend.shield=minf(30,float(friend.shield)+12+int(unit.stats.level))
  "focus":
   for friend in units.values():friend.focus=5.0
  "disrupt":target.dazed_remaining=maxf(target.dazed_remaining,2.0)
  "strike":target.hit(CreatureCombat.damage(float(unit.stats.attack)*1.5,CreatureCombat.wild_level(target)*2,unit.stats.affinity,CreatureCombat.affinity(target.definition.id)),true)
 SpaceEffects.burst(self,unit.actor.global_position,SanctuaryState.fauna(str(unit.resident.species)).glow,1.1)
 expedition.status_message=str(unit.resident.name)+" / "+str(unit.stats.ability)

func complete_battle() -> void:
 if not is_instance_valid(target):return
 var defeated:=target;target=null
 if defeated.has_meta("battle_xp_awarded"):return
 defeated.set_meta("battle_xp_awarded",true)
 var before: Array=expedition.profile.sanctuary.residents.duplicate(true)
 for resident in residents():
  if units.has(int(resident.id)):
   CreatureCombat.award(resident,20+CreatureCombat.wild_level(defeated)*8)
 if not expedition.profile.save_profile():
  expedition.profile.sanctuary.residents=before
  defeated.remove_meta("battle_xp_awarded")
  expedition.status_message="XP SAVE FAILED / "+expedition.profile.save_error;return
 for key in units:
  for resident in residents():
   if int(resident.id)==key:
    units[key].resident=resident.duplicate(true);units[key].stats=CreatureCombat.attributes(resident);units[key].max_hp=units[key].stats.hp
 expedition.status_message="BATTLE WON / experience saved. Scan with G, then C to capture."

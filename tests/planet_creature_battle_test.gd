extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
 checks+=1
 if value:print("PASS: "+message)
 else:failures+=1;push_error(message)
func run() -> void:
 var expedition:=PlanetExpedition.new();expedition.profile=PlayerProfile.new();expedition.profile.save_path="user://creature-battle-test.json"
 expedition.profile.sanctuary.residents.append(SanctuaryState.new_resident(2,"sporehopper","Pearl"))
 expedition.profile.sanctuary.residents.append(SanctuaryState.new_resident(3,"nightfang","Flare"))
 expedition.profile.sanctuary.residents.append(SanctuaryState.new_resident(4,"veilcrawler","Pebble"))
 root.add_child(expedition);expedition.set_physics_process(false);expedition.bot.set_physics_process(false);expedition.party.set_physics_process(false)
 for animal in expedition.fauna:animal.set_physics_process(false)
 var party:=expedition.party
 check(not party.deploy(999),"Cannot deploy an unowned creature")
 check(party.deploy(1) and party.deploy(2) and party.deploy(3),"Owned sanctuary creatures deploy on the surface")
 check(not party.deploy(1) and not party.deploy(4),"Duplicate residents and a fourth active creature are blocked")
 var old_hp: float=party.units[1].hp
 party.units[1].hp=old_hp-10;party.units[1].ability_cooldown=6
 party.recall();check(party.units.is_empty(),"Recall removes active combatants")
 party.deploy(1)
 check(party.units[1].hp==old_hp-10 and party.units[1].ability_cooldown==6,"Recall cannot refill health or reset abilities")
 var animal:=expedition.fauna[0]
 expedition.bot.position=Vector3(0,2,-25);animal.position=Vector3(1,2,-28)
 expedition.hunt_species=animal.definition.id
 for other in expedition.fauna:
  if other!=animal:other.alive=false
 party.target=animal;party.units[1].actor.global_position=animal.global_position
 party.units[1].cooldown=0
 var before:=animal.health
 party._physics_process(.1)
 check(animal.health<before,"Companion AI attacks wildlife using actual combat damage")
 check(party.units[1].ability_cooldown>0,"Companion AI automatically activates its species ability")
 var resident: Dictionary=expedition.profile.sanctuary.residents[0]
 resident.level=1;resident.experience=40
 animal.health=1;party.target=animal;party.complete_battle()
 check(resident.level==2 and resident.experience>0,"Winning combat grants experience and levels")
 check(FileAccess.file_exists(expedition.profile.save_path),"Combat progression writes the local save")
 var earned: int=resident.experience;party.target=animal;party.complete_battle()
 check(resident.experience==earned,"The same subdued wildlife cannot award XP twice")
 var reloaded:=PlayerProfile.new();reloaded.save_path=expedition.profile.save_path;reloaded.load_profile()
 check(reloaded.sanctuary.residents[0].level==2,"Creature levels survive save and reload")
 check(CreatureCombat.multiplier("Tide","Ember")>1 and CreatureCombat.multiplier("Ember","Tide")<1,"Strengths and weaknesses are directional")
 check(CreatureCombat.damage(20,5,"Tide","Ember")>CreatureCombat.damage(20,5,"Ember","Tide"),"Affinity changes actual damage")
 check(CreatureCombat.damage(20,30,"Grove","Grove")<CreatureCombat.damage(20,5,"Grove","Grove"),"Defense reduces actual damage")
 var names: Dictionary={}
 for species in CreatureCombat.ROSTER:names[CreatureCombat.ROSTER[species].ability]=true
 check(names.size()==9,"All nine creature species have distinct abilities")
 var xp_before: int=resident.experience
 animal.remove_meta("battle_xp_awarded");party.target=animal;expedition.profile.save_blocked=true;party.complete_battle()
 check(expedition.profile.sanctuary.residents[0].experience==xp_before and not animal.has_meta("battle_xp_awarded"),"Failed XP saves roll back progression and allow a safe retry")
 expedition.profile.save_blocked=false
 party.units[1].shield=0;party.units[1].ability_cooldown=0;party.target=animal;party.use_ability(1)
 check(party.units[1].shield>0,"Verdant Guard supplies a real damage-absorbing shield")
 party.deploy(2);party.units[1].hp=10;party.target=animal;party.use_ability(2)
 check(party.units[1].hp>10,"Pearl Mend heals a teammate")
 party.deploy(3);animal.health=20;party.target=animal;party.use_ability(3)
 check(animal.health<20 and animal.health>=1,"Flare Pounce deals nonlethal ability damage")
 var defender:=expedition.fauna[10];defender.alive=true;defender.health=20;defender.guard_remaining=0;party.wild_skill(defender)
 check(defender.guard_remaining>0,"Wildlife AI can use its defensive species ability")
 var hp_before:=defender.health;defender.hit(2,true)
 check(hp_before-defender.health<2,"Wild Verdant Guard reduces received damage")
 var predator:=expedition.fauna[20];predator.alive=true;predator.dazed_remaining=0;predator.position=party.units[1].actor.global_position;predator.attack_timer=0
 party.units[1].hp=.1;party.units[1].shield=0;party.target=null
 party._physics_process(.01)
 check(party.exhausted.has(1) and not party.units.has(1),"Wildlife AI can damage and faint a deployed creature")
 party.recall()
 check(not party.deploy(1),"Fainted creatures cannot be immediately redeployed")
 expedition.bot.position=Vector3(200,2,0);check(not party.rest(),"Party recovery requires the landing ship")
 expedition.bot.position=Vector3(0,1.5,0);check(party.rest() and party.deploy(1),"Landing refuge restores fainted party members")
 check(expedition.profile.sanctuary.residents.size()==4,"Battling and fainting preserve sanctuary ownership")
 expedition.finished=true;check(not party.deploy(4),"Finished expeditions cannot deploy creatures")
 expedition.queue_free();await process_frame
 print("PLANET CREATURE BATTLE TEST: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)

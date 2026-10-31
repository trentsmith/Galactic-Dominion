class_name BattleMatch
extends Node3D
signal ended(winner, reason)

const CLASSES = [preload("res://resources/ships/interceptor.tres"), preload("res://resources/ships/skirmisher.tres"), preload("res://resources/ships/guardian.tres")]
var sector_map: ArmadaSector
var spatial: BattleSpatialIndex
var map_seed:=0
var broadphase_clock:=0.0
var aura_clock:=0.0
var mega: MegaWeapons
var story_mission := ""
var difficulty := "standard"
var playtest_path := ""
var training := false
var armada_mode:=false
var enemy_team_size:=0
var team_size := 3
var elimination_only := false
var ships: Array[CombatShip] = []
var fleet: FleetManager
var pilot: PlayerPilot
var zone: BattleZone
var camera: Camera3D
var elapsed := 0.0
var finished := false
var winner := -1
var end_reason := ""
var hud: BattleHUD
var network_role := "offline"
var preconfigured_stats: Array[ShipStats] = []
var max_duration := 480.0
var profile: PlayerProfile
var rewards: Array[Dictionary] = []
var reward_summary := ""
var battle_id := ""

func _init() -> void:
 process_mode = Node.PROCESS_MODE_PAUSABLE

func _ready() -> void:
 difficulty = SoloDifficulty.valid(difficulty)
 battle_id = "%d-%d" % [Time.get_ticks_usec(), get_instance_id()]
 # Network protocol remains six slots; Fleet War is an offline mode.
 armada_mode=network_role=="offline" and (armada_mode or team_size==200)
 if armada_mode:
  team_size=ArmadaCombat.count(team_size)
  enemy_team_size=ArmadaCombat.count(enemy_team_size if enemy_team_size>0 else team_size)
 else:
  team_size=10 if team_size==10 and network_role=="offline" else 3
  enemy_team_size=team_size
 elimination_only = armada_mode or team_size>=10
 var arena := SpaceArena.new()
 arena.open_space = training or is_armada()
 arena.battle_scale = 1.7 if team_size == 10 else 1.0
 arena.star_radius=12000 if is_armada() else 1700
 if is_armada():
  if map_seed==0:
   var random:=RandomNumberGenerator.new();random.randomize();map_seed=random.randi_range(1,2147483646)
  arena.arena_seed=map_seed
 add_child(arena)
 zone = BattleZone.new()
 if team_size >= 10:
  zone.start_radius = 1050.0
  zone.final_radius = 150.0
 if is_armada():zone.start_radius=ArmadaSector.RADIUS;zone.final_radius=350
 add_child(zone)
 if is_armada():
  spatial=BattleSpatialIndex.new()
  sector_map=ArmadaSector.new();sector_map.battle=self;sector_map.seed_value=map_seed;add_child(sector_map)
 camera = Camera3D.new()
 camera.far = 16000.0 if is_armada() else 4000.0
 camera.current = true
 add_child(camera)
 pilot = PlayerPilot.new()
 pilot.camera = camera
 add_child(pilot)
 fleet = FleetManager.new()
 fleet.pilot = pilot
 add_child(fleet)
 for team_index in range(2):
  for slot in range(team_size if team_index==0 else enemy_team_size):
   var ship := CombatShip.new()
   ship.lightweight=is_armada() and not (team_index==0 and slot<3)
   ship.set_meta("armada_lod",ship.lightweight)
   ship.stats = profile.configured_stats(slot) if team_index == 0 and profile != null and slot < 3 else reinforcement_stats(slot)
   if team_index == 0 and profile != null and slot < 3:
    var crew := CollectionCatalog.find(str(profile.loadouts[slot].crew))
    ship.crew_name = crew.display_name if crew != null else "Unassigned"
   if preconfigured_stats.size() == team_size + enemy_team_size:
    ship.stats = preconfigured_stats[(team_size if team_index==1 else 0) + slot]
   if team_index == 1 and network_role == "offline":
    ship.stats = ArmadaCombat.enemy_stats(ship.stats,difficulty) if is_armada() else SoloDifficulty.enemy_stats(ship.stats,"standard" if training else difficulty)
    ship.crew_name = "AI pilot"
   ship.team = team_index
   ship.fleet_slot = slot
   ship.callsign = ("Vanguard" if team_index == 0 else "Ravager") + " %d" % (slot + 1)
   ship.position = Vector3((slot - 1) * 40.0, slot * 12.0, 230.0 if team_index == 0 else -230.0)
   if team_size == 10:
    ship.position = Vector3((slot % 5 - 2) * 65.0, (slot / 5) * 65.0 - 32.5, (410.0 + (slot / 5) * 75.0) * (1 if team_index == 0 else -1))
   if is_armada():ship.position=sector_map.spawn_position(team_index,slot)
   if team_index == 1:ship.rotation.y=PI
   add_child(ship)
   if is_armada():
    ship.look_at(Vector3.ZERO)
    ship.brain.command="attack"
    ship.brain.sensor_range=ArmadaSector.SENSOR;ship.brain.retarget_timer=float(slot%12)*.05
    ship.targeting.selection_range=ArmadaSector.SENSOR;ship.targeting.enforce_range=true
   ships.append(ship)
   if network_role=="offline":
    if team_index==0:
     ship.weapons.secondary.speed=220.0;ship.weapons.secondary.turn_rate=4.5
     ship.weapons.aim_assist_dot=.97;ship.targeting.lock_duration=.8
    else:
     SoloDifficulty.configure_enemy(ship,"standard" if training else difficulty)
    if is_armada():ArmadaCombat.configure(ship,difficulty)
   ship.eliminated.connect(_on_eliminated)
   if team_index == 0:
    fleet.ships.append(ship)
    ship.eliminated.connect(fleet.on_eliminated)
 if spatial!=null:spatial.rebuild(ships)
 fleet.switch_to(0)
 pilot.ship.targeting.cycle()
 fleet.issue_command("attack" if network_role=="offline" else "follow")
 if team_size >= 10:
  # Start separate dogfights instead of assigning nine escorts to one opponent.
  for ally in fleet.ships:ally.brain.commanded_target = null
 if is_armada():
  mega=MegaWeapons.new();mega.battle=self;add_child(mega)
 hud = BattleHUD.new()
 hud.battle = self
 add_child(hud)
 if sector_map!=null:
  var layer:=CanvasLayer.new();layer.layer=8;add_child(layer)
  var chart:=ArmadaChart.new();chart.battle=self;layer.add_child(chart)
 if network_role != "offline":
  pilot.set_physics_process(false)
  pilot.set_process_unhandled_input(false)
  fleet.set_process_unhandled_input(false)
  for ship in ships:
   ship.player_controlled = false
  if network_role == "client":
   set_physics_process(false)
   for ship in ships:
    ship.set_physics_process(false)
    ship.collision_layer = 0
    ship.collision_mask = 0
 if network_role == "server":
  hud.visible = false
 else:
  Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
 if finished:
  return
 elapsed += delta
 if is_instance_valid(mega):mega.tick(delta)
 if spatial!=null:
  broadphase_clock-=delta
  if broadphase_clock<=0:spatial.rebuild(ships);broadphase_clock=.1
  sector_map.tick(delta)
  aura_clock-=delta
  if aura_clock<=0:update_auras();aura_clock=.1
 else:update_auras()
 zone.tick(delta, ships)
 if elapsed >= max_duration and not elimination_only:
  var scores := [0.0, 0.0]
  for ship in ships:
   if ship.alive:
    scores[ship.team] += ship.health.hull / ship.health.max_hull + ship.health.shield / ship.health.max_shield
  finish(0 if scores[0] > scores[1] else (1 if scores[1] > scores[0] else -1), "Time limit · surviving hull and shields decide")

func update_auras() -> void:
 # Reset and aggregate Guardian auras once per simulation tick.
 for ship in ships:
  ship.health.protection = 1.0
 for guardian in ships:
  if guardian.alive and guardian.stats.ability == "aegis" and guardian.ability_remaining > 0.0:
   for friend in spatial.nearby(guardian.position,90) if spatial!=null else ships:
    if friend.alive and friend.team == guardian.team and friend.global_position.distance_to(guardian.global_position) < 90.0:
     friend.health.protection = 0.45

func _on_eliminated(_ship: CombatShip, _attacker: CombatShip) -> void:
 if finished:
  return
 var allies := living(0)
 var enemies := living(1)
 if allies == 0 or enemies == 0:
  finish(0 if enemies == 0 and allies > 0 else (1 if allies == 0 and enemies > 0 else -1), "Fleet eliminated")

func living(team: int) -> int:
 var count := 0
 for ship in ships:
  if ship.team == team and ship.alive:
   count += 1
 return count

func finish(team: int, reason: String) -> void:
 if finished:
  return
 finished = true
 winner = team
 end_reason = reason
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 # Freeze simulation for a stable results screen without pausing UI.
 for ship in ships:
  ship.set_physics_process(false)
 pilot.set_physics_process(false)
 fleet.set_process_unhandled_input(false)
 for child in get_children():
  if child is SpaceProjectile:
   child.set_physics_process(false)
 if profile != null:
  var kills := 0
  var damage := 0.0
  for ally in fleet.ships:
   kills += ally.kills
   damage += ally.damage_dealt
  rewards = profile.settle_battle(battle_id, winner, kills, damage)
  if network_role=="offline" and story_mission=="crimson_interdiction" and winner==0:
   if not StoryCampaign.victory(profile):profile.story_message="Patrol cleared, but story progress was not saved. Retry the story encounter after fixing saving."
  reward_summary = "+%d salvage · %d discovery rolls" % [60 if winner == 0 else 30, 2 if winner == 0 else 1]
 ended.emit(team, reason)
 if network_role != "server":
  hud.show_results()

func local_team() -> int:
 return pilot.ship.team if is_instance_valid(pilot.ship) else 0

func reinforcement_stats(slot: int) -> ShipStats:
 if slot < 3:
  return CLASSES[slot]
 var support_classes := [CLASSES[0], CLASSES[1], CLASSES[2], preload("res://resources/ships/bomber.tres"), preload("res://resources/ships/support.tres")]
 return support_classes[(slot - 3) % support_classes.size()]

func is_armada() -> bool:
 return armada_mode
func mode_name() -> String:
 return "%dv%d"%[team_size,enemy_team_size if enemy_team_size>0 else team_size]

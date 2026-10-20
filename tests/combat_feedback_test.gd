extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
 checks += 1
 if value:print("PASS: "+message)
 else:failures+=1;push_error(message)
func run() -> void:
 var main: Node = load("res://scenes/main.tscn").instantiate()
 main.profile_path = "user://feedback-test.json"
 root.add_child(main)
 await process_frame
 main.start_battle()
 var battle: BattleMatch = main.battle
 battle.profile = null
 battle.set_physics_process(false)
 battle.pilot.set_physics_process(false)
 battle.hud.feedback.set_process(false)
 for ship in battle.ships:
  ship.set_physics_process(false)
  ship.position = Vector3(9000+ship.fleet_slot*40,1000,ship.team*1000)
 var player := battle.pilot.ship
 var enemy := battle.ships[3]
 var feedback := battle.hud.feedback
 player.position = Vector3(5000,0,0)
 enemy.position = Vector3(5000,0,-80)
 player.rotation = Vector3.ZERO
 battle.camera.basis = Basis.IDENTITY
 player.health.damage(5,enemy,"laser")
 check(player.health.shield_damage == 5 and player.health.hull_damage == 0,"Confirmed shield damage is recorded separately")
 check(feedback.directions.size() == 1 and feedback.damage_label == "HIT FROM FRONT","Front attacker creates a directional warning")
 check(feedback.direction_label(player.position+Vector3.RIGHT*10) == "RIGHT","Right attacker is labelled correctly")
 check(feedback.direction_label(player.position+Vector3.BACK*10) == "REAR","Rear attacker is distinguished from front")
 battle.camera.rotate_y(PI)
 check(feedback.direction_label(player.position+Vector3.FORWARD*10) == "REAR","Warnings follow camera orientation")
 battle.camera.basis = Basis.IDENTITY
 player.health.damage(player.health.shield+2,enemy,"missile")
 check(player.health.hull_damage == 2 and player.health.damage_history.back().shield_broken,"Shield overflow records hull damage and a shield break")
 check(feedback.audio_events.has("shield_break"),"Shield collapse triggers its own alert")
 player.health.damage(player.health.hull-player.health.max_hull*.2,enemy,"laser")
 check(feedback.audio_events.has("critical") and feedback.notice.contains("CRITICAL HULL"),"Crossing low hull triggers a critical warning")
 feedback.directions.clear()
 player.health.damage(1,null,"battle zone")
 check(feedback.directions.is_empty() and feedback.damage_label == "BATTLE ZONE DAMAGE","Environmental damage does not invent an attacker direction")
 check(player.health.environment_damage == 1,"Environmental damage is accounted separately")
 var sequence := player.health.damage_sequence
 player.health.protection = 0
 player.health.damage(50,enemy)
 check(player.health.damage_sequence == sequence,"Blocked damage produces no false hit feedback")
 player.health.protection = 1
 player.targeting.select(null)
 check(not player.weapons.fire(true) and feedback.notice.contains("SELECT A TARGET"),"Unlocked missile attempt explains target selection")
 player.targeting.select(enemy)
 player.targeting.tick(2)
 feedback.tick(.1)
 var lock_sounds := feedback.audio_events.count("lock")
 feedback.tick(.1)
 check(lock_sounds == 1 and feedback.audio_events.count("lock") == 1,"Confirmed missile lock sounds once rather than every frame")
 check(player.weapons.fire(true),"Locked missile launch succeeds")
 check(not player.weapons.fire(true) and feedback.notice == "MISSILE RELOADING","Cooldown refusal has a distinct explanation")
 for node in battle.get_children():
  if node is SpaceProjectile:node.queue_free()
 await process_frame
 enemy.health.hull = 1000
 enemy.health.max_hull = 1000
 enemy.health.shield = 0
 player.weapons.laser_remaining = 0
 var hull_before := enemy.health.hull
 check(player.weapons.fire(),"A real primary projectile launches")
 for frame in range(100):
  await physics_frame
  if enemy.health.hull<hull_before:break
 check(enemy.health.hull<hull_before and feedback.hit_remaining>0 and feedback.hit_hull,"A real projectile impact creates outgoing hit confirmation")
 var incoming := SpaceProjectile.new()
 incoming.spec = enemy.weapons.secondary.duplicate()
 incoming.target = player;incoming.team = enemy.team;incoming.shooter = enemy
 battle.add_child(incoming);incoming.position = player.position+Vector3(0,0,-100)
 incoming.set_physics_process(false)
 check(feedback.count_incoming() == 1,"Tracking enemy missile produces an incoming threat")
 incoming.team = player.team
 check(feedback.count_incoming() == 0,"Friendly missiles do not produce threat alarms")
 incoming.team = enemy.team;incoming.target = battle.ships[1]
 check(feedback.count_incoming() == 0,"Missiles targeting other ships do not warn the player")
 incoming.target = player;feedback.threat_clock = 0;feedback.tick(.1)
 check(feedback.incoming_count == 1 and feedback.audio_events.has("incoming"),"Incoming missile has a distinct audible alert")
 incoming.queue_free()
 var previous_ship := player
 battle.fleet.switch_to(1)
 feedback.tick(.1)
 check(feedback.directions.is_empty() and feedback.active_ship == battle.pilot.ship,"Switching ships clears damage directions from the old vessel")
 battle.fleet.switch_to(0);feedback.tick(.1)
 var state_before := Vector2(player.health.hull,player.health.shield)
 main.network.arena = battle
 var report := {"sequence":player.health.damage_sequence+1,"victim":0,"attacker":3,"attacker_id":0,"attacker_name":"Remote attacker","position":enemy.position,"directional":true,"source":"laser","shield":0.0,"hull":1.0,"shield_broken":false,"critical":false,"fatal":false}
 main.network.receive_feedback([report])
 var history_count := player.health.damage_history.size()
 main.network.receive_feedback([report])
 check(Vector2(player.health.hull,player.health.shield) == state_before,"Replicated feedback never applies client-side damage")
 check(player.health.damage_history.size() == history_count,"Duplicate network feedback is ignored")
 check(player.health.damage_history.back().attacker_id == enemy.get_instance_id(),"Network attacker indices resolve to local ship identities")
 for hit in range(20):player.health.damage(.01,enemy)
 check(player.health.damage_history.size() == 8 and feedback.directions.size() <= 6,"Damage history and direction indicators remain bounded")
 var audio: SpaceAudio = main.get_node("Audio")
 var distinct := {}
 var safe := true
 for event in SpaceAudio.DURATIONS:
  var stream := audio._tone(event)
  distinct[hash(stream.data)] = true
  var peak := 0
  for index in range(0,stream.data.size(),2):peak=maxi(peak,absi(stream.data.decode_s16(index)))
  safe = safe and peak>100 and peak<30000 and stream.mix_rate == 22050
 check(distinct.size() == SpaceAudio.DURATIONS.size() and safe,"All original PCM effects are distinct, non-silent and leave clipping headroom")
 battle.finish(1,"Time limit · surviving hull and shields decide")
 var explanation := battle.hud.results.find_child("BattleExplanation",true,false) as Label
 check(explanation != null and explanation.text.contains("Time-limit survival score") and explanation.text.contains("environmental"),"Results explain the actual tiebreak score and damage sources")
 for frame in range(3):await process_frame
 var menu_visible := false
 for button in battle.hud.results.find_children("","Button",true,false):
  if button.text == "MAIN MENU":menu_visible = root.get_visible_rect().encloses(button.get_global_rect())
 check(menu_visible,"Results navigation stays visible without scrolling the report")
 main.network.arena = null
 main.start_free_roam(true)
 var roam: FreeRoamMatch = main.battle
 roam.set_physics_process(false);roam.pilot.set_physics_process(false)
 for vessel in roam.ships:vessel.set_physics_process(false)
 roam.replace_pilot_ship(0,roam.ships[0].stats.duplicate(true),"Replacement","Test pilot",true)
 var replacement := roam.ships[0]
 replacement.set_physics_process(false)
 replacement.health.protection = 1
 replacement.health.damage(1,roam.ships[3],"laser")
 check(roam.hud.feedback.directions.size() == 1,"Replacement free-roam vessels retain damage feedback hooks")
 main.queue_free();await process_frame
 print("COMBAT_FEEDBACK_TEST: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)

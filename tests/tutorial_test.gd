extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
 checks += 1
 if value:print("PASS: " + message)
 else:failures += 1;push_error(message)
func run() -> void:
 var main: Node = load("res://scenes/main.tscn").instantiate()
 main.profile_path = "user://tutorial-test-profile.json"
 root.add_child(main)
 await process_frame
 var button := main.menu.find_child("TutorialButton",true,false) as Button
 check(button != null,"Flight school is accessible from the command deck")
 var salvage: int = main.profile.salvage
 button.pressed.emit()
 await process_frame
 var training: TrainingFlight = main.battle
 training.set_physics_process(false)
 training.pilot.set_physics_process(false)
 for ship in training.ships:ship.set_physics_process(false)
 check(training.profile == null and training.training,"Practice cannot settle collection rewards")
 check(training.lesson == 0 and not training.completed,"Training begins with the first lesson")
 var ship := training.pilot.ship
 ship.health.damage(10000,null)
 check(ship.alive and ship.health.hull == ship.health.max_hull,"Training ship cannot be destroyed")
 check(not training.drone.is_physics_processing(),"Practice drone cannot move or attack")
 training._physics_process(600)
 check(not training.completed and not training.finished and training.lesson == 0,"Waiting does not complete lessons or trigger a match timeout")
 Input.action_press("forward")
 ship.movement.thrust = Vector3.FORWARD
 ship.set_physics_process(true)
 for frame in range(60):await physics_frame
 ship.set_physics_process(false)
 training._physics_process(.7)
 Input.action_release("forward")
 check(training.lesson == 1,"Actual forward movement advances the first lesson")
 for action in ["strafe_right","up"]:
  Input.action_press(action)
  ship.velocity = Vector3.RIGHT * 20
  training._physics_process(.7)
  Input.action_release(action)
 check(training.lesson == 3,"Strafe and vertical inputs advance their lessons")
 ship.rotate_y(.3)
 training._physics_process(.1)
 check(training.lesson == 4,"Ship rotation completes steering practice")
 ship.movement.boost_requested = true
 ship.movement.boost_energy -= 10
 ship.velocity = Vector3.FORWARD * 30
 training._physics_process(.7)
 check(training.lesson == 5,"Boosting with spent reserve advances boost training")
 ship.targeting.select(training.drone)
 Input.action_press("target")
 training._physics_process(.1)
 Input.action_release("target")
 check(training.lesson == 6 and ship.targeting.target == training.drone,"Selecting the drone starts laser practice")
 check(ship.weapons.fire(),"A real practice laser is launched")
 for frame in range(100):
  await physics_frame
  if training.lesson == 7:break
 check(training.lesson == 7,"A real projectile hit advances laser practice")
 ship.targeting.tick(2)
 check(ship.targeting.locked(),"Practice drone can be missile-locked")
 check(ship.weapons.fire(true) and training.lesson == 8,"Successful locked missile launch advances missile training")
 training.fleet.switch_to(1)
 training.pilot.ship.set_physics_process(false)
 training._physics_process(.1)
 check(training.lesson == 9,"Taking control of a wingmate advances switching practice")
 training.fleet.issue_command("follow")
 Input.action_press("command_1")
 training._physics_process(.1)
 Input.action_release("command_1")
 check(training.completed and main.settings.get_value("tutorial","flight_completed",false),"Follow order completes training and saves its completion flag")
 check(main.profile.salvage == salvage,"Completing training grants no farmable salvage")
 main.return_to_menu()
 await process_frame
 check(main.menu.find_child("TutorialButton",true,false).text.contains("Replay"),"Completed training remains replayable")
 main.start_tutorial()
 await process_frame
 var event := InputEventAction.new();event.action = "pause";event.pressed = true
 main._unhandled_input(event)
 await process_frame
 check(paused and main.menu.find_child("RetryLessonButton",true,false) != null,"Pause offers a lesson retry")
 main.menu.find_child("RetryLessonButton",true,false).pressed.emit()
 check(not paused and main.battle.lesson == 0,"Retry resumes the current lesson")
 main._unhandled_input(event)
 await process_frame
 main.menu.find_child("ReturnButton",true,false).pressed.emit()
 check(not paused and main.battle == null,"Skipping safely returns to the command deck")
 main.queue_free()
 await process_frame
 print("TUTORIAL_TEST: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)

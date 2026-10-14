extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
 checks += 1
 if value: print("PASS: " + message)
 else: failures += 1;push_error("FAIL: " + message)
func run() -> void:
 var connection := ServerConnection.new()
 connection.save_path = "user://connection-test-%d.cfg" % Time.get_ticks_usec()
 connection.load_settings()
 check(connection.api_url == "http://127.0.0.1:8080" and connection.combat_port == 7777,"Local host defaults work without external configuration")
 check(connection.save_settings("http://192.168.1.12:8080/","192.168.1.12",7777,"Pilot"),"LAN address and commander can be saved")
 var reload := ServerConnection.new()
 reload.save_path = connection.save_path
 reload.load_settings()
 check(reload.api_url == "http://192.168.1.12:8080" and reload.combat_host == "192.168.1.12" and reload.commander == "Pilot","Joining preferences survive reload")
 check(not reload.save_settings("file:///tmp/x","",0,"Pilot"),"Malformed endpoint settings are rejected")
 var text := FileAccess.get_file_as_string(connection.save_path)
 check(not text.contains("password") and not text.contains("token"),"Saved connection settings contain no passwords or account tokens")
 var main: Node = load("res://scenes/main.tscn").instantiate()
 main.profile_path = "user://connection-ui-test-%d.json" % Time.get_ticks_usec()
 root.add_child(main)
 await process_frame
 main.show_online()
 await process_frame
 var hub: OnlineHub = main.menu.get_child(0)
 hub.connection.save_path = connection.save_path
 hub.api_address.text = "invalid"
 await hub._sign_in(false)
 check(not hub.busy and hub.status.text.contains("Check"),"Invalid settings do not leave sign-in permanently busy")
 hub.combat_address.text = "192.168.1.22"
 var shortcut: Button
 for button in hub.find_children("","Button",true,false):
  if button.text.begins_with("USE THIS ADDRESS"): shortcut = button
 shortcut.pressed.emit()
 check(hub.api_address.text == "http://192.168.1.22:8080","LAN shortcut derives the account endpoint from the host address")
 var profile_path: String = main.profile_path
 main.queue_free()
 await process_frame
 await process_frame
 DirAccess.remove_absolute(ProjectSettings.globalize_path(connection.save_path))
 for suffix in ["", ".bak", ".tmp"]:
  if FileAccess.file_exists(profile_path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(profile_path+suffix))
 OS.delay_msec(50)
 print("SERVER CONNECTION TEST: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)

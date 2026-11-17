class_name FlightPreferences
extends RefCounted
## Device bindings are separate from account data; online inputs remain host validated.
const PATH="user://flight-controls.cfg"
const ACTIONS=["ping","forward","reverse","strafe_left","strafe_right","up","down","roll_left","roll_right","boost","laser","missile","target","ability","scan","recover_component","frontier_use","surface_land","story_journal","surface_capture","surface_extract","surface_gather","surface_next_hunt","surface_next_bot","surface_deploy_creature","surface_cycle_creature","surface_attack_creature","surface_recall_creatures","ship_1","ship_2","ship_3","fleet_next","fleet_previous","mega_weapon","sector_map","scenic_hud","command_1","command_2","command_3","command_4","command_5","pause"]
static var config:=ConfigFile.new()
static var save_path:=PATH
static var originals: Dictionary={}
static var quality:="high"
static var large_text:=false
static var reduced_flashes:=false
static var reduced_camera_motion:=false
static var show_lead_guide:=true
static func install(reload_config: bool=true) -> void:
 if originals.is_empty():
  for action in ACTIONS:
   if InputMap.has_action(action):originals[action]=InputMap.action_get_events(action)
 if reload_config:config=ConfigFile.new();config.load(save_path)
 quality=str(config.get_value("display","quality","high"))
 if quality not in ["low","medium","high"]:quality="high"
 large_text=bool(config.get_value("accessibility","large_text",false))
 reduced_flashes=bool(config.get_value("accessibility","reduced_flashes",false))
 reduced_camera_motion=bool(config.get_value("accessibility","reduced_camera_motion",false))
 show_lead_guide=bool(config.get_value("display","show_lead_guide",true))
 for action in ACTIONS:
  if originals.has(action):
   InputMap.action_erase_events(action)
   for event in originals[action]:InputMap.action_add_event(action,event)
 for binding in [["strafe_left",0,-1.0],["strafe_right",0,1.0],["forward",1,-1.0],["reverse",1,1.0],["laser",5,1.0],["missile",4,1.0]]:
  var axis:=InputEventJoypadMotion.new();axis.axis=binding[1];axis.axis_value=binding[2];InputMap.action_add_event(binding[0],axis)
 for binding in [["up",JOY_BUTTON_RIGHT_SHOULDER],["down",JOY_BUTTON_LEFT_SHOULDER],["boost",JOY_BUTTON_A],["surface_capture",JOY_BUTTON_B],["target",JOY_BUTTON_Y],["ability",JOY_BUTTON_X],["scan",JOY_BUTTON_DPAD_UP],["frontier_use",JOY_BUTTON_DPAD_UP],["surface_extract",JOY_BUTTON_DPAD_DOWN],["surface_next_hunt",JOY_BUTTON_DPAD_LEFT],["surface_deploy_creature",JOY_BUTTON_DPAD_RIGHT],["pause",JOY_BUTTON_START],["story_journal",JOY_BUTTON_BACK],["ping",JOY_BUTTON_RIGHT_STICK]]:
  var button:=InputEventJoypadButton.new();button.button_index=binding[1];InputMap.action_add_event(binding[0],button)
 for action in ["look_left","look_right","look_up","look_down"]:
  if not InputMap.has_action(action):InputMap.add_action(action,.18)
  InputMap.action_erase_events(action)
 for binding in [["look_left",2,-1.0],["look_right",2,1.0],["look_up",3,-1.0],["look_down",3,1.0]]:
  var axis:=InputEventJoypadMotion.new();axis.axis=binding[1];axis.axis_value=binding[2];InputMap.action_add_event(binding[0],axis)
 for action in (config.get_section_keys("bindings") if config.has_section("bindings") else PackedStringArray()):
  if not action in ACTIONS:continue
  var value: Variant=config.get_value("bindings",action)
  if value is InputEvent:replace(action,value,false)
  elif value is Dictionary:
   for device in ["key","mouse","pad"]:
    var event: Variant=value.get(device)
    if event is InputEvent and family(event)==device:replace(action,event,false)
static func look() -> Vector2:
 return Input.get_vector("look_left","look_right","look_up","look_down") if InputMap.has_action("look_left") else Vector2.ZERO
static func replace(action: String,event: InputEvent,save_value:=true) -> Error:
 var device:=family(event)
 if not action in ACTIONS or not InputMap.has_action(action) or device.is_empty():return ERR_INVALID_PARAMETER
 var clean:=event.duplicate() as InputEvent;clean.device=-1
 # Replace only the selected device family, preserving the other devices.
 for old in InputMap.action_get_events(action):
  if (event is InputEventKey and old is InputEventKey) or (event is InputEventMouseButton and old is InputEventMouseButton) or (event is InputEventJoypadButton and old is InputEventJoypadButton):InputMap.action_erase_event(action,old)
 InputMap.action_add_event(action,clean)
 if save_value:
  var prior: Variant=config.get_value("bindings",action,{})
  var overrides: Dictionary=prior.duplicate() if prior is Dictionary else {}
  if prior is InputEvent and not family(prior).is_empty():overrides[family(prior)]=prior
  overrides[device]=clean
  config.set_value("bindings",action,overrides);return config.save(save_path)
 return OK
static func family(event: InputEvent) -> String:
 return "key" if event is InputEventKey else "mouse" if event is InputEventMouseButton else "pad" if event is InputEventJoypadButton else ""
static func label_for(action: String) -> String:
 for type in ["key","mouse","pad"]:
  for event in InputMap.action_get_events(action):
   if family(event)==type:return event.as_text().replace(" (Physical)","").replace(" - Physical","").replace("BracketLeft","[").replace("BracketRight","]").replace("Left Mouse Button","LMB").replace("Right Mouse Button","RMB").replace("Middle Mouse Button","MMB")
 return action.replace("_"," ").capitalize()
static func reset() -> Error:
 if config.has_section("bindings"):config.erase_section("bindings")
 var error:=config.save(save_path);install(false);return error
static func save_display() -> Error:
 config.set_value("display","quality",quality);config.set_value("accessibility","large_text",large_text);config.set_value("accessibility","reduced_flashes",reduced_flashes);config.set_value("accessibility","reduced_camera_motion",reduced_camera_motion);config.set_value("display","show_lead_guide",show_lead_guide);return config.save(save_path)
static func apply_node(node: Node) -> void:
 if not is_instance_valid(node):return
 if node is Light3D:
  if not node.has_meta("original_shadow"):node.set_meta("original_shadow",node.shadow_enabled)
  node.shadow_enabled=bool(node.get_meta("original_shadow")) and quality!="low"
 if node is Viewport:node.msaa_3d=Viewport.MSAA_DISABLED if quality=="low" else Viewport.MSAA_2X if quality=="medium" else Viewport.MSAA_4X
 if node is WorldEnvironment and node.environment!=null:
  for property in ["glow_enabled","ssao_enabled"]:
   if not node.has_meta(property):node.set_meta(property,node.environment.get(property))
   node.environment.set(property,bool(node.get_meta(property)) and quality=="high")
 for child in node.get_children():apply_node(child)
static func apply_id(id: int) -> void:
 if is_instance_id_valid(id):apply_node(instance_from_id(id) as Node)

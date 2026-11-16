class_name ControlsPanel
extends VBoxContainer
var waiting:=""
var notice: Label
var buttons: Dictionary={}
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 notice=Label.new();notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;notice.custom_minimum_size.x=420;notice.text="Gamepad: left stick flies, right stick aims, triggers fire; bumpers move vertically. D-pad up interacts. Menus use standard gamepad navigation.";add_child(notice)
 for action in FlightPreferences.ACTIONS:
  if not InputMap.has_action(action):continue
  var button:=Button.new();button.custom_minimum_size.y=34;buttons[action]=button;add_child(button)
  button.pressed.connect(func():waiting=action;notice.text="Press a key, mouse button or gamepad button for "+action+". Esc cancels. Device axes keep their defaults.")
 var reset:=Button.new();reset.text="RESTORE DEFAULT CONTROLS";reset.pressed.connect(func():FlightPreferences.reset();refresh());add_child(reset);refresh()
func refresh() -> void:
 for action in buttons:
  var words: PackedStringArray=[]
  for event in InputMap.action_get_events(action):words.append(event.as_text())
  buttons[action].text=action.replace("_"," ").capitalize()+" / "+", ".join(words)
  buttons[action].text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
func _input(event: InputEvent) -> void:
 if waiting.is_empty():return
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:waiting="";notice.text="Binding cancelled.";get_viewport().set_input_as_handled();return
 if (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed) or (event is InputEventJoypadButton and event.pressed):
  var clean:=event.duplicate() as InputEvent
  if clean is InputEventKey:clean.keycode=event.keycode;clean.physical_keycode=0
  var error:=FlightPreferences.replace(waiting,clean)
  notice.text="Binding saved." if error==OK else "Binding active, but settings could not save."
  waiting="";refresh();get_viewport().set_input_as_handled()

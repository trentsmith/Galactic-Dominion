class_name JourneyPage
extends VBoxContainer
var host: Node
var notice: Label
func _ready() -> void:
 add_theme_constant_override("separation",10);refresh()
func words(value: String) -> void:
 var label:=Label.new();label.text=value;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(label)
func button(value: String,action: Callable) -> Button:
 var control:=Button.new();control.text=value;control.custom_minimum_size.y=36;control.pressed.connect(action);add_child(control);return control
func refresh() -> void:
 for child in get_children():remove_child(child);child.queue_free()
 words("YOUR JOURNEY / %d OF %d BADGES"%[host.profile.journey.claimed.size(),JourneyState.GOALS.size()])
 words("Explore in any order. Pin one personal goal for a small HUD reminder, or leave them all unpinned. These badges award ordinary salvage once; they never alter rare-component odds or require the archived story.")
 var metrics:=JourneyState.metrics(host.profile)
 for id in JourneyState.GOALS:
  var goal: Dictionary=JourneyState.GOALS[id];var progress:=mini(int(metrics[goal.metric]),int(goal.need));var claimed: bool=id in host.profile.journey.claimed
  words("%s / %d OF %d / %s"%[goal.title,progress,goal.need,"EARNED" if claimed else "+%d salvage"%goal.reward]);words(goal.help)
  var bar:=ProgressBar.new();bar.max_value=goal.need;bar.value=progress;bar.show_percentage=false;bar.custom_minimum_size.y=8;add_child(bar)
  var pinned: bool=host.profile.journey.goal==id
  button("UNPIN GOAL" if pinned else "PIN THIS GOAL",func():
   if JourneyState.pin(host.profile,"" if pinned else id):refresh()
   else:notice.text="Goal could not save. "+host.profile.save_error)
  var claim:=button("BADGE EARNED" if claimed else "CLAIM BADGE & SALVAGE",func():
   if JourneyState.claim(host.profile,id):refresh()
   else:notice.text="Badge could not save, or its requirements are incomplete. "+host.profile.save_error)
  claim.disabled=claimed or progress<int(goal.need)
 var checkpoint: Dictionary=host.profile.journey.resume
 words("CONTINUE / "+(FreeRoamWorld.NAMES[int(checkpoint.region)]+" safe dock" if not checkpoint.is_empty() else "No journey checkpoint yet. Fly in Free Roam, then dock with G."))
 words("Local free-roam checkpoints save every 12 seconds, when docking and when returning to the menu. Continue starts at the last serviced station with your optional job progress. NPC fleets start fresh. Unsecured wreck interior data and unextracted surface surveys still require returning through their exit.")
 button("SAVE JOURNEY NOW",func():
  var success: bool=host.save_frontier();notice.text="Journey saved." if success else "Journey could not save. "+host.profile.save_error)
 notice=Label.new();notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(notice)

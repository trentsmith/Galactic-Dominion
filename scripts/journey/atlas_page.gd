class_name AtlasPage
extends VBoxContainer
var host: Node
var battle: FreeRoamMatch
var category:="all"
var search:=""
var list: VBoxContainer
var notice: Label
const KINDS=["all","station","landmark","job","salvage","mineral","beacon","fauna"]
func _ready() -> void:
 size_flags_horizontal=Control.SIZE_EXPAND_FILL;add_theme_constant_override("separation",10)
 var info:=Label.new();info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;info.text="FIELD ATLAS / choose a course without accepting a mission. Stations broadcast coordinates; landmarks still need surveying. Resource contacts appear within sensor range. Personal beacons and discoveries stay separate from online accounts.";add_child(info)
 var row:=HBoxContainer.new();add_child(row)
 var filter:=OptionButton.new();filter.name="AtlasFilter"
 for id in KINDS:filter.add_item(id.capitalize())
 filter.item_selected.connect(func(index):category=KINDS[index];refresh());row.add_child(filter)
 var query:=LineEdit.new();query.name="AtlasSearch";query.placeholder_text="Find a region, place or creature...";query.custom_minimum_size.x=350;query.text_changed.connect(func(value):search=value;refresh());row.add_child(query)
 action(row,"REFRESH",refresh)
 var navigation:=HBoxContainer.new();add_child(navigation)
 action(navigation,"CLEAR COURSE",func():notice.text="Course cleared." if battle.navigation.set_route({}) else "Course could not save. "+battle.profile.save_error)
 if battle.network_role=="offline":
  action(navigation,"SAVE BEACON HERE (MAX 12)",func():
   notice.text="Personal beacon saved." if JourneyState.bookmark(battle.profile,battle.pilot.ship.position,"Beacon in "+FreeRoamWorld.NAMES[FreeRoamWorld.nearest_region(battle.pilot.ship.position)]) else "Beacon could not save: limit reached or "+battle.profile.save_error
   refresh())
 var team:=HBoxContainer.new();add_child(team)
 for i in range(3):action(team,"PING / "+TeamPings.TYPES[i],func():battle.pings.request(i);notice.text="Ping requested. Close the atlas to fly.")
 notice=Label.new();notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(notice)
 list=VBoxContainer.new();list.add_theme_constant_override("separation",10);add_child(list);refresh()
func action(parent: Node,words: String,callback: Callable) -> Button:
 var button:=Button.new();button.text=words;button.custom_minimum_size.y=34;button.pressed.connect(callback);parent.add_child(button);return button
func refresh() -> void:
 if list==null:return
 for child in list.get_children():list.remove_child(child);child.queue_free()
 var entries:=AtlasData.entries(battle)
 entries.sort_custom(func(a,b):
  if a.kind=="job" and b.kind!="job":return true
  if b.kind=="job" and a.kind!="job":return false
  return battle.pilot.ship.position.distance_squared_to(JourneyState.vector(a.at))<battle.pilot.ship.position.distance_squared_to(JourneyState.vector(b.at)))
 var shown:=0
 for entry in entries:
  if category!="all" and entry.kind!=category:continue
  if not search.is_empty() and not (str(entry.name)+" "+FreeRoamWorld.NAMES[int(entry.region)]).to_lower().contains(search.to_lower()):continue
  shown+=1
  var title:=Label.new();title.text=str(entry.name)+" / "+FreeRoamWorld.NAMES[int(entry.region)]+(" / SURVEYED" if entry.kind=="landmark" and entry.known else " / UNSURVEYED" if entry.kind=="landmark" else "");title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;list.add_child(title)
  if entry.has("detail"):
   var detail:=Label.new();detail.text=entry.detail;detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;list.add_child(detail)
  var row:=HBoxContainer.new();list.add_child(row)
  action(row,"SET COURSE / %dm"%int(battle.pilot.ship.position.distance_to(JourneyState.vector(entry.at))),func():notice.text="Course saved. Close O and follow the mint beacon." if battle.navigation.set_route(entry) else "Course could not save. "+battle.profile.save_error)
  action(row,"WARP TO REGION",func():
   if not battle.navigation.set_route(entry):notice.text="Course could not save.";return
   if battle.network_role=="client":battle.travel_requested.emit(int(entry.region));host.close_story()
   elif battle.travel_fleet(int(entry.region)):host.close_story()
   else:notice.text=battle.log_label.text;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE)
  if entry.kind=="beacon" and battle.profile!=null:action(row,"DELETE BEACON",func():
   notice.text="Beacon deleted." if JourneyState.remove_bookmark(battle.profile,entry.id) else "Beacon could not save. "+battle.profile.save_error
   refresh())
 if shown==0:
  var empty:=Label.new();empty.name="NoAtlasContacts";empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;empty.text="No contacts match this filter. Clear the search or try another category. Mineral and salvage contacts appear when you fly within sensor range; creature records appear after survey delivery.";list.add_child(empty)
 if battle.profile!=null:
  var line:=Label.new();line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;line.text="Discovery record: %d regions · %d landmarks · %d creature species. G surveys landmarks; planet scans count once delivered at the landing ship."%[JourneyState.metrics(battle.profile).regions,JourneyState.metrics(battle.profile).landmarks,JourneyState.metrics(battle.profile).fauna];list.add_child(line)

class_name FrontierScreen
extends Control
var host: Node
var body: VBoxContainer
var tab:=0
var notice:=""
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS;theme=CartoonStyle.ui_theme();set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);refresh()
func label(parent: Node,words: String,size_value: int=16) -> Label:
 var item:=Label.new();item.text=words;item.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;item.add_theme_font_size_override("font_size",size_value);parent.add_child(item);return item
func button(parent: Node,words: String,action: Callable,id: String="") -> Button:
 var item:=Button.new();item.text=words;item.custom_minimum_size.y=38
 if not id.is_empty():item.name=id
 item.pressed.connect(action);parent.add_child(item);return item
func manager() -> FrontierDirector:
 if host.battle is FreeRoamMatch:return host.battle.frontier
 if is_instance_valid(host.parked_roam):return host.parked_roam.frontier
 return null
func refresh() -> void:
 for child in get_children():remove_child(child);child.queue_free()
 var background:=ColorRect.new();background.color=Color(.012,.022,.035,.99);background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(background)
 var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,28)
 add_child(margin)
 var layout:=VBoxContainer.new();layout.add_theme_constant_override("separation",12);margin.add_child(layout)
 label(layout,"FRONTIER / FLY YOUR OWN COURSE",27)
 label(layout,"Optional distress calls, discovered wrecks, faction standing and your home base. The scripted campaign is archived.",14)
 var tabs:=TabBar.new()
 for words in ["Distress board","Factions & rumors","Companion protocols","Home facilities","Log & archive","Field atlas","Journey & badges"]:tabs.add_tab(words)
 tabs.current_tab=tab;tabs.tab_changed.connect(func(value):tab=value;refresh());layout.add_child(tabs)
 var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;layout.add_child(scroll)
 body=VBoxContainer.new();body.custom_minimum_size.x=1000;body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",12);scroll.add_child(body)
 var online: bool=host.battle is FreeRoamMatch and host.battle.network_role!="offline"
 if tab==5:
  var flight: FreeRoamMatch=host.battle if host.battle is FreeRoamMatch else host.parked_roam
  if is_instance_valid(flight) and flight.is_inside_tree():
   var atlas:=AtlasPage.new();atlas.host=host;atlas.battle=flight;body.add_child(atlas)
  else:label(body,"Enter Free Roam to browse real station, landmark and resource positions. Your saved creature surveys remain in the discovery records.")
 elif tab==6:
  if online:label(body,"Personal journey badges belong to your local exploration save. Online rewards remain in your host's account service.")
  else:
   var page:=JourneyPage.new();page.host=host;body.add_child(page)
 elif online:shared_board()
 else:
  match tab:
   0:jobs()
   1:factions()
   2:roles()
   3:home()
   4:records()
 label(layout,notice,14)
 var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);layout.add_child(row)
 button(row,"CLOSE / O OR ESC",host.close_story,"CloseFrontier")
 if not online:
  button(row,"RETURN TO FLIGHT" if host.battle is FreeRoamMatch else "ENTER FREE ROAM",func():
   if host.battle is FreeRoamMatch:host.close_story()
   else:launch(false),"LaunchFrontier")
  button(row,"NEW PEACEFUL FLIGHT",func():launch(true))
func launch(peaceful: bool) -> void:
 if host.surface is DerelictExpedition:notice="Return to orbit through the wreck airlock or pause menu first.";refresh();return
 if not host.story_can_travel():notice=host.profile.story_message;refresh();return
 host.close_story();host.start_free_roam(peaceful)
func jobs() -> void:
 var director:=manager()
 if director!=null and not director.active.is_empty():
  label(body,"ACTIVE / "+str(director.active.title),21);label(body,FreeRoamWorld.NAMES[int(director.active.region)]+" / J: star chart");label(body,FrontierData.HELP[director.active.kind]);label(body,"Remaining window: %ds"%maxi(0,360-int(director.elapsed)))
  button(body,"RESUME ACTIVE JOB",host.close_story)
  if host.battle is FreeRoamMatch:button(body,"ABANDON JOB / NO REWARD",func():director.cancel();refresh())
  return
 label(body,"Choose a signal. Nothing here is required to explore.",20)
 var offers: Array[Dictionary]=director.offers if director!=null else FrontierData.offers(host.profile)
 for offer in offers:
  if offer.slot in host.profile.frontier.done:continue
  label(body,"%s / %s / %s"%[offer.title,FreeRoamWorld.NAMES[offer.region],FrontierState.FACTIONS[offer.faction]],20)
  label(body,str(FrontierData.HELP[offer.kind])+"\nReward: %d salvage · +8 standing · 1 intel"%offer.reward,15)
  var launch:=button(body,"ACCEPT / "+str(offer.kind).to_upper(),func():
   if director==null:notice="Enter Free Roam first, then accept a distress call."
   else:
    if director.accept(int(offer.slot)):host.close_story();return
    notice=director.message
   refresh(),"AcceptFrontier_%d"%offer.slot)
  launch.disabled=not host.battle is FreeRoamMatch
func factions() -> void:
 for faction in FrontierState.FACTIONS:
  var points:=int(host.profile.frontier.reputation[faction])
  label(body,"%s / %s / %d"%[FrontierState.FACTIONS[faction],FrontierState.standing(points),points],20)
 label(body,"At +24 standing, that faction's patrols become friendly in solo space. Helping its distress calls adds +8. Destroying its ships lowers standing. WANTED factions send a nearby interception group when you enter their sectors.",15)
 label(body,"RUMOR DESK / %d recovered intel"%int(host.profile.frontier.intel),20)
 label(body,"Finish a distress call or build an observatory to decode component bearings. Follow a rumor job to an existing gold salvage cache, then use K. Legendary and mythic chances are unchanged; a bearing does not promise a rare find.",15)
 var ending: String=host.profile.ship_story.ending
 if ending=="seal":label(body,"ARCHIVED OUTCOME / A relay reconstruction tender near Vesper adds 0.6 hull/s to your fleet's repair outside combat within 500m.")
 elif ending=="preserve":label(body,"ARCHIVED OUTCOME / A contained memory echo watches Vesper. Its decoded map adds 500m to salvage bearings; your observatory displays the core.")
func roles() -> void:
 label(body,"Choose a protocol for equipped non-human companions. Applies on your next deployment; human officers do not spawn a companion.",16)
 var descriptions={"striker":"Original attack behavior and full companion damage.","scout":"70% attack damage; distress and salvage bearings reach farther.","guardian":"60% attack damage; intercepts a nearby hostile missile at most once every eight seconds.","engineer":"50% attack damage; repairs its ship by 2 hull/s after damage has stopped."}
 for id in FrontierState.ROLES:
  label(body,id.to_upper()+" / "+str(descriptions[id]))
  button(body,("SELECTED / " if host.profile.frontier.role==id else "SELECT / ")+id.to_upper(),func():notice="Protocol saved for next deployment." if FrontierState.role(host.profile,id) else "Protocol could not save. "+host.profile.save_error;refresh(),"Protocol_"+id)
func home() -> void:
 label(body,"HOME BASE / %d salvage"%host.profile.salvage,20)
 for id in FrontierState.FACILITIES:
  var level:=int(host.profile.frontier.facilities[id]);var data: Dictionary=FrontierState.FACILITIES[id]
  label(body,"%s / LEVEL %d OF 3"%[data.name,level],20);label(body,data.description,15)
  var build:=button(body,"UPGRADE / %d SALVAGE"%(50*(level+1)),func():
   notice="Facility built." if FrontierState.build(host.profile,id) else "Need more salvage, a working save or an unfinished upgrade."
   if is_instance_valid(host.sanctuary_scene):host.sanctuary_scene.refresh_frontier_modules()
   refresh(),"BuildFrontier_"+id)
  build.disabled=level>=3
 label(body,"WORKSHOP / permanent component schematics",20)
 for id in FrontierState.RECIPES:
  var parts: PackedStringArray=[]
  for key in FrontierState.RECIPES[id]:parts.append("%d %s"%[FrontierState.RECIPES[id][key],key])
  var craft:=button(body,"FABRICATE "+CollectionCatalog.find(id).display_name+" / "+" + ".join(parts),func():notice="Blueprint saved. Fit it in Fleet Hangar." if FrontierState.craft(host.profile,id) else "Need a workshop, the listed materials, an undiscovered blueprint and a writable save.";refresh())
  craft.disabled=host.profile.owns(id)
 button(body,"VISIT YOUR SANCTUARY / HOME",func():
  if host.story_can_travel():host.close_story();host.show_sanctuary()
  else:notice=host.profile.story_message;refresh())
func records() -> void:
 label(body,"%d optional jobs completed"%int(host.profile.frontier.completed),20)
 for entry in host.profile.frontier.log:label(body,str(entry),15)
 label(body,"CAMPAIGN ARCHIVE / preserved",20)
 label(body,"The Fractured Relay, its choices and the biological story remain in your save. Campaign guidance and forced objectives are disabled in this free-roam release. They can be re-enabled by the campaign feature setting for a future build.")
 label(body,"Co-op space jobs are available from Online → Co-op Frontier. Planet and wreck interiors remain local expeditions in this release.",15)
func shared_board() -> void:
 var director:=manager()
 label(body,"ONLINE / server-authoritative space jobs",21)
 if not host.battle.cooperative:
  label(body,"This session is PvP Free Roam. To fly as one allied team, start Co-op Frontier from the online lobby. Local facilities, roles and wildlife rewards stay separate from online inventory.");return
 if director!=null and not director.active.is_empty():label(body,"SHARED JOB / "+str(director.active.title)+"\n"+FrontierData.HELP[director.active.kind]);button(body,"RETURN TO SHARED FLIGHT",host.close_story)
 else:
  label(body,"The lobby leader can choose a shared signal. All allied human pilots may help. Hold F at repair/rescue signals; escort work shares participation within the mission area.")
  for i in range(3):
   var kind: String=["rescue","repair","escort"][i]
   button(body,"REQUEST SHARED "+kind.to_upper(),func():host.network.ship_event.rpc_id(1,"frontier_start",i);notice="Request sent to host. Close the board to see the shared signal.";refresh())
 label(body,"Rewards are recorded by your host's account service, once per event and eligible account. Local save files cannot mint online rewards.",14)

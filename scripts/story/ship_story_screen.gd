class_name ShipStoryScreen
extends Control
var host: Node
var readonly:=false
var npc:="astra"
var body: VBoxContainer
var tab_index:=0
var content: VBoxContainer
const MINT:=Color(.64,.87,.80)
const MUTED:=Color(.57,.68,.75)
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS;theme=CartoonStyle.ui_theme();set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);refresh()
func label(parent: Node,words: String,font_size: int=16,color: Color=Color(.9,.94,.96)) -> Label:
 var item:=Label.new();item.text=words;item.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;item.size_flags_horizontal=Control.SIZE_EXPAND_FILL;item.add_theme_font_size_override("font_size",font_size);item.add_theme_color_override("font_color",color);parent.add_child(item);return item
func button(parent: Node,words: String,action: Callable,id: String="") -> Button:
 var item:=Button.new();item.text=words;item.custom_minimum_size.y=36
 if not id.is_empty():item.name=id
 item.pressed.connect(func():SpaceAudio.play("click"));item.pressed.connect(action);parent.add_child(item);return item
func refresh() -> void:
 for child in get_children():remove_child(child);child.queue_free()
 var bg:=ColorRect.new();bg.color=Color(.012,.021,.034,.99);bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(bg)
 var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,24)
 add_child(margin)
 body=VBoxContainer.new();body.add_theme_constant_override("separation",12);margin.add_child(body)
 var header:=HBoxContainer.new();body.add_child(header)
 var heading:=VBoxContainer.new();heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(heading)
 label(heading,"N E X U S   A R C H I V E S   /   F L E E T   C O M M S",12,MINT)
 label(heading,"The Fractured Relay",28)
 button(header,"CLOSE / O OR ESC",host.close_story,"CloseShipStory")
 var row:=HBoxContainer.new();row.add_theme_constant_override("separation",24);row.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_child(row)
 var rail:=VBoxContainer.new();rail.custom_minimum_size.x=270;rail.add_theme_constant_override("separation",12);row.add_child(rail)
 label(rail,"COMMISSION / LANTERN NETWORK",12,MUTED)
 var step:=ShipCampaign.stage(host.profile)
 var stage_log:=""
 for i in range(7):stage_log+=("✓ " if i<step else "→ " if i==step else "· ")+ShipCampaign.TITLES[i]+"\n\n"
 label(rail,stage_log,14)
 var rail_note: String="LIVE SORTIE / comms paused with local play" if host.ship_story_busy() else "SOLO CAMPAIGN / progress saves at objectives"
 label(rail,rail_note,12,MINT)
 var right:=VBoxContainer.new();right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;right.add_theme_constant_override("separation",10);row.add_child(right)
 label(right,"OBJECTIVE %d / 7"%mini(7,step+1) if step<7 else "COMMISSION ARCHIVED",12,MINT)
 label(right,ShipCampaign.TITLES[step],22)
 label(right,ShipCampaign.HINTS[step],15)
 var tabs:=TabBar.new();tabs.name="NexusJournalTabs"
 for title in ["Briefing","Recordings","Nexus dossiers","Sortie record"]:tabs.add_tab(title)
 tabs.current_tab=tab_index;right.add_child(tabs)
 var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;right.add_child(scroll)
 content=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_theme_constant_override("separation",12);scroll.add_child(content)
 tabs.tab_changed.connect(func(index):tab_index=index;refresh_content())
 refresh_content()
 var message: String="ONLINE / local commission controls are disabled; this server keeps flying." if readonly else host.profile.story_message
 label(body,message,13,Color(1,.78,.5) if host.profile.save_blocked or not host.profile.save_error.is_empty() else MUTED)
 var actions:=HBoxContainer.new();actions.add_theme_constant_override("separation",12);body.add_child(actions)
 var words: Array=["ACCEPT ASTRA'S COMMISSION","LAUNCH / VARKHOSS BLOCKADE","FOLLOW THE SALVAGE TRAIL","OPEN HANGAR / FIT ENGINE","LAUNCH / MNEMOSYNE","LAUNCH / RIFT WARFRONT","ARCHIVE THE TRANSMISSION · +100 SALVAGE","CONTINUE FREE FLIGHT"]
 var primary:=button(actions,"RESUME CURRENT SORTIE" if host.ship_story_busy() else words[step],host.ship_story_action,"ShipStoryObjectiveButton");primary.size_flags_horizontal=Control.SIZE_EXPAND_FILL;primary.disabled=readonly or (step==5 and host.profile.ship_story.decision.is_empty())
 var hangar:=button(actions,"FLEET HANGAR",func():host.story_travel("hangar"));hangar.disabled=readonly or host.ship_story_busy()
func refresh_content() -> void:
 for child in content.get_children():content.remove_child(child);child.queue_free()
 match tab_index:
  0:briefing()
  1:recordings()
  2:dossiers()
  3:records()
func briefing() -> void:
 var step:=ShipCampaign.stage(host.profile)
 var voices:=HBoxContainer.new();content.add_child(voices)
 for id in ["astra","sera","milo"]:
  var choice:=button(voices,str(NexusStoryData.character(id).name),func():npc=id;refresh_content());choice.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  choice.modulate=NexusStoryData.character(id).color if npc==id else Color.WHITE
 var person:=NexusStoryData.character(npc)
 label(content,str(person.name).to_upper()+" / "+str(person.role),13,person.color)
 label(content,ShipCampaign.dialogue(npc,"mission",step),17)
 if step==5 or step==7:
  protocol_controls()
 if step==7:
  label(content,NexusStoryData.ending(host.profile.ship_story.ending),17,MINT)
 if ShipCampaign.MISSIONS.has(step):
  var data: Dictionary=NexusStoryData.MISSIONS[ShipCampaign.MISSIONS[step]]
  label(content,str(data.location).to_upper(),12,MUTED);label(content,data.brief,15);label(content,data.bonus,14,MINT)
 label(content,ShipCampaign.dialogue(npc,"help",step),13,MUTED)
func protocol_controls() -> void:
 var state: Dictionary=host.profile.ship_story
 label(content,"FRACTURE PROTOCOL / "+("LOCKED FOR THIS CHAPTER" if state.decision_locked else "CHOOSE BEFORE LAUNCH"),14,MINT)
 label(content,"SEAL closes the local passage; Mnemosyne's remaining voices stay beyond it. PRESERVE evacuates a memory core and commits the Vanguard to contain and study it. Both routes pay the same chapter reward. Launching locks the choice.",15)
 var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);content.add_child(row)
 for id in ["seal","preserve"]:
  var choice:=button(row,("✓ " if state.decision==id else "")+("SEAL / THREE CONDUITS" if id=="seal" else "PRESERVE / CORE ESCORT"),func():host.choose_ship_protocol(id),"Protocol_"+id)
  choice.disabled=readonly or state.decision_locked or host.ship_story_busy();choice.size_flags_horizontal=Control.SIZE_EXPAND_FILL
func recordings() -> void:
 label(content,"RECOVERED TRANSMISSIONS",15,MINT)
 label(content,"Recovered sortie transmissions and the lines already received in your current flight. Unheard dialogue stays sealed.",13,MUTED)
 var heard: Array=[]
 for mission in NexusStoryData.MISSIONS:
  var record: Dictionary=host.profile.ship_story.reports.get(mission,{})
  for id in record.get("heard",[]):
   if not id in heard:heard.append(id)
 if is_instance_valid(host.battle) and is_instance_valid(host.battle.narrative):
  for id in host.battle.narrative.comms.history:
   if not id in heard:heard.append(id)
 if heard.is_empty():label(content,"No transmissions recovered yet. Launch the highlighted sortie.",16)
 for id in heard:
  var line: Array=NexusStoryData.RADIO[id];var speaker:=NexusStoryData.character(line[0])
  label(content,str(speaker.name).to_upper(),12,speaker.color);label(content,str(line[1]),16)
func dossiers() -> void:
 var stage:=ShipCampaign.stage(host.profile)
 label(content,"PEOPLE / FACTIONS / WHAT WE CAN VERIFY",15,MINT)
 for id in ["astra","sera","milo","veyr","choir"]:
  if (id=="veyr" and stage<2) or (id=="choir" and stage<5):continue
  var person:=NexusStoryData.character(id)
  label(content,str(person.name),17,person.color)
  label(content,"Astra runs frontier operations. The sealed survey files suggest she knows more about Mnemosyne than her first briefing admits." if id=="astra" and stage<5 else str(person.bio),15)
 for id in NexusStoryData.CODEX:
  var entry: Dictionary=NexusStoryData.CODEX[id]
  if stage<int(entry.unlock):
   label(content,"SEALED DOSSIER / continue the commission",13,MUTED);continue
  label(content,str(entry.title),18,MINT);label(content,entry.body,15)
func records() -> void:
 label(content,"SORTIES / REPLAYS / COMMENDATIONS",15,MINT)
 label(content,"Replays preserve campaign progress and do not repeat component commissions or the 100-salvage chapter payout. Normal battle salvage still applies. A first-time optional commendation can still be earned.",13,MUTED)
 label(content,"LANTERN KEEPER / civilian relay preserved above 70% · +25 salvage earned" if "lantern_keeper" in host.profile.ship_story.honors else "LANTERN KEEPER / preserve 70% relay integrity to earn this commendation once",14)
 for mission in NexusStoryData.MISSIONS:
  var data: Dictionary=NexusStoryData.MISSIONS[mission]
  label(content,data.title,18,MINT)
  var report: Dictionary=host.profile.ship_story.reports.get(mission,{})
  if report.is_empty():label(content,"No detailed sortie recording. Earlier-build completions remain valid.",14,MUTED)
  else:label(content,"Last sortie: %s · %d:%02d · %d survivors · %d%% integrity%s"%["success" if report.success else "lost",int(report.seconds)/60,int(report.seconds)%60,int(report.allies),int(report.integrity)," · "+str(report.choice).to_upper() if not str(report.choice).is_empty() else ""],14)
  var replay:=button(content,"REPLAY / "+str(data.title),func():host.replay_ship_story(mission),"Replay_"+mission)
  replay.disabled=readonly or host.ship_story_busy() or not ShipCampaign.can_replay(host.profile,mission) or (mission=="nexus_warfront" and host.profile.ship_story.decision.is_empty())

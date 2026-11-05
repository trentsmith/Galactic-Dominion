class_name ShipStoryScreen
extends Control
var host: Node
var readonly:=false
var npc:="astra"
var body: VBoxContainer
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS;theme=CartoonStyle.ui_theme();set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var bg:=ColorRect.new();bg.color=Color(.012,.02,.04,.99);bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(bg)
 var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,32)
 add_child(margin)
 var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;margin.add_child(scroll)
 body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",14);scroll.add_child(body);refresh()
func text(content: String,size_value: int=17) -> Label:
 var item:=Label.new();item.text=content;item.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;item.custom_minimum_size.x=600;item.add_theme_font_size_override("font_size",size_value);body.add_child(item);return item
func button(content: String,action: Callable,id: String="") -> Button:
 var item:=Button.new();item.text=content;item.custom_minimum_size.y=38
 if not id.is_empty():item.name=id
 item.pressed.connect(action);body.add_child(item);return item
func refresh() -> void:
 for child in body.get_children():body.remove_child(child);child.queue_free()
 var step:=ShipCampaign.stage(host.profile)
 text("NEXUS ARCHIVES / THE FRACTURED RELAY",28)
 text("THE CRIMSON–ELDRITCH WAR / FLEET COMMISSION",14)
 var log:=""
 for i in range(7):log+=("✓ " if i<step else "→ " if i==step else "· ")+ShipCampaign.TITLES[i]+"\n"
 text(log,14);text(ShipCampaign.TITLES[step],24);text(ShipCampaign.HINTS[step])
 if not readonly:
  var actions:=["ACCEPT FLEET COMMISSION","LAUNCH 3v3 / CRIMSON BLOCKADE","FLY TO COMPONENT SALVAGE","OPEN FLEET HANGAR / FIT ENGINE","LAUNCH 3v3 / DREAMING ABYSS","LAUNCH 10v10 / RIFT WARFRONT","ARCHIVE TRANSMISSION / +100 SALVAGE","EXPLORE THE GALAXY"]
  button(actions[step],host.ship_story_action,"ShipStoryObjectiveButton")
  button("FLEET HANGAR",func():host.story_travel("hangar"))
 for id in ["astra","sera","milo"]:
  button("COMMS / "+("Archivist Sera" if id=="sera" else StoryNPC.NAMES[id]),func():npc=id;refresh())
 text(ShipCampaign.dialogue(npc,"mission",step))
 button("NEXUS LORE",func():text(ShipCampaign.dialogue(npc,"lore",step)))
 button("FLIGHT AND MISSION HELP",func():text(ShipCampaign.dialogue(npc,"help",step)))
 text("Online flight continues. Leave online play before local commission actions." if readonly else host.profile.story_message,14)
 button("CLOSE COMMS / O OR ESC",host.close_story)

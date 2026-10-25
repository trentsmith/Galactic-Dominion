class_name StoryScreen
extends Control
var host: Node
var npc := "astra"
var readonly := false
var body: VBoxContainer
var speech: Label
var message: Label
var portrait_world: Node3D
var mission_log: Label
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 theme=CartoonStyle.ui_theme()
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var bg:=ColorRect.new();bg.color=Color(.015,.025,.045,.98);bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(bg)
 var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,24)
 add_child(margin)
 var layout:=VBoxContainer.new();margin.add_child(layout)
 var title:=Label.new();title.text="THE LANTERN SIGNAL / MISSION JOURNAL";title.add_theme_font_size_override("font_size",26);layout.add_child(title)
 var row:=HBoxContainer.new();row.size_flags_vertical=Control.SIZE_EXPAND_FILL;layout.add_child(row)
 var left:=VBoxContainer.new();left.custom_minimum_size.x=340;row.add_child(left)
 var viewport_container:=SubViewportContainer.new();viewport_container.custom_minimum_size=Vector2(320,150);left.add_child(viewport_container)
 var viewport:=SubViewport.new();viewport.size=Vector2i(320,150);viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport_container.add_child(viewport)
 portrait_world=Node3D.new();viewport.add_child(portrait_world)
 var camera:=Camera3D.new();camera.fov=32;camera.position=Vector3(0,1.55,-4);portrait_world.add_child(camera);camera.look_at(Vector3(0,1.5,0))
 var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-30,-30,0);portrait_world.add_child(light)
 for id in ["astra","sera","milo"]:
  button(left,StoryNPC.NAMES[id],func():npc=id;refresh())
 button(left,"About the worlds",func():say("lore"))
 button(left,"How does this work?",func():say("help"))
 var log:=Label.new();mission_log=log;log.add_theme_font_size_override("font_size",14);log.text="";log.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;log.custom_minimum_size.x=330;left.add_child(log)
 var step:=StoryCampaign.stage(host.profile)
 for index in range(7):log.text+=("✓ " if index<step else "→ " if index==step else "· ")+StoryCampaign.TITLES[index]+"\n"
 var scroll:=ScrollContainer.new();scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;row.add_child(scroll)
 body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",14);scroll.add_child(body)
 button(layout,"CLOSE / O OR ESC",host.close_story)
 refresh()
func button(parent: Node,text: String,action: Callable) -> Button:
 var result:=Button.new();result.text=text;result.custom_minimum_size.y=34;result.pressed.connect(action);parent.add_child(result);return result
func label(text: String,size: int=16) -> Label:
 var result:=Label.new();result.text=text;result.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;result.custom_minimum_size.x=560;result.add_theme_font_size_override("font_size",size);body.add_child(result);return result
func refresh() -> void:
 for child in body.get_children():body.remove_child(child);child.queue_free()
 for child in portrait_world.get_children():
  if child is StoryNPC:portrait_world.remove_child(child);child.queue_free()
 var actor:=StoryNPC.new();actor.npc_id=npc;portrait_world.add_child(actor)
 var stage:=StoryCampaign.stage(host.profile)
 mission_log.text=""
 for index in range(7):mission_log.text+=("✓ " if index<stage else "→ " if index==stage else "· ")+StoryCampaign.TITLES[index]+"\n"
 label("OBJECTIVE %d / 7 · %s"%[mini(7,stage+1),StoryCampaign.TITLES[stage]],22)
 label(StoryCampaign.HINTS[stage])
 label(StoryNPC.NAMES[npc].to_upper(),18)
 speech=label(StoryCampaign.dialogue(npc,"mission",stage))
 message=label("Online flight continues. Local story actions require leaving online play." if readonly else host.profile.story_message,14)
 if readonly:return
 var actions:=["Accept Astra's mission (+2 pods)","Follow Varkhoss waypoint in space","Continue rescue expedition","Accept Sera's reserved parts kit","Open Milo's workshop","Launch Crimson patrol encounter","Archive the signal (+75 salvage)","Explore the galaxy"]
 var action:=button(body,actions[stage],func():host.story_action())
 action.name="StoryObjectiveButton"
 if npc=="milo" or stage==4:
  label("MILO'S WORKSHOP / PERMANENT COMPONENT BLUEPRINTS",18)
  for id in StoryCampaign.RECIPES:
   var definition:=CollectionCatalog.find(id)
   label(definition.display_name+" · "+definition.modifier_text(),14)
   var price: String="Sera's reserved kit" if id=="engine_sprint" and host.profile.story.kit else StoryCampaign.recipe_text(id)
   var craft:=button(body,("Owned · " if host.profile.owns(id) else "Craft · ")+definition.display_name+" / "+price,func():StoryCampaign.craft(host.profile,id);refresh())
   craft.name="Craft_"+id
  var fit:=button(body,"FIT SPRINT DRIVE TO F1 (NEXT LAUNCH)",func():StoryCampaign.fit_engine(host.profile);refresh())
  fit.name="StoryFitEngine"
 button(body,"Visit sanctuary",func():host.story_travel("sanctuary"))
 button(body,"Open fleet hangar",func():host.story_travel("hangar"))
func say(topic: String) -> void:
 speech.text=StoryCampaign.dialogue(npc,topic,StoryCampaign.stage(host.profile))

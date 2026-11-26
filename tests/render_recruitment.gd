extends SceneTree
## Native UI capture with a throwaway account fixture, never a live save.
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var args:=OS.get_cmdline_user_args()
 if not "--profile" in args:push_error("Pass a fixture --profile JSON path");quit(1);return
 var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[args.find("--profile")+1]))
 root.size=Vector2i(1280,720)
 var main=load("res://scenes/main.tscn").instantiate()
 main.profile_path="user://render-recruitment-only.json";root.add_child(main)
 await process_frame
 main.online_api.account=data;main.show_online()
 for i in range(5):await process_frame
 var hub: OnlineHub
 for child in main.menu.get_children():
  if child is OnlineHub:hub=child
 var tabs: TabContainer=hub.find_children("","TabContainer",true,false)[0]
 hub.recruitment_offers=data.offers
 for offer in data.offers:hub.recruit_list.add_item("%s  ·  %s  ·  %d SALVAGE"%[offer.name,str(offer.hull).capitalize(),offer.cost])
 hub.recruit_list.select(0);hub._recruit_selected(0)
 for tab_name in ["Connect & Lobby","Recruitment","Online Fleet","Battle Fleet"]:
  for i in range(tabs.get_tab_count()):
   if tabs.get_tab_title(i)==tab_name:tabs.current_tab=i
  if tab_name=="Battle Fleet":
   hub.battle_roster.select(4);hub._update_vessel()
   print("FLEET_UI_FITTING selected=",hub.vessel_item.get_item_metadata(hub.vessel_item.selected)," actual=",hub._selected_vessel().loadout.engine)
  for i in range(8):await process_frame
  await RenderingServer.frame_post_draw
  var slug: String=tab_name.to_lower().replace(" & ","-").replace(" ","-")
  var capture:=root.get_texture().get_image()
  capture.save_png("/tmp/gd46-"+slug+".png")
  if tab_name=="Battle Fleet":capture.save_webp("res://docs/images/fleet-recruitment.webp",true,.9)
  print("RECRUITMENT_UI_CAPTURE ",tab_name)
 main.queue_free()
 for i in range(5):await process_frame
 await RenderingServer.frame_post_draw
 quit()

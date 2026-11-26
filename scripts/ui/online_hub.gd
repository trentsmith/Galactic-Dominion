class_name OnlineHub
extends Control
signal back_requested
var api: OnlineAPI
var session: OnlineSession
var api_address: LineEdit
var combat_address: LineEdit
var combat_port: SpinBox
var username: LineEdit
var password: LineEdit
var status: Label
var lobby_info: Label
var account_info: Label
var inventory: ItemList
var market: ItemList
var offers: ItemList
var market_entries: Array = []
var offer_entries: Array = []
var listing_price: SpinBox
var offer_amount: SpinBox
var public_name: LineEdit
var public_info: Label
var fleet_index: OptionButton
var fitting_slot: OptionButton
var fitting_item: OptionButton
var hull_choice: OptionButton
var fleet_summary: Label
var recruit_list: ItemList
var recruit_details: Label
var recruitment_offers: Array = []
var battle_roster: ItemList
var battle_count: Label
var vessel_details: Label
var vessel_slot: OptionButton
var vessel_item: OptionButton
var fit_options: Array = []
var busy := false
var connection := ServerConnection.new()

func _ready() -> void:
 connection.load_settings()
 theme = CartoonStyle.ui_theme()
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var bg := ColorRect.new()
 bg.color = Color(0.014, 0.025, 0.055)
 bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(bg)
 var margin := MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left", "right", "top", "bottom"]:
  margin.add_theme_constant_override("margin_" + side, 25)
 add_child(margin)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation", 10)
 margin.add_child(column)
 var header := HBoxContainer.new()
 column.add_child(header)
 var title := label("GALACTIC NETWORK  /  RECRUIT · COMMAND · DUEL", 24)
 title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 header.add_child(title)
 button(header, "MAIN MENU", func():
  session.disconnect_session()
  back_requested.emit())
 status = label("Run the self-hosted server first. Online progress is separate from your local save.", 14)
 status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 column.add_child(status)
 var tabs := TabContainer.new()
 tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
 column.add_child(tabs)
 var connect_scroll := ScrollContainer.new()
 connect_scroll.name = "Connect & Lobby"
 connect_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 tabs.add_child(connect_scroll)
 var connect_tab := VBoxContainer.new()
 connect_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 connect_tab.add_theme_constant_override("separation", 14)
 connect_scroll.add_child(connect_tab)
 api_address = field(connect_tab, "Account server URL", connection.api_url)
 combat_address = field(connect_tab, "Combat server address", connection.combat_host)
 combat_port = number(connect_tab, "Combat UDP port", connection.combat_port, 65535)
 button(connect_tab, "USE THIS ADDRESS FOR A LOCAL-NETWORK HOST", func():
  var host := combat_address.text.strip_edges()
  if not host.is_empty(): api_address.text = "http://" + host + ":8080")
 username = field(connect_tab, "Commander name (3–24 letters, numbers, underscores)", connection.commander)
 password = field(connect_tab, "Password (at least 10 characters)", "")
 password.secret = true
 var login_buttons := HBoxContainer.new()
 connect_tab.add_child(login_buttons)
 button(login_buttons, "SIGN IN", func(): _sign_in(false))
 button(login_buttons, "CREATE ACCOUNT", func(): _sign_in(true))
 button(login_buttons, "JOIN OPEN ARENA", _join)
 var ready_buttons := HBoxContainer.new()
 connect_tab.add_child(ready_buttons)
 button(ready_buttons, "TEAM 1", func():
  if not session.client_lobby.is_empty(): session.choose_team.rpc_id(1, 0))
 button(ready_buttons, "TEAM 2", func():
  if not session.client_lobby.is_empty(): session.choose_team.rpc_id(1, 1))
 button(ready_buttons, "READY", func():
  if not session.client_lobby.is_empty():
   session.ready_up.rpc_id(1, true))
 button(ready_buttons, "NOT READY", func():
  if not session.client_lobby.is_empty():
   session.ready_up.rpc_id(1, false))
 button(ready_buttons, "LAUNCH MATCH (LOBBY LEADER)", func():
  if not session.client_lobby.is_empty():
   session.request_start.rpc_id(1))
 var roam_buttons := HBoxContainer.new()
 connect_tab.add_child(roam_buttons)
 button(roam_buttons, "LAUNCH FREE ROAM (LOBBY LEADER)", func():
  if not session.client_lobby.is_empty(): session.request_start.rpc_id(1, "free_roam"))
 button(roam_buttons,"LAUNCH CO-OP FRONTIER",func():
  if not session.client_lobby.is_empty():session.request_start.rpc_id(1,"co_op"))
 var duel_row := HBoxContainer.new()
 connect_tab.add_child(duel_row)
 button(duel_row, "FLEET DUEL · YOUR FLEET vs THEIR FLEET", func():
  if session.client_lobby.is_empty():
   status.text = "Sign in and join the arena first. Fleet Duel needs two commanders on opposing teams."
  else: session.request_start.rpc_id(1, "fleet_duel"))
 button(ready_buttons, "LEAVE LOBBY", func():
  session.disconnect_session()
  lobby_info.text = "Disconnected.")
 lobby_info = label("FLEET DUEL: two commanders, up to 50 owned ships each. Choose opposite teams, ready up, then the leader launches.
Recruit and customize in Battle Fleet before joining. F1–F3 lead ships, [ / ] cycle all survivors, 1–5 give orders.
Fleet Royale / Free Roam / Co-op still support up to six pilots. One session per host.", 14)
 lobby_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 connect_tab.add_child(lobby_info)
 var recruit_tab := VBoxContainer.new()
 recruit_tab.name = "Recruitment"
 recruit_tab.add_theme_constant_override("separation", 12)
 tabs.add_child(recruit_tab)
 var recruit_intro := label("RECRUIT A FLEET\nSpend online salvage to hire permanent ships. Own up to 200 vessels; choose up to 50 for Fleet Duel.\nEvery class has different stats and an ability. Keep your ships after battle, even if destroyed.", 16)
 recruit_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 recruit_tab.add_child(recruit_intro)
 button(recruit_tab, "REFRESH RECRUITMENT BOARD", _refresh_recruits)
 recruit_list = ItemList.new()
 recruit_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
 recruit_list.item_selected.connect(_recruit_selected)
 recruit_tab.add_child(recruit_list)
 recruit_details = label("Sign in to see available ships and server prices.", 16)
 recruit_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 recruit_tab.add_child(recruit_details)
 var recruit_buttons := HBoxContainer.new()
 recruit_tab.add_child(recruit_buttons)
 button(recruit_buttons, "RECRUIT SELECTED SHIP", _recruit)
 button(recruit_buttons, "RETRY PENDING RECRUITMENT", _retry_recruit)
 var fleet_tab := VBoxContainer.new()
 fleet_tab.name = "Online Fleet"
 fleet_tab.add_theme_constant_override("separation", 12)
 tabs.add_child(fleet_tab)
 account_info = label("Sign in to view your server-owned fleet.", 17)
 account_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 fleet_tab.add_child(account_info)
 fleet_summary = label("Three active vessels · additional recruits wait in reserve", 14)
 fleet_tab.add_child(fleet_summary)
 button(fleet_tab, "REFRESH ONLINE INVENTORY", _refresh_account)
 var selectors := HBoxContainer.new()
 fleet_tab.add_child(selectors)
 fleet_index = OptionButton.new()
 for index in range(3):
  fleet_index.add_item("FLEET SLOT %d" % (index + 1))
 fleet_index.item_selected.connect(func(_index): _update_fits())
 selectors.add_child(fleet_index)
 hull_choice = OptionButton.new()
 selectors.add_child(hull_choice)
 button(selectors, "DEPLOY OWNED SHIP", _equip_hull)
 var fitting_row := HBoxContainer.new()
 fleet_tab.add_child(fitting_row)
 fitting_slot = OptionButton.new()
 for slot in PlayerProfile.SLOTS:
  fitting_slot.add_item(slot.capitalize())
 fitting_slot.item_selected.connect(func(_index): _update_fits())
 fitting_row.add_child(fitting_slot)
 fitting_item = OptionButton.new()
 fitting_row.add_child(fitting_item)
 button(fitting_row, "FIT ITEM", _equip)
 inventory = ItemList.new()
 inventory.size_flags_vertical = Control.SIZE_EXPAND_FILL
 fleet_tab.add_child(inventory)
 button(fleet_tab, "COMMISSION SELECTED SHIP BLUEPRINT INTO RESERVE (CONSUMES ONE)", _commission)
 var reserve_note := label("Deploying returns the previous ship to reserve with its fittings. Contracts and commissioned vessels stay yours; unused blueprint copies remain tradable.", 13)
 reserve_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 fleet_tab.add_child(reserve_note)
 var research_row := HBoxContainer.new()
 fleet_tab.add_child(research_row)
 var research_item := OptionButton.new()
 for definition in CollectionCatalog.DEFINITIONS:
  if definition.research_cost > 0:
   var index := research_item.item_count
   research_item.add_item("%s (%d salvage)" % [definition.display_name, definition.research_cost])
   research_item.set_item_metadata(index, definition.id)
 research_row.add_child(research_item)
 button(research_row, "RESEARCH", func():
  _mutation("/research", {"item": research_item.get_item_metadata(research_item.selected)}))
 _build_battle_fleet_tab(tabs)
 var market_tab := VBoxContainer.new()
 market_tab.name = "Marketplace"
 market_tab.add_theme_constant_override("separation", 10)
 tabs.add_child(market_tab)
 market_tab.add_child(label("Every online win grants a permanent random hull. Trade copies here using salvage; items and offer funds are held in escrow.", 14))
 button(market_tab, "REFRESH LISTINGS & OFFERS", _refresh_market)
 market = ItemList.new()
 market.size_flags_vertical = Control.SIZE_EXPAND_FILL
 market_tab.add_child(market)
 var market_actions := HBoxContainer.new()
 market_tab.add_child(market_actions)
 button(market_actions, "BUY SELECTED", func(): _listing_action("/market/buy"))
 button(market_actions, "CANCEL MY LISTING", func(): _listing_action("/market/cancel"))
 offer_amount = number(market_actions, "Offer salvage", 50, 1000000)
 button(market_actions, "MAKE OFFER", _make_offer)
 var listing_row := HBoxContainer.new()
 market_tab.add_child(listing_row)
 listing_price = number(listing_row, "Listing price", 80, 1000000)
 button(listing_row, "LIST SELECTED ONLINE INVENTORY ITEM", _list_item)
 market_tab.add_child(label("Select the item in Online Fleet, then return here to list it. Unequip your last copy first.", 12))
 offers = ItemList.new()
 offers.custom_minimum_size.y = 90
 market_tab.add_child(offers)
 var offer_actions := HBoxContainer.new()
 market_tab.add_child(offer_actions)
 button(offer_actions, "ACCEPT OFFER (SELLER)", func(): _offer_action("/offers/accept"))
 button(offer_actions, "CANCEL / REJECT OFFER", func(): _offer_action("/offers/cancel"))
 var public_tab := VBoxContainer.new()
 public_tab.name = "Public Profiles"
 public_tab.add_theme_constant_override("separation", 12)
 tabs.add_child(public_tab)
 public_name = field(public_tab, "Commander to look up", "")
 button(public_tab, "VIEW PUBLIC PROFILE", _public_profile)
 public_info = label("Public profiles show online fleets, collection records and combat totals.", 16)
 public_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 var public_scroll := ScrollContainer.new()
 public_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 public_tab.add_child(public_scroll)
 public_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 public_scroll.add_child(public_info)
 session.lobby_changed.connect(_lobby_changed)
 session.status_changed.connect(_status)
 _update_account()

func _build_battle_fleet_tab(tabs: TabContainer) -> void:
 var tab := VBoxContainer.new()
 tab.name = "Battle Fleet"
 tab.add_theme_constant_override("separation", 12)
 tabs.add_child(tab)
 battle_count = label("YOUR BATTLE FLEET  /  0 OF 50 SHIPS", 20)
 tab.add_child(battle_count)
 var hint := label("Start with three issued ships, then recruit more. Select any owned vessel to customize its stats and add it to your lineup. F1–F3 are your lead ships; [ / ] lets you pilot every surviving wingmate.", 14)
 hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 tab.add_child(hint)
 var row := HBoxContainer.new()
 row.size_flags_vertical = Control.SIZE_EXPAND_FILL
 row.add_theme_constant_override("separation", 18)
 tab.add_child(row)
 battle_roster = ItemList.new()
 battle_roster.custom_minimum_size.x = 460
 battle_roster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 battle_roster.item_selected.connect(func(_index): _update_vessel())
 row.add_child(battle_roster)
 var details := VBoxContainer.new()
 details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 details.add_theme_constant_override("separation", 14)
 row.add_child(details)
 vessel_details = label("Sign in to inspect ship statistics.", 16)
 vessel_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 vessel_details.size_flags_vertical = Control.SIZE_EXPAND_FILL
 details.add_child(vessel_details)
 vessel_slot = OptionButton.new()
 for slot in PlayerProfile.SLOTS: vessel_slot.add_item(slot.capitalize())
 vessel_slot.item_selected.connect(func(_index): _update_vessel())
 details.add_child(vessel_slot)
 vessel_item = OptionButton.new()
 details.add_child(vessel_item)
 button(details, "FIT SELECTED ITEM TO THIS SHIP", _fit_vessel)
 var actions := HBoxContainer.new()
 tab.add_child(actions)
 button(actions, "ADD TO BATTLE FLEET", func(): _assign_vessel(true))
 button(actions, "RETURN TO RESERVE", func(): _assign_vessel(false))
 button(actions, "REFRESH FLEET", _refresh_account)

func _selected_vessel() -> Dictionary:
 if not is_instance_valid(battle_roster): return {}
 var selected := battle_roster.get_selected_items()
 if selected.is_empty(): return {}
 var sid := str(battle_roster.get_item_metadata(selected[0]))
 for ship in api.account.get("fleet_roster", []):
  if str(ship.id) == sid: return ship
 return {}

func _update_battle_fleet() -> void:
 var selected_id := str(_selected_vessel().get("id", ""))
 battle_roster.clear()
 if api.account.is_empty(): return
 var lineup: Array = api.account.get("battle_fleet", [])
 battle_count.text = "YOUR BATTLE FLEET  /  %d OF 50 SHIPS  ·  %d IN RESERVE" % [lineup.size(), api.account.fleet_roster.size() - lineup.size()]
 var selected := 0
 for ship in api.account.fleet_roster:
  var order := lineup.find(ship.id)
  var row := battle_roster.item_count
  battle_roster.add_item("%s  %s · %s" % ["F%d" % (order + 1) if order in range(3) else "%02d" % (order + 1) if order >= 0 else "—", ship.name, str(ship.hull).capitalize()])
  battle_roster.set_item_metadata(row, ship.id)
  battle_roster.set_item_custom_fg_color(row, Color(.4,.9,1) if order >= 0 else Color(.65,.73,.85))
  if str(ship.id) == selected_id: selected = row
 if battle_roster.item_count > 0: battle_roster.select(selected)
 _update_vessel()

func _update_vessel() -> void:
 var ship := _selected_vessel()
 vessel_item.clear()
 if ship.is_empty(): return
 var stats := FleetManifest.vessel_stats(api.account, ship)
 var order: int = api.account.battle_fleet.find(ship.id)
 vessel_details.text = "%s\n%s · %s\n\nHULL  %d     SHIELDS  %d\nSPEED  %d m/s     TURN  %.1f\nLASER  %d damage / %.2fs\nMISSILE  %d damage / %.1fs\nABILITY  %s / %.0fs recharge\n\n%s" % [ship.name, stats.class_name_text, "BATTLE SLOT %d" % (order+1) if order>=0 else "RESERVE", stats.hull, stats.shield, stats.speed, stats.turn_speed, stats.laser_damage, stats.laser_cooldown, stats.missile_damage, stats.missile_cooldown, stats.ability.to_upper(), stats.ability_recharge, stats.variant_name]
 var slot: String = PlayerProfile.SLOTS[vessel_slot.selected]
 if slot == "crew":
  vessel_item.add_item("AI flight computer (no crew)")
  vessel_item.set_item_metadata(0, "")
 for definition in CollectionCatalog.for_slot(slot, stats.class_name_text):
  if not api.account.inventory.has(definition.id): continue
  var index := vessel_item.item_count
  vessel_item.add_item(definition.display_name)
  vessel_item.set_item_metadata(index, definition.id)
  if ship.loadout.get(slot, "") == definition.id: vessel_item.select(index)

func _assign_vessel(deployed: bool) -> void:
 var ship := _selected_vessel()
 if ship.is_empty():
  status.text = "Select an owned vessel first."
  return
 _mutation("/fleet/assign", {"ship_id": ship.id, "deployed": deployed})

func _fit_vessel() -> void:
 var ship := _selected_vessel()
 if ship.is_empty() or vessel_item.selected < 0: return
 _mutation("/fleet/fit", {"ship_id": ship.id, "slot": PlayerProfile.SLOTS[vessel_slot.selected], "item": vessel_item.get_item_metadata(vessel_item.selected)})

func label(value: String, font_size: int = 16) -> Label:
 var node := Label.new()
 node.text = value
 node.add_theme_font_size_override("font_size", font_size)
 return node

func button(parent: Control, value: String, callback: Callable) -> Button:
 var node := Button.new()
 node.text = value
 node.custom_minimum_size.y = 34
 node.pressed.connect(callback)
 parent.add_child(node)
 return node

func field(parent: Control, title: String, value: String) -> LineEdit:
 var row := HBoxContainer.new()
 parent.add_child(row)
 var text := label(title, 14)
 text.custom_minimum_size.x = 360
 row.add_child(text)
 var node := LineEdit.new()
 node.text = value
 node.custom_minimum_size.x = 360
 row.add_child(node)
 return node

func number(parent: Control, title: String, value: int, maximum: int) -> SpinBox:
 var row := HBoxContainer.new()
 parent.add_child(row)
 row.add_child(label(title, 13))
 var node := SpinBox.new()
 node.min_value = 1
 node.max_value = maximum
 node.value = value
 row.add_child(node)
 return node

func _status(value: String) -> void:
 status.text = value

func _sign_in(register: bool) -> void:
 if busy:
  return
 busy = true
 session.disconnect_session()
 if not connection.save_settings(api_address.text,combat_address.text,int(combat_port.value),username.text):
  status.text = "Check the server URL, address and port. Connection settings could not save."
  busy = false
  return
 api.base_url = api_address.text.strip_edges()
 status.text = "Contacting account server…"
 var reply := await api.sign_in(username.text.strip_edges(), password.text, register)
 if not is_inside_tree():
  return
 busy = false
 password.text = ""
 status.text = str(reply.error) if reply.has("error") else "Signed in. Your server-owned inventory is ready."
 _update_account()
 if reply.has("data"): await _refresh_recruits()

func _join() -> void:
 if busy:
  return
 if not connection.save_settings(api_address.text,combat_address.text,int(combat_port.value),username.text):
  status.text = "Check the server URL, address and port. Connection settings could not save."
  busy = false
  return
 api.base_url = api_address.text.strip_edges()
 await session.join_server(combat_address.text.strip_edges(), int(combat_port.value))

func _lobby_changed(data: Dictionary) -> void:
 var lines: PackedStringArray = []
 for player in data.players:
  lines.append("TEAM %d / SLOT %d  ·  %s  ·  %s%s" % [int(player.team) + 1, int(player.slot) + 1, player.name, "READY" if player.ready else "WAITING", "  (LEADER)" if player.peer == data.leader else ""])
 lobby_info.text = "\n".join(lines)

func _refresh_account() -> void:
 if api.token.is_empty():
  status.text = "Sign in first."
  return
 var reply := await api.refresh()
 if not is_inside_tree():
  return
 status.text = str(reply.error) if reply.has("error") else "Online inventory refreshed."
 _update_account()

func _update_account() -> void:
 inventory.clear()
 hull_choice.clear()
 if api.account.is_empty():
  fleet_summary.text = "Sign in to assemble your online fleet."
  return
 account_info.text = "%s  /  %d SALVAGE  /  %d OWNED SHIPS · %d IN BATTLE FLEET  /  %d WINS" % [api.account.commander_name, api.account.salvage, api.account.get("fleet_roster", []).size(), api.account.get("battle_fleet", []).size(), api.account.wins]
 fleet_summary.text = FleetManifest.summary(api.account)
 for id in api.account.inventory:
  var definition := CollectionCatalog.find(str(id))
  if definition == null or not GameFeatures.collectible_active(definition):
   continue
  var index := inventory.item_count
  inventory.add_item("%s × %d  /  %s" % [definition.display_name, api.account.inventory[id].count, definition.rarity.to_upper()])
  inventory.set_item_metadata(index, id)
 _update_fits()
 _update_battle_fleet()

func _update_fits() -> void:
 if api.account.is_empty():
  return
 var index := fleet_index.selected
 hull_choice.clear()
 for ship in api.account.get("fleet_roster", []):
  var item_index := hull_choice.item_count
  var active_slot: int = api.account.active_ships.find(ship.id)
  hull_choice.add_item("%s · %s%s" % [ship.name, str(ship.hull).capitalize(), " / F%d" % (active_slot + 1) if active_slot >= 0 else " / Reserve"])
  hull_choice.set_item_metadata(item_index, ship.id)
  hull_choice.set_item_disabled(item_index, active_slot >= 0 and active_slot != index)
  if active_slot == index:
   hull_choice.select(item_index)
 fitting_item.clear()
 var slot: String = PlayerProfile.SLOTS[fitting_slot.selected]
 var hull_name: String = CollectionCatalog.SHIP_TYPES[api.account.ship_classes[index]].class_name_text
 if slot == "crew":
  fitting_item.add_item("Unassigned")
  fitting_item.set_item_metadata(0, "")
 for definition in CollectionCatalog.for_slot(slot, hull_name):
  if not api.account.inventory.has(definition.id):
   continue
  var item_index := fitting_item.item_count
  fitting_item.add_item(definition.display_name)
  fitting_item.set_item_metadata(item_index, definition.id)
  if api.account.loadouts[index][slot] == definition.id:
   fitting_item.select(item_index)

func _mutation(path: String, data: Dictionary) -> void:
 if busy or api.token.is_empty():
  status.text = "Sign in first or wait for the current request."
  return
 busy = true
 var reply := await api.request(path, data)
 if not is_inside_tree():
  return
 busy = false
 status.text = str(reply.error) if reply.has("error") else "Server confirmed the change."
 if reply.has("data"):
  await api.refresh()
  if is_inside_tree():
   _update_account()

func _equip() -> void:
 if fitting_item.selected >= 0:
  _mutation("/equip", {"index": fleet_index.selected, "slot": PlayerProfile.SLOTS[fitting_slot.selected], "item": fitting_item.get_item_metadata(fitting_item.selected)})

func _equip_hull() -> void:
 if hull_choice.selected >= 0:
  _mutation("/fleet/deploy", {"index": fleet_index.selected, "ship_id": hull_choice.get_item_metadata(hull_choice.selected)})

func _refresh_recruits() -> void:
 if busy or api.token.is_empty():
  status.text = "Sign in first or wait for the current request."
  return
 busy = true
 var reply := await api.request("/fleet/recruits", {}, HTTPClient.METHOD_GET)
 if not is_inside_tree(): return
 busy = false
 if reply.has("error"):
  status.text = str(reply.error)
  return
 api.account = reply.data.profile
 recruitment_offers = reply.data.offers
 recruit_list.clear()
 for offer in recruitment_offers:
  recruit_list.add_item("%s  ·  %s  ·  %d SALVAGE" % [offer.name, str(offer.hull).capitalize(), offer.cost])
 if not recruitment_offers.is_empty():
  recruit_list.select(0)
  _recruit_selected(0)
 _update_account()
 status.text = "Recruitment board ready · %d / %d ships owned · %d salvage" % [api.account.fleet_roster.size(), reply.data.capacity, api.account.salvage]

func _recruit_selected(index: int) -> void:
 if index < 0 or index >= recruitment_offers.size(): return
 var offer: Dictionary = recruitment_offers[index]
 recruit_details.text = "%s\n%s\n%d salvage · Permanent ownership · Standard fittings · Deploy from Online Fleet" % [offer.name, offer.role, offer.cost]

func _recruit() -> void:
 var selected := recruit_list.get_selected_items()
 if selected.is_empty():
  status.text = "Sign in, refresh the board and select a recruitment contract."
  return
 _request_recruit("/fleet/recruit", {"offer": recruitment_offers[selected[0]].id})

func _commission() -> void:
 var selected := inventory.get_selected_items()
 if selected.is_empty():
  status.text = "Select a won or traded ship blueprint in your online inventory first."
  return
 var item := str(inventory.get_item_metadata(selected[0]))
 if not item.begins_with("ship_"):
  status.text = "Only ship blueprints can be commissioned. Select a ship, not a fitting or crew member."
  return
 _request_recruit("/fleet/commission", {"item": item})

func _request_recruit(path: String, payload: Dictionary) -> void:
 if busy or api.account.is_empty():
  status.text = "Sign in first or wait for the current request."
  return
 var uid := str(api.account.user_id)
 if api.pending_recruitments.has(uid):
  status.text = "A recruitment is awaiting confirmation. Use RETRY PENDING RECRUITMENT to resolve it before hiring another ship."
  return
 payload["request_id"] = Crypto.new().generate_random_bytes(16).hex_encode()
 api.pending_recruitments[uid] = {"path": path, "payload": payload}
 _retry_recruit()

func _retry_recruit() -> void:
 if busy or api.account.is_empty(): return
 var uid := str(api.account.user_id)
 if not api.pending_recruitments.has(uid):
  status.text = "No recruitment is awaiting confirmation."
  return
 busy = true
 status.text = "Confirming recruitment with the account server…"
 var pending: Dictionary = api.pending_recruitments[uid]
 var reply := await api.request(pending.path, pending.payload)
 if not is_inside_tree(): return
 busy = false
 if reply.has("error"):
  if not reply.get("retryable", false): api.pending_recruitments.erase(uid)
  status.text = str(reply.error) + (" Use RETRY PENDING RECRUITMENT; the same request will not charge twice." if reply.get("retryable", false) else "")
  return
 api.pending_recruitments.erase(uid)
 api.account = reply.data.profile
 _update_account()
 status.text = "Recruitment confirmed · ship saved. Open Battle Fleet to customize it and add it to your 50-ship lineup."

func _refresh_market() -> void:
 if api.token.is_empty():
  status.text = "Sign in first."
  return
 var reply := await api.request("/market", {}, HTTPClient.METHOD_GET)
 if not is_inside_tree():
  return
 if reply.has("error"):
  status.text = str(reply.error)
  return
 market_entries = reply.data.filter(func(entry):
  var item:=CollectionCatalog.find(str(entry.item))
  return item==null or GameFeatures.collectible_active(item))
 market.clear()
 for entry in market_entries:
  var definition := CollectionCatalog.find(str(entry.item))
  market.add_item("%s  /  %d SALVAGE  /  %s%s" % [definition.display_name if definition != null else entry.item, entry.price, entry.seller_name, " (YOURS)" if entry.mine else ""])
 var offer_reply := await api.request("/offers", {}, HTTPClient.METHOD_GET)
 if not is_inside_tree():
  return
 if offer_reply.has("data"):
  offer_entries = offer_reply.data
  offers.clear()
  for entry in offer_entries:
   offers.add_item("%s offers %d for %s" % [entry.buyer_name, entry.amount, entry.item])
 status.text = "Marketplace refreshed."

func _listing_action(path: String) -> void:
 var selected := market.get_selected_items()
 if selected.is_empty():
  return
 await _mutation(path, {"listing": market_entries[selected[0]].id})
 if is_inside_tree():
  await _refresh_market()

func _list_item() -> void:
 var selected := inventory.get_selected_items()
 if selected.is_empty():
  status.text = "Select an item in the Online Fleet inventory first."
  return
 await _mutation("/market/list", {"item": inventory.get_item_metadata(selected[0]), "price": int(listing_price.value)})
 if is_inside_tree():
  await _refresh_market()

func _make_offer() -> void:
 var selected := market.get_selected_items()
 if selected.is_empty():
  return
 await _mutation("/offers/create", {"listing": market_entries[selected[0]].id, "amount": int(offer_amount.value)})
 if is_inside_tree():
  await _refresh_market()

func _offer_action(path: String) -> void:
 var selected := offers.get_selected_items()
 if selected.is_empty():
  return
 await _mutation(path, {"offer": offer_entries[selected[0]].id})
 if is_inside_tree():
  await _refresh_market()

func _public_profile() -> void:
 if not connection.save_settings(api_address.text,combat_address.text,int(combat_port.value),username.text):
  status.text = "Check the server URL, address and port. Connection settings could not save."
  busy = false
  return
 api.base_url = api_address.text.strip_edges()
 var reply := await api.request("/profiles?name=" + public_name.text.strip_edges().uri_encode(), {}, HTTPClient.METHOD_GET)
 if not is_inside_tree():
  return
 if reply.has("error"):
  public_info.text = str(reply.error)
  return
 var data: Dictionary = reply.data
 var lines: PackedStringArray = [str(data.commander_name).to_upper(), "%d victories / %d battles  ·  %d kills  ·  %d damage" % [data.wins, data.battles, data.total_kills, data.total_damage], "FLEET  /  " + ", ".join(data.ship_classes), "DISCOVERY RECORDS"]
 if data.has("active_fleet"):
  lines.insert(3, "%d owned ships · Active: %s" % [data.get("fleet_size", 3), ", ".join(data.active_fleet.map(func(ship): return str(ship.name)))])
 for id in data.get("discovery_records", data.inventory):
  var definition := CollectionCatalog.find(str(id))
  if definition != null and GameFeatures.collectible_active(definition):
   var record: Dictionary = data.get("discovery_records", data.inventory)[id]
   var timestamp := int(record.get("discovered_at", 0))
   var found := "Fleet issue" if timestamp == 0 else Time.get_datetime_string_from_unix_time(timestamp).replace("T", " ") + " UTC"
   lines.append(definition.display_name + "  /  " + definition.rarity.to_upper() + "  /  " + found)
 public_info.text = "\n".join(lines)

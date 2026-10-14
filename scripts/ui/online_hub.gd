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
var fit_options: Array = []
var busy := false

func _ready() -> void:
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
 var title := label("GALACTIC NETWORK  /  LOBBY · PROFILES · TRADE", 24)
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
 var connect_tab := VBoxContainer.new()
 connect_tab.name = "Connect & Lobby"
 connect_tab.add_theme_constant_override("separation", 14)
 tabs.add_child(connect_tab)
 api_address = field(connect_tab, "Account server URL", api.base_url)
 combat_address = field(connect_tab, "Combat server address", "127.0.0.1")
 combat_port = number(connect_tab, "Combat UDP port", 7777, 65535)
 username = field(connect_tab, "Commander name (3–24 letters, numbers, underscores)", "")
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
 button(ready_buttons, "LEAVE LOBBY", func():
  session.disconnect_session()
  lobby_info.text = "Disconnected.")
 lobby_info = label("Up to six pilots; each team has three ships. AI fills every empty slot.
Choose Fleet Royale or a continuous free-roam session with AI patrols.
One session per server instance. All connected pilots must be ready.", 16)
 connect_tab.add_child(lobby_info)
 var fleet_tab := VBoxContainer.new()
 fleet_tab.name = "Online Fleet"
 fleet_tab.add_theme_constant_override("separation", 12)
 tabs.add_child(fleet_tab)
 account_info = label("Sign in to view your server-owned fleet.", 17)
 fleet_tab.add_child(account_info)
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
 button(selectors, "SET HULL", _equip_hull)
 fitting_slot = OptionButton.new()
 for slot in PlayerProfile.SLOTS:
  fitting_slot.add_item(slot.capitalize())
 fitting_slot.item_selected.connect(func(_index): _update_fits())
 selectors.add_child(fitting_slot)
 fitting_item = OptionButton.new()
 selectors.add_child(fitting_item)
 button(selectors, "FIT ITEM", _equip)
 inventory = ItemList.new()
 inventory.size_flags_vertical = Control.SIZE_EXPAND_FILL
 fleet_tab.add_child(inventory)
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
 api.base_url = api_address.text.strip_edges()
 status.text = "Contacting account server…"
 var reply := await api.sign_in(username.text.strip_edges(), password.text, register)
 if not is_inside_tree():
  return
 busy = false
 password.text = ""
 status.text = str(reply.error) if reply.has("error") else "Signed in. Your server-owned inventory is ready."
 _update_account()

func _join() -> void:
 if busy:
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
 if api.account.is_empty():
  return
 account_info.text = "%s  /  %d SALVAGE  /  %d DISCOVERIES  /  %d WINS IN %d MATCHES" % [api.account.commander_name, api.account.salvage, api.account.inventory.size(), api.account.wins, api.account.battles]
 for id in api.account.inventory:
  var definition := CollectionCatalog.find(str(id))
  if definition == null:
   continue
  var index := inventory.item_count
  inventory.add_item("%s × %d  /  %s" % [definition.display_name, api.account.inventory[id].count, definition.rarity.to_upper()])
  inventory.set_item_metadata(index, id)
 _update_fits()

func _update_fits() -> void:
 if api.account.is_empty():
  return
 var index := fleet_index.selected
 hull_choice.clear()
 for hull in CollectionCatalog.SHIP_TYPES:
  if hull not in ["interceptor", "skirmisher", "guardian"] and not api.account.inventory.has("ship_" + hull):
   continue
  var item_index := hull_choice.item_count
  hull_choice.add_item(CollectionCatalog.SHIP_TYPES[hull].class_name_text)
  hull_choice.set_item_metadata(item_index, hull)
  if hull == api.account.ship_classes[index]:
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
  _mutation("/equip", {"index": fleet_index.selected, "hull": hull_choice.get_item_metadata(hull_choice.selected)})

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
 market_entries = reply.data
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
 api.base_url = api_address.text.strip_edges()
 var reply := await api.request("/profiles?name=" + public_name.text.strip_edges().uri_encode(), {}, HTTPClient.METHOD_GET)
 if not is_inside_tree():
  return
 if reply.has("error"):
  public_info.text = str(reply.error)
  return
 var data: Dictionary = reply.data
 var lines: PackedStringArray = [str(data.commander_name).to_upper(), "%d victories / %d battles  ·  %d kills  ·  %d damage" % [data.wins, data.battles, data.total_kills, data.total_damage], "FLEET  /  " + ", ".join(data.ship_classes), "DISCOVERY RECORDS"]
 for id in data.get("discovery_records", data.inventory):
  var definition := CollectionCatalog.find(str(id))
  if definition != null:
   var record: Dictionary = data.get("discovery_records", data.inventory)[id]
   var timestamp := int(record.get("discovered_at", 0))
   var found := "Fleet issue" if timestamp == 0 else Time.get_datetime_string_from_unix_time(timestamp).replace("T", " ") + " UTC"
   lines.append(definition.display_name + "  /  " + definition.rarity.to_upper() + "  /  " + found)
 public_info.text = "\n".join(lines)

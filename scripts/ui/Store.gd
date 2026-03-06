extends Control

@onready var back_btn: Button = $SafeArea/Main/TopBar/ShopBack
@onready var coins_label: Label = $SafeArea/Main/TopBar/ShopCoinsLabel

@onready var body_grid: GridContainer = $SafeArea/Main/MarginContainer/ShopFrame/ShopPadding/TabContainer/BodyTab/ShopBodyGrid
@onready var outfit_grid: GridContainer = $SafeArea/Main/MarginContainer/ShopFrame/ShopPadding/TabContainer/OutfitTab/ShopOutfitGrid
@onready var hat_grid: GridContainer = $SafeArea/Main/MarginContainer/ShopFrame/ShopPadding/TabContainer/HatTab/ShopHatGrid

@onready var buy_confirm: AcceptDialog = $BuyConfirm
@onready var warn_popup: AcceptDialog = $WarnPopup

var _pending_buy_id: String = ""


func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)

	# When player presses ✓ on the confirm dialog, we actually buy
	buy_confirm.confirmed.connect(_on_buy_confirmed)
	$SafeArea/Main/MarginContainer/ShopFrame/ShopPadding/TabContainer.set_tab_title(0, "      Body      ")
	$SafeArea/Main/MarginContainer/ShopFrame/ShopPadding/TabContainer.set_tab_title(1, "     Outfit     ")
	$SafeArea/Main/MarginContainer/ShopFrame/ShopPadding/TabContainer.set_tab_title(2, "       Hat      ")


	_refresh_coins()
	_build_all()


func _refresh_coins() -> void:
	coins_label.text = "Coins: %d" % int(GameState.coins)


func _build_all() -> void:
	_clear_children(body_grid)
	_clear_children(outfit_grid)
	_clear_children(hat_grid)

	_build_grid("body", body_grid)
	_build_grid("outfit", outfit_grid)
	_build_grid("hat", hat_grid)


func _build_grid(t: String, grid: GridContainer) -> void:
	var ids: Array[String] = Catalog.list_by_type(t)

	for id in ids:
		var name: String = Catalog.get_item_name(id)
		var price: int = Catalog.get_item_price(id)
		var tex_path: String = Catalog.get_item_tex(id)
		var owned: bool = GameState.owns(id)

		var chosen_id := id # avoid closure issues

		var card := _make_store_card(name, tex_path, price, owned)
		card.pressed.connect(func() -> void:
			_on_card_pressed(chosen_id)
		)

		grid.add_child(card)


func _on_card_pressed(id: String) -> void:
	# Already owned → do nothing (your UI also disables owned cards)
	if GameState.owns(id):
		return

	# Safety: ensure item exists
	var item := Catalog.get_item(id)
	if item.is_empty():
		push_error("[Store] Missing item in Catalog: " + id)
		return

	var name: String = Catalog.get_item_name(id)
	var price: int = Catalog.get_item_price(id)

	# Not enough coins → warning popup
	if int(GameState.coins) < price:
		_show_warn("Meow! You don't have enough funds.")
		return

	# Otherwise show confirm purchase popup
	_pending_buy_id = id
	_show_confirm("Buy %s for %d coins?" % [name, price])


func _show_confirm(msg: String) -> void:
	buy_confirm.dialog_text = msg
	buy_confirm.popup_centered()


func _show_warn(msg: String) -> void:
	warn_popup.dialog_text = msg
	warn_popup.popup_centered()


func _on_buy_confirmed() -> void:
	# User pressed ✓ on the confirm dialog
	var id := _pending_buy_id
	_pending_buy_id = ""

	if id == "":
		return

	# Re-check (in case coins changed somehow)
	if Catalog.get_item(id).is_empty():
		return

	if GameState.owns(id):
		return

	var price: int = Catalog.get_item_price(id)
	if int(GameState.coins) < price:
		_show_warn("Meow! You don't have enough funds.")
		return

	GameState.coins = int(GameState.coins) - price
	GameState.add_owned(id)

	_refresh_coins()
	_build_all()


func _make_store_card(label: String, tex_path: String, price: int, owned: bool) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(260, 300)
	b.flat = true
	b.text = ""

	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	b.add_child(vb)

	var tr := TextureRect.new()
	tr.custom_minimum_size = Vector2(220, 220)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if tex_path != "":
		var tex := load(tex_path) as Texture2D
		if tex:
			tr.texture = tex
	vb.add_child(tr)

	var name_lbl := Label.new()
	name_lbl.text = label
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(name_lbl)

	var price_lbl := Label.new()
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_lbl.text = "Owned" if owned else ("Price: %d" % price)
	vb.add_child(price_lbl)

	if owned:
		b.disabled = true
		b.modulate = Color(1, 1, 1, 0.7)

	return b


func _clear_children(n: Node) -> void:
	for c in n.get_children():
		c.queue_free()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world/RoomHub.tscn")

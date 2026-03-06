extends Control

# ---------------- PATHS (edit if you renamed nodes) ----------------
const CAT_PATH := NodePath("SafeArea/Main/PreviewArea/Center/SubViewportContainer/SubViewport/PreviewRoot/CatAvatar")
const SUBVIEWPORT_PATH := NodePath("SafeArea/Main/PreviewArea/Center/SubViewportContainer/SubViewport")

# ---------------- NODES ----------------
var cat: CatAvatar
var sv: SubViewport

@onready var fur_grid: GridContainer    = $SafeArea/Main/PreviewArea/Options/FurTab/FurScroll/FurGrid
@onready var outfit_grid: GridContainer = $SafeArea/Main/PreviewArea/Options/OutfitTab/OutfitScroll/OutfitGrid
@onready var hat_grid: GridContainer    = $SafeArea/Main/PreviewArea/Options/HatTab/HatScroll/HatGrid

@onready var back_btn: Button    = $SafeArea/Main/TopBar/BackButton
@onready var confirm_btn: Button = $SafeArea/Main/TopBar/ConfirmButton

var current: Dictionary = {}
const DEFAULT_BODY_ID := "body_01"


# ---------------- LIFECYCLE ----------------
func _ready() -> void:
	# Safer than $... (won't hard-crash if path is wrong)
	cat = get_node_or_null(CAT_PATH) as CatAvatar
	sv  = get_node_or_null(SUBVIEWPORT_PATH) as SubViewport

	if cat == null:
		push_error("Customization.gd: CatAvatar node not found. Rename your preview cat node to 'CatAvatar' OR update CAT_PATH.")
		return

	current = GameState.appearance.duplicate(true)
	_ensure_default_keys()

	back_btn.pressed.connect(_on_back_pressed)
	confirm_btn.pressed.connect(_on_confirm_pressed)

	_build_all_grids()
	_apply_to_preview()

	# Center after layout/viewport is ready
	if sv != null:
		sv.size_changed.connect(_center_preview_cat)
	call_deferred("_center_preview_cat")


# ---------------- DEFAULTS ----------------
func _ensure_default_keys() -> void:
	if not current.has("body_id"):
		current["body_id"] = DEFAULT_BODY_ID
	if not current.has("outfit_id"):
		current["outfit_id"] = ""
	if not current.has("hat_id"):
		current["hat_id"] = ""

	# Make sure body_id is valid + owned; if not, pick first owned body
	var owned_bodies := _owned_ids("body")
	if owned_bodies.is_empty():
		# Safety: ensure at least default body is owned
		GameState.add_owned(DEFAULT_BODY_ID)
		owned_bodies = _owned_ids("body")

	if not GameState.owns(String(current["body_id"])) and not owned_bodies.is_empty():
		current["body_id"] = owned_bodies[0]


# ---------------- PREVIEW ----------------
func _apply_to_preview() -> void:
	if cat == null:
		return
	cat.apply_appearance(current)

func _center_preview_cat() -> void:
	if cat == null or sv == null:
		return
	var center := Vector2(sv.size.x * 0.5, sv.size.y * 0.55)
	cat.position = center


# ---------------- OWNED / CATALOG HELPERS ----------------
func _owned_ids(t: String) -> Array[String]:
	var all_ids: Array[String] = Catalog.list_by_type(t)
	var out: Array[String] = []
	for id: String in all_ids:
		if GameState.owns(id):
			out.append(id)
	out.sort()
	return out


# ---------------- GRID BUILDING ----------------
func _build_all_grids() -> void:
	_clear_children(fur_grid)
	_clear_children(outfit_grid)
	_clear_children(hat_grid)

	_build_body_grid_into_fur_tab() # using FurTab as Body selection for now
	_build_outfit_grid()
	_build_hat_grid()


# Treat FurTab as BodyTab (base body selection)
func _build_body_grid_into_fur_tab() -> void:
	var body_ids := _owned_ids("body")

	for id: String in body_ids:
		var chosen_id := id  # IMPORTANT: avoid closure capturing loop var
		var name: String = Catalog.get_item_name(chosen_id)
		var tex_path: String = Catalog.get_item_tex(chosen_id)

		var tb := _make_item_tile(name, tex_path, String(current["body_id"]) == chosen_id)
		tb.pressed.connect(func() -> void:
			current["body_id"] = chosen_id
			_rebuild_and_apply()
		)

		fur_grid.add_child(tb)


func _build_outfit_grid() -> void:
	# Always show None
	var none_btn := _make_item_tile("None", "", String(current["outfit_id"]) == "")
	none_btn.pressed.connect(func() -> void:
		current["outfit_id"] = ""
		_rebuild_and_apply()
	)
	outfit_grid.add_child(none_btn)

	var ids := _owned_ids("outfit")
	for id: String in ids:
		var chosen_id := id
		var name: String = Catalog.get_item_name(chosen_id)
		var tex_path: String = Catalog.get_item_tex(chosen_id)

		var tb := _make_item_tile(name, tex_path, String(current["outfit_id"]) == chosen_id)
		tb.pressed.connect(func() -> void:
			current["outfit_id"] = chosen_id
			_rebuild_and_apply()
		)
		outfit_grid.add_child(tb)


func _build_hat_grid() -> void:
	# Always show None
	var none_btn := _make_item_tile("None", "", String(current["hat_id"]) == "")
	none_btn.pressed.connect(func() -> void:
		current["hat_id"] = ""
		_rebuild_and_apply()
	)
	hat_grid.add_child(none_btn)

	var ids := _owned_ids("hat")
	for id: String in ids:
		var chosen_id := id
		var name: String = Catalog.get_item_name(chosen_id)
		var tex_path: String = Catalog.get_item_tex(chosen_id)

		var tb := _make_item_tile(name, tex_path, String(current["hat_id"]) == chosen_id)
		tb.pressed.connect(func() -> void:
			current["hat_id"] = chosen_id
			_rebuild_and_apply()
		)
		hat_grid.add_child(tb)


func _rebuild_and_apply() -> void:
	_build_all_grids()
	_apply_to_preview()


# ---------------- TILE UI ----------------
func _make_item_tile(label: String, tex_path: String, selected: bool) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(180, 210)
	b.flat = true
	b.text = ""
	b.focus_mode = Control.FOCUS_NONE

	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	b.add_child(vb)

	var tr := TextureRect.new()
	tr.custom_minimum_size = Vector2(160, 160)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	if tex_path != "":
		var tex := load(tex_path) as Texture2D
		if tex != null:
			tr.texture = tex
	vb.add_child(tr)

	var lbl := Label.new()
	lbl.text = label
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(lbl)

	if selected:
		_add_selected_outline(b)

	return b


func _add_selected_outline(btn: Button) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.05)
	sb.border_color = Color(1, 0.8, 0.9, 1.0)
	sb.border_width_left = 4
	sb.border_width_top = 4
	sb.border_width_right = 4
	sb.border_width_bottom = 4
	sb.corner_radius_top_left = 18
	sb.corner_radius_top_right = 18
	sb.corner_radius_bottom_left = 18
	sb.corner_radius_bottom_right = 18
	btn.add_theme_stylebox_override("normal", sb)


func _clear_children(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()


# ---------------- NAV ----------------
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world/RoomHub.tscn")

func _on_confirm_pressed() -> void:
	GameState.appearance = current.duplicate(true)
	get_tree().change_scene_to_file("res://scenes/world/RoomHub.tscn")

extends Control

@onready var wall = $Background/VBox/Wall
@onready var floor = $Background/VBox/Floor

@onready var desk = $World/DeskHotspot
@onready var tv = $World/TVHotspot
@onready var wardrobe = $World/WardrobeHotspot

@onready var lives_label: Label = $UI/TopBar/PanelContainer/HBoxContainer/LivesLabel
@onready var settings_btn: Button = $UI/TopBar/PanelContainer/HBoxContainer/SettingButton
@onready var cat: CatAvatar = $World/CatAvatar

func _ready():
	cat.apply_appearance(GameState.appearance)
	apply_room_style()
	apply_player_look_if_you_have_one()
	update_topbar()

	desk.gui_input.connect(_on_desk_gui_input)
	tv.gui_input.connect(_on_tv_gui_input)
	wardrobe.gui_input.connect(_on_wardrobe_gui_input)

	settings_btn.pressed.connect(_on_settings_pressed)

func update_topbar():
	lives_label.text = "Lives: %d" % GameState.lives

func apply_room_style():
	# For now your Wall/Floor are ColorRect. Later we swap to TextureRect.
	wall.color = _wall_color_from_id(GameState.room_style["wall_id"])
	floor.color = _floor_color_from_id(GameState.room_style["floor_id"])

func _wall_color_from_id(id:String) -> Color:
	return {
		"wall_blue": Color(0.86, 0.92, 1.0),
		"wall_pink": Color(1.0, 0.88, 0.92),
	}.get(id, Color(0.86, 0.92, 1.0))

func _floor_color_from_id(id:String) -> Color:
	return {
		"floor_beige": Color(0.98, 0.95, 0.85),
		"floor_gray": Color(0.93, 0.93, 0.95),
	}.get(id, Color(0.98, 0.95, 0.85))

func _on_desk_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		get_tree().change_scene_to_file("res://scenes/ui/Minigame.tscn")
		print("Desk tapped → open minigame menu later")

func _on_tv_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		print("TV tapped → go to shop")
		get_tree().change_scene_to_file("res://scenes/ui/Store.tscn")
		_open_shop()

func _on_wardrobe_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		print("Wardrobe tapped → go to customization scene")
		get_tree().change_scene_to_file("res://scenes/ui/Customization.tscn")

func _on_settings_pressed():
	print("Settings pressed → open settings popup later")

func _open_shop():
	# placeholder for next step
	pass

func apply_player_look_if_you_have_one():
	# when you build the Cat node as sprites, you'll apply GameState.appearance here
	pass
	

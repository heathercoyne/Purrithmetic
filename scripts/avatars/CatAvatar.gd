extends Node2D
class_name CatAvatar

@onready var body: Sprite2D = $Body
@onready var outfit: Sprite2D = $Outfit
@onready var hat: Sprite2D = $Hat

const BODY_PATH := "res://assets/cat/body/%s.png"
const OUTFIT_PATH := "res://assets/cat/outfits/%s.png"
const HAT_PATH := "res://assets/cat/hats/%s.png"

func apply_appearance(a: Dictionary) -> void:
	# Body swap
	var body_id: String = a.get("body_id", "body_01")
	body.texture = load(BODY_PATH % body_id)
	body.modulate = Color(1,1,1)  # keep original color (you removed fur colors)

	# Outfit
	var outfit_id: String = a.get("outfit_id", "")
	if outfit_id == "":
		outfit.visible = false
	else:
		outfit.visible = true
		outfit.texture = load(OUTFIT_PATH % outfit_id)

	# Hat
	var hat_id: String = a.get("hat_id", "")
	if hat_id == "":
		hat.visible = false
	else:
		hat.visible = true
		hat.texture = load(HAT_PATH % hat_id)

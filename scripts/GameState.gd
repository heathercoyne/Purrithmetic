extends Node
# --------------------
# Player currencies/stats
# --------------------
var lives: int = 5
var coins: int = 500

# --------------------
# Owned items (ONE set for everything)
# --------------------
# Use Dictionary as a set: owned["id"] = true
var owned: Dictionary = {
	# Default owned cat items
	"body_01": true,

	# you can decide if these should be default owned or not
	# (if you want default to be "none", you can remove these)
	"outfit_01": true,
	"hat_01": true,

	# Default owned room items
	"wall_blue": true,
	"floor_beige": true,
}

func owns(id: String) -> bool:
	return owned.has(id)

func add_owned(id: String) -> void:
	owned[id] = true

# Optional helper: remove (useful for debugging)
func remove_owned(id: String) -> void:
	if owned.has(id):
		owned.erase(id)

# Optional helper: list owned ids by prefix (handy later)
func owned_ids_with_prefix(prefix: String) -> Array[String]:
	var out: Array[String] = []
	for k in owned.keys():
		var id := String(k)
		if id.begins_with(prefix):
			out.append(id)
	out.sort()
	return out

# --------------------
# Equipped appearance
# --------------------
# IMPORTANT: default outfit/hat is none = ""
# body_id must always exist and be owned.
var appearance: Dictionary = {
	"body_id": "body_01",
	"outfit_id": "",
	"hat_id": "",
}

# --------------------
# Equipped room style
# --------------------
var room_style: Dictionary = {
	"wall_id": "wall_blue",
	"floor_id": "floor_beige",
}

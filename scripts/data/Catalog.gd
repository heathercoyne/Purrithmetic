extends Node
class_name Catalog

const ITEMS: Dictionary = {
	# Bodies
	"body_01": {"type":"body", "name":"White",  "price":0,   "tex":"res://assets/cat/body/body_01.png"},
	"body_02": {"type":"body", "name":"Calico", "price":200, "tex":"res://assets/cat/body/body_02.png"},
	"body_03": {"type":"body", "name":"Tabby",  "price":200, "tex":"res://assets/cat/body/body_03.png"},

	# Outfits
	"outfit_01": {"type":"outfit", "name":"Outfit 1", "price":150, "tex":"res://assets/cat/outfits/outfit_01.png"},
	"outfit_02": {"type":"outfit", "name":"Outfit 2", "price":150, "tex":"res://assets/cat/outfits/outfit_02.png"},

	# Hats
	"hat_01": {"type":"hat", "name":"Bow 1", "price":120, "tex":"res://assets/cat/hats/hat_01.png"},
	"hat_02": {"type":"hat", "name":"Bow 2", "price":120, "tex":"res://assets/cat/hats/hat_02.png"},
}

static func get_item(id: String) -> Dictionary:
	var v = ITEMS.get(id)
	if typeof(v) == TYPE_DICTIONARY:
		return v as Dictionary
	return {}

static func list_by_type(t: String) -> Array[String]:
	var out: Array[String] = []
	for k in ITEMS.keys():
		var id := String(k)
		var item := get_item(id)
		if String(item.get("type", "")) == t:
			out.append(id)
	out.sort()
	return out

static func get_item_tex(id: String) -> String:
	return String(get_item(id).get("tex", ""))

static func get_item_name(id: String) -> String:
	return String(get_item(id).get("name", id))

static func get_item_price(id: String) -> int:
	return int(get_item(id).get("price", 0))

## ItemRegistry.gd  [Autoload]
## Loads every HabitatItemDefinition .tres from res://data/items/ at startup.
## Access anywhere via:  ItemRegistry.get_def(&"flower_pot")
extends Node

var _definitions: Dictionary = {}

func _ready() -> void:
	_load_all()

func _load_all() -> void:
	var dir := DirAccess.open("res://data/items/")
	if dir == null:
		push_error("ItemRegistry: could not open res://data/items/")
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path := "res://data/items/" + file_name
			var res := load(path)
			if res is HabitatItemDefinition:
				if res.id == &"":
					push_warning("ItemRegistry: definition at %s has no id set — skipping." % path)
				else:
					_definitions[res.id] = res
			else:
				push_warning("ItemRegistry: %s is not a HabitatItemDefinition — skipping." % path)
		file_name = dir.get_next()
	dir.list_dir_end()
	print("ItemRegistry: loaded %d definitions." % _definitions.size())

func get_def(id: StringName) -> HabitatItemDefinition:
	return _definitions.get(id, null)

func get_all() -> Array:
	var arr := _definitions.values()
	arr.sort_custom(func(a, b): return a.unlock_cost < b.unlock_cost)
	return arr

func has(id: StringName) -> bool:
	return _definitions.has(id)

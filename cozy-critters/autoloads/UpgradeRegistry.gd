## UpgradeRegistry.gd  [Autoload]
## Loads every UpgradeDefinition .tres from res://data/upgrades/ at startup.
## Access anywhere via:  UpgradeRegistry.get_def(&"click_power_1")
extends Node

var _definitions: Dictionary = {}

func _ready() -> void:
	_load_all()

func _load_all() -> void:
	var dir := DirAccess.open("res://data/upgrades/")
	if dir == null:
		push_error("UpgradeRegistry: could not open res://data/upgrades/")
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path := "res://data/upgrades/" + file_name
			var res := load(path)
			if res is UpgradeDefinition:
				if res.id == &"":
					push_warning("UpgradeRegistry: definition at %s has no id — skipping." % path)
				else:
					_definitions[res.id] = res
			else:
				push_warning("UpgradeRegistry: %s is not an UpgradeDefinition — skipping." % path)
		file_name = dir.get_next()
	dir.list_dir_end()
	print("UpgradeRegistry: loaded %d definitions." % _definitions.size())

func get_def(id: StringName) -> UpgradeDefinition:
	return _definitions.get(id, null)

## Returns all upgrades in prerequisite-safe order (prerequisites always come first).
func get_all_ordered() -> Array:
	var arr := _definitions.values()
	arr.sort_custom(func(a, b): return a.cost < b.cost)
	return arr

func has(id: StringName) -> bool:
	return _definitions.has(id)

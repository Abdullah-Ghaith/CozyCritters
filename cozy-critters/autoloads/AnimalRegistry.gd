## AnimalRegistry.gd  [Autoload]
## Loads every AnimalDefinition .tres from res://data/animals/ at startup.
## Access anywhere via:  AnimalRegistry.get_def(&"hedgehog")
extends Node

## All loaded definitions keyed by their id StringName
var _definitions: Dictionary = {}

func _ready() -> void:
	_load_all()

func _load_all() -> void:
	var dir := DirAccess.open("res://data/animals/")
	if dir == null:
		push_error("AnimalRegistry: could not open res://data/animals/")
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path := "res://data/animals/" + file_name
			var res := load(path)
			if res is AnimalDefinition:
				if res.id == &"":
					push_warning("AnimalRegistry: definition at %s has no id set — skipping." % path)
				else:
					_definitions[res.id] = res
			else:
				push_warning("AnimalRegistry: %s is not an AnimalDefinition — skipping." % path)
		file_name = dir.get_next()
	dir.list_dir_end()
	print("AnimalRegistry: loaded %d definitions." % _definitions.size())

## Returns the AnimalDefinition for the given id, or null if not found.
func get_def(id: StringName) -> AnimalDefinition:
	return _definitions.get(id, null)

## Returns all definitions as an Array[AnimalDefinition], sorted by unlock_cost.
func get_all() -> Array:
	var arr := _definitions.values()
	arr.sort_custom(func(a, b): return a.unlock_cost < b.unlock_cost)
	return arr

## Returns true if the id exists in the registry.
func has(id: StringName) -> bool:
	return _definitions.has(id)

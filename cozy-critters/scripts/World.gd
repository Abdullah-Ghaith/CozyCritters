## World.gd
## Attach to the World Node2D inside StripViewport.
## Listens to GameState signals to spawn / despawn animals and items.
## Also handles click events on the strip to award Acorns.
extends Node2D

# ── Export (set in inspector) ─────────────────────────────────────────────────

@export var animal_scene: PackedScene   ## Assign AnimalInstance.tscn
@export var item_scene:   PackedScene   ## Assign HabitatItem.tscn

## Y position of the ground line within the strip (global, matches DragHandler.ground_y)
@export var ground_y: float = 110.0

# ── Internal ──────────────────────────────────────────────────────────────────
## Maps instance_uid → AnimalInstance node
var _animal_nodes: Dictionary = {}
## Maps item_index → HabitatItem node (indices match GameState.placed_items)
var _item_nodes: Dictionary = {}

signal animal_context_requested(animal_node: AnimalInstance)

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	# Connect to GameState signals
	GameState.animal_placed.connect(_on_animal_placed)
	GameState.animal_removed.connect(_on_animal_removed)
	GameState.item_placed.connect(_on_item_placed)
	GameState.item_removed.connect(_on_item_removed)
	GameState.save_loaded.connect(_rebuild_from_save)

	# Rebuild if save was loaded before World was ready
	_rebuild_from_save()

# ── Spawn / despawn ───────────────────────────────────────────────────────────

func _on_animal_placed(data: Dictionary) -> void:
	_spawn_animal(data)

func _on_animal_removed(uid: String) -> void:
	if _animal_nodes.has(uid):
		_animal_nodes[uid].queue_free()
		_animal_nodes.erase(uid)

func _on_item_placed(data: Dictionary) -> void:
	var index := GameState.placed_items.find(data)
	_spawn_item(data, index)

func _on_item_removed(index: int) -> void:
	if _item_nodes.has(index):
		_item_nodes[index].queue_free()
		_item_nodes.erase(index)

func _rebuild_from_save() -> void:
	# Clear existing
	for node in _animal_nodes.values(): node.queue_free()
	for node in _item_nodes.values():   node.queue_free()
	_animal_nodes.clear()
	_item_nodes.clear()

	for data in GameState.placed_animals:
		_spawn_animal(data)
	for i in range(GameState.placed_items.size()):
		_spawn_item(GameState.placed_items[i], i)

func _spawn_animal(data: Dictionary) -> void:
	if animal_scene == null:
		push_error("World: animal_scene not assigned in inspector")
		return
	var def := AnimalRegistry.get_def(data["id"])
	if def == null:
		push_warning("World._spawn_animal: no definition for id '%s'" % data["id"])
		return

	var node: AnimalInstance = animal_scene.instantiate()
	$AnimalLayer.add_child(node)
	node.setup(def, data["instance_uid"], data.get("x", 100.0), data.get("is_helper", false))

	# Pass ground_y to all DragHandlers
	node.get_node("DragHandler").ground_y = ground_y

	# Forward context requests upward
	node.animal_context_requested.connect(_on_animal_context_requested)

	_animal_nodes[data["instance_uid"]] = node

func _spawn_item(data: Dictionary, index: int) -> void:
	if item_scene == null:
		push_error("World: item_scene not assigned in inspector")
		return
	var def := ItemRegistry.get_def(data["id"])
	if def == null:
		push_warning("World._spawn_item: no definition for id '%s'" % data["id"])
		return

	var node = item_scene.instantiate()
	$HabitatLayer.add_child(node)
	node.get_node("DragHandler").ground_y = ground_y
	node.setup(def, index, data.get("x", 200.0))
	_item_nodes[index] = node

# ── Click to earn acorns ──────────────────────────────────────────────────────

func _on_click_receiver_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			GameState.on_click()

# ── Context menu passthrough ──────────────────────────────────────────────────

func _on_animal_context_requested(animal_node: AnimalInstance) -> void:
	animal_context_requested.emit(animal_node)

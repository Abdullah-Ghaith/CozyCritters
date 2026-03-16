## DragHandler.gd
## Attach to any draggable node (AnimalInstance or HabitatItem).
## Requires a sibling Area2D called "DragArea" with a CollisionShape2D.
##
## For AnimalInstance: also notifies the AnimalStateMachine on grab/drop.
## For HabitatItem:    just moves the node and saves position on drop.
class_name DragHandler extends Node

# ── Config ────────────────────────────────────────────────────────────────────

## If true, Y position is locked to ground_y while dragging
@export var lock_y: bool = true

## The Y position (global) to snap to when lock_y is true.
## Set this from World.gd after scene is ready to match your ground line.
@export var ground_y: float = 120.0

## Left/right clamp bounds in global X. Set from World.gd.
@export var bounds_min_x: float = 0.0
@export var bounds_max_x: float = 1920.0

# ── Signals ───────────────────────────────────────────────────────────────────
signal drag_started()
signal drag_ended(final_x: float)

# ── State ─────────────────────────────────────────────────────────────────────
var is_dragging: bool = false

# ── Internal ──────────────────────────────────────────────────────────────────
var _parent_node: Node2D
var _drag_offset: Vector2 = Vector2.ZERO
var _state_machine: AnimalStateMachine = null  # populated if parent is AnimalInstance

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_parent_node = get_parent() as Node2D
	if _parent_node == null:
		push_error("DragHandler must be a child of a Node2D")
		return

	# Optional state machine on animal instances
	_state_machine = _parent_node.get_node_or_null("StateMachine") as AnimalStateMachine

	var drag_area := _parent_node.get_node_or_null("DragArea") as Area2D
	if drag_area:
		drag_area.input_event.connect(_on_drag_area_input)
	else:
		push_warning("DragHandler: no DragArea sibling found on %s" % _parent_node.name)

func _process(_delta: float) -> void:
	if not is_dragging:
		return
	var mouse : Vector2 = _parent_node.get_global_mouse_position()
	var new_x : float  = clamp(mouse.x + _drag_offset.x, bounds_min_x, bounds_max_x)
	var new_y := ground_y if lock_y else mouse.y + _drag_offset.y
	_parent_node.global_position = Vector2(new_x, new_y)

# ── Input ─────────────────────────────────────────────────────────────────────

func _on_drag_area_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_begin_drag(event.global_position)
			elif is_dragging:
				_end_drag()

func _input(event: InputEvent) -> void:
	# Safety: release drag if mouse button is released anywhere
	if is_dragging and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_end_drag()

# ── Drag lifecycle ────────────────────────────────────────────────────────────

func _begin_drag(global_mouse: Vector2) -> void:
	is_dragging = true
	_drag_offset = _parent_node.global_position - global_mouse
	_drag_offset.x = clamp(_drag_offset.x, -30.0, 30.0)  # prevent teleport on grab
	if _state_machine:
		_state_machine.on_grab()
	drag_started.emit()
	# Bring to top of draw order while dragging
	_parent_node.z_index = 10

func _end_drag() -> void:
	is_dragging = false
	_parent_node.z_index = 0
	var final_x := _parent_node.global_position.x
	if _state_machine:
		_state_machine.on_drop()
	drag_ended.emit(final_x)
	# Persist new position
	_save_position(final_x)

func _save_position(x: float) -> void:
	# Animal instances carry an instance_uid property
	var uid: String = _parent_node.get("instance_uid")
	if uid != null and uid != "":
		GameState.update_animal_x(uid, x)
		GameState.save_game()
		return
	# Habitat items carry an item_index property
	var idx: int = _parent_node.get("item_index")
	if idx >= 0:
		GameState.update_item_x(idx, x)
		GameState.save_game()

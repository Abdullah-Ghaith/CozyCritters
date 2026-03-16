## ShopPanel.gd
## Attach to the ShopPanel Control node inside UILayer.
## Manages three tabs: Animals, Items, Upgrades.
## Spawns ShopCard instances into the appropriate GridContainer.
extends Control

# ── Exports (assign in inspector) ─────────────────────────────────────────────
@export var shop_card_scene: PackedScene   ## Assign ShopCard.tscn

# ── Internal node refs ────────────────────────────────────────────────────────
@onready var tab_container:    TabContainer  = %TabContainer
@onready var animal_grid:      GridContainer = %AnimalGrid
@onready var item_grid:        GridContainer = %ItemGrid
@onready var upgrade_grid:     GridContainer = %UpgradeGrid
@onready var close_button:     Button        = %CloseButton

## Where newly unlocked animals get placed on the strip (set from World or Main)
@export var default_spawn_x: float = 200.0

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	close_button.pressed.connect(func(): visible = false)
	visibility_changed.connect(_on_visibility_changed)

	GameState.animal_unlocked.connect(_on_animal_unlocked)
	GameState.item_unlocked.connect(_on_item_unlocked)
	GameState.upgrade_purchased.connect(_on_upgrade_purchased)

func _on_visibility_changed() -> void:
	if visible:
		_populate_all()

# ── Population ────────────────────────────────────────────────────────────────

func _populate_all() -> void:
	_clear_grid(animal_grid)
	_clear_grid(item_grid)
	_clear_grid(upgrade_grid)

	for def in AnimalRegistry.get_all():
		_add_animal_card(def)
	for def in ItemRegistry.get_all():
		_add_item_card(def)
	for def in UpgradeRegistry.get_all_ordered():
		_add_upgrade_card(def)

func _clear_grid(grid: GridContainer) -> void:
	for child in grid.get_children():
		child.queue_free()

func _add_animal_card(def: AnimalDefinition) -> void:
	if shop_card_scene == null: return
	var card: Control = shop_card_scene.instantiate()
	animal_grid.add_child(card)
	card.setup_animal(def)
	card.purchase_requested.connect(_on_purchase_requested)

func _add_item_card(def: HabitatItemDefinition) -> void:
	if shop_card_scene == null: return
	var card: Control = shop_card_scene.instantiate()
	item_grid.add_child(card)
	card.setup_item(def)
	card.purchase_requested.connect(_on_purchase_requested)

func _add_upgrade_card(def: UpgradeDefinition) -> void:
	if shop_card_scene == null: return
	var card: Control = shop_card_scene.instantiate()
	upgrade_grid.add_child(card)
	card.setup_upgrade(def)
	card.purchase_requested.connect(_on_purchase_requested)

# ── Purchase routing ──────────────────────────────────────────────────────────

func _on_purchase_requested(item_id: StringName, item_type: String) -> void:
	match item_type:
		"animal":
			if GameState.unlock_animal(item_id):
				# Automatically place the animal on the strip at a sensible X
				var x := _find_open_x()
				GameState.place_animal(item_id, x)
		"item":
			if GameState.unlock_item(item_id):
				var x := _find_open_x()
				GameState.place_item(item_id, x)
		"upgrade":
			GameState.purchase_upgrade(item_id)

## Finds a horizontal position on the strip that is not already occupied.
func _find_open_x() -> float:
	var strip_w := float(DisplayServer.window_get_size().x)
	var occupied: Array[float] = []
	for pd in GameState.placed_animals:
		occupied.append(pd.get("x", 0.0))
	for itd in GameState.placed_items:
		occupied.append(itd.get("x", 0.0))

	var spacing := 60.0
	var x       := 80.0
	while x < strip_w - 80.0:
		var clear := true
		for ox in occupied:
			if abs(ox - x) < spacing:
				clear = false
				break
		if clear:
			return x
		x += spacing
	# Fallback: random position
	return randf_range(80.0, strip_w - 80.0)

# ── React to purchases (refresh cards) ───────────────────────────────────────

func _on_animal_unlocked(_id: StringName) -> void:
	if visible: _populate_all()

func _on_item_unlocked(_id: StringName) -> void:
	if visible: _populate_all()

func _on_upgrade_purchased(_id: StringName) -> void:
	if visible: _populate_all()

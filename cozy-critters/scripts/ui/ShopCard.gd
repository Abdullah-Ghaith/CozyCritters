## ShopCard.gd
## Attach to a ShopCard Control node inside ShopPanel's grid.
## Displays one purchasable item (animal, habitat item, or upgrade).
## Set up via setup() after instancing.
extends PanelContainer

# ── Signals ───────────────────────────────────────────────────────────────────
signal purchase_requested(item_id: StringName, item_type: String)

# ── Internal ──────────────────────────────────────────────────────────────────
@onready var icon_rect:   TextureRect = $VBox/IconRect
@onready var name_label:  Label       = $VBox/NameLabel
@onready var cost_label:  Label       = $VBox/CostLabel
@onready var buy_button:  Button      = $VBox/BuyButton

var _item_id:   StringName = &""
var _item_type: String     = ""   # "animal", "item", "upgrade"
var _cost:      int        = 0
var _purchased: bool       = false

# ── Setup ─────────────────────────────────────────────────────────────────────

## item_type: "animal" | "item" | "upgrade"
func setup_animal(def: AnimalDefinition) -> void:
	_item_id   = def.id
	_item_type = "animal"
	_cost      = def.unlock_cost
	name_label.text = def.display_name if GameState.is_animal_unlocked(def.id) else "???"
	cost_label.text = "%d 🌰" % def.unlock_cost
	if def.spritesheet:
		icon_rect.texture = def.spritesheet
	_purchased = GameState.is_animal_unlocked(def.id)
	_refresh_button()
	GameState.acorns_changed.connect(_on_acorns_changed)

func setup_item(def: HabitatItemDefinition) -> void:
	_item_id   = def.id
	_item_type = "item"
	_cost      = def.unlock_cost
	name_label.text = def.display_name
	cost_label.text = "%d 🌰" % def.unlock_cost
	if def.texture:
		icon_rect.texture = def.texture
	_purchased = GameState.is_item_unlocked(def.id)
	_refresh_button()
	GameState.acorns_changed.connect(_on_acorns_changed)

func setup_upgrade(def: UpgradeDefinition) -> void:
	_item_id   = def.id
	_item_type = "upgrade"
	_cost      = def.cost
	name_label.text = def.display_name
	cost_label.text = "%d 🌰" % def.cost
	if def.icon:
		icon_rect.texture = def.icon
	_purchased = GameState.is_upgrade_purchased(def.id)
	_refresh_button()
	GameState.acorns_changed.connect(_on_acorns_changed)

# ── Handlers ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	buy_button.pressed.connect(_on_buy_pressed)

func _on_buy_pressed() -> void:
	if _purchased: return
	purchase_requested.emit(_item_id, _item_type)

func _on_acorns_changed(_total: int) -> void:
	_refresh_button()

# ── Helpers ───────────────────────────────────────────────────────────────────

func _refresh_button() -> void:
	if _purchased:
		buy_button.text     = "✓ Owned"
		buy_button.disabled = true
	else:
		buy_button.text     = "Buy"
		buy_button.disabled = (GameState.acorns < _cost)

func mark_purchased() -> void:
	_purchased = true
	_refresh_button()

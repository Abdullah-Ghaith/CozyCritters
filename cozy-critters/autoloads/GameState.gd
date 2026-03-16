## GameState.gd  [Autoload]
## Single source of truth for all mutable game data.
## UI and gameplay scripts NEVER write state directly — they call methods here.
## Emits signals so all listeners stay in sync automatically.
extends Node

# ── Signals ───────────────────────────────────────────────────────────────────

signal acorns_changed(new_total: int)
signal animal_unlocked(animal_id: StringName)
signal item_unlocked(item_id: StringName)
signal upgrade_purchased(upgrade_id: StringName)
signal animal_placed(instance_data: Dictionary)
signal animal_removed(instance_uid: String)
signal item_placed(item_data: Dictionary)
signal item_removed(item_index: int)
signal save_loaded()

# ── Constants ─────────────────────────────────────────────────────────────────

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1

## Helper income tick rate in real seconds
const HELPER_TICK_RATE: float = 1.0

# ── Runtime state ─────────────────────────────────────────────────────────────

var acorns: int = 0
var total_acorns_earned: int = 0
var click_power: float = 1.0           # base acorns per click (float for upgrade math)
var helper_multiplier: float = 1.0     # applied to all helper rates

var unlocked_animals: Array[StringName] = []   # ids of unlocked species
var unlocked_items:   Array[StringName] = []   # ids of unlocked habitat items
var purchased_upgrades: Array[StringName] = [] # ids of purchased upgrades

## Each entry: { "id": StringName, "instance_uid": String, "x": float, "is_helper": bool }
var placed_animals: Array[Dictionary] = []

## Each entry: { "id": StringName, "x": float }
var placed_items: Array[Dictionary] = []

## Fractional acorns accumulated by helpers between ticks (prevent rounding loss)
var helper_accrual_pending: float = 0.0

# ── Internal ──────────────────────────────────────────────────────────────────
var _helper_tick_accum: float = 0.0
var _uid_counter: int = 0

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	load_game()

func _process(delta: float) -> void:
	_tick_helpers(delta)

# ── Currency ──────────────────────────────────────────────────────────────────

func add_acorns(amount: int) -> void:
	acorns += amount
	total_acorns_earned += amount
	acorns_changed.emit(acorns)

## Returns true if successful, false if not enough acorns.
func spend_acorns(amount: int) -> bool:
	if acorns < amount:
		return false
	acorns -= amount
	acorns_changed.emit(acorns)
	return true

## Called by ClickReceiver on every click.
func on_click() -> void:
	add_acorns(int(click_power))

# ── Helpers (passive income) ──────────────────────────────────────────────────

func _tick_helpers(delta: float) -> void:
	_helper_tick_accum += delta
	if _helper_tick_accum < HELPER_TICK_RATE:
		return
	_helper_tick_accum -= HELPER_TICK_RATE

	var total_rate := 0.0
	for pd in placed_animals:
		if pd.get("is_helper", false):
			var def := AnimalRegistry.get_def(pd["id"])
			if def:
				total_rate += def.helper_rate

	total_rate *= helper_multiplier
	helper_accrual_pending += total_rate
	var whole := int(helper_accrual_pending)
	if whole >= 1:
		helper_accrual_pending -= whole
		add_acorns(whole)

# ── Unlocks ───────────────────────────────────────────────────────────────────

func unlock_animal(id: StringName) -> bool:
	if id in unlocked_animals:
		return false
	var def := AnimalRegistry.get_def(id)
	if def == null:
		push_error("GameState.unlock_animal: unknown id '%s'" % id)
		return false
	if not spend_acorns(def.unlock_cost):
		return false
	unlocked_animals.append(id)
	animal_unlocked.emit(id)
	save_game()
	return true

func unlock_item(id: StringName) -> bool:
	if id in unlocked_items:
		return false
	var def := ItemRegistry.get_def(id)
	if def == null:
		push_error("GameState.unlock_item: unknown id '%s'" % id)
		return false
	if not spend_acorns(def.unlock_cost):
		return false
	unlocked_items.append(id)
	item_unlocked.emit(id)
	save_game()
	return true

func purchase_upgrade(id: StringName) -> bool:
	if id in purchased_upgrades:
		return false
	var def := UpgradeRegistry.get_def(id)
	if def == null:
		push_error("GameState.purchase_upgrade: unknown id '%s'" % id)
		return false
	# Check prerequisite
	if def.prerequisite_id != &"" and not (def.prerequisite_id in purchased_upgrades):
		return false
	if not spend_acorns(def.cost):
		return false
	purchased_upgrades.append(id)
	_apply_upgrade(def)
	upgrade_purchased.emit(id)
	save_game()
	return true

func _apply_upgrade(def: UpgradeDefinition) -> void:
	match def.upgrade_type:
		UpgradeDefinition.UpgradeType.CLICK_POWER:
			click_power += def.value
		UpgradeDefinition.UpgradeType.HELPER_MULTIPLIER:
			helper_multiplier *= def.value
		UpgradeDefinition.UpgradeType.SLOT_UNLOCK:
			pass  # Handled by World.gd listening to the upgrade_purchased signal

# ── Animal placement ──────────────────────────────────────────────────────────

func place_animal(id: StringName, x: float, is_helper: bool = false) -> String:
	var uid := _generate_uid(id)
	var data := { "id": id, "instance_uid": uid, "x": x, "is_helper": is_helper }
	placed_animals.append(data)
	animal_placed.emit(data)
	save_game()
	return uid

func remove_animal(instance_uid: String) -> void:
	for i in range(placed_animals.size()):
		if placed_animals[i]["instance_uid"] == instance_uid:
			placed_animals.remove_at(i)
			animal_removed.emit(instance_uid)
			save_game()
			return

func update_animal_x(instance_uid: String, new_x: float) -> void:
	for pd in placed_animals:
		if pd["instance_uid"] == instance_uid:
			pd["x"] = new_x
			# Debounced save happens via save_game() call on drag-end in DragHandler
			return

func set_animal_helper(instance_uid: String, is_helper: bool) -> void:
	for pd in placed_animals:
		if pd["instance_uid"] == instance_uid:
			pd["is_helper"] = is_helper
			save_game()
			return

# ── Item placement ────────────────────────────────────────────────────────────

func place_item(id: StringName, x: float) -> void:
	var data := { "id": id, "x": x }
	placed_items.append(data)
	item_placed.emit(data)
	save_game()

func remove_item(index: int) -> void:
	if index < 0 or index >= placed_items.size():
		return
	placed_items.remove_at(index)
	item_removed.emit(index)
	save_game()

func update_item_x(index: int, new_x: float) -> void:
	if index >= 0 and index < placed_items.size():
		placed_items[index]["x"] = new_x

# ── Save / Load ───────────────────────────────────────────────────────────────

func save_game() -> void:
	var data := {
		"version": SAVE_VERSION,
		"acorns": acorns,
		"total_acorns_earned": total_acorns_earned,
		"click_power": click_power,
		"helper_multiplier": helper_multiplier,
		"unlocked_animals": unlocked_animals.map(func(s): return str(s)),
		"unlocked_items":   unlocked_items.map(func(s): return str(s)),
		"purchased_upgrades": purchased_upgrades.map(func(s): return str(s)),
		"placed_animals": placed_animals,
		"placed_items": placed_items,
		"helper_accrual_pending": helper_accrual_pending,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("GameState: could not write save file at %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_apply_all_upgrades_from_list()  # fresh game, nothing to load
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("GameState: could not read save file.")
		return
	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_error("GameState: save file is not a valid JSON object.")
		return
	var save_data := parsed as Dictionary

	# Migrate old save versions here in future
	acorns                  = save_data.get("acorns", 0)
	total_acorns_earned     = save_data.get("total_acorns_earned", 0)
	click_power             = save_data.get("click_power", 1.0)
	helper_multiplier       = save_data.get("helper_multiplier", 1.0)
	helper_accrual_pending  = save_data.get("helper_accrual_pending", 0.0)

	# StringName arrays
	unlocked_animals.clear()
	for s in save_data.get("unlocked_animals", []):
		unlocked_animals.append(StringName(s))
	unlocked_items.clear()
	for s in save_data.get("unlocked_items", []):
		unlocked_items.append(StringName(s))
	for s in save_data.get("purchased_upgrades", []):
		purchased_upgrades.append(StringName(s))

	placed_animals = []
	for pd in save_data.get("placed_animals", []):
		pd["id"] = StringName(pd["id"])
		placed_animals.append(pd)

	placed_items.clear()
	for itd in save_data.get("placed_items", []):
		itd["id"] = StringName(itd["id"])

	# Re-apply upgrade effects so runtime multipliers are correct
	_apply_all_upgrades_from_list()

	save_loaded.emit()
	print("GameState: save loaded. Acorns: %d" % acorns)

## Re-apply every purchased upgrade's numeric effects after a load.
## click_power and helper_multiplier are stored directly in the save,
## so this is a no-op unless the save is from an older version without them.
func _apply_all_upgrades_from_list() -> void:
	pass  # Values already restored from save fields; this hook exists for migrations.

# ── Helpers ───────────────────────────────────────────────────────────────────

func _generate_uid(prefix: StringName) -> String:
	_uid_counter += 1
	return "%s_%04d" % [prefix, _uid_counter]

func is_animal_unlocked(id: StringName) -> bool:
	return id in unlocked_animals

func is_item_unlocked(id: StringName) -> bool:
	return id in unlocked_items

func is_upgrade_purchased(id: StringName) -> bool:
	return id in purchased_upgrades

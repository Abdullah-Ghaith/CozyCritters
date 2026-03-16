## HabitatItemDefinition.gd
## Data resource describing a single placeable habitat decoration.
## Create one .tres file per item in res://data/items/
## e.g. flower_pot.tres, log.tres, water_bowl.tres
class_name HabitatItemDefinition
extends Resource

## ── Identity ──────────────────────────────────────────────────────────────────

## Unique string key. Used in save data. Never change after shipping.
## e.g. &"flower_pot"
@export var id: StringName = &""

## Friendly name shown in UI
@export var display_name: String = ""

## Flavour text for the shop tooltip
@export var description: String = ""

## ── Visuals ───────────────────────────────────────────────────────────────────

## Static sprite texture. For animated items, leave null and assign frames instead.
@export var texture: Texture2D

## Optional: animated item frames (overrides texture if set)
@export var animated_frames: SpriteFrames

## Draw layer: 0 = behind animals (ground items), 1 = same as animals, 2 = foreground
@export var z_layer: int = 0

## ── Gameplay ──────────────────────────────────────────────────────────────────

## Cost in Acorns to unlock in the shop
@export var unlock_cost: int = 50

## Whether the player can place multiple copies of this item
@export var is_stackable: bool = true

## Future use: Acorn/sec bonus added to Helpers within a radius of this item
@export var mood_bonus: float = 0.0

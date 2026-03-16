## AnimalDefinition.gd
## Data resource describing a single animal species.
## Create one .tres file per animal in res://data/animals/
## e.g. hedgehog.tres, bunny.tres, capybara.tres
class_name AnimalDefinition
extends Resource

## ── Identity ──────────────────────────────────────────────────────────────────

## Unique string key. Used in save data and registries. Never change after shipping.
## e.g. &"hedgehog"
@export var id: StringName = &""

## Friendly name shown in UI
@export var display_name: String = ""

## Flavour text shown in the Collection Log
@export var description: String = ""

## Short teaser shown in the shop before the animal is unlocked
@export var unlock_hint: String = "???"

## ── Visuals ───────────────────────────────────────────────────────────────────

## Full spritesheet atlas texture
@export var spritesheet: Texture2D

## Pixel dimensions of one frame on the spritesheet
@export var frame_size: Vector2i = Vector2i(32, 32)

## Animation definitions keyed by name.
## Required keys: "walk", "idle", "sleep"
## Optional keys: "interact", "yawn"
## Values must be AnimData resources.
@export var animations: Dictionary = {}

## ── Gameplay ──────────────────────────────────────────────────────────────────

## Cost in Acorns to unlock this animal in the shop
@export var unlock_cost: int = 100

## Acorns per second generated when this animal is designated as a Helper.
## Set to 0.0 if this animal cannot be a Helper.
@export var helper_rate: float = 0.5

## Base walk speed in pixels per second when wandering
@export var walk_speed: float = 30.0

## ── Rarity ────────────────────────────────────────────────────────────────────

enum Rarity { COMMON, UNCOMMON, RARE, SECRET }

@export var rarity: Rarity = Rarity.COMMON

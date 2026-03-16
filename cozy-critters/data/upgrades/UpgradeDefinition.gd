## UpgradeDefinition.gd
## Data resource describing a single purchasable upgrade.
## Create one .tres file per upgrade in res://data/upgrades/
## e.g. click_power_1.tres, helper_boost_1.tres
class_name UpgradeDefinition
extends Resource

## ── Upgrade type enum ─────────────────────────────────────────────────────────
## Fixed categories — these never need to grow from save data, so enum is correct here.
enum UpgradeType {
	CLICK_POWER,        ## Adds flat +value to each click
	HELPER_MULTIPLIER,  ## Multiplies all Helper income by value
	SLOT_UNLOCK,        ## Unlocks an additional animal slot on the strip
}

## ── Identity ──────────────────────────────────────────────────────────────────

## Unique string key. Used in save data. Never change after shipping.
## e.g. &"click_power_1"
@export var id: StringName = &""

## Friendly name shown in shop
@export var display_name: String = ""

## Description of what this upgrade does
@export var description: String = ""

## Icon shown in shop (optional)
@export var icon: Texture2D

## ── Gameplay ──────────────────────────────────────────────────────────────────

## Cost in Acorns
@export var cost: int = 200

## What kind of upgrade this is
@export var upgrade_type: UpgradeType = UpgradeType.CLICK_POWER

## The numeric effect:
##   CLICK_POWER       → added to clicks_per_click (e.g. 1.0 = +1 acorn per click)
##   HELPER_MULTIPLIER → multiplied against all helper rates (e.g. 1.5 = 50% more)
##   SLOT_UNLOCK       → ignored (the unlock itself is the effect)
@export var value: float = 1.0

## ID of another upgrade that must be purchased before this one is available.
## Leave empty (&"") for no prerequisite.
@export var prerequisite_id: StringName = &""

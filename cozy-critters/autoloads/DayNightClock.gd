## DayNightClock.gd  [Autoload]
## Runs an accelerated day/night cycle.
## One full in-game day = REAL_SECONDS_PER_DAY real seconds (default: 45 minutes).
##
## On startup, the clock is seeded from the real system time so it always
## "feels" roughly correct — launching at 2pm starts near midday, not midnight.
##
## Phases use an enum (fixed categories, never stored in save data).
extends Node

## ── Configuration ─────────────────────────────────────────────────────────────

## How many real-world seconds equal one full in-game day. Change freely.
const REAL_SECONDS_PER_DAY: float = 45.0 * 60.0  # 45 minutes

## ── Phase enum ────────────────────────────────────────────────────────────────
## Dawn 5–8, Day 8–18, Dusk 18–21, Night 21–5  (in-game hours, 0–24 scale)
enum Phase { DAWN, DAY, DUSK, NIGHT }

## Emitted whenever the phase changes. Connect in Background.gd, AnimalLayer, etc.
signal time_of_day_changed(new_phase: Phase)

## Emitted every frame with the current normalised time (0.0–1.0 = midnight-to-midnight).
## Useful for smooth sky gradient interpolation.
signal time_fraction_updated(fraction: float)

## ── State ─────────────────────────────────────────────────────────────────────

## Current phase (read-only from outside — use the signal to react to changes)
var current_phase: Phase = Phase.DAY

## Normalised time within the day: 0.0 = midnight, 0.5 = noon, 1.0 = midnight again
var time_fraction: float = 0.5

## Current in-game hour (0.0–24.0, fractional)
var game_hour: float = 12.0

## ── Internal ──────────────────────────────────────────────────────────────────
var _elapsed: float = 0.0  # real seconds accumulated today

func _ready() -> void:
	_seed_from_system_time()

## Seed the internal clock from the real system time so the starting phase
## matches what time of day it actually is.
func _seed_from_system_time() -> void:
	var dt := Time.get_datetime_dict_from_system()
	var real_hour: float = dt["hour"] + dt["minute"] / 60.0 + dt["second"] / 3600.0
	# Map real 0–24h onto our accelerated day
	time_fraction = real_hour / 24.0
	_elapsed = time_fraction * REAL_SECONDS_PER_DAY
	game_hour = real_hour  # start matching real time, will diverge as it accelerates
	current_phase = _phase_for_hour(game_hour)

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= REAL_SECONDS_PER_DAY:
		_elapsed -= REAL_SECONDS_PER_DAY  # wrap around

	time_fraction = _elapsed / REAL_SECONDS_PER_DAY
	game_hour = time_fraction * 24.0

	time_fraction_updated.emit(time_fraction)

	var new_phase := _phase_for_hour(game_hour)
	if new_phase != current_phase:
		current_phase = new_phase
		time_of_day_changed.emit(current_phase)

## Returns the Phase for a given game_hour (0–24).
func _phase_for_hour(h: float) -> Phase:
	if   h >= 5.0  and h < 8.0:  return Phase.DAWN
	elif h >= 8.0  and h < 18.0: return Phase.DAY
	elif h >= 18.0 and h < 21.0: return Phase.DUSK
	else:                          return Phase.NIGHT

## Returns a human-readable time string e.g. "14:32" for UI/debug display.
func get_time_string() -> String:
	var h := int(game_hour)
	var m := int((game_hour - h) * 60.0)
	return "%02d:%02d" % [h, m]

## Returns 0.0–1.0 representing how far through the current phase we are.
## Useful for smoothly interpolating sub-phase visuals.
func get_phase_progress() -> float:
	match current_phase:
		Phase.DAWN:  return inverse_lerp(5.0, 8.0,  game_hour)
		Phase.DAY:   return inverse_lerp(8.0, 18.0, game_hour)
		Phase.DUSK:  return inverse_lerp(18.0, 21.0, game_hour)
		Phase.NIGHT:
			# Night wraps midnight — normalise to 0–1 across 21–29 (mod 24)
			var h := game_hour if game_hour >= 21.0 else game_hour + 24.0
			return inverse_lerp(21.0, 29.0, h)
	return 0.0

## Background.gd
## Attach to the Background CanvasLayer node.
## Smoothly tweens sky and ground colours through the day/night cycle.
extends CanvasLayer

@onready var _sky : ColorRect    = $SkyGradient
@onready var _ground: Sprite2D = $Ground

# ── Sky colour palette (one Color per phase) ──────────────────────────────────
const SKY_COLOURS := {
	DayNightClock.Phase.DAWN:  Color(0.98, 0.75, 0.55, 1.0),   # warm peach
	DayNightClock.Phase.DAY:   Color(0.53, 0.81, 0.98, 1.0),   # sky blue
	DayNightClock.Phase.DUSK:  Color(0.85, 0.45, 0.30, 1.0),   # orange-red
	DayNightClock.Phase.NIGHT: Color(0.08, 0.08, 0.18, 1.0),   # deep navy
}

## Tween duration for phase transitions (seconds)
const TWEEN_DURATION: float = 8.0

# ── Internal ──────────────────────────────────────────────────────────────────
var _tween: Tween

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:


	DayNightClock.time_of_day_changed.connect(_on_phase_changed)

	# Set initial colour immediately (no tween)
	var initial_colour: Color = SKY_COLOURS[DayNightClock.current_phase]
	if _sky: _sky.color = initial_colour
	_apply_ground_tint(DayNightClock.current_phase)

# ── Phase change ──────────────────────────────────────────────────────────────

func _on_phase_changed(phase: DayNightClock.Phase) -> void:
	var target_colour: Color = SKY_COLOURS[phase]

	if _tween: _tween.kill()
	_tween = create_tween()
	if _sky:
		_tween.tween_property(_sky, "color", target_colour, TWEEN_DURATION)
	_tween.parallel().tween_method(_tween_ground_tint.bind(phase), 0.0, 1.0, TWEEN_DURATION)

func _tween_ground_tint(t: float, phase: DayNightClock.Phase) -> void:
	if _ground == null: return
	var target := _ground_colour_for_phase(phase)
	_ground.modulate = _ground.modulate.lerp(target, t)

func _apply_ground_tint(phase: DayNightClock.Phase) -> void:
	if _ground: _ground.modulate = _ground_colour_for_phase(phase)

func _ground_colour_for_phase(phase: DayNightClock.Phase) -> Color:
	match phase:
		DayNightClock.Phase.DAWN:  return Color(1.0, 0.95, 0.85)
		DayNightClock.Phase.DAY:   return Color(1.0, 1.0,  1.0 )
		DayNightClock.Phase.DUSK:  return Color(0.9, 0.75, 0.65)
		DayNightClock.Phase.NIGHT: return Color(0.4, 0.4,  0.55)
	return Color.WHITE

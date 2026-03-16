## AnimalStateMachine.gd
## Attach to the StateMachine child node of AnimalInstance.
## Drives the animal's behaviour through Wander → Idle → Sleep → Grabbed states.
## Parent AnimalInstance is accessed via get_parent().
class_name AnimalStateMachine
extends Node

# ── State enum ────────────────────────────────────────────────────────────────
enum State { WANDER, IDLE, SLEEP, GRABBED }

# ── Config ────────────────────────────────────────────────────────────────────

## How long (seconds) the animal stands idle before wandering again
const IDLE_DURATION_MIN: float = 2.0
const IDLE_DURATION_MAX: float = 6.0

## When picked up at night the animal wakes briefly — it returns to sleep after this
const WAKE_ON_GRAB_DURATION: float = 3.0

## Separation distance — animals push away from each other when closer than this
const SEPARATION_DIST: float = 16.0
const SEPARATION_FORCE: float = 20.0

# ── Signals ───────────────────────────────────────────────────────────────────
signal state_changed(new_state: State)

# ── State ─────────────────────────────────────────────────────────────────────
var current_state: State = State.IDLE

# ── Internal ──────────────────────────────────────────────────────────────────
var _animal: CharacterBody2D   # the AnimalInstance parent
var _target_x: float = 0.0
var _idle_timer: float = 0.0
var _wake_timer: float = 0.0
var _was_sleeping_before_grab: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_animal = get_parent() as CharacterBody2D
	if _animal == null:
		push_error("AnimalStateMachine must be a child of CharacterBody2D (AnimalInstance)")
		return
	# Listen to global day/night changes
	DayNightClock.time_of_day_changed.connect(_on_time_of_day_changed)
	# Seed starting state based on current phase
	_on_time_of_day_changed(DayNightClock.current_phase)

func _physics_process(delta: float) -> void:
	if _animal == null:
		return
	match current_state:
		State.WANDER: _process_wander(delta)
		State.IDLE:   _process_idle(delta)
		State.SLEEP:  _process_sleep(delta)
		State.GRABBED: pass   # position driven externally by DragHandler

# ── State processors ──────────────────────────────────────────────────────────

func _process_wander(delta: float) -> void:
	var dir : float = sign(_target_x - _animal.global_position.x)
	if abs(_target_x - _animal.global_position.x) < 2.0:
		transition(State.IDLE)
		return

	var def: AnimalDefinition = _animal.definition
	var speed := def.walk_speed if def else 30.0

	# Separation from nearby animals
	var sep := _calc_separation()

	_animal.velocity = Vector2((dir * speed) + sep, 0.0)
	_animal.move_and_slide()

	# Flip sprite to face direction of travel
	_animal.get_node_or_null("Sprite").flip_h = (dir < 0)

func _process_idle(delta: float) -> void:
	_animal.velocity = Vector2.ZERO
	_idle_timer -= delta
	if _idle_timer <= 0.0:
		_pick_wander_target()
		transition(State.WANDER)

func _process_sleep(_delta: float) -> void:
	_animal.velocity = Vector2.ZERO
	if _wake_timer > 0.0:
		_wake_timer -= _delta
		if _wake_timer <= 0.0 and _was_sleeping_before_grab:
			transition(State.SLEEP)

# ── Transitions ───────────────────────────────────────────────────────────────

func transition(new_state: State) -> void:
	if new_state == current_state:
		return
	_exit_state(current_state)
	current_state = new_state
	_enter_state(new_state)
	state_changed.emit(new_state)

func _enter_state(s: State) -> void:
	var sprite: AnimatedSprite2D = _animal.get_node_or_null("Sprite")
	match s:
		State.WANDER:
			if sprite: sprite.play("walk")
		State.IDLE:
			_idle_timer = randf_range(IDLE_DURATION_MIN, IDLE_DURATION_MAX)
			if sprite: sprite.play("idle")
		State.SLEEP:
			if sprite: sprite.play("sleep")
			var sleep_particles = _animal.get_node_or_null("SleepParticles")
			if sleep_particles: sleep_particles.emitting = true
		State.GRABBED:
			if sprite: sprite.play("idle")  # freeze-look while held

func _exit_state(s: State) -> void:
	if s == State.SLEEP:
		var sleep_particles = _animal.get_node_or_null("SleepParticles")
		if sleep_particles: sleep_particles.emitting = false

# ── Public API (called by DragHandler) ────────────────────────────────────────

func on_grab() -> void:
	_was_sleeping_before_grab = (current_state == State.SLEEP)
	transition(State.GRABBED)

func on_drop() -> void:
	_wake_timer = 0.0
	if _was_sleeping_before_grab:
		# Brief wander then back to sleep
		_pick_wander_target()
		_wake_timer = WAKE_ON_GRAB_DURATION
		transition(State.WANDER)
	else:
		_pick_wander_target()
		transition(State.WANDER)

# ── Day/Night response ────────────────────────────────────────────────────────

func _on_time_of_day_changed(phase: DayNightClock.Phase) -> void:
	if phase == DayNightClock.Phase.NIGHT:
		# Stagger sleep onset so animals don't all konk out simultaneously
		if current_state != State.GRABBED:
			var delay := randf_range(0.0, 5.0)
			get_tree().create_timer(delay).timeout.connect(
				func():
					if current_state != State.GRABBED:
						transition(State.SLEEP)
			)
	elif phase == DayNightClock.Phase.DAWN:
		if current_state == State.SLEEP:
			transition(State.IDLE)

# ── Helpers ───────────────────────────────────────────────────────────────────

func _pick_wander_target() -> void:
	# Wander within the strip bounds; keep a margin from the edges
	var strip_width: float = DisplayServer.window_get_size().x
	var margin: float = 40.0
	_target_x = randf_range(margin, strip_width - margin)

func _calc_separation() -> float:
	## Returns a horizontal push force away from the nearest overlapping animal.
	var force := 0.0
	var my_x := _animal.global_position.x
	for sibling: Node2D in get_tree().get_nodes_in_group("animals"):
		if sibling == _animal:
			continue
		var dist := my_x - sibling.global_position.x
		if abs(dist) < SEPARATION_DIST and dist != 0.0:
			force += sign(dist) * SEPARATION_FORCE
	return force

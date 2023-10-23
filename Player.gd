extends KinematicBody2D

const GRAVITY: float = 1400.0
const FAST_FALL_MAX_MULTIPLIER: int = 6

const WALK_ACC: int = 2000
const WALK_MAX_SPEED: int = 400
const STOP_ACC: int = 2000

const INITIAL_JUMP_SPEED: int = 400
const JUMP_TIME_TO_PEAK: float = 0.2
const AIR_ACC: int = 2000
var time_in_air: float = 0

var is_grounded: bool = false
var velocity: Vector2 = Vector2()

var in_jump: bool = false
var jump_exited: bool = false


func _physics_process(delta):
	var input_x = (Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"))

	if is_grounded:
		var walk: float = WALK_ACC * input_x
		if abs(walk) < WALK_ACC * 0.2:
			velocity.x = 0
		elif velocity.x != 0 and sign(velocity.x) != sign(input_x):
			velocity.x = 0
		else:
			velocity.x += walk * delta
		velocity.x = clamp(velocity.x, -WALK_MAX_SPEED, WALK_MAX_SPEED)
		jump_exited = false
	else:
		var air_speed: float = AIR_ACC * input_x
		velocity.x += air_speed * delta
		velocity.x = clamp(velocity.x, -WALK_MAX_SPEED, WALK_MAX_SPEED)

	var in_down = Input.get_action_strength("ui_down")

	if in_down > 0 and velocity.y < 0:
		velocity.y = 0
	velocity.y += GRAVITY * (FAST_FALL_MAX_MULTIPLIER * in_down + 1) * delta
	velocity = move_and_slide_with_snap(velocity, Vector2.DOWN, Vector2.UP)

	if test_move(transform, Vector2.DOWN * 5):
		is_grounded = true
	else:
		is_grounded = false

	if is_grounded and Input.is_action_just_pressed("ui_up"):
		in_jump = true

	if in_jump and Input.is_action_pressed("ui_up") and time_in_air < JUMP_TIME_TO_PEAK:
		velocity.y = -INITIAL_JUMP_SPEED
		time_in_air += delta
	else:
		in_jump = false
		time_in_air = 0

	if velocity.y > 0:
		jump_exited = true

	if Input.is_action_just_released("ui_up") and time_in_air < JUMP_TIME_TO_PEAK and not is_grounded and not jump_exited:
		jump_exited = true


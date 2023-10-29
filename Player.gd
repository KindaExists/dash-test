extends KinematicBody2D

# Misc Constants
export var epsilon = 0.002

# Gravity
const GRAVITY_ACC: int = 2000

# Ground movement values
const GROUND_ACC: int = 2000
const GROUND_BASE_MAX_SPEED: int = 400
const GROUND_BASE_STOP_ACC: int = 2000
const GROUND_BASE_TURN_ACC: int = 5000
const GROUND_OVER_DECEL: int = 7500	# Rapidly decelerate if on ground and over max speed
var is_grounded: bool = false

# Jump physics values
const JUMP_INITIAL_SPEED: int = 350
const JUMP_RISING_SPEED: int = 60
const JUMP_TIME_TO_PEAK: float = 0.2
const JUMP_TIME_TO_ENABLE_DROP: float = 0.1
var is_jumping: bool = false
var was_jump_just_released: bool = false

# Air movement values
const AIR_ACC: int = 2000
const AIR_BASE_MAX_SPEED: int = 400
const AIR_BASE_STOP_ACC: int = 1000
const AIR_BASE_TURN_ACC: int = 2000
var time_in_air: float = 0.0

# Dash values
const DASH_DISTANCE: int = 180
const DASH_TIME_TO_END: float = 0.1
const DASH_END_FRACTION_OF_SPEED: int = 8
var time_in_dash: float = 0.0
var is_dash_ready: bool = false
var is_dashing: bool = false

# Vectors
var velocity_vector: Vector2 = Vector2.ZERO
var dash_vector: Vector2 = Vector2.ZERO
var input_direction: Vector2 = Vector2.ZERO
var last_nonzero_x_input_direction: float = 1
var input_vector: Vector2 = Vector2.ZERO
var captured_dash_vector: Vector2 = Vector2.ZERO

# Misc
onready var player_sprite: Sprite = $Sprite


func _physics_process(delta: float):
	is_grounded = test_move(transform, Vector2.DOWN)

	input_direction = get_input_direction()
	input_vector = get_input_vector()

	if input_direction.x != 0:
		last_nonzero_x_input_direction = input_direction.x

	# x-axis movement
	if is_grounded:
		# Player is on ground
		is_dash_ready = true
		was_jump_just_released = false

		if abs(velocity_vector.x) > GROUND_BASE_MAX_SPEED:
			velocity_vector.x = move_toward(velocity_vector.x, GROUND_BASE_MAX_SPEED * sign(velocity_vector.x), GROUND_OVER_DECEL * delta)

		elif abs(velocity_vector.x) > epsilon and sign(velocity_vector.x) == -sign(input_vector.x):
			# Player is turning while under base max speed
			velocity_vector.x = move_toward(velocity_vector.x, 0, GROUND_BASE_TURN_ACC * delta)

		elif abs(velocity_vector.x) > epsilon and abs(input_vector.x) < epsilon:
			# Player is stopping while under base max speed
			velocity_vector.x = move_toward(velocity_vector.x, 0, GROUND_BASE_STOP_ACC * delta)

		else:
			velocity_vector.x = move_toward(
				velocity_vector.x,
				GROUND_BASE_MAX_SPEED * sign(input_vector.x),
				GROUND_ACC * input_vector.x * sign(input_vector.x) * delta
			)

	else:
		# Player is in the air
		if abs(velocity_vector.x) > epsilon and sign(velocity_vector.x) == -sign(input_vector.x):
			# Player is turning while under base max speed
			velocity_vector.x = move_toward(velocity_vector.x, 0, AIR_BASE_TURN_ACC * delta)

		elif abs(velocity_vector.x) > epsilon and abs(input_vector.x) < epsilon:
			# Player is stopping while under base max speed
			velocity_vector.x = move_toward(velocity_vector.x, 0, AIR_BASE_STOP_ACC * delta)

		else:
			velocity_vector.x = move_toward(
				velocity_vector.x,
				AIR_BASE_MAX_SPEED * sign(input_vector.x),
				AIR_ACC * input_vector.x * sign(input_vector.x) * delta
			)


	# y-axis movement
	if is_grounded:
		velocity_vector.y = 0
		if Input.is_action_just_pressed("jump"):
			velocity_vector.y -= JUMP_INITIAL_SPEED
			is_jumping = true
			is_grounded = false

			# prematurely ends dash if active
			is_dashing = false
			time_in_dash = 0

	else:
		if (
			is_jumping
			and Input.is_action_pressed("jump")
			and time_in_air < JUMP_TIME_TO_PEAK
		):
			velocity_vector.y -= JUMP_RISING_SPEED * delta
			time_in_air += delta
		else:
			is_jumping = false
			time_in_air = 0
			if not is_dashing:
				velocity_vector.y += GRAVITY_ACC * delta


	# Dash movement
	if is_dash_ready:
		player_sprite.modulate = Color(1, 1, 1)
	else:
		# Changes color slightly if dash is not ready
		player_sprite.modulate = Color(0.9, 0.5, 0.5)

	if (
		Input.is_action_just_pressed("dash")
		and is_dash_ready
		and not is_dashing
	):
		is_dashing = true
		is_dash_ready = false
		time_in_dash = 0
		if input_direction == Vector2(0, 0):
			captured_dash_vector = Vector2(last_nonzero_x_input_direction, 0)
		else:
			captured_dash_vector = input_direction

	if time_in_dash < DASH_TIME_TO_END and is_dashing:
		time_in_dash += delta
		if is_grounded and captured_dash_vector.y > 0:
			captured_dash_vector.y = 0
		velocity_vector = captured_dash_vector.normalized() * (DASH_DISTANCE / DASH_TIME_TO_END)
	else:
		if is_dashing:
			# Only occurs if dash ends normally
			velocity_vector = velocity_vector / DASH_END_FRACTION_OF_SPEED
		is_dashing = false
		time_in_dash = 0
		captured_dash_vector = Vector2.ZERO

	move_and_slide_with_snap(velocity_vector, Vector2.DOWN, Vector2.UP)



# Not the same as input vector, gets digital input (direction) vector
func get_input_direction() -> Vector2:
	return Vector2(
		int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left")),
		int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))
	)


# Not the same as input direction, gets analog input vector
func get_input_vector() -> Vector2:
	return Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	)

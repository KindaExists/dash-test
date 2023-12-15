extends KinematicBody2D

# Misc Constants
const EPSILON: float = 0.002

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

# Walljump values
const WALL_HORIZONTAL_REPEL_SPEED: int = 400
const WALL_FRICTION: float = 0.7
var is_sliding_on_wall: bool = false
var was_sliding_on_wall: bool = false

# Vectors
export var velocity_vector: Vector2 = Vector2.ZERO
var dash_vector: Vector2 = Vector2.ZERO
var input_direction: Vector2 = Vector2.ZERO
var last_nonzero_x_input_direction: float = 1
var input_vector: Vector2 = Vector2.ZERO
var captured_dash_vector: Vector2 = Vector2.ZERO

# Misc
const GHOST_MIN_SPEED: int = 1200
onready var player_sprite: Sprite = $Sprite
var ghost_scene = preload("res://DashGhost.tscn")


func _process(_delta: float):
	if is_dash_ready:
		player_sprite.modulate = Color(1, 1, 1)
	else:
		# Changes color slightly if dash is not ready
		player_sprite.modulate = Color(0.9, 0.5, 0.5)

	if is_dashing or velocity_vector.length() > GHOST_MIN_SPEED:
		instance_ghost()


func instance_ghost():
	var ghost: Sprite = ghost_scene.instance()
	get_parent().add_child(ghost)

	ghost.global_position = global_position

var is_hitting_ceilling: bool = false
var did_hit_ceilling: bool = false

func _physics_process(delta: float):
	is_grounded = test_move(transform, Vector2.DOWN)
	is_hitting_ceilling = test_move(transform, Vector2.UP)
	var is_wall_on_left: bool = test_move(transform, Vector2.LEFT)
	var is_wall_on_right: bool = test_move(transform, Vector2.RIGHT)

	input_direction = get_input_direction()
	input_vector = get_input_vector()

	is_sliding_on_wall = (is_wall_on_left and (input_direction.x < 0)) or (is_wall_on_right and (input_direction.x > 0))

	if input_direction.x != 0:
		last_nonzero_x_input_direction = input_direction.x

	# x-axis movement
	if is_grounded:
		# Player is on ground
		is_dash_ready = true
		was_jump_just_released = false

		if abs(velocity_vector.x) > GROUND_BASE_MAX_SPEED:
			velocity_vector.x = move_toward(velocity_vector.x, GROUND_BASE_MAX_SPEED * sign(velocity_vector.x), GROUND_OVER_DECEL * delta)

		elif abs(velocity_vector.x) > EPSILON and sign(velocity_vector.x) == -sign(input_vector.x):
			# Player is turning while under base max speed
			velocity_vector.x = move_toward(velocity_vector.x, 0, GROUND_BASE_TURN_ACC * delta)

		elif abs(velocity_vector.x) > EPSILON and abs(input_vector.x) < EPSILON:
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
		if abs(velocity_vector.x) > EPSILON and sign(velocity_vector.x) == -sign(input_vector.x):
			# Player is turning while under base max speed
			velocity_vector.x = move_toward(velocity_vector.x, 0, AIR_BASE_TURN_ACC * delta)

		elif abs(velocity_vector.x) > EPSILON and abs(input_vector.x) < EPSILON:
			# Player is stopping while under base max speed
			velocity_vector.x = move_toward(velocity_vector.x, 0, AIR_BASE_STOP_ACC * delta)

		else:
			if abs(velocity_vector.x) < AIR_BASE_MAX_SPEED:
				velocity_vector.x = move_toward(
					velocity_vector.x,
					AIR_BASE_MAX_SPEED * sign(input_vector.x),
					AIR_ACC * input_vector.x * sign(input_vector.x) * delta
				)


	# y-axis movement
	if is_grounded:
		did_hit_ceilling = false
		velocity_vector.y = 0
		if Input.is_action_just_pressed("jump"):
			$PlayerSounds/Jump.play()
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
			and not is_hitting_ceilling
			and time_in_air < JUMP_TIME_TO_PEAK
		):
			velocity_vector.y -= JUMP_RISING_SPEED * delta
			time_in_air += delta
		else:
			is_jumping = false
			time_in_air = 0
			if not is_dashing:
				velocity_vector.y += GRAVITY_ACC * delta

		if is_hitting_ceilling and not did_hit_ceilling:
			did_hit_ceilling = true
			velocity_vector.y = 0

		if velocity_vector.y > 0 and is_sliding_on_wall and not was_sliding_on_wall:
			velocity_vector.y = 0

		if velocity_vector.y > 0 and is_sliding_on_wall:
			did_hit_ceilling = false
			velocity_vector.y -= GRAVITY_ACC * delta * WALL_FRICTION


	# Dash movement
	if (
		Input.is_action_just_pressed("dash")
		and is_dash_ready
		and not is_dashing
	):
		$PlayerSounds/Dash.play()
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


	# Walljump
	was_sliding_on_wall = is_sliding_on_wall

	if is_sliding_on_wall and Input.is_action_just_pressed("jump") and not test_move(transform, Vector2.DOWN):
		$PlayerSounds/Jump.play()
		velocity_vector.x = (int(is_wall_on_left) - int(is_wall_on_right)) * WALL_HORIZONTAL_REPEL_SPEED
		velocity_vector.y = -JUMP_INITIAL_SPEED
		is_jumping = true
		is_grounded = false

		# prematurely ends dash if active
		is_dashing = false
		time_in_dash = 0


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

extends Node2D

const DISTANCE_TO_ZOOM_RATIO: float = 0.002
const BASE_X_BOUNDS: int = 400

onready var camera: Camera2D = $PlayerCamera
onready var player: KinematicBody2D = $Player
onready var respawn_point: Node2D = $RespawnPoint
onready var level_complete_text: Control = $LevelCompleteText

const CAMERA_HORIZONTAL_INITIAL_SPEED: int = 400
const CAMERA_HORIZONTAL_ACC: int = 2000
const CAMERA_HORIZONTAL_MAX_SPEED: int = 6000

const CAMERA_VERTICAL_INITIAL_SPEED: int = 400
const CAMERA_VERTICAL_ACC: int = 2000
const CAMERA_VERTICAL_MAX_SPEED: int = 999999

const SLOW_HORIZONTAL_CUTOFF: int = 40
const FAST_HORIZONTAL_CUTOFF: int = 50
const MIN_HORIZONTAL_PLAYER_VELOCITY_CUTOFF: int = 1000

const SLOW_VERTICAL_CUTOFF: int = 60
const FAST_VERTICAL_CUTOFF: int = 80
const MIN_VERTICAL_PLAYER_VELOCITY_CUTOFF: int = 1000

var camera_velocity_x: float = CAMERA_HORIZONTAL_INITIAL_SPEED
var was_beyond_fast_cutoff_x = false
var caught_up_x: bool = true
var pos_diff_x: float = 0

var camera_velocity_y: float = CAMERA_HORIZONTAL_INITIAL_SPEED
var was_beyond_fast_cutoff_y: bool = false
var pos_diff_y: float = 0

func _process(delta: float):
	if player:
		var player_velocity_vector: Vector2 = player.get("velocity_vector")

		pos_diff_x = camera.global_position.x - player.global_position.x

		if abs(pos_diff_x) > FAST_HORIZONTAL_CUTOFF and not was_beyond_fast_cutoff_x:
			was_beyond_fast_cutoff_x = true
			caught_up_x = false
		elif abs(pos_diff_x) > SLOW_HORIZONTAL_CUTOFF and not was_beyond_fast_cutoff_x:
			camera.global_position.x = player.global_position.x + SLOW_HORIZONTAL_CUTOFF * sign(pos_diff_x)

		if caught_up_x and was_beyond_fast_cutoff_x:
			if abs(player_velocity_vector.x) < MIN_HORIZONTAL_PLAYER_VELOCITY_CUTOFF:
				if abs(pos_diff_x) > 0.01:
					camera_velocity_x = move_toward(camera_velocity_x, CAMERA_HORIZONTAL_MAX_SPEED, CAMERA_HORIZONTAL_ACC * delta)
					camera.global_position.x = move_toward(camera.global_position.x, player.global_position.x, clamp(camera_velocity_x * delta, 0, abs(pos_diff_x)))
				else:
					camera_velocity_x = CAMERA_HORIZONTAL_INITIAL_SPEED
					was_beyond_fast_cutoff_x = false
			else:
				camera.global_position.x = player.global_position.x + SLOW_HORIZONTAL_CUTOFF * sign(-player_velocity_vector.x)
		elif was_beyond_fast_cutoff_x:
			camera_velocity_x = move_toward(camera_velocity_x, CAMERA_HORIZONTAL_MAX_SPEED, CAMERA_HORIZONTAL_ACC * delta)
			camera.global_position.x = move_toward(camera.global_position.x, player.global_position.x, clamp(camera_velocity_x * delta, 0, abs(pos_diff_x)))

			if abs(pos_diff_x) <= SLOW_HORIZONTAL_CUTOFF:
				caught_up_x = true
				camera_velocity_x = CAMERA_HORIZONTAL_INITIAL_SPEED




		pos_diff_y = camera.global_position.y - player.global_position.y
		if abs(pos_diff_y) > SLOW_VERTICAL_CUTOFF:
			camera.global_position.y = player.global_position.y + SLOW_VERTICAL_CUTOFF * sign(pos_diff_y)

func _on_DeathBoxes_body_entered(body: Node):
	if body == player:
		$Player/PlayerSounds/Death.play()
		player.global_position = respawn_point.global_position
		camera.global_position = player.global_position

		# I shouldn't be doing this, but I rather not do this the better way right now
		player.set("velocity_vector", Vector2.ZERO)
		player.set("is_dashing", false)
		player.set("is_jumping", false)


func _on_Flag_body_entered(body: Node):
	if body == player:
		$GUI/LevelCompleteMenu.level_completed()

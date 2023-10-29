extends Node2D

const DISTANCE_TO_ZOOM_RATIO: float = 0.002
const BASE_X_BOUNDS: int = 400

onready var camera: Camera2D = $Camera2D
onready var player: KinematicBody2D = $Player

func _physics_process(_delta: float):
	var player_x_pos: float = player.position.x

	if abs(player_x_pos) > BASE_X_BOUNDS:
		var new_zoom_factor: float = 1 + (abs(player_x_pos) - BASE_X_BOUNDS) * DISTANCE_TO_ZOOM_RATIO
		camera.zoom = Vector2(new_zoom_factor, new_zoom_factor)

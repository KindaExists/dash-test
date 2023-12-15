extends Control

var is_paused: bool = false setget set_is_paused

func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		self.is_paused = !is_paused


func set_is_paused(value):
	# Made following this tutorial: https://youtu.be/Su3pU14YzeY?si=u8XGiI-mxk7JOTf4
	is_paused = value
	get_tree().paused = is_paused
	self.visible = is_paused


func _on_ResumeButton_pressed():
	self.is_paused = false


func _on_MainMenuButton_pressed():
	self.is_paused = false
	get_tree().change_scene("res://MainMenu.tscn")

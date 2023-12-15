extends Control

func level_completed():
	get_tree().paused = true
	self.visible = true

func _on_MainMenuButton_pressed():
	get_tree().paused = false
	get_tree().change_scene("res://MainMenu.tscn")
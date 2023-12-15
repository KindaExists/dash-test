extends Control


func _on_StartButton_pressed():
	get_tree().change_scene("res://Main.tscn")


func _on_SettingsButton_pressed():
	get_tree().change_scene("res://OptionsMenu.tscn")


func _on_QuitButton_pressed():
	get_tree().quit()

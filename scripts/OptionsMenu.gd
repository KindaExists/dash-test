extends Control


func _ready():
	var volume_slider: Control = $ColorRect/CenterContainer/VBoxContainer/HBoxContainer/VBoxContainer/VolumeSlider
	volume_slider.value = int(AudioServer.get_bus_volume_db(0))


func _on_BackButton_pressed():
	get_tree().change_scene("res://MainMenu.tscn")


func _on_VolumeSlider_value_changed(value: float):
	if value <= -45:
		AudioServer.set_bus_mute(0, true)
	else:
		AudioServer.set_bus_mute(0, false)
	AudioServer.set_bus_volume_db(0, value)

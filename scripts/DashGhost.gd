extends Sprite

func _ready():
	$Tween.interpolate_property(self, "modulate:a", 0.9, 0.0, 0.15, 4, 1)
	$Tween.start()

func _on_Tween_tween_all_completed():
	queue_free()

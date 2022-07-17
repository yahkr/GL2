extends TextureRect


func fade():
	var tween := get_tree().create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.1).set_delay(0.5)

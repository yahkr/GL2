extends Control


func _ready():
	var tween := get_tree().create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.1).set_delay(3)
	tween.finished.connect(queue_free)

class_name MuzzleFlash

extends GPUParticles3D


func emit() -> void:
	restart()
	$Light.light_energy = 1
	var tween = get_tree().create_tween()
	tween.tween_property($Light, "light_energy", 0, .1)

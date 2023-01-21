extends Node3D


func _ready():
	get_tree().create_timer(4.0).timeout.connect($Particles.queue_free)


func concrete():
	$Particles/Wood.queue_free()
	$Particles/Metal.queue_free()
	$Particles/Concrete.emitting = true


func wood():
	$Particles/Concrete.queue_free()
	$Particles/Metal.queue_free()
	$Particles/Wood.emitting = true


func metal():
	$Particles/Wood.queue_free()
	$Particles/Concrete.queue_free()
	$Particles/Metal.emitting = true

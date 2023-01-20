extends RigidBody3D

const explosion = preload("res://objects/explosion.tscn")

@onready var sound_break := $SoundBreak as AudioStreamPlayer3D

var health := 3:
	set(value):
		health = value
		if health == 1:
			$Fire.visible = true
			$Fire.monitoring = true
		if health == 0:
			sound_break.play()
			var explosion_instance := explosion.instantiate()
			get_tree().get_root().add_child(explosion_instance)
			explosion_instance.global_position = global_position + Vector3.UP * 0.4
			freeze = true
			visible = false
			$CollisionShape3D.disabled = true
			await sound_break.finished
			queue_free()

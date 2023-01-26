extends RigidBody3D


@onready var sound_break := $SoundBreak as AudioStreamPlayer3D

var health := 3:
	set(value):
		health = value
		if health == 0:
			sound_break.play()
			freeze = true
			visible = false
			$CollisionShape3D.disabled = true
			for i in range(1,9):
				var chunk: PackedScene
				chunk = load("res://objects/wooden_crate/wodden_crate_chunk_0%s.tscn" % i)
				var chunk_instance := chunk.instantiate()
				get_tree().current_scene.add_child(chunk_instance)
				chunk_instance.position = position
				chunk_instance.rotation = rotation
				chunk_instance.apply_torque(Vector3.FORWARD * 20)
			await sound_break.finished
			queue_free()

extends RigidDynamicBody3D


@onready var sound_break := $SoundBreak as AudioStreamPlayer3D

var health := 3:
	set(value):
		health = value
		if health == 0:
			sound_break.play()
			freeze = true
			visible = false
			$CollisionShape3D.disabled = true
			await sound_break.finished
			queue_free()

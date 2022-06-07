extends Weapon


@onready var sound_swing := $SoundSwing as AudioStreamPlayer


func _ready():
	super()


func _process(_delta):
	if visible and Input.is_action_just_pressed("primary_attack") and cooldown.is_stopped():
		cooldown.start()
		sound_swing.play()
		animation_player.stop()
		if weapon_raycast.is_colliding():
			animation_player.play("hitcenter" + str(randi() % 3 + 1))
		else:
			animation_player.play("misscenter" + str(randi() % 2 + 1))
		hit()

extends Weapon


@onready var sound_swing := $SoundSwing as AudioStreamPlayer


func _ready():
	super()


func _process(_delta):
	if is_attacking():
		cooldown.start()
		sound_swing.play()
		animation_player.stop()
		if weapon_raycast.is_colliding():
			animation_player.play("hitcenter" + str(randi() % 3 + 1))
		else:
			animation_player.play("misscenter" + str(randi() % 2 + 1))
		hit()

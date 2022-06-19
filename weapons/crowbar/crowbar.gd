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


func _on_area_3d_body_entered(body):
	if body.is_in_group("CrowbarItem"):
		body.queue_free()
		process_mode = Node.PROCESS_MODE_INHERIT
		%SoundCollectAmmo.play()
		get_parent().select_weapon(get_index(), false)
		get_tree().get_nodes_in_group("WeaponSelectItem")[get_index()].modulate = Color.WHITE

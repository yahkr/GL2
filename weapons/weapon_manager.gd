extends RayCast3D


@onready var timer := %TimerWeaponSelectFade as Timer

var current_weapon := -1


func _ready():
	pass


func _process(_delta):
	if Input.is_action_just_released("next_weapon"):
		cycle_weapon(false)
	elif Input.is_action_just_released("previous_weapon"):
		cycle_weapon(true)


func cycle_weapon(previous: bool):
	var new_index := current_weapon
	for i in get_child_count():
		new_index += -1 if previous else 1
		new_index = posmod(new_index, get_child_count())
		
		var weapon := get_child(new_index) as Weapon
		if weapon and weapon.process_mode == Node.PROCESS_MODE_INHERIT:
			select_weapon(new_index, true)
			break


func select_weapon(index: int, show_hud := true):
	if current_weapon != index:
		get_child(current_weapon).visible = false
		
		var weapon_select_items := get_tree().get_nodes_in_group("WeaponSelectItem")
		
		weapon_select_items[current_weapon].get_theme_stylebox("panel").border_color = "1a1a1ac8"
		
		if index >= 0:
			current_weapon = index
			
			get_child(current_weapon).emit_signal("weapon_selected")
			
			weapon_select_items[current_weapon].get_theme_stylebox("panel").border_color = "ffd600"
			
			var gun := get_child(current_weapon) as Gun
			if gun:
				%PrimaryAmmo.visible = true
				%SecondaryAmmo.visible = gun.secondary_ammo >= 0
			else:
				%PrimaryAmmo.visible = false
				%SecondaryAmmo.visible = false
	
	if show_hud:
		%SoundSwitchWeapon.play()
		
		timer.start()
		var tween := get_tree().create_tween()
		tween.tween_property(%WeaponCategories, "modulate", Color.WHITE, 0.1)


func _on_timer_weapon_select_fade_timeout():
	var tween := get_tree().create_tween()
	tween.tween_property(%WeaponCategories, "modulate", Color.TRANSPARENT, 0.1)

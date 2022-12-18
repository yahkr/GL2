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
	elif Input.is_action_just_pressed("First Weapon Category"):
		cycle_weapon(false, 0)
	elif Input.is_action_just_pressed("Second Weapon Category"):
		cycle_weapon(false, 1)
	elif Input.is_action_just_pressed("Third Weapon Category"):
		cycle_weapon(false, 2)
	elif Input.is_action_just_pressed("Fourth Weapon Category"):
		cycle_weapon(false, 3)
	elif Input.is_action_just_pressed("Fifth Weapon Category"):
		cycle_weapon(false, 4)
	elif Input.is_action_just_pressed("Sixth Weapon Category"):
		cycle_weapon(false, 5)


func cycle_weapon(previous: bool, category := -1):
	var new_index := current_weapon
	var category_node := %WeaponCategories.get_child(category)
	var category_child_count := category_node.get_child_count()
	var category_start := get_tree().get_nodes_in_group("WeaponSelectItem").find(category_node.get_child(0))

	for i in get_child_count():
		if category != -1 and not new_index in range(category_start, category_start + category_child_count):
			new_index = category_start - 1
		
		new_index += -1 if previous else 1

		if category == -1:
			new_index = posmod(new_index, get_child_count())
		else:
			new_index = wrapi(new_index, category_start, category_start + category_child_count)

		var weapon := get_child(new_index) as Weapon
		if weapon and weapon.process_mode == Node.PROCESS_MODE_INHERIT:
			select_weapon(new_index, true)
			break


func select_weapon(index: int, show_hud := true):
	if current_weapon != index:
		var current_weapon_node := get_child(current_weapon)
		current_weapon_node.visible = false
		# Cancel ammo refill on weapon switch
		if current_weapon_node is Gun:
			if current_weapon_node.animation_player.animation_finished.is_connected(
					current_weapon_node.refill_ammo
			):
				current_weapon_node.animation_player.animation_finished.disconnect(
					current_weapon_node.refill_ammo
				)

		var weapon_select_items := get_tree().get_nodes_in_group("WeaponSelectItem")

		weapon_select_items[current_weapon].get_theme_stylebox("panel").border_color = "1a1a1ac8"

		if index >= 0:
			current_weapon = index
			current_weapon_node = get_child(current_weapon)

			current_weapon_node.emit_signal("weapon_selected")

			weapon_select_items[current_weapon].get_theme_stylebox("panel").border_color = "ffd600"

			if current_weapon_node is Gun:
				%PrimaryAmmo.visible = true
				%SecondaryAmmo.visible = current_weapon_node.secondary_ammo >= 0
				current_weapon_node.update_ammo_labels()
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

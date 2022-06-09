extends RayCast3D


@onready var timer := %TimerWeaponSelectFade as Timer

var current_weapon := 0


func _ready():
	select_weapon(current_weapon)


func _process(_delta):
	if Input.is_action_just_released("next_weapon"):
		select_weapon(current_weapon + 1)
	elif Input.is_action_just_released("previous_weapon"):
		select_weapon(current_weapon - 1)


func select_weapon(index: int):
	var weapon_select_items := get_tree().get_nodes_in_group("WeaponSelectItem")
	
	if current_weapon != index:
		%SoundSwitchWeapon.play()
		
		weapon_select_items[current_weapon].get_theme_stylebox("panel").border_color = "1a1a1ac8"
		
		get_child(current_weapon).visible = false
		
		timer.start()
		var tween := get_tree().create_tween()
		tween.tween_property(%WeaponCategories, "modulate", Color.WHITE, 0.1)
	
	current_weapon = posmod(index, weapon_select_items.size())
	
	weapon_select_items[current_weapon].get_theme_stylebox("panel").border_color = "ffd600"
	
	get_child(current_weapon).emit_signal("weapon_selected")
	
	var gun := get_child(current_weapon) as Gun
	if gun:
		%PrimaryAmmo.visible = true
		%SecondaryAmmo.visible = gun.secondary_ammo >= 0
	else:
		%PrimaryAmmo.visible = false
		%SecondaryAmmo.visible = false


func _on_timer_weapon_select_fade_timeout():
	var tween := get_tree().create_tween()
	tween.tween_property(%WeaponCategories, "modulate", Color.TRANSPARENT, 0.1)

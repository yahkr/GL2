extends RayCast3D


var current_weapon := 0
var selected_panel := preload("res://weapons/selected_panel.tres")


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
		
		weapon_select_items[current_weapon].remove_theme_stylebox_override("panel")
		
		get_child(current_weapon).visible = false
	
	current_weapon = posmod(index, weapon_select_items.size())
	
	weapon_select_items[current_weapon].add_theme_stylebox_override("panel", selected_panel)
	
	get_child(current_weapon).emit_signal("weapon_selected")
	
	var gun := get_child(current_weapon) as Gun
	if gun:
		%PrimaryAmmo.visible = true
		%SecondaryAmmo.visible = gun.secondary_ammo >= 0
	else:
		%PrimaryAmmo.visible = false
		%SecondaryAmmo.visible = false

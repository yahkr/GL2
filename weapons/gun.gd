extends Weapon

class_name Gun


const ammo_notification = preload("res://weapons/ammo_notification.tscn")

@onready var sound_lowammo := $SoundLowAmmo as AudioStreamPlayer
@onready var sound_noammo := $SoundNoAmmo as AudioStreamPlayer
@onready var sound_reload := $SoundReload as AudioStreamPlayer
@onready var sound_shoot := $SoundShoot as AudioStreamPlayer
@onready var weapon_categories := %WeaponCategories

@onready var initial_idle_animation := idle_animation

@export var idle_empty_animation := "idle01empty"
@export var magazine_ammo := 18:
	set(value):
		call_deferred("update_ammo_labels")
		if value == int(magazine_size / 4.0):
			sound_lowammo.play()
		if value == 0 and reserve_ammo == 0:
			owner.play_fvox("blip")
			owner.play_fvox("ammo_depleted")
			weapon_categories.find_child(name).modulate = Color.RED
			idle_animation = idle_empty_animation
		elif weapon_categories:
			weapon_categories.find_child(name).modulate = Color.WHITE
		magazine_ammo = value
@export var magazine_size := 18
@export var reserve_size := 150
@export var reserve_ammo := 0:
	set(value):
			call_deferred("update_ammo_labels")
			reserve_ammo = value
@export var secondary_ammo := -1:
	set(value):
		call_deferred("update_ammo_labels")
		secondary_ammo = value


func _ready():
	super()


func shoot_gun():
	if is_attacking():
		if magazine_ammo > 0:
			cooldown.start()
			sound_shoot.play()
			if $Model.has_node("MuzzleFlash"):
				$Model/MuzzleFlash.emit()
			magazine_ammo -= 1
			animation_player.stop()
			if magazine_ammo == 0 and animation_player.has_animation("fireempty"):
				animation_player.play("fireempty")
			else:
				animation_player.play("fire")
			hit()
			return true
		else:
			sound_noammo.play()
	return false


func reload_gun():
	if (
			not visible
			or not animation_player.current_animation.begins_with("idle")
			and not (
					animation_player.current_animation.begins_with("fire")
					and animation_player.current_animation_position > 0.1
			)
	):
		return

	if Input.is_action_just_pressed("reload") or magazine_ammo == 0:
		var amount: int = min(reserve_ammo, magazine_size - magazine_ammo)
		if amount > 0:
			sound_reload.play()
			animation_player.play("reload")
			animation_player.animation_finished.connect(refill_ammo.bind(amount), CONNECT_ONE_SHOT)
			idle_animation = initial_idle_animation


func refill_ammo(anim: String, amount: int):
	if anim == "reload":
		reserve_ammo -= amount
		magazine_ammo += amount


func update_ammo_labels():
	%PrimaryAmmo/HBoxContainer/LabelMagazine.text = str(magazine_ammo)
	%PrimaryAmmo/HBoxContainer/LabelReserve.text = str(reserve_ammo)
	%SecondaryAmmo/Label.text = str(secondary_ammo)
	if magazine_ammo == 0:
		%PrimaryAmmo.modulate = Color.RED
	else:
		%PrimaryAmmo.modulate = Color.WHITE

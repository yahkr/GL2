extends Weapon

class_name Gun


@onready var sound_lowammo := $SoundLowAmmo as AudioStreamPlayer
@onready var sound_noammo := $SoundNoAmmo as AudioStreamPlayer
@onready var sound_reload := $SoundReload as AudioStreamPlayer
@onready var sound_shoot := $SoundShoot as AudioStreamPlayer
@onready var weapon_categories := %WeaponCategories

@export var magazine_ammo := 18:
	set(value):
		call_deferred("update_ammo_labels")
		if value == int(magazine_size / 4.0):
			sound_lowammo.play()
		elif value == 0 and reserve_ammo == 0:
			owner.play_fvox("blip")
			owner.play_fvox("ammo_depleted")
			weapon_categories.find_child(name).modulate = Color.RED
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

const ammo_notification = preload("res://weapons/ammo_notification.tscn")


func _ready():
	super()


func shoot_gun():
	if is_attacking():
		if magazine_ammo > 0:
			cooldown.start()
			sound_shoot.play()
			animation_player.stop()
			animation_player.play("fire")
			magazine_ammo -= 1
			hit()
			return true
		else:
			sound_noammo.play()
	return false


func reload_gun():
	if (
			not visible
			or animation_player.current_animation != "idle01"
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


func refill_ammo(anim: String, amount: int):
	if anim == "reload":
		reserve_ammo -= amount
		magazine_ammo += amount


func update_ammo_labels():
	%PrimaryAmmo/HBoxContainer/LabelMagazine.text = str(magazine_ammo)
	%PrimaryAmmo/HBoxContainer/LabelReserve.text = str(reserve_ammo)
	%SecondaryAmmo/Label.text = str(secondary_ammo)
	if magazine_ammo == 0 and reserve_ammo == 0:
		%PrimaryAmmo.modulate = Color.RED
	else:
		%PrimaryAmmo.modulate = Color.WHITE

extends Weapon

class_name Gun

@onready var sound_noammo := $SoundNoAmmo as AudioStreamPlayer
@onready var sound_reload := $SoundReload as AudioStreamPlayer
@onready var sound_shoot := $SoundShoot as AudioStreamPlayer

@export var magazine_ammo := 17:
	set(value):
		call_deferred("update_ammo_labels")
		magazine_ammo = value
@export var magazine_size := 17
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
	if not visible or animation_player.current_animation == "reload":
		return
	
	if Input.is_action_just_pressed("primary_attack") and cooldown.is_stopped():
		if magazine_ammo > 0:
			cooldown.start()
			sound_shoot.play()
			animation_player.stop()
			animation_player.play("fire")
			magazine_ammo -= 1
			hit()
		else:
			sound_noammo.play()


func reload_gun():
	if not visible or animation_player.current_animation == "fire1":
		return
	
	if Input.is_action_just_pressed("reload") or magazine_ammo == 0:
		var reload_ammo: int = min(reserve_ammo, magazine_size - magazine_ammo)
		if reload_ammo > 0:
			reserve_ammo -= reload_ammo
			magazine_ammo += reload_ammo
			sound_reload.play()
			animation_player.play("reload")


func update_ammo_labels():
	%PrimaryAmmo/HBoxContainer/LabelMagazine.text = str(magazine_ammo)
	%PrimaryAmmo/HBoxContainer/LabelReserve.text = str(reserve_ammo)
	%SecondaryAmmo/Label.text = str(secondary_ammo)

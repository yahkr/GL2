extends Weapon

class_name Gun


@onready var sound_reload := $SoundReload as AudioStreamPlayer3D
@onready var sound_shoot := $SoundShoot as AudioStreamPlayer

@export var magazine_ammo := 0:
	set(value):
		call_deferred("update_ammo_labels")
		magazine_ammo = value
@export var reserve_ammo := 0
@export var secondary_ammo := -1:
	set(value):
		call_deferred("update_ammo_labels")
		secondary_ammo = value


func _ready():
	super()


func shoot_gun():
	if visible and Input.is_action_just_pressed("primary_attack") and cooldown.is_stopped():
		cooldown.start()
		sound_shoot.play()
		magazine_ammo -= 1
		hit()


func reload_gun():
	if visible and Input.is_action_just_pressed("reload"):
		magazine_ammo += 17
		reserve_ammo -= 17


func update_ammo_labels():
	%PrimaryAmmo/HBoxContainer/LabelMagazine.text = str(magazine_ammo)
	%PrimaryAmmo/HBoxContainer/LabelReserve.text = str(reserve_ammo)
	%SecondaryAmmo/Label.text = str(secondary_ammo)

extends Node3D

class_name Weapon


@export var hit_range := 3.0

@onready var cooldown := $Cooldown as Timer
@onready var sound_hit_concrete := $SoundHitConcrete as AudioStreamPlayer3D
@onready var sound_hit_metal := $SoundHitMetal as AudioStreamPlayer3D
@onready var sound_hit_wood := $SoundHitWood as AudioStreamPlayer3D
@onready var weapon_raycast := get_parent() as RayCast3D


func _ready():
	connect("visibility_changed", update_hit_range)


func hit():
	var node := weapon_raycast.get_collider() as Node3D
	if node:
		if node.is_in_group("MetalMaterial"):
			sound_hit_metal.position = weapon_raycast.get_collision_point()
			sound_hit_metal.play()
		elif node.is_in_group("WoodMaterial"):
			sound_hit_wood.position = weapon_raycast.get_collision_point()
			sound_hit_wood.play()
		else:
			sound_hit_concrete.position = weapon_raycast.get_collision_point()
			sound_hit_concrete.play()


func update_hit_range():
	weapon_raycast.target_position = Vector3.FORWARD * hit_range

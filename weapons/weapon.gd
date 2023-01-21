extends Node3D

class_name Weapon


const bullet_hole = preload("res://weapons/decals/bullet_hole.tscn")
const item_notification = preload("res://objects/item_notification.tscn")

@export var hit_range := 3.0
@export var idle_animation := "idle01"

@onready var animation_player := $Model/AnimationPlayer as AnimationPlayer
@onready var cooldown := $Cooldown as Timer
@onready var sound_hit_concrete := $SoundHitConcrete as AudioStreamPlayer3D
@onready var sound_hit_metal := $SoundHitMetal as AudioStreamPlayer3D
@onready var sound_hit_wood := $SoundHitWood as AudioStreamPlayer3D
@onready var weapon_raycast := get_parent() as RayCast3D

signal weapon_selected


func _ready():
	weapon_selected.connect(draw_weapon)
	animation_player.animation_finished.connect(play_idle)


func is_attacking() -> bool:
	return (visible
			and Input.is_action_just_pressed("primary_attack")
			and cooldown.is_stopped()
			and not (animation_player.current_animation == "draw"
					and animation_player.current_animation_position < 1.0)
			and animation_player.current_animation != "reload")


func hit():
	var node := weapon_raycast.get_collider() as Node3D
	if node:
		var bullet_hole_instance = bullet_hole.instantiate()
		if node.is_in_group("MetalMaterial"):
			sound_hit_metal.position = weapon_raycast.get_collision_point()
			sound_hit_metal.play()
			bullet_hole_instance.metal()
		elif node.is_in_group("WoodMaterial"):
			sound_hit_wood.position = weapon_raycast.get_collision_point()
			sound_hit_wood.play()
			bullet_hole_instance.wood()
		else:
			sound_hit_concrete.position = weapon_raycast.get_collision_point()
			sound_hit_concrete.play()
			bullet_hole_instance.concrete()

		node.add_child(bullet_hole_instance)
		bullet_hole_instance.global_position = weapon_raycast.get_collision_point()
		if Vector3.UP.is_equal_approx(weapon_raycast.get_collision_normal()):
			bullet_hole_instance.global_rotation.x = -PI / 2
		else:
			bullet_hole_instance.look_at(
					bullet_hole_instance.global_position - weapon_raycast.get_collision_normal()
			)

		if "health" in node:
			node.health -= 1

		if node is RigidBody3D:
			var hit_force := -global_transform.basis.z
			hit_force.y = 0
			node.apply_force(hit_force * 200)

func draw_weapon():
	weapon_raycast.target_position = Vector3.FORWARD * hit_range
	if not animation_player.current_animation.is_empty():
		animation_player.stop()
	animation_player.play("draw", 0)
	animation_player.advance(0)
	visible = true


func play_idle(anim_name: String):
	if anim_name != "holster":
		animation_player.play(idle_animation)

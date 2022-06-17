extends CharacterBody3D

class_name Player


@export var speed: float

@onready var anim_tree := $AnimationTree as AnimationTree
@onready var state_machine = anim_tree["parameters/playback"] as AnimationNodeStateMachinePlayback
@onready var camera := $Camera3D as Camera3D
@onready var health_label := %HealthValue as Label
@onready var suit_power_label := %SuitValue as Label
@onready var use_raycast := $Camera3D/UseRayCast3D as RayCast3D
@onready var sound_cannot_use := $SoundCannotUse as AudioStreamPlayer
@onready var sound_flashlight := $SoundFlashlight as AudioStreamPlayer
@onready var sound_suit_battery := $SoundSuitBattery as AudioStreamPlayer
@onready var sound_health_kit := $SoundHealthKit as AudioStreamPlayer
@onready var sound_fvox := $SoundFVOX as AudioStreamPlayer

const AIR_ACCELERATION = 2.0
const FALL_DAMAGE_THRESHOLD = 20.0
const FALL_DAMAGE_MULTIPLIER = 15.0
const GROUND_ACCELERATION = 20.0
const JUMP_VELOCITY = 6.0

const item_notification = preload("res://objects/item_notification.tscn")
const fvox_file = "res://sounds/fvox/%s.wav"

var health: int:
	set(value):
		health = clamp(value, 0, 100)
		health_label.text = str(health)
		if health < 20:
			$Indicators/Health.modulate = Color(1.0, 0.25, 0.25)
		else:
			$Indicators/Health.modulate = Color.WHITE

var suit_power: int:
	set(value):
		suit_power = clamp(value, 0, 100)
		suit_power_label.text = str(suit_power)

var current_interactable: Interactable

var acceleration: float
var fall_velocity: float
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var joypad_look: Vector2
var movement: Vector2

var joypad_look_curve: float
var joypad_look_inverted_x: bool
var joypad_look_inverted_y: bool
var joypad_look_outer_threshold: float
var joypad_look_sensitivity_x: float
var joypad_look_sensitivity_y: float

var mouse_look_inverted_x: bool
var mouse_look_inverted_y: bool
var mouse_look_sensitivity: float


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	health = 10
	suit_power = 0


func _process(_delta):
	look()


func _input(event):
	if event is InputEventMouseMotion:
		var input = event.relative
		if mouse_look_inverted_x:
			input.x *= -1
		if mouse_look_inverted_y:
			input.y *= -1
		
		rotate_y(-input.x * mouse_look_sensitivity / 500)
		camera.rotate_x(-input.y * mouse_look_sensitivity / 500)


func _physics_process(delta):
	move(delta)
	interact()
	flashlight()


func flashlight():
	if Input.is_action_just_pressed("flashlight"):
		%Flashlight.visible = !%Flashlight.visible
		sound_flashlight.play()


func interact():
	var interactable := use_raycast.get_collider() as Interactable
	
	if Input.is_action_just_released("use") or interactable != current_interactable:
		if current_interactable:
			current_interactable.stop_interact()
			current_interactable = null
	
	if interactable:
		if Input.is_action_pressed("use"):
			interactable.interact(self)
			current_interactable = interactable
	elif Input.is_action_just_pressed("use"):
		sound_cannot_use.play()


func look():
	var look_input = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	
	if joypad_look_inverted_x:
		look_input.x *= -1
	if joypad_look_inverted_y:
		look_input.y *= -1
	
	if abs(look_input.x) > 1 - joypad_look_outer_threshold:
		look_input.x = round(look_input.x)
	joypad_look.x = abs(look_input.x) ** joypad_look_curve * joypad_look_sensitivity_x / 10
	if look_input.x < 0:
		joypad_look.x *= -1
	
	if abs(look_input.y) > 1 - joypad_look_outer_threshold:
		look_input.y = round(look_input.y)
	joypad_look.y = abs(look_input.y) ** joypad_look_curve * joypad_look_sensitivity_y / 10
	if look_input.y < 0:
		joypad_look.y *= -1
	
	rotate_y(-joypad_look.x)
	camera.rotate_x(-joypad_look.y)
	
	# Clamp vertical camera rotation for both mouse and joypad
	camera.rotation.x = clamp(camera.rotation.x, -PI / 2, PI / 2)


func move(delta):
	# Gravity and jumping
	if is_on_floor():
		if fall_velocity < -FALL_DAMAGE_THRESHOLD:
			health += int((fall_velocity + FALL_DAMAGE_THRESHOLD) * FALL_DAMAGE_MULTIPLIER)
		fall_velocity = 0
		acceleration = GROUND_ACCELERATION
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
	else:
		velocity.y -= gravity * delta
		fall_velocity = velocity.y
		acceleration = AIR_ACCELERATION
	
	# Crouching and sprinting
	if Input.is_action_pressed("crouch"):
		state_machine.travel("Crouch")
	elif not test_move(transform, Vector3.UP):
		if Input.is_action_pressed("sprint"):
			state_machine.travel("Sprint")
		else:
			state_machine.travel("RESET")
	
	# Get input and move with acceleration/deceleration
	var move_input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	move_input = move_input.rotated(-rotation.y)
	movement = movement.lerp(move_input * speed, acceleration * delta)
	velocity.x = movement.x
	velocity.z = movement.y
	move_and_slide()


func play_fvox(sound_name: String):
	sound_fvox.stream = load(fvox_file % sound_name)
	sound_fvox.play()


func _on_area_3d_body_entered(body):
	var notification_instance = item_notification.instantiate()
	%ItemNotifications.add_child(notification_instance)
	if body.is_in_group("HealthKit"):
		if health < 100:
			health += 15
			body.queue_free()
			sound_health_kit.play()
	elif body.is_in_group("SuitBattery"):
		if suit_power < 100:
			suit_power += 6
			body.queue_free()
			sound_suit_battery.play()
			notification_instance.text = "*"
			
			play_fvox("fuzz")
			
			await sound_fvox.finished
			await get_tree().create_timer(0.5).timeout
			
			var snap := snapped(suit_power, 5)
			var five := fmod(snap, 10)
			var tens := int(snap / 10)
			
			if tens != 10:
				play_fvox("power")
				
				await sound_fvox.finished
			
			match tens:
				1:
					if five:
						play_fvox("fifteen")
					else:
						play_fvox("ten")
				2:
					play_fvox("twenty")
				3:
					play_fvox("thirty")
				4:
					play_fvox("fourty")
				5:
					play_fvox("fifty")
				6:
					play_fvox("sixty")
				7:
					play_fvox("seventy")
				8:
					play_fvox("eighty")
				9:
					play_fvox("ninety")
				10:
					play_fvox("power_level_is")
					
					await sound_fvox.finished
					
					play_fvox("onehundred")
			
			if tens != 0:
				await sound_fvox.finished
			
			if five and tens != 1:
				play_fvox("five")
				
				await sound_fvox.finished
			
			play_fvox("percent")

class_name Player
extends CharacterBody3D


const AIR_ACCELERATION = 2.0
const FALL_DAMAGE_THRESHOLD = 15.0
const FALL_DAMAGE_MULTIPLIER = 15.0
const GROUND_ACCELERATION = 20.0
const JUMP_VELOCITY = 6.0
const SUIT_ABSORBTION = 0.8

const ITEM_NOTIFICATION = preload("res://objects/item_notification.tscn")
const FVOX_FILE = "res://sounds/fvox/%s.wav"

@export var subviewport: SubViewport

@export var speed: float

var health: int:
	set(value):
		if health > value:
			%DamageIndicatorLeft.fade()
			%DamageIndicatorRight.fade()
			var absorbed_damage := ceili((health - value) * SUIT_ABSORBTION)
			var new_suit_power := suit_power - absorbed_damage
			suit_power = new_suit_power
			if new_suit_power < 0:
				value += new_suit_power
			value += absorbed_damage
		value = clamp(value, 0, 100)
		if health != value and value == 0:
			if health > value:
				if value < 10:
					play_fvox("beep")
					play_fvox("beep")
					play_fvox("beep")
					play_fvox("near_death")
				elif value < 25:
					play_fvox("beep")
					play_fvox("beep")
					play_fvox("beep")
					play_fvox("health_critical")
					play_fvox("boop")
					play_fvox("boop")
					play_fvox("boop")
					play_fvox("seek_medic")
			play_fvox("flatline", true)
			fvox_queue.clear()
			timer_burn.paused = true
			timer_electrocute.paused = true
			timer_toxic_slime.paused = true
			$DeathOverlay.visible = true
			$Indicators.visible = false
			$ItemNotifications.visible = false
			$WeaponCategories.visible = false
			$Crosshair.visible = false
			$DamageIndicators.visible = false
			weapon_manager.select_weapon(-1, false)
			weapon_manager.set_process(false)
			current_pickup = null
		health = value
		health_label.text = str(health)
		if health < 20:
			$Indicators/Health.modulate = Color(1.0, 0.25, 0.25)
		else:
			$Indicators/Health.modulate = Color.WHITE

var suit_power: int:
	set(value):
		suit_power = clamp(value, 0, 100)
		suit_power_label.text = str(suit_power)

var suit: bool:
	set(value):
		suit = value
		$Indicators.visible = suit
		%WeaponCategories.visible = suit
		%ItemNotifications.visible = suit

var burn: bool:
	set(value):
		burn = value
		if timer_burn.is_stopped():
			_on_timer_burn_timeout()

var electrocute: bool:
	set(value):
		electrocute = value
		if timer_electrocute.is_stopped():
			_on_timer_electrocute_timeout()

var toxic_slime: bool:
	set(value):
		toxic_slime = value
		if timer_toxic_slime.is_stopped():
			_on_timer_toxic_slime_timeout()

var geiger: float:
	set(value):
		geiger = value
		if geiger:
			sound_geiger.play()

var ladder: Array[StaticBody3D]

var current_interactable: Interactable
var current_pickup: Node3D:
	set(value):
		if value == null:
			if current_pickup:
				current_pickup.freeze = false
				current_pickup.collision_layer = 1
		else:
			value.freeze = true
			value.collision_layer = 0
		current_pickup = value

var fvox_queue: Array[String]

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

var look_delta: Vector3
var time: float

@onready var anim_tree := $AnimationTree as AnimationTree
@onready var state_machine = anim_tree["parameters/playback"] as AnimationNodeStateMachinePlayback
@onready var camera := $Camera3D as Camera3D
@onready var floor_raycast := $FloorRayCast3D as RayCast3D
@onready var health_label := %HealthValue as Label
@onready var suit_power_label := %SuitValue as Label
@onready var use_raycast := $Camera3D/UseRayCast3D as RayCast3D
@onready var weapon_manager := $Camera3D/WeaponManager as RayCast3D
@onready var sound_cannot_use := $SoundCannotUse as AudioStreamPlayer
@onready var sound_flashlight := $SoundFlashlight as AudioStreamPlayer
@onready var sound_footstep_concrete := $SoundFootstepConcrete as AudioStreamPlayer
@onready var sound_footstep_metal := $SoundFootstepMetal as AudioStreamPlayer
@onready var sound_footstep_wood := $SoundFootstepWood as AudioStreamPlayer
@onready var sound_grab := $SoundGrab as AudioStreamPlayer
@onready var sound_suit_battery := $SoundSuitBattery as AudioStreamPlayer
@onready var sound_health_kit := $SoundHealthKit as AudioStreamPlayer
@onready var sound_fall_damage := $SoundFallDamage as AudioStreamPlayer
@onready var sound_fvox := $SoundFVOX as AudioStreamPlayer
@onready var sound_geiger := $SoundGeiger as AudioStreamPlayer
@onready var sound_burn := $SoundBurn as AudioStreamPlayer
@onready var sound_electrocute := $SoundElectrocute as AudioStreamPlayer
@onready var sound_ladder := $SoundLadder as AudioStreamPlayer
@onready var timer_footstep := $TimerFootstep as Timer
@onready var timer_burn := $TimerBurn as Timer
@onready var timer_electrocute := $TimerElectrocute as Timer
@onready var timer_toxic_slime := $TimerToxicSlime as Timer
@onready var timer_toxic_slime_fvox := $TimerToxicSlimeFVOX as Timer
@onready var timer_vital_signs_dropping_fvox := $TimerVitalSignsDroppingFVOX as Timer
@onready var timer_minor_fracture_fvox := $TimerMinorFractureFVOX as Timer
@onready var timer_major_fracture_fvox := $TimerMajorFractureFVOX as Timer


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	update_subviewport_size()
	get_viewport().size_changed.connect(update_subviewport_size)

	health = 100
	suit_power = 0
	suit = true


func _process(delta: float) -> void:
	look()
	$SubViewportContainer/SubViewport/Camera3D.global_transform = $Camera3D.global_transform
	weapon_manager.position = weapon_manager.position.lerp(look_delta / 6, delta * 6)

	if health == 0:
		get_tree().create_timer(1.0).timeout.connect(func():
			if Input.is_anything_pressed():
				get_tree().reload_current_scene()
		)

	if current_pickup:
		current_pickup.position = %PickupPoint.global_transform.origin


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var input = event.relative
		if mouse_look_inverted_x:
			input.x *= -1
		if mouse_look_inverted_y:
			input.y *= -1

		look_delta = Vector3(-input.x, 0, -input.y) * mouse_look_sensitivity / 1000

		rotate_y(look_delta.x)
		camera.rotate_x(look_delta.z)


func _physics_process(delta: float)  -> void:
	move(delta)

	if health > 0:
		interact()
		flashlight()


func flashlight() -> void:
	if Input.is_action_just_pressed("flashlight") and suit:
		%Flashlight.visible = !%Flashlight.visible
		sound_flashlight.play()


func flash_white() -> void:
	var tween := get_tree().create_tween()
	tween.tween_property(%ColorFade, "color", Color.WHITE, 0.05)
	tween.tween_property(%ColorFade, "color", Color.TRANSPARENT, 0.1)


func set_footstep_volume(volume_db: int) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Footstep"), volume_db)


func interact() -> void:
	var node := use_raycast.get_collider() as Node3D

	if current_pickup and Input.is_action_just_pressed("use"):
		current_pickup = null
		return

	if Input.is_action_just_released("use") or node != current_interactable:
		if current_interactable:
			current_interactable.stop_interact()
			current_interactable = null

	if use_raycast.is_colliding():
		if Input.is_action_just_pressed("use"):
			if node.is_in_group("Pickup"):
				sound_grab.play()
				current_pickup = node
			elif not node is Interactable:
				sound_cannot_use.play()

		if node is Interactable and Input.is_action_pressed("use"):
			node.interact(self)
			current_interactable = node
	elif Input.is_action_just_pressed("use"):
		sound_cannot_use.play()


func look() -> void:
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

	if abs(joypad_look.x) > 0:
		look_delta.x = -joypad_look.x
	if abs(joypad_look.y) > 0:
		look_delta.z = -joypad_look.y

	rotate_y(-joypad_look.x)
	camera.rotate_x(-joypad_look.y)

	# Clamp vertical camera rotation for both mouse and joypad
	camera.rotation.x = clamp(camera.rotation.x, -PI / 2, PI / 2)


func move(delta: float) -> void:
	# Gravity and jumping
	if is_on_floor():
		var horizontal_velocity := Vector2(velocity.x, velocity.z)
		if fall_velocity < -1 or horizontal_velocity.length_squared() >= 1:
			if timer_footstep.is_stopped():
				play_footstep()

		if fall_velocity < -FALL_DAMAGE_THRESHOLD:
			sound_fall_damage.play()
			var fall_damage := int((fall_velocity + FALL_DAMAGE_THRESHOLD) * FALL_DAMAGE_MULTIPLIER)
			if fall_damage < -25 and timer_major_fracture_fvox.is_stopped():
				timer_major_fracture_fvox.start()
				play_fvox("boop")
				play_fvox("boop")
				play_fvox("boop")
				play_fvox("major_fracture")
				play_fvox("boop")
				play_fvox("boop")
				play_fvox("boop")
				play_fvox("automedic_on")
				play_fvox("boop")
				play_fvox("boop")
				play_fvox("boop")
				play_fvox("hiss")
				play_fvox("morphine_shot")
			elif timer_minor_fracture_fvox.is_stopped():
				timer_minor_fracture_fvox.start()
				play_fvox("boop")
				play_fvox("boop")
				play_fvox("boop")
				play_fvox("minor_fracture")
			health += fall_damage
		fall_velocity = 0
		acceleration = GROUND_ACCELERATION
		if Input.is_action_just_pressed("jump") and health > 0:
			velocity.y = JUMP_VELOCITY
			play_footstep()
	elif ladder.is_empty():
		velocity.y -= gravity * delta
		fall_velocity = velocity.y
		acceleration = AIR_ACCELERATION

	# Crouching and sprinting
	if Input.is_action_pressed("crouch") or health == 0:
		state_machine.travel("Crouch")
	elif not test_move(transform, Vector3.UP):
		if Input.is_action_pressed("sprint") and suit:
			state_machine.travel("Sprint")
		else:
			state_machine.travel("RESET")

	# Get input and move with acceleration/deceleration
	var move_input := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if health == 0:
		move_input = Vector2.ZERO

	# View Bob
	var view_movement := Vector3.ZERO
	var unrotated_velocity := velocity.rotated(Vector3.UP, -rotation.y)
	view_movement.x = -unrotated_velocity.x * sin(time * 6) * 0.001
	view_movement.z = -unrotated_velocity.z * sin(time * 8) * 0.001
	view_movement *= speed / 2
	if move_input.length_squared() > 0:
		time += delta
	else:
		time = 0
	weapon_manager.position = weapon_manager.position.lerp(view_movement, delta * 8)

	move_input = move_input.rotated(-rotation.y)

	if not ladder.is_empty():
		# Ladder Climbing
		velocity = Vector3.ZERO
		movement = Vector2.ZERO
		state_machine.travel("RESET")

		var ladder_move_angle := ladder[0].global_transform.basis.z.angle_to(Vector3(move_input.x, 0, move_input.y))
		if ladder_move_angle > PI / 2:
			climb_ladder(200 * delta)
		elif ladder_move_angle == 0 and move_input.y <= 0:
			velocity.y = 0
		else:
			climb_ladder(-200 * delta)
	else:
		# Standard Movement
		movement = movement.lerp(move_input * speed, acceleration * delta)
		velocity.x = movement.x
		velocity.z = movement.y
	move_and_slide()


func play_footstep() -> void:
	var node := floor_raycast.get_collider() as Node3D
	if node:
		timer_footstep.start()
		if node.is_in_group("MetalMaterial"):
			sound_footstep_metal.play()
		elif node.is_in_group("WoodMaterial"):
			sound_footstep_wood.play()
		else:
			sound_footstep_concrete.play()


func climb_ladder(climb_speed: float) -> void:
	velocity.y = climb_speed

	if climb_speed < 0 and floor_raycast.is_colliding():
		ladder.clear()

	if timer_footstep.is_stopped():
		timer_footstep.start()
		sound_ladder.play()


func play_fvox(sound_name: String, immediate := false) -> void:
	if immediate:
		sound_fvox.stream = load(FVOX_FILE % sound_name)
		sound_fvox.play()
	else:
		fvox_queue.append(sound_name)

		if not sound_fvox.stream:
			_on_sound_fvox_finished()


func update_subviewport_size():
	subviewport.size = get_viewport().size


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Ladder"):
		ladder.append(body)

	if body.is_in_group("HEVSuit") and not suit:
		body.queue_free()
		suit = true
		play_fvox("bell")
		play_fvox("hev_logon")
		return

	if body.is_in_group("HealthKit"):
		if health < 100:
			health += 15
			body.queue_free()
			sound_health_kit.play()
			var notification_instance = ITEM_NOTIFICATION.instantiate()
			%ItemNotifications.add_child(notification_instance)
	elif body.is_in_group("SuitBattery") and suit:
		if suit_power < 100:
			suit_power += 15
			body.queue_free()
			sound_suit_battery.play()
			var notification_instance = ITEM_NOTIFICATION.instantiate()
			%ItemNotifications.add_child(notification_instance)
			notification_instance.text = "*"

			play_fvox("fuzz")
			play_fvox("fuzz")
			play_fvox("_comma")

			var snap := snappedf(suit_power, 5)
			var five := fmod(snap, 10)
			var tens := int(snap / 10)

			if tens != 10:
				play_fvox("power")

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
					play_fvox("onehundred")

			if five and tens != 1:
				play_fvox("five")

			play_fvox("percent")


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("Ladder"):
		ladder.erase(body)


func _on_sound_fvox_finished() -> void:
	if fvox_queue.size() > 0:
		sound_fvox.stream = load(FVOX_FILE % fvox_queue.pop_front())
		sound_fvox.play()
	else:
		sound_fvox.stream = null


func _on_sound_geiger_finished() -> void:
	if geiger > 0:
		await get_tree().create_timer(1 - geiger).timeout
		sound_geiger.play()


func _on_timer_burn_timeout() -> void:
	if burn:
		health -= 10
		sound_burn.play()
		timer_burn.start()


func _on_timer_electrocute_timeout() -> void:
	if electrocute:
		health -= 10
		sound_electrocute.play()
		timer_electrocute.start()


func _on_timer_toxic_slime_timeout() -> void:
	if toxic_slime:
		timer_toxic_slime.start()
		flash_white()

		if timer_toxic_slime_fvox.is_stopped():
			timer_toxic_slime_fvox.start()
			play_fvox("blip")
			play_fvox("blip")
			play_fvox("blip")
			play_fvox("radiation_detected")

		if timer_vital_signs_dropping_fvox.is_stopped():
			timer_vital_signs_dropping_fvox.start()
			play_fvox("beep")
			play_fvox("beep")
			play_fvox("health_dropping2")

		health -= 10

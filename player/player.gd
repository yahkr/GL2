extends CharacterBody3D


@onready var camera = $Camera3D
@onready var crosshair = $Crosshair
@onready var options = $Options

const AIR_ACCELERATION = 2.0
const GROUND_ACCELERATION = 20.0

const CROUCH_SPEED = 2.5
const SPRINT_SPEED = 10.0
const WALK_SPEED = 5.0

const JUMP_VELOCITY = 6.0

var acceleration: float
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var joypad_look: Vector2
var movement: Vector2
var speed: float

var JOYPAD_LOOK_CURVE = 2.0
var JOYPAD_LOOK_INVERTED_X = false
var JOYPAD_LOOK_INVERTED_Y = false
var JOYPAD_LOOK_OUTER_THRESHOLD = 0.02
var joypad_look_sensitivity_x
var joypad_look_sensitivity_y

var MOUSE_LOOK_INVERTED_X = false
var MOUSE_LOOK_INVERTED_Y = false
var mouse_look_sensitivity


func apply_options(_section: String, key: String, value: Variant):
	match key:
		"mouse_sensitivity":
			mouse_look_sensitivity = value
		"controller_sensitivity_x":
			joypad_look_sensitivity_x = value
		"controller_sensitivity_y":
			joypad_look_sensitivity_y = value
		"fov":
			camera.fov = value


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	return
	if event is InputEventMouseMotion:
		var input = event.relative
		if MOUSE_LOOK_INVERTED_X:
			input.x *= -1
		if MOUSE_LOOK_INVERTED_Y:
			input.y *= -1
		
		rotate_y(-input.x * mouse_look_sensitivity)
		camera.rotate_x(-input.y * mouse_look_sensitivity)


func _physics_process(delta):
	return
	# Joypad look
	if Input.get_connected_joypads().size() > 0:
		var input = Input.get_vector("look_left", "look_right", "look_up", "look_down")
		
		if JOYPAD_LOOK_INVERTED_X:
			input.x *= -1
		if JOYPAD_LOOK_INVERTED_Y:
			input.y *= -1
		
		joypad_look.x = pow(abs(input.x), JOYPAD_LOOK_CURVE) * joypad_look_sensitivity_x
		if input.x < 0:
			joypad_look.x *= -1
		if abs(input.x) >= 1 - JOYPAD_LOOK_OUTER_THRESHOLD:
			input.x = round(input.x)
		joypad_look.y = pow(abs(input.y), JOYPAD_LOOK_CURVE) * joypad_look_sensitivity_y
		if input.y < 0:
			joypad_look.y *= -1
		if abs(input.y) >= 1 - JOYPAD_LOOK_OUTER_THRESHOLD:
			input.y = round(input.y)
		
		rotate_y(-joypad_look.x)
		camera.rotate_x(-joypad_look.y)
	
	# Clamp vertical camera rotation for both mouse and joypad
	camera.rotation.x = clamp(camera.rotation.x, -PI / 2, PI / 2)
	
	# Gravity and jumping
	if is_on_floor():
		acceleration = GROUND_ACCELERATION
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
	else:
		velocity.y -= gravity * delta
		acceleration = AIR_ACCELERATION
	
	# Crouching and sprinting
	if Input.is_action_pressed("crouch"):
		speed = CROUCH_SPEED
	elif Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
	
	# Get input and move with acceleration/deceleration
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	input = input.rotated(-rotation.y)
	movement = movement.lerp(input * speed, acceleration * delta)
	velocity.x = movement.x
	velocity.z = movement.y
	move_and_slide()

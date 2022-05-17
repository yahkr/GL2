extends CharacterBody3D


@onready var camera = $Camera3D
@onready var crosshair = $Crosshair
@onready var options_menu = $OptionsMenu

const AIR_ACCELERATION = 2.0
const GROUND_ACCELERATION = 20.0

const CROUCH_SPEED = 2.5
const SPRINT_SPEED = 10.0
const WALK_SPEED = 5.0

const JUMP_VELOCITY = 6.0

var acceleration: float
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var joypad_look: Vector2
var movement: Vector2
var speed: float

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


func _input(event):
	if event is InputEventMouseMotion:
		var input = event.relative
		if mouse_look_inverted_x:
			input.x *= -1
		if mouse_look_inverted_y:
			input.y *= -1
		
		rotate_y(-input.x * mouse_look_sensitivity / 100)
		camera.rotate_x(-input.y * mouse_look_sensitivity / 100)


func _physics_process(delta):
	# Joypad look
	var look_input = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	
	if joypad_look_inverted_x:
		look_input.x *= -1
	if joypad_look_inverted_y:
		look_input.y *= -1
	
	if abs(look_input.x) > 1 - joypad_look_outer_threshold:
		look_input.x = round(look_input.x)
	joypad_look.x = pow(abs(look_input.x), joypad_look_curve) * joypad_look_sensitivity_x / 10
	if look_input.x < 0:
		joypad_look.x *= -1
	
	if abs(look_input.y) > 1 - joypad_look_outer_threshold:
		look_input.y = round(look_input.y)
	joypad_look.y = pow(abs(look_input.y), joypad_look_curve) * joypad_look_sensitivity_y / 10
	if look_input.y < 0:
		joypad_look.y *= -1
	
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
	var move_input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	move_input = move_input.rotated(-rotation.y)
	movement = movement.lerp(move_input * speed, acceleration * delta)
	velocity.x = movement.x
	velocity.z = movement.y
	move_and_slide()

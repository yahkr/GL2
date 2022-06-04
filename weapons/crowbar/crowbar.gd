extends Weapon


@onready var sound_swing := $SoundSwing as AudioStreamPlayer


func _ready():
	super()


func _process(_delta):
	if visible and Input.is_action_just_pressed("primary_attack") and cooldown.is_stopped():
		cooldown.start()
		sound_swing.play()
		hit()

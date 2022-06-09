extends Interactable


enum ChargerType {HEALTH, SUIT}

@export var type: ChargerType
@export var max_charges := 75

@onready var animation_player := $Model/AnimationPlayer as AnimationPlayer
@onready var charges := max_charges
@onready var sound_shot := $SoundShot as AudioStreamPlayer
@onready var sound_charge := $SoundCharge as AudioStreamPlayer
@onready var sound_deny := $SoundDeny as AudioStreamPlayer
@onready var timer_charge := $TimerCharge as Timer
@onready var timer_sound := $TimerSound as Timer


func _ready():
	animation_player.play("idle", -1, 0)


func can_charge(player) -> bool:
	if charges > 0:
		if type == ChargerType.HEALTH and player.health < 100:
			return true
		if type == ChargerType.SUIT and player.suit_power < 100:
			return true
	return false


func charge(player):
	if type == ChargerType.HEALTH:
		player.health += 1
	elif type == ChargerType.SUIT:
		player.suit_power += 1
	charges -= 1
	if charges == 0:
		animation_player.play("emptyclick")
	else:
		var progress := 1 - charges / float(max_charges)
		var tween := get_tree().create_tween()
		tween.tween_method(animation_player.seek,
				animation_player.current_animation_position,
				progress * animation_player.current_animation_length,
				timer_charge.wait_time)


func interact(player):
	if can_charge(player):
		if timer_charge.is_stopped():
			charge(player)
			timer_charge.connect("timeout", charge.bind(player))
			timer_charge.start()
			timer_charge.one_shot = false
			sound_shot.play()
			timer_sound.start()
	else:
		stop_interact()
		if timer_charge.is_stopped() and not sound_deny.playing:
			sound_deny.play()


func stop_interact():
	if timer_charge.is_connected("timeout", charge):
		timer_charge.disconnect("timeout", charge)
		timer_charge.one_shot = true
		timer_sound.stop()
		sound_charge.stop()


func _on_timer_sound_timeout():
	sound_charge.play()

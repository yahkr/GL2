extends GPUParticles3D


@export var shapecast: ShapeCast3D


func _ready() -> void:
	emitting = true


func _physics_process(_delta: float) -> void:
	for index in shapecast.get_collision_count():
		var player := shapecast.get_collider(index) as Player
		if player:
			var dist := shapecast.get_collision_point(index).distance_squared_to(global_position)
			player.health -= int(exp((36 - dist) * 0.14))
	shapecast.collide_with_bodies = false
	await get_tree().create_timer(lifetime).timeout
	queue_free()

extends StaticBody3D
class_name Door

@export var open_speed: float = 3.0
@export var open_distance: float = 5.0
@export var open_direction: Vector3 = Vector3.UP

var is_opening: bool = false
var is_open: bool = false
var original_position: Vector3 = Vector3.ZERO
var target_position: Vector3 = Vector3.ZERO

@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	original_position = position
	target_position = original_position + open_direction.normalized() * open_distance

func _process(delta: float) -> void:
	if is_opening and not is_open:
		position = position.move_toward(target_position, open_speed * delta)
		if position.distance_to(target_position) < 0.01:
			is_open = true
			is_opening = false
			if collision_shape != null:
				collision_shape.disabled = true

func open_door() -> void:
	if is_opening or is_open:
		return
	is_opening = true

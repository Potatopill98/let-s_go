extends Area3D
class_name Bullet

# Bullet properties
@export var speed: float = 80.0
@export var damage: float = 25.0
@export var lifetime: float = 2.0
@export var max_distance: float = 50.0

var velocity: Vector3 = Vector3.ZERO
var traveled_distance: float = 0.0
var start_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	add_to_group("bullet")
	start_position = global_position
	body_entered.connect(_on_body_entered)

func setup(direction: Vector3, pos: Vector3) -> void:
	global_position = pos
	velocity = direction.normalized() * speed
	start_position = pos

func _physics_process(delta: float) -> void:
	var move_amount: Vector3 = velocity * delta
	global_position += move_amount
	traveled_distance += move_amount.length()
	lifetime -= delta
	# Auto destroy after lifetime or max distance
	if traveled_distance >= max_distance or lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("monster"):
		if body.has_method("take_damage"):
			var knockback_dir: Vector3 = velocity.normalized()
			knockback_dir.y = 0.0
			body.take_damage(damage, knockback_dir * 5.0)
	queue_free()

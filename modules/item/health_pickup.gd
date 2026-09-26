extends Area3D
class_name HealthPickup

# ============================================================
# Health Pickup - touch to heal, does not occupy hand
# Independent from holdable item system
# ============================================================

@export var heal_amount: float = 30.0
@export var respawn_time: float = 0.0  # 0 = one-time use, >0 = respawn after seconds
@export var bob_speed: float = 2.0
@export var bob_height: float = 0.15

var base_y: float = 0.0
var is_available: bool = true
var respawn_timer: float = 0.0
var mesh_ref: MeshInstance3D = null
var light_ref: OmniLight3D = null

func _ready() -> void:
	add_to_group("health_pickup")
	body_entered.connect(_on_body_entered)
	mesh_ref = get_node("MeshInstance3D") as MeshInstance3D
	light_ref = get_node("OmniLight3D") as OmniLight3D
	base_y = position.y

func _process(delta: float) -> void:
	if is_available:
		# Floating animation
		if mesh_ref != null:
			mesh_ref.position.y = base_y + sin(Time.get_ticks_msec() / 1000.0 * bob_speed) * bob_height
			mesh_ref.rotation.y += delta * 1.5
	else:
		# Respawn timer
		if respawn_time > 0:
			respawn_timer -= delta
			if respawn_timer <= 0:
				_respawn()

func _on_body_entered(body: Node3D) -> void:
	if not is_available:
		return
	if body.is_in_group("player"):
		if body.has_method("take_damage") and "current_health" in body and "max_health" in body:
			var player: Node = body
			if player.current_health < player.max_health:
				player.current_health = min(player.max_health, player.current_health + heal_amount)
				UIManager.show_message("+%d 生命值" % int(heal_amount))
				_pickup_effect()
				_consume()

func _pickup_effect() -> void:
	# Flash effect - could add particles later
	pass

func _consume() -> void:
	is_available = false
	if mesh_ref != null:
		mesh_ref.visible = false
	if light_ref != null:
		light_ref.visible = false
	if respawn_time > 0:
		respawn_timer = respawn_time
	else:
		# One-time use, remove after a short delay for effect
		queue_free()

func _respawn() -> void:
	is_available = true
	if mesh_ref != null:
		mesh_ref.visible = true
	if light_ref != null:
		light_ref.visible = true

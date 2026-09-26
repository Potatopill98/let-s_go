extends RigidBody3D
class_name Throwable
## 投掷物基类
## 所有投掷物的基础逻辑：抛出、飞行、碰撞、效果

@export var throw_item_id: String = "throw_brick"
@export var damage: float = 5.0
@export var explosion_radius: float = 0.0
@export var explosion_damage: float = 0.0
@export var burn_duration: float = 0.0
@export var stun_duration: float = 0.0
@export var smoke_duration: float = 0.0
@export var attract_monsters: bool = false
@export var attract_duration: float = 0.0
@export var destroy_on_impact: bool = true

var thrower: Node = null
var has_impacted: bool = false
var lifetime: float = 10.0

func _ready() -> void:
	add_to_group("throwable")
	body_entered.connect(_on_body_entered)
	# 5秒后自动消失
	var timer: Timer = Timer.new()
	timer.wait_time = lifetime
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

func throw_from(position: Vector3, direction: Vector3, force: float = 15.0) -> void:
	global_position = position
	linear_velocity = direction * force
	angular_velocity = Vector3(randf_range(-5, 5), randf_range(-5, 5), randf_range(-5, 5))

func _on_body_entered(body: Node) -> void:
	if has_impacted:
		return
	if body == thrower:
		return
	has_impacted = true
	_apply_impact_effect(body)
	if destroy_on_impact:
		# 延迟一帧销毁，避免物理回调中销毁
		call_deferred("queue_free")

func _apply_impact_effect(body: Node) -> void:
	# 直接伤害
	if damage > 0 and body.has_method("take_damage"):
		body.take_damage(damage, -global_transform.basis.z * 5.0)
	# 范围爆炸
	if explosion_radius > 0 and explosion_damage > 0:
		_explode()
	# 吸引怪物
	if attract_monsters and attract_duration > 0:
		_attract_monsters()

func _explode() -> void:
	# 范围伤害
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = explosion_radius
	query.shape = sphere
	query.transform = Transform3D(Basis(), global_position)
	var results: Array = space_state.intersect_shape(query)
	for result in results:
		var collider: Node = result.collider
		if collider != null and collider.has_method("take_damage"):
			var dist: float = collider.global_position.distance_to(global_position)
			var falloff: float = 1.0 - (dist / explosion_radius)
			collider.take_damage(explosion_damage * falloff, (collider.global_position - global_position).normalized() * 10.0)
	# 爆炸粒子（简化：用点光源模拟）
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = Color(1, 0.5, 0.2)
	light.light_energy = 5.0
	light.omni_range = explosion_radius * 2
	add_child(light)
	var t: Timer = Timer.new()
	t.wait_time = 0.1
	t.timeout.connect(light.queue_free)
	add_child(t)
	t.start()

func _attract_monsters() -> void:
	var monsters: Array = get_tree().get_nodes_in_group("monster")
	for m in monsters:
		if m.has_method("set_target_position"):
			m.set_target_position(global_position)
	# 持续吸引
	var timer: Timer = Timer.new()
	timer.wait_time = 0.5
	timer.timeout.connect(func(): 
		for m in get_tree().get_nodes_in_group("monster"):
			if m.has_method("set_target_position"):
				m.set_target_position(global_position)
	)
	add_child(timer)
	timer.start()
	# attract_duration后停止
	var stop_timer: Timer = Timer.new()
	stop_timer.wait_time = attract_duration
	stop_timer.timeout.connect(timer.queue_free)
	add_child(stop_timer)
	stop_timer.start()

extends Node3D
class_name Placeable
## 放置物基类
## 所有放置物的基础逻辑：放置、持续时间、效果

@export var place_item_id: String = "place_glow_stick"
@export var duration: float = 60.0
@export var is_turret: bool = false
@export var turret_damage: float = 10.0
@export var turret_range: float = 15.0
@export var turret_fire_rate: float = 0.3
@export var is_trap: bool = false
@export var trap_damage: float = 20.0
@export var trap_stun_duration: float = 3.0
@export var is_light: bool = false
@export var light_range: float = 10.0
@export var light_color: Color = Color(0.5, 1.0, 0.5)
@export var is_barricade: bool = false
@export var barricade_health: float = 100.0

var life_timer: float = 0.0
var turret_timer: float = 0.0
var current_health: float = 100.0
var light_node: OmniLight3D = null

func _ready() -> void:
	add_to_group("placeable")
	current_health = barricade_health
	if is_light:
		_create_light()
	if is_turret:
		_create_turret_visual()
	if is_barricade:
		_create_barricade_collision()
	# 生命周期计时器
	var timer: Timer = Timer.new()
	timer.wait_time = duration
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

func _process(delta: float) -> void:
	life_timer += delta
	if is_turret:
		turret_timer -= delta
		if turret_timer <= 0:
			turret_timer = turret_fire_rate
			_turret_attack()

func _create_light() -> void:
	light_node = OmniLight3D.new()
	light_node.light_color = light_color
	light_node.light_energy = 2.0
	light_node.omni_range = light_range
	add_child(light_node)

func _create_turret_visual() -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(0.5, 0.5, 0.5)
	mesh.mesh = box
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.2, 0.2)
	mesh.material_override = mat
	add_child(mesh)
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(0.5, 0.5, 0.5)
	col.shape = shape
	add_child(col)

func _create_barricade_collision() -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(2.0, 1.5, 0.3)
	mesh.mesh = box
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.5, 0.3)
	mesh.material_override = mat
	add_child(mesh)
	var body: StaticBody3D = StaticBody3D.new()
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(2.0, 1.5, 0.3)
	col.shape = shape
	body.add_child(col)
	add_child(body)

func _turret_attack() -> void:
	# 找最近的怪物
	var nearest_monster: Node = null
	var nearest_dist: float = turret_range
	var monsters: Array = get_tree().get_nodes_in_group("monster")
	for m in monsters:
		if m == null or not is_instance_valid(m):
			continue
		var dist: float = global_position.distance_to(m.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_monster = m
	if nearest_monster == null:
		return
	# 攻击
	if nearest_monster.has_method("take_damage"):
		nearest_monster.take_damage(turret_damage, Vector3.ZERO)
	# 枪口闪光
	var flash: OmniLight3D = OmniLight3D.new()
	flash.light_color = Color(1, 0.8, 0.3)
	flash.light_energy = 3.0
	flash.omni_range = 3.0
	add_child(flash)
	var t: Timer = Timer.new()
	t.wait_time = 0.05
	t.timeout.connect(flash.queue_free)
	add_child(t)
	t.start()

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO) -> void:
	if not is_barricade:
		return
	current_health -= amount
	if current_health <= 0:
		queue_free()

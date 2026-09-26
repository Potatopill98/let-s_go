extends StaticBody3D
class_name Destructible
## 可破坏物体基类
## 玻璃墙、木箱、爆炸桶等可破坏物体

@export var destructible_id: String = "dest_wooden_crate"
@export var max_health: float = 20.0
@export var is_explosive: bool = false
@export var explosion_radius: float = 3.0
@export var explosion_damage: float = 50.0
@export var drop_loot: bool = false
@export var loot_table: Array = []
@export var spawn_monster_on_break: bool = false
@export var monster_scene_path: String = ""
@export var break_color: Color = Color(0.6, 0.4, 0.2)

var current_health: float = 20.0
var is_broken: bool = false
var mesh_instance: MeshInstance3D = null
var collision_shape: CollisionShape3D = null

func _ready() -> void:
	current_health = max_health
	add_to_group("destructible")
	mesh_instance = get_node_or_null("Mesh") as MeshInstance3D
	collision_shape = get_node_or_null("Collision") as CollisionShape3D

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO) -> void:
	if is_broken:
		return
	current_health -= amount
	# 受击闪白
	if mesh_instance != null:
		var mat: StandardMaterial3D = mesh_instance.material_override as StandardMaterial3D
		if mat != null:
			mat.emission_enabled = true
			mat.emission = Color.WHITE
			mat.emission_energy_multiplier = 2.0
			var t: Timer = Timer.new()
			t.wait_time = 0.1
			t.timeout.connect(func(): 
				if mat != null and is_instance_valid(mat):
					mat.emission_energy_multiplier = 0.0
			)
			add_child(t)
			t.start()
	if current_health <= 0:
		break_object()

func break_object() -> void:
	if is_broken:
		return
	is_broken = true
	# 隐藏网格和碰撞
	if mesh_instance != null:
		mesh_instance.visible = false
	if collision_shape != null:
		collision_shape.disabled = true
	# 爆炸效果
	if is_explosive:
		_explode()
	# 掉落物
	if drop_loot:
		_drop_loot()
	# 释放怪物
	if spawn_monster_on_break and monster_scene_path != "":
		_spawn_monster()
	# 碎片粒子（简化：用几个小方块）
	_spawn_debris()
	# 延迟销毁
	var t: Timer = Timer.new()
	t.wait_time = 0.5
	t.timeout.connect(queue_free)
	add_child(t)
	t.start()

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
	# 爆炸光效
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = Color(1, 0.5, 0.2)
	light.light_energy = 8.0
	light.omni_range = explosion_radius * 3
	add_child(light)
	var t: Timer = Timer.new()
	t.wait_time = 0.15
	t.timeout.connect(light.queue_free)
	add_child(t)
	t.start()

func _drop_loot() -> void:
	if loot_table.is_empty():
		return
	# 随机掉落1-2个物品
	var drop_count: int = randi_range(1, 2)
	for i in range(drop_count):
		var item_id: String = loot_table[randi() % loot_table.size()]
		# 生成拾取物（简化：用ItemManager生成）
		var pickup_scene: PackedScene = load("res://modules/item/item_pickup.tscn")
		if pickup_scene != null:
			var pickup: Node = pickup_scene.instantiate()
			get_tree().current_scene.add_child(pickup)
			pickup.global_position = global_position + Vector3(randf_range(-1, 1), 0.5, randf_range(-1, 1))

func _spawn_monster() -> void:
	var monster_scene: PackedScene = load(monster_scene_path)
	if monster_scene != null:
		var monster: Node = monster_scene.instantiate()
		get_tree().current_scene.add_child(monster)
		monster.global_position = global_position + Vector3.UP

func _spawn_debris() -> void:
	for i in range(6):
		var debris: MeshInstance3D = MeshInstance3D.new()
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(0.15, 0.15, 0.15)
		debris.mesh = box
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = break_color
		debris.material_override = mat
		get_tree().current_scene.add_child(debris)
		debris.global_position = global_position + Vector3(randf_range(-0.5, 0.5), randf_range(0, 1), randf_range(-0.5, 0.5))
		# 简单飞散效果
		var body: RigidBody3D = RigidBody3D.new()
		var col: CollisionShape3D = CollisionShape3D.new()
		var shape: BoxShape3D = BoxShape3D.new()
		shape.size = Vector3(0.15, 0.15, 0.15)
		col.shape = shape
		body.add_child(col)
		body.add_child(debris)
		debris.position = Vector3.ZERO
		get_tree().current_scene.add_child(body)
		body.global_position = debris.global_position
		body.linear_velocity = Vector3(randf_range(-3, 3), randf_range(3, 6), randf_range(-3, 3))
		# 5秒后销毁
		var t: Timer = Timer.new()
		t.wait_time = 5.0
		t.timeout.connect(body.queue_free)
		body.add_child(t)
		t.start()

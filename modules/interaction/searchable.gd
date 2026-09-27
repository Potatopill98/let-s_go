extends StaticBody3D
class_name Searchable
## 可搜索物体基类
## 尸体、柜子、抽屉等，按E搜索获得物品

@export var searchable_id: String = "searchable_corpse"
@export var searchable_name: String = "研究员尸体"
@export var search_prompt: String = "按E搜索"
@export var search_time: float = 1.5  # 搜索耗时
@export var loot_table: Array = []  # 可掉落的物品ID列表
@export var guaranteed_loot: String = ""  # 必定掉落的物品ID
@export var search_color: Color = Color(0.9, 0.9, 0.9, 1)
@export var model_type: String = "corpse"  # corpse, cabinet, drawer, locker

var is_searched: bool = false
var is_being_searched: bool = false
var search_progress: float = 0.0
var mesh_instance: MeshInstance3D = null
var interaction_area: Area3D = null
var player_inside: Node = null

func _ready() -> void:
	add_to_group("searchable")
	_build_visual()
	_build_interaction_area()

func _process(delta: float) -> void:
	# 检测E键开始搜索
	if player_inside != null and not is_searched and not is_being_searched:
		if Input.is_action_pressed("interact") or Input.is_key_pressed(KEY_E):
			start_search()
	if is_being_searched and player_inside != null:
		search_progress += delta / search_time
		if search_progress >= 1.0:
			_finish_search()
		# 更新UI进度
		if UIManager != null:
			UIManager.update_progress(search_progress * 100, 100)
	else:
		search_progress = 0.0

func _build_visual() -> void:
	mesh_instance = MeshInstance3D.new()
	if model_type == "corpse":
		# 研究员尸体：白色衣服，躺着
		var body: CapsuleMesh = CapsuleMesh.new()
		body.radius = 0.3
		body.height = 1.6
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = search_color
		mesh_instance.mesh = body
		mesh_instance.material_override = mat
		mesh_instance.rotation.x = PI / 2  # 躺着
		mesh_instance.position.y = 0.3
	elif model_type == "cabinet":
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(1.0, 2.0, 0.5)
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = search_color
		mesh_instance.mesh = box
		mesh_instance.material_override = mat
		mesh_instance.position.y = 1.0
	elif model_type == "drawer":
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(0.8, 0.4, 0.4)
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = search_color
		mesh_instance.mesh = box
		mesh_instance.material_override = mat
		mesh_instance.position.y = 0.5
	add_child(mesh_instance)
	# 碰撞
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(1.0, 1.0, 1.0)
	col.shape = shape
	col.position.y = 0.5
	add_child(col)

func _build_interaction_area() -> void:
	interaction_area = Area3D.new()
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: SphereShape3D = SphereShape3D.new()
	shape.radius = 2.0
	col.shape = shape
	col.position.y = 1.0
	interaction_area.add_child(col)
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	add_child(interaction_area)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not is_searched:
		player_inside = body
		if UIManager != null:
			UIManager.show_interaction_prompt(search_prompt)

func _on_body_exited(body: Node) -> void:
	if body == player_inside:
		player_inside = null
		is_being_searched = false
		search_progress = 0.0
		if UIManager != null:
			UIManager.hide_interaction_prompt()
			UIManager.hide_progress()

func start_search() -> void:
	if is_searched or player_inside == null:
		return
	is_being_searched = true

func cancel_search() -> void:
	is_being_searched = false
	search_progress = 0.0

func _finish_search() -> void:
	# 防止立刻重新触发
	if Input.is_key_pressed(KEY_E):
		pass
	is_searched = true
	is_being_searched = false
	search_progress = 1.0
	# 掉落物品
	_drop_loot()
	# 视觉反馈：变灰
	if mesh_instance != null:
		var mat: StandardMaterial3D = mesh_instance.material_override as StandardMaterial3D
		if mat != null:
			mat.albedo_color = Color(0.4, 0.4, 0.4, 1)
	# UI
	if UIManager != null:
		UIManager.hide_progress()
		UIManager.hide_interaction_prompt()
		UIManager.show_toast("搜索完成")

func _drop_loot() -> void:
	# 必定掉落
	if guaranteed_loot != "":
		_spawn_item(guaranteed_loot)
	# 随机掉落1-2个
	if loot_table.size() > 0:
		var drop_count: int = randi_range(1, 2)
		for i in range(drop_count):
			var item_id: String = loot_table[randi() % loot_table.size()]
			_spawn_item(item_id)

func _spawn_item(item_id: String) -> void:
	var data: Dictionary = {}
	if ItemManager != null:
		data = ItemManager.get_item_data(item_id)
	# 根据物品类型生成不同的拾取物
	var item_type: String = data.get("item_type", "")
	var pickup_scene: PackedScene = null
	if item_type == "held_tool" or item_type == "melee_weapon" or item_type == "ranged_weapon":
		pickup_scene = load("res://modules/item/item_pickup.tscn")
	elif item_type == "instant_consumable":
		pickup_scene = load("res://modules/item/health_pickup.tscn")
	else:
		# 背包物品直接进背包
		if player_inside != null and player_inside.has_method("pickup_inventory_item"):
			player_inside.pickup_inventory_item(item_id)
		return
	if pickup_scene != null:
		var pickup: Node = pickup_scene.instantiate()
		get_tree().current_scene.add_child(pickup)
		pickup.global_position = global_position + Vector3(randf_range(-0.5, 0.5), 0.5, randf_range(-0.5, 0.5))
		# 设置物品ID
		if pickup.has_method("set_item_id"):
			pickup.set_item_id(item_id)

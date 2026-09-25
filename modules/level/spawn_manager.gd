extends Node3D
class_name SpawnManager

@export var monster_scene: PackedScene = null
@export var spawn_point_paths: Array[NodePath] = []
var spawn_points: Array[Node3D] = []
@export var base_spawn_interval: float = 5.0
@export var min_spawn_interval: float = 1.0
@export var max_monsters: int = 30
@export var repair_progress_ref: Node = null # 引用修理任务，用来获取进度
@export var stop_on_repair_complete: bool = true # 修理完成后是否停止刷怪

var spawn_timer: float = 0.0
var current_spawn_interval: float = 5.0
var spawned_monsters: int = 0

func _ready() -> void:
	current_spawn_interval = base_spawn_interval
	spawn_timer = current_spawn_interval
	# 解析刷怪点路径
	for path in spawn_point_paths:
		var point: Node3D = get_node(path) as Node3D
		if point != null:
			spawn_points.append(point)

func _process(delta: float) -> void:
	if monster_scene == null or spawn_points.size() == 0:
		return
	# 根据修理进度动态调整刷怪间隔
	if repair_progress_ref != null and repair_progress_ref.has_method("get_progress_percent"):
		var progress: float = repair_progress_ref.get_progress_percent()
		# 进度越高，刷怪越快
		current_spawn_interval = lerp(base_spawn_interval, min_spawn_interval, progress)
	# 计数当前存活怪物
	var alive_monsters: int = get_tree().get_nodes_in_group("monster").size()
	if alive_monsters >= max_monsters:
		return
	# 刷怪计时
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = current_spawn_interval
		spawn_monster()

func spawn_monster() -> void:
	if monster_scene == null or spawn_points.size() == 0:
		return
	# 随机选一个刷怪点
	var spawn_point: Node3D = spawn_points[randi() % spawn_points.size()]
	var monster: Node = monster_scene.instantiate()
	monster.position = spawn_point.position
	get_parent().add_child(monster)
	spawned_monsters += 1

func set_repair_ref(repair_node: Node) -> void:
	repair_progress_ref = repair_node

func _on_repair_completed() -> void:
	# 修理完成后根据配置决定是否停止刷怪
	if stop_on_repair_complete:
		set_process(false)


extends Node3D

## 第一关：实验体收容区
## 游戏开始时播放广播公告序列

var broadcast_timer: Timer = null

func _ready() -> void:
	# 延迟2秒后开始广播
	broadcast_timer = Timer.new()
	broadcast_timer.wait_time = 2.0
	broadcast_timer.one_shot = true
	broadcast_timer.timeout.connect(_start_broadcast)
	add_child(broadcast_timer)
	broadcast_timer.start()
	_build_level_exit()

func _start_broadcast() -> void:
	if UIManager == null:
		return
	# 广播序列：实验室背景信息+任务目标
	UIManager.show_announcement("实验体收容区 - 区域B7", 4.0)
	UIManager.show_announcement("警告：实验体处于休眠状态，请勿靠近牢房", 5.0)
	UIManager.show_announcement("主电源离线 - 备用供电仅维持照明", 4.0)
	UIManager.show_announcement("需要修复3台发电机恢复主供电", 4.0)
	UIManager.show_announcement("门禁权限锁定 - 权限者：皮特博士", 4.0)
	UIManager.show_announcement("皮特博士最后出现位置：收容区东侧", 4.0)
	UIManager.show_announcement("目标：修复发电机 → 搜索研究员尸体 → 开启安全门", 6.0)
	UIManager.show_announcement("操作：WASD移动 | 左键攻击 | E交互/维修 | Shift奔跑 | Q闪避 | G丢弃", 8.0)
func _build_level_exit() -> void:
	# 大门后触发区域：玩家进入后切换到第二关（场景独立，不耦合）
	var exit_area: Area3D = Area3D.new()
	exit_area.name = "LevelExit"
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(20.0, 4.0, 10.0)
	col.shape = shape
	exit_area.add_child(col)
	exit_area.position = Vector3(0, 2.0, 65.0)
	exit_area.body_entered.connect(_on_exit_entered)
	add_child(exit_area)

func _on_exit_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if UIManager != null:
			UIManager.show_announcement("正在进入下一区域...", 2.0)
		get_tree().change_scene_to_file("res://scenes/level2_corridor.tscn")
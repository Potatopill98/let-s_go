extends Node3D
## 中场休息室
## 安全区域，可存档、储物、进入下一关

@export var next_level_path: String = ""
@export var rest_room_name: String = "中场休息室"

var safe_zone: Area3D = null
var save_point: Node3D = null
var next_portal: Node3D = null
var is_in_safe_zone: bool = false

func _ready() -> void:
	safe_zone = get_node_or_null("SafeZone") as Area3D
	save_point = get_node_or_null("SavePoint") as Node3D
	next_portal = get_node_or_null("NextLevelPortal") as Node3D
	if safe_zone != null:
		safe_zone.body_entered.connect(_on_safe_zone_entered)
		safe_zone.body_exited.connect(_on_safe_zone_exited)
	# 自动存档
	if SaveManager != null:
		SaveManager.save_game()
	# 显示提示
	if UIManager != null:
		UIManager.show_toast("进入 " + rest_room_name + "，已自动存档")

func _process(delta: float) -> void:
	# 检查玩家是否在存档点附近
	if save_point != null:
		var players: Array = get_tree().get_nodes_in_group("player")
		for player in players:
			if player.global_position.distance_to(save_point.global_position) < 3.0:
				if Input.is_action_just_pressed("interact") or Input.is_key_pressed(KEY_E):
					_manual_save()
	# 检查玩家是否在下一关入口附近
	if next_portal != null and next_level_path != "":
		var players: Array = get_tree().get_nodes_in_group("player")
		for player in players:
			if player.global_position.distance_to(next_portal.global_position) < 2.0:
				if Input.is_action_just_pressed("interact") or Input.is_key_pressed(KEY_E):
					_enter_next_level()

func _on_safe_zone_entered(body: Node) -> void:
	if body.is_in_group("player"):
		is_in_safe_zone = true
		if UIManager != null:
			UIManager.show_toast("安全区域 - 怪物无法进入")

func _on_safe_zone_exited(body: Node) -> void:
	if body.is_in_group("player"):
		is_in_safe_zone = false

func _manual_save() -> void:
	if SaveManager == null:
		return
	# 保存玩家数据
	var players: Array = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player: Node = players[0]
		if player.has_method("get_health"):
			SaveManager.set_player_data(player.get_health(), player.get_max_health(), 1)
	SaveManager.save_game()
	if UIManager != null:
		UIManager.show_toast("游戏已保存")

func _enter_next_level() -> void:
	if next_level_path == "":
		return
	# 保存游戏
	if SaveManager != null:
		SaveManager.save_game()
	# 加载下一关
	var next_scene: PackedScene = load(next_level_path)
	if next_scene != null:
		get_tree().change_scene_to_packed(next_scene)

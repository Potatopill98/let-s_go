extends Area3D
class_name WeaponPickup

@export var weapon_scene: PackedScene
@export var weapon_name: String = "武器"

var player_in_range: bool = false

func _ready() -> void:
	add_to_group("weapon_pickup")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		pickup()
	# 上下浮动
	position.y = 1.0 + sin(Time.get_ticks_msec() / 500.0) * 0.2
	# 旋转
	rotation.y += delta * 2.0

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		player_in_range = true
		UIManager.show_interaction_prompt("按E拾取" + weapon_name)

func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		player_in_range = false
		UIManager.hide_interaction_prompt()

func pickup() -> void:
	var player: Player = get_tree().get_first_node_in_group("player") as Player
	if player == null or weapon_scene == null:
		return
	# 实例化武器并挂载到玩家武器点
	var weapon: Node = weapon_scene.instantiate()
	player.equip_weapon(weapon)
	UIManager.hide_interaction_prompt()
	UIManager.show_message("获得" + weapon_name)
	queue_free()

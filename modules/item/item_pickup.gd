extends Area3D
class_name ItemPickup

# ============================================================
# Generic Item Pickup
# Can pick up any HoldableItem (wrench, tools, etc.)
# ============================================================

@export var item_scene: PackedScene
@export var item_name: String = "物品"

var player_in_range: bool = false

func _ready() -> void:
	add_to_group("item_pickup")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		pickup()
	# Floating animation
	position.y = 1.0 + sin(Time.get_ticks_msec() / 500.0) * 0.2
	# Rotation
	rotation.y += delta * 2.0

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		player_in_range = true
		UIManager.show_interaction_prompt("按E拾取" + item_name)

func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		player_in_range = false
		UIManager.hide_interaction_prompt()

func pickup() -> void:
	var player: Player = get_tree().get_first_node_in_group("player") as Player
	if player == null or item_scene == null:
		return
	var item: Node = item_scene.instantiate()
	player.pick_up_item(item)
	UIManager.hide_interaction_prompt()
	UIManager.show_message("获得" + item_name)
	queue_free()

extends Area3D
class_name ItemPickup

# ============================================================
# Generic Item Pickup
# Shows the actual item model floating and rotating
# Supports both scene-defined meshes and script-created meshes
# ============================================================

@export var item_scene: PackedScene
@export var item_name: String = "物品"

var player_in_range: bool = false
var model_container: Node3D = null
var item_instance: Node = null

func _ready() -> void:
	add_to_group("item_pickup")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	model_container = get_node("ModelContainer") as Node3D
	_spawn_item_model()

func _spawn_item_model() -> void:
	if item_scene == null or model_container == null:
		return
	# Instantiate item and add to scene so its _ready() runs and creates meshes
	item_instance = item_scene.instantiate()
	model_container.add_child(item_instance)
	# Wait one frame for _ready() to complete (script-created meshes)
	await get_tree().process_frame
	# Now disable all collision and scripts, keep only the visual meshes
	_disable_collision_and_scripts(item_instance)

func _disable_collision_and_scripts(node: Node) -> void:
	# Disable collision shapes
	if node is CollisionShape3D:
		node.disabled = true
	# Disable Area3D monitoring
	if node is Area3D:
		node.monitoring = false
		node.monitorable = false
	# Disable physics bodies
	if node is PhysicsBody3D:
		node.process_mode = Node.PROCESS_MODE_DISABLED
	# Recurse into children
	for child in node.get_children():
		_disable_collision_and_scripts(child)

func _process(delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		pickup()
	# Floating + rotating animation for the model
	if model_container != null:
		model_container.position.y = 1.0 + sin(Time.get_ticks_msec() / 500.0) * 0.2
		model_container.rotation.y += delta * 2.0

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

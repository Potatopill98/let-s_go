extends Area3D
class_name ItemPickup

# ============================================================
# Generic Item Pickup
# Shows the actual item model floating and rotating
# ============================================================

@export var item_scene: PackedScene
@export var item_name: String = "物品"

var player_in_range: bool = false
var model_container: Node3D = null

func _ready() -> void:
	add_to_group("item_pickup")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	model_container = get_node("ModelContainer") as Node3D
	_spawn_item_model()

func _spawn_item_model() -> void:
	if item_scene == null or model_container == null:
		return
	# Instantiate item scene to get its visual model
	var item_instance: Node = item_scene.instantiate()
	# Copy all MeshInstance3D children to model container
	_copy_meshes(item_instance, model_container)
	# Free the instance, we only needed its meshes
	item_instance.queue_free()

func _copy_meshes(source: Node, target: Node) -> void:
	for child in source.get_children():
		if child is MeshInstance3D:
			var mesh_copy: MeshInstance3D = MeshInstance3D.new()
			mesh_copy.mesh = child.mesh
			mesh_copy.position = child.position
			mesh_copy.rotation = child.rotation
			mesh_copy.scale = child.scale
			mesh_copy.material_override = child.material_override
			target.add_child(mesh_copy)
		# Recurse into children to find nested meshes
		if child.get_child_count() > 0:
			_copy_meshes(child, target)

func _process(delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		pickup()
	# Floating animation for the model
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

extends Area3D
class_name RepairTask

@export var task_name: String = "修理任务"
@export var repair_speed_per_player: float = 10.0
@export var required_progress: float = 100.0
@export var interaction_key: Key = KEY_E
@export var required_tool_tag: String = "wrench" # Tool needed to repair
@export var require_tool: bool = true

signal repair_completed()
signal repair_progress_changed(progress: float, total: float)

var current_progress: float = 0.0
var interacting_players: Array = []
var is_completed: bool = false

func _ready() -> void:
	add_to_group("interactable")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if is_completed:
		return
	# Hold E to repair, multiple players speed up
	var active_players: int = 0
	var has_tool_player: bool = false
	for player in interacting_players:
		if player != null and is_instance_valid(player):
			if Input.is_key_pressed(interaction_key):
				# Check if player has required tool
				if require_tool:
					var player_tag: String = ""
					if player.has_method("get_current_interact_tag"):
						player_tag = player.get_current_interact_tag()
					if player_tag == required_tool_tag:
						active_players += 1
						has_tool_player = true
				else:
					active_players += 1
	if active_players > 0:
		current_progress += repair_speed_per_player * active_players * delta
		UIManager.show_progress(current_progress, required_progress, "修理中")
		UIManager.show_interaction_prompt("修理中：%d%%" % int(current_progress / required_progress * 100))
		repair_progress_changed.emit(current_progress, required_progress)
		if current_progress >= required_progress:
			current_progress = required_progress
			complete_repair()
	elif interacting_players.size() > 0 and require_tool and not has_tool_player:
		# Show prompt that tool is needed
		UIManager.show_interaction_prompt("需要扳手才能修理")

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		var player: Player = body as Player
		interacting_players.append(player)
		if interacting_players.size() == 1:
			if require_tool:
				var player_tag: String = ""
				if player.has_method("get_current_interact_tag"):
					player_tag = player.get_current_interact_tag()
				if player_tag == required_tool_tag:
					UIManager.show_interaction_prompt("按住E修理（%d%%）" % int(current_progress / required_progress * 100))
				else:
					UIManager.show_interaction_prompt("需要扳手才能修理")
			else:
				UIManager.show_interaction_prompt("按住E修理（%d%%）" % int(current_progress / required_progress * 100))

func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		var player: Player = body as Player
		interacting_players.erase(player)
		if interacting_players.size() == 0:
			UIManager.hide_interaction_prompt()
			UIManager.hide_progress()

func complete_repair() -> void:
	if is_completed:
		return
	is_completed = true
	UIManager.hide_interaction_prompt()
	UIManager.hide_progress()
	UIManager.show_message("修理完成！")
	repair_completed.emit()

func get_progress_percent() -> float:
	if required_progress <= 0:
		return 1.0
	return current_progress / required_progress

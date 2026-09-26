extends Node3D
class_name HoldableItem

# ============================================================
# Holdable Item Base Class
# All items player can hold inherit from this
# Types: tool, weapon, consumable
# ============================================================

enum ItemType { TOOL, WEAPON, CONSUMABLE }

@export var item_name: String = "Item"
@export var item_type: ItemType = ItemType.TOOL
@export var can_attack: bool = false
@export var can_interact: bool = false
@export var interact_tag: String = "" # Which interactables this tool can use
@export var drop_on_switch: bool = true

var is_held: bool = false
var holder: Node = null

func _ready() -> void:
	add_to_group("holdable")

func pick_up(player: Node) -> void:
	is_held = true
	holder = player
	visible = false
	if has_node("CollisionShape3D"):
		$CollisionShape3D.disabled = true

func drop(drop_position: Vector3) -> void:
	is_held = false
	holder = null
	global_position = drop_position
	visible = true
	if has_node("CollisionShape3D"):
		$CollisionShape3D.disabled = false

func use_primary() -> void:
	# Override in child classes
	pass

func use_secondary() -> void:
	# Override in child classes
	pass

extends Node3D
class_name BaseWeapon

# 通用武器属性
@export var weapon_name: String = "BaseWeapon"
@export var damage: float = 10.0
@export var attack_cooldown: float = 1.0
@export var knockback_force: float = 5.0

# 内部状态
var attack_timer: float = 0.0
var owner_player: Player = null

func _ready() -> void:
	add_to_group("weapon")

func _process(delta: float) -> void:
	if attack_timer > 0.0:
		attack_timer -= delta

# 武器被玩家拾取时调用
func set_owner_player(player: Player) -> void:
	owner_player = player

# 攻击接口，子类实现
func attack() -> void:
	pass

# 判断是否可以攻击
func can_attack() -> bool:
	return attack_timer <= 0.0 and owner_player != null

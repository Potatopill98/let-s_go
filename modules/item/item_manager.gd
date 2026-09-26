extends Node
## 道具管理器 - 全局单例
## 负责所有道具的注册、查询、生成、掉落

var item_database: Dictionary = {}

func _ready() -> void:
	_register_all_items()
	print("[ItemManager] 已注册 ", item_database.size(), " 个道具")

# ==================== 注册所有道具 ====================
func _register_all_items() -> void:
	# ---- 手持工具 ----
	_register_item({
		"item_id": "tool_wrench",
		"item_name": "扳手",
		"item_type": "holdable",
		"item_subtype": "tool",
		"stackable": false,
		"max_stack": 1,
		"droppable": true,
		"can_attack": false,
		"can_repair": true,
		"repair_speed_mult": 2.0,
		"description": "修理速度+100%，唯一能修门的工具",
		"model_scene": "res://modules/item/wrench.tscn",
		"color": Color(0.3, 0.5, 1.0),
	})
	_register_item({
		"item_id": "tool_flashlight",
		"item_name": "手电筒",
		"item_type": "holdable",
		"item_subtype": "tool",
		"stackable": false,
		"max_stack": 1,
		"droppable": true,
		"can_attack": false,
		"can_illuminate": true,
		"battery_max": 100.0,
		"description": "照亮10米范围，黑暗区域必备",
		"model_scene": "res://modules/item/flashlight.tscn",
		"color": Color(1.0, 1.0, 0.5),
	})
	_register_item({
		"item_id": "tool_crowbar",
		"item_name": "撬棍",
		"item_type": "holdable",
		"item_subtype": "tool",
		"stackable": false,
		"max_stack": 1,
		"droppable": true,
		"can_attack": true,
		"damage": 10,
		"knockback": 6.0,
		"attack_cooldown": 0.7,
		"can_unlock": true,
		"can_break_glass": true,
		"description": "开锁+砸玻璃，近战伤害10",
		"model_scene": "",
		"color": Color(0.7, 0.7, 0.8),
	})

	# ---- 手持近战武器 ----
	_register_item({
		"item_id": "wpn_bat",
		"item_name": "木棒",
		"item_type": "holdable",
		"item_subtype": "melee",
		"stackable": false,
		"max_stack": 1,
		"droppable": true,
		"can_attack": true,
		"damage": 15,
		"knockback": 8.0,
		"attack_cooldown": 0.8,
		"description": "基础近战武器",
		"model_scene": "res://modules/weapon/melee_weapon.tscn",
		"color": Color(0.6, 0.4, 0.2),
	})
	_register_item({
		"item_id": "wpn_stun_baton",
		"item_name": "电击棒",
		"item_type": "holdable",
		"item_subtype": "melee",
		"stackable": false,
		"max_stack": 1,
		"droppable": true,
		"can_attack": true,
		"damage": 8,
		"knockback": 4.0,
		"attack_cooldown": 1.0,
		"stun_duration": 2.0,
		"battery_max": 50.0,
		"description": "麻痹2秒，电量有限",
		"model_scene": "",
		"color": Color(0.5, 1.0, 1.0),
	})
	_register_item({
		"item_id": "wpn_fire_axe",
		"item_name": "消防斧",
		"item_type": "holdable",
		"item_subtype": "melee",
		"stackable": false,
		"max_stack": 1,
		"droppable": true,
		"can_attack": true,
		"damage": 25,
		"knockback": 12.0,
		"attack_cooldown": 1.2,
		"armor_pierce": true,
		"can_break_glass": true,
		"description": "高伤害+破甲+砸玻璃",
		"model_scene": "",
		"color": Color(1.0, 0.3, 0.3),
	})

	# ---- 手持远程武器 ----
	_register_item({
		"item_id": "wpn_pistol",
		"item_name": "手枪",
		"item_type": "holdable",
		"item_subtype": "ranged",
		"stackable": false,
		"max_stack": 1,
		"droppable": true,
		"can_attack": true,
		"damage": 25,
		"mag_size": 12,
		"fire_rate": 0.3,
		"range": 50.0,
		"ammo_type": "pistol",
		"description": "基础远程武器",
		"model_scene": "res://modules/weapon/ranged_weapon.tscn",
		"color": Color(0.3, 0.3, 0.3),
	})
	_register_item({
		"item_id": "wpn_shotgun",
		"item_name": "霰弹枪",
		"item_type": "holdable",
		"item_subtype": "ranged",
		"stackable": false,
		"max_stack": 1,
		"droppable": true,
		"can_attack": true,
		"damage": 8,
		"pellets": 8,
		"mag_size": 6,
		"fire_rate": 0.8,
		"range": 15.0,
		"ammo_type": "shotgun",
		"description": "近距离爆发伤害",
		"model_scene": "",
		"color": Color(0.5, 0.3, 0.2),
	})
	_register_item({
		"item_id": "wpn_rifle",
		"item_name": "步枪",
		"item_type": "holdable",
		"item_subtype": "ranged",
		"stackable": false,
		"max_stack": 1,
		"droppable": true,
		"can_attack": true,
		"damage": 30,
		"mag_size": 30,
		"fire_rate": 0.1,
		"range": 80.0,
		"ammo_type": "rifle",
		"description": "全自动步枪",
		"model_scene": "",
		"color": Color(0.2, 0.4, 0.2),
	})

	# ---- 即时消耗品（碰到直接生效）----
	_register_item({
		"item_id": "con_medkit",
		"item_name": "医疗包",
		"item_type": "instant_consumable",
		"item_subtype": "heal",
		"stackable": false,
		"max_stack": 1,
		"droppable": true,
		"heal_amount": 30,
		"description": "碰到直接回血30",
		"model_scene": "res://modules/item/health_pickup.tscn",
		"color": Color(1.0, 0.2, 0.2),
	})
	_register_item({
		"item_id": "con_adrenaline",
		"item_name": "肾上腺素",
		"item_type": "instant_consumable",
		"item_subtype": "buff",
		"stackable": false,
		"max_stack": 1,
		"droppable": true,
		"speed_mult": 1.5,
		"buff_duration": 10.0,
		"description": "移速+50%持续10秒",
		"model_scene": "",
		"color": Color(1.0, 0.5, 0.0),
	})
	_register_item({
		"item_id": "con_armor_shard",
		"item_name": "护甲碎片",
		"item_type": "instant_consumable",
		"item_subtype": "armor",
		"stackable": false,
		"max_stack": 1,
		"droppable": true,
		"armor_amount": 25,
		"description": "+25护甲",
		"model_scene": "",
		"color": Color(0.5, 0.5, 0.8),
	})
	_register_item({
		"item_id": "con_battery",
		"item_name": "电池",
		"item_type": "instant_consumable",
		"item_subtype": "battery",
		"stackable": false,
		"max_stack": 1,
		"droppable": true,
		"battery_amount": 50.0,
		"description": "手电筒/电击棒+50%电量",
		"model_scene": "",
		"color": Color(0.8, 0.8, 0.2),
	})

	# ---- 背包任务道具（2格）----
	_register_item({
		"item_id": "task_keycard_lab",
		"item_name": "实验室门禁卡",
		"item_type": "inventory_task",
		"item_subtype": "keycard",
		"stackable": false,
		"max_stack": 1,
		"droppable": false,
		"unlocks": "lab_door",
		"description": "开启实验室区域门",
		"model_scene": "",
		"color": Color(0.2, 0.8, 1.0),
	})
	_register_item({
		"item_id": "task_keycard_office",
		"item_name": "办公区门禁卡",
		"item_type": "inventory_task",
		"item_subtype": "keycard",
		"stackable": false,
		"max_stack": 1,
		"droppable": false,
		"unlocks": "office_door",
		"description": "开启办公区域门",
		"model_scene": "",
		"color": Color(0.2, 0.8, 0.5),
	})
	_register_item({
		"item_id": "task_fuse",
		"item_name": "保险丝",
		"item_type": "inventory_task",
		"item_subtype": "component",
		"stackable": false,
		"max_stack": 1,
		"droppable": false,
		"unlocks": "power_socket",
		"description": "插入电源插座通电",
		"model_scene": "",
		"color": Color(0.9, 0.9, 0.3),
	})
	_register_item({
		"item_id": "task_key_generator",
		"item_name": "发电机钥匙",
		"item_type": "inventory_task",
		"item_subtype": "key",
		"stackable": false,
		"max_stack": 1,
		"droppable": false,
		"unlocks": "generator_room",
		"description": "打开发电机房",
		"model_scene": "",
		"color": Color(0.8, 0.6, 0.2),
	})

	# ---- 背包消耗品（4格，可堆叠）----
	_register_item({
		"item_id": "inv_medkit",
		"item_name": "医疗包",
		"item_type": "inventory_consumable",
		"item_subtype": "heal",
		"stackable": true,
		"max_stack": 3,
		"droppable": true,
		"heal_amount": 30,
		"description": "使用后回血30",
		"model_scene": "",
		"color": Color(1.0, 0.2, 0.2),
	})
	_register_item({
		"item_id": "inv_bandage",
		"item_name": "绷带",
		"item_type": "inventory_consumable",
		"item_subtype": "heal",
		"stackable": true,
		"max_stack": 5,
		"droppable": true,
		"heal_amount": 15,
		"heal_duration": 2.0,
		"description": "2秒持续回血15",
		"model_scene": "",
		"color": Color(0.9, 0.9, 0.9),
	})
	_register_item({
		"item_id": "inv_adrenaline",
		"item_name": "肾上腺素",
		"item_type": "inventory_consumable",
		"item_subtype": "buff",
		"stackable": true,
		"max_stack": 2,
		"droppable": true,
		"speed_mult": 1.5,
		"buff_duration": 10.0,
		"description": "移速+50%持续10秒",
		"model_scene": "",
		"color": Color(1.0, 0.5, 0.0),
	})
	_register_item({
		"item_id": "inv_painkillers",
		"item_name": "止痛药",
		"item_type": "inventory_consumable",
		"item_subtype": "buff",
		"stackable": true,
		"max_stack": 2,
		"droppable": true,
		"damage_resist": 0.5,
		"buff_duration": 10.0,
		"description": "减伤50%持续10秒",
		"model_scene": "",
		"color": Color(0.6, 0.2, 0.8),
	})
	_register_item({
		"item_id": "inv_pistol_ammo",
		"item_name": "手枪弹药",
		"item_type": "inventory_consumable",
		"item_subtype": "ammo",
		"stackable": true,
		"max_stack": 5,
		"droppable": true,
		"ammo_type": "pistol",
		"ammo_amount": 24,
		"description": "+24发手枪弹",
		"model_scene": "",
		"color": Color(0.8, 0.8, 0.2),
	})
	_register_item({
		"item_id": "inv_shotgun_ammo",
		"item_name": "霰弹",
		"item_type": "inventory_consumable",
		"item_subtype": "ammo",
		"stackable": true,
		"max_stack": 3,
		"droppable": true,
		"ammo_type": "shotgun",
		"ammo_amount": 12,
		"description": "+12发霰弹",
		"model_scene": "",
		"color": Color(0.8, 0.4, 0.2),
	})
	_register_item({
		"item_id": "inv_rifle_ammo",
		"item_name": "步枪弹",
		"item_type": "inventory_consumable",
		"item_subtype": "ammo",
		"stackable": true,
		"max_stack": 3,
		"droppable": true,
		"ammo_type": "rifle",
		"ammo_amount": 60,
		"description": "+60发步枪弹",
		"model_scene": "",
		"color": Color(0.4, 0.6, 0.2),
	})

	# ---- 穿戴装备 - 头部 ----
	_register_item({
		"item_id": "wear_gas_mask",
		"item_name": "防毒面具",
		"item_type": "wearable",
		"item_subtype": "head",
		"stackable": false,
		"max_stack": 1,
		"droppable": true,
		"immunity": ["poison", "gas"],
		"vision_penalty": 0.2,
		"description": "免疫毒气，视野-20%",
		"model_scene": "",
		"color": Color(0.3, 0.6, 0.3),
	})
	_register_item({
		"item_id": "wear_night_vision",
		"item_name": "夜视仪",
		"item_type": "wearable",
		"item_subtype": "head",
		"stackable": false,
		"max_stack": 1,
		"droppable": true,
		"night_vision": true,
		"battery_max": 100.0,
		"description": "黑暗中可视，绿色滤镜",
		"model_scene": "",
		"color": Color(0.2, 1.0, 0.2),
	})
	_register_item({
		"item_id": "wear_helmet",
		"item_name": "头盔",
		"item_type": "wearable",
		"item_subtype": "head",
		"stackable": false,
		"max_stack": 1,
		"droppable": true,
		"headshot_resist": 0.5,
		"description": "爆头减伤50%",
		"model_scene": "",
		"color": Color(0.5, 0.5, 0.6),
	})

	# ---- 穿戴装备 - 身体 ----
	_register_item({
		"item_id": "wear_hazmat",
		"item_name": "防护服",
		"item_type": "wearable",
		"item_subtype": "body",
		"stackable": false,
		"max_stack": 1,
		"droppable": true,
		"immunity": ["poison", "gas", "acid"],
		"speed_penalty": 0.1,
		"description": "免疫毒气+腐蚀，移速-10%",
		"model_scene": "",
		"color": Color(1.0, 0.9, 0.2),
	})
	_register_item({
		"item_id": "wear_winter_suit",
		"item_name": "保暖服",
		"item_type": "wearable",
		"item_subtype": "body",
		"stackable": false,
		"max_stack": 1,
		"droppable": true,
		"immunity": ["cold"],
		"description": "免疫低温掉血",
		"model_scene": "",
		"color": Color(0.6, 0.7, 0.9),
	})
	_register_item({
		"item_id": "wear_bulletproof",
		"item_name": "防弹衣",
		"item_type": "wearable",
		"item_subtype": "body",
		"stackable": false,
		"max_stack": 1,
		"droppable": true,
		"damage_resist": 0.3,
		"description": "全局减伤30%",
		"model_scene": "",
		"color": Color(0.2, 0.3, 0.5),
	})

	# ---- 穿戴装备 - 脚部 ----
	_register_item({
		"item_id": "wear_grip_boots",
		"item_name": "防滑靴",
		"item_type": "wearable",
		"item_subtype": "feet",
		"stackable": false,
		"max_stack": 1,
		"droppable": true,
		"immunity": ["slippery"],
		"description": "冰面/湿滑不减速",
		"model_scene": "",
		"color": Color(0.4, 0.3, 0.2),
	})
	_register_item({
		"item_id": "wear_silent_boots",
		"item_name": "静音靴",
		"item_type": "wearable",
		"item_subtype": "feet",
		"stackable": false,
		"max_stack": 1,
		"droppable": true,
		"stealth_mult": 0.5,
		"description": "走路无声，怪物更难发现",
		"model_scene": "",
		"color": Color(0.2, 0.2, 0.3),
	})

	# ---- 放置物 ----
	_register_item({
		"item_id": "place_turret",
		"item_name": "自动炮塔",
		"item_type": "placeable",
		"item_subtype": "defense",
		"stackable": false,
		"max_stack": 1,
		"droppable": true,
		"duration": 30.0,
		"damage": 10,
		"fire_rate": 0.3,
		"description": "自动攻击怪物，持续30秒",
		"model_scene": "",
		"color": Color(0.8, 0.2, 0.2),
	})
	_register_item({
		"item_id": "place_electric_trap",
		"item_name": "电击陷阱",
		"item_type": "placeable",
		"item_subtype": "trap",
		"stackable": true,
		"max_stack": 3,
		"droppable": true,
		"damage": 20,
		"stun_duration": 3.0,
		"description": "踩中麻痹3秒+伤害20",
		"model_scene": "",
		"color": Color(0.5, 1.0, 1.0),
	})
	_register_item({
		"item_id": "place_barricade",
		"item_name": "路障",
		"item_type": "placeable",
		"item_subtype": "defense",
		"stackable": true,
		"max_stack": 2,
		"droppable": true,
		"health": 100,
		"description": "挡住通道，怪物需打破",
		"model_scene": "",
		"color": Color(0.6, 0.5, 0.3),
	})
	_register_item({
		"item_id": "place_glow_stick",
		"item_name": "照明棒",
		"item_type": "placeable",
		"item_subtype": "light",
		"stackable": true,
		"max_stack": 5,
		"droppable": true,
		"duration": 60.0,
		"light_range": 10.0,
		"description": "照亮10米范围，持续60秒",
		"model_scene": "",
		"color": Color(0.2, 1.0, 0.5),
	})

# ==================== 核心API ====================
func _register_item(data: Dictionary) -> void:
	var item_id: String = data.get("item_id", "")
	if item_id == "":
		push_warning("[ItemManager] 注册道具失败：缺少item_id")
		return
	item_database[item_id] = data

func get_item_data(item_id: String) -> Dictionary:
	if item_database.has(item_id):
		return item_database[item_id]
	push_warning("[ItemManager] 未找到道具：" + item_id)
	return {}

func has_item(item_id: String) -> bool:
	return item_database.has(item_id)

func get_item_name(item_id: String) -> String:
	var data: Dictionary = get_item_data(item_id)
	return data.get("item_name", item_id)

func get_item_type(item_id: String) -> String:
	var data: Dictionary = get_item_data(item_id)
	return data.get("item_type", "unknown")

func get_item_color(item_id: String) -> Color:
	var data: Dictionary = get_item_data(item_id)
	return data.get("color", Color.WHITE)

func get_all_items() -> Dictionary:
	return item_database

func get_items_by_type(item_type: String) -> Array:
	var result: Array = []
	for item_id in item_database.keys():
		var data: Dictionary = item_database[item_id]
		if data.get("item_type", "") == item_type:
			result.append(data)
	return result

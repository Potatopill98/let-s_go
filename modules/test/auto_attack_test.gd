extends Node3D
## 自动化测试：模拟玩家空手攻击怪物（确保命中+击杀）

var test_timer: float = 0.0
var test_phase: int = 0
var player_ref: Node = null
var spawned_monsters: Array = []
var attack_count: int = 0
var max_attacks: int = 30

func _ready() -> void:
	print("[TEST] 自动化攻击测试启动")
	test_timer = 1.5

func _process(delta: float) -> void:
	test_timer -= delta
	if test_timer > 0:
		return
	
	match test_phase:
		0:
			var players: Array = get_tree().get_nodes_in_group("player")
			if players.size() > 0:
				player_ref = players[0]
				print("[TEST] 找到玩家, pos=", player_ref.global_position)
				test_phase = 1
				test_timer = 0.3
			else:
				test_timer = 0.3
		1:
			# 在玩家面前生成怪物（z负方向=玩家面前）
			print("[TEST] 生成怪物在玩家面前")
			var monster_scene: PackedScene = load("res://modules/monster/base_monster.tscn")
			if monster_scene != null:
				for i in 3:
					var monster: Node = monster_scene.instantiate()
					# 玩家面前 z=-2 到 -4，x左右偏移
					var offset: Vector3 = Vector3(randf_range(-1.5, 1.5), 0, randf_range(-3.5, -2))
					monster.position = player_ref.global_position + offset
					monster.max_health = 10.0  # 低血量确保能打死
					monster.current_health = 10.0
					get_tree().current_scene.add_child(monster)
					spawned_monsters.append(monster)
					print("[TEST] 怪物", i, " pos=", monster.position, " hp=", monster.current_health)
				test_phase = 2
				test_timer = 0.5
			else:
				print("[TEST] 怪物场景加载失败!")
				test_phase = 99
		2:
			# 连续攻击
			if player_ref != null and is_instance_valid(player_ref):
				attack_count += 1
				player_ref.start_punch()
				# 检查怪物状态
				var alive_count: int = 0
				for m in spawned_monsters:
					if is_instance_valid(m):
						if not m.is_dead:
							alive_count += 1
						print("[TEST] 攻击", attack_count, " -> 怪物 hp=", m.current_health, " dead=", m.is_dead, " valid=", is_instance_valid(m))
					else:
						print("[TEST] 攻击", attack_count, " -> 怪物已释放")
				print("[TEST] 存活怪物数: ", alive_count)
				if attack_count >= max_attacks:
					print("[TEST] 攻击阶段完成")
					test_phase = 3
					test_timer = 3.0
				else:
					test_timer = 0.15  # 攻击间隔
			else:
				print("[TEST] 玩家失效!")
				test_phase = 99
		3:
			print("[TEST] === 最终状态 ===")
			for m in spawned_monsters:
				if is_instance_valid(m):
					print("[TEST]   怪物: hp=", m.current_health, " dead=", m.is_dead)
				else:
					print("[TEST]   怪物: 已释放")
			print("[TEST] === 测试完成，游戏未崩溃 ===")
			test_phase = 99
		99:
			pass

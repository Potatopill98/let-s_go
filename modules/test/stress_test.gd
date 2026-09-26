extends Node3D
## 全面压力测试：模拟真实游戏环境下的空手攻击

var test_timer: float = 0.0
var test_phase: int = 0
var player_ref: Node = null
var spawned_monsters: Array = []
var attack_count: int = 0
var move_phase: float = 0.0

func _ready() -> void:
	print("[STRESS] 压力测试启动")
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
				print("[STRESS] 玩家 pos=", player_ref.global_position)
				test_phase = 1
				test_timer = 0.3
			else:
				test_timer = 0.3
		1:
			# 生成5个怪物在玩家周围
			print("[STRESS] 生成5个怪物")
			var monster_scene: PackedScene = load("res://modules/monster/base_monster.tscn")
			if monster_scene != null:
				for i in 5:
					var monster: Node = monster_scene.instantiate()
					var angle: float = float(i) / 5.0 * TAU
					var dist: float = 2.5
					var offset: Vector3 = Vector3(sin(angle) * dist, 0, cos(angle) * dist)
					monster.position = player_ref.global_position + offset
					monster.max_health = 15.0
					monster.current_health = 15.0
					get_tree().current_scene.add_child(monster)
					spawned_monsters.append(monster)
				test_phase = 2
				test_timer = 0.5
				attack_count = 0
			else:
				test_phase = 99
		2:
			# 连续攻击20次，同时玩家左右移动
			if player_ref != null and is_instance_valid(player_ref):
				attack_count += 1
				# 模拟玩家左右移动
				move_phase += 0.3
				var move_dir: Vector3 = Vector3(sin(move_phase) * 3.0, 0, 0)
				player_ref.velocity.x = move_dir.x
				# 攻击
				player_ref.start_punch()
				# 统计
				var alive: int = 0
				var dead: int = 0
				var freed: int = 0
				for m in spawned_monsters:
					if is_instance_valid(m):
						if m.is_dead:
							dead += 1
						else:
							alive += 1
					else:
						freed += 1
				if attack_count % 5 == 0:
					print("[STRESS] 攻击", attack_count, " 存活:", alive, " 死亡:", dead, " 已释放:", freed)
				if attack_count >= 25:
					print("[STRESS] 第一轮攻击完成")
					test_phase = 3
					test_timer = 3.0
				else:
					test_timer = 0.12
			else:
				print("[STRESS] 玩家失效!")
				test_phase = 99
		3:
			# 等待尸体消失，然后第二轮
			print("[STRESS] 第二轮：生成新怪物+怪物反击")
			var monster_scene: PackedScene = load("res://modules/monster/base_monster.tscn")
			if monster_scene != null:
				for i in 3:
					var monster: Node = monster_scene.instantiate()
					var offset: Vector3 = Vector3(randf_range(-2, 2), 0, randf_range(-3, -2))
					monster.position = player_ref.global_position + offset
					monster.max_health = 20.0
					monster.current_health = 20.0
					monster.move_speed = 4.0
					monster.attack_damage = 5.0
					get_tree().current_scene.add_child(monster)
					spawned_monsters.append(monster)
				test_phase = 4
				test_timer = 0.5
				attack_count = 0
			else:
				test_phase = 99
		4:
			# 第二轮攻击，怪物会反击
			if player_ref != null and is_instance_valid(player_ref):
				attack_count += 1
				player_ref.start_punch()
				var player_hp: float = player_ref.current_health
				if attack_count % 5 == 0:
					print("[STRESS] 攻击", attack_count, " 玩家HP:", player_hp)
				if attack_count >= 30:
					print("[STRESS] 第二轮攻击完成")
					test_phase = 5
					test_timer = 4.0
				else:
					test_timer = 0.12
			else:
				test_phase = 99
		5:
			print("[STRESS] === 最终状态检查 ===")
			var alive: int = 0
			for m in spawned_monsters:
				if is_instance_valid(m):
					alive += 1
					print("[STRESS]   怪物: hp=", m.current_health, " dead=", m.is_dead)
				else:
					print("[STRESS]   怪物: 已释放")
			print("[STRESS] 总怪物数:", spawned_monsters.size(), " 仍在场景:", alive)
			print("[STRESS] 玩家HP:", player_ref.current_health)
			print("[STRESS] === 压力测试完成，游戏未崩溃 ===")
			test_phase = 99
		99:
			pass

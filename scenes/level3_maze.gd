extends Node3D

# ============================================================
# Level 3 - Underground Maze
# 地下废弃实验区迷宫
# 目标: 找钥匙 -> 找到电梯 -> 上去逃生
# 极暗环境, 手电筒是核心道具
# ============================================================

const CELL_SIZE: float = 4.0
const MAZE_W: int = 20
const MAZE_H: int = 20
const WALL_HEIGHT: float = 3.0
const WALL_THICK: float = 0.3

var maze_cells: Array = []
var walls: Array = []
var key_picked: bool = false
var elevator_unlocked: bool = false

func _ready() -> void:
	_generate_maze()
	_build_floor()
	_build_ceiling()
	_build_walls()
	_build_lighting()
	_spawn_player()
	_spawn_flashlights()
	_spawn_key()
	_spawn_elevator()
	_spawn_wall_crawlers()
	if UIManager != null:
		UIManager.show_announcement("地下实验区 - 找到钥匙卡, 前往电梯撤离", 5.0)

# ============================================================
# Maze generation (recursive backtracker)
# ============================================================
func _generate_maze() -> void:
	maze_cells.clear()
	for x in range(MAZE_W):
		maze_cells.append([])
		for y in range(MAZE_H):
			maze_cells[x].append({"walls": [true, true, true, true], "visited": false})
	var stack: Array = [Vector2i(0, 0)]
	maze_cells[0][0].visited = true
	while stack.size() > 0:
		var current: Vector2i = stack[-1]
		var neighbors: Array = _get_unvisited_neighbors(current)
		if neighbors.size() > 0:
			var next_cell: Vector2i = neighbors[randi() % neighbors.size()]
			_remove_wall(current, next_cell)
			maze_cells[next_cell.x][next_cell.y].visited = true
			stack.append(next_cell)
		else:
			stack.pop_back()
	# 开一些额外通道, 让迷宫有环路(不那么死)
	for i in range(30):
		var rx: int = randi() % MAZE_W
		var ry: int = randi() % MAZE_H
		var dir: int = randi() % 4
		var nx: int = rx
		var ny: int = ry
		if dir == 0 and rx > 0:
			nx = rx - 1
			_remove_wall(Vector2i(rx, ry), Vector2i(nx, ny))
		elif dir == 1 and rx < MAZE_W - 1:
			nx = rx + 1
			_remove_wall(Vector2i(rx, ry), Vector2i(nx, ny))
		elif dir == 2 and ry > 0:
			ny = ry - 1
			_remove_wall(Vector2i(rx, ry), Vector2i(nx, ny))
		elif dir == 3 and ry < MAZE_H - 1:
			ny = ny + 1
			_remove_wall(Vector2i(rx, ry), Vector2i(nx, ny))

func _get_unvisited_neighbors(cell: Vector2i) -> Array:
	var result: Array = []
	var dirs: Array = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	for d in dirs:
		var nx: int = cell.x + d.x
		var ny: int = cell.y + d.y
		if nx >= 0 and nx < MAZE_W and ny >= 0 and ny < MAZE_H:
			if not maze_cells[nx][ny].visited:
				result.append(Vector2i(nx, ny))
	return result

func _remove_wall(a: Vector2i, b: Vector2i) -> void:
	var dx: int = b.x - a.x
	var dy: int = b.y - a.y
	if dx == 1:
		maze_cells[a.x][a.y].walls[1] = false
		maze_cells[b.x][b.y].walls[3] = false
	elif dx == -1:
		maze_cells[a.x][a.y].walls[3] = false
		maze_cells[b.x][b.y].walls[1] = false
	elif dy == 1:
		maze_cells[a.x][a.y].walls[2] = false
		maze_cells[b.x][b.y].walls[0] = false
	elif dy == -1:
		maze_cells[a.x][a.y].walls[0] = false
		maze_cells[b.x][b.y].walls[2] = false

# ============================================================
# Build geometry
# ============================================================
func _build_floor() -> void:
	var floor_mi: MeshInstance3D = MeshInstance3D.new()
	var floor_box: BoxMesh = BoxMesh.new()
	floor_box.size = Vector3(MAZE_W * CELL_SIZE + 2, 0.2, MAZE_H * CELL_SIZE + 2)
	var floor_mat: StandardMaterial3D = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.12, 0.12, 0.14)
	floor_mat.roughness = 0.9
	floor_box.material = floor_mat
	floor_mi.mesh = floor_box
	floor_mi.position = Vector3(MAZE_W * CELL_SIZE / 2.0, -0.1, MAZE_H * CELL_SIZE / 2.0)
	add_child(floor_mi)
	var floor_col: StaticBody3D = StaticBody3D.new()
	var floor_cs: CollisionShape3D = CollisionShape3D.new()
	var floor_shape: BoxShape3D = BoxShape3D.new()
	floor_shape.size = Vector3(MAZE_W * CELL_SIZE + 2, 0.2, MAZE_H * CELL_SIZE + 2)
	floor_cs.shape = floor_shape
	floor_col.add_child(floor_cs)
	floor_col.position = floor_mi.position
	add_child(floor_col)

func _build_ceiling() -> void:
	var ceil_mi: MeshInstance3D = MeshInstance3D.new()
	var ceil_box: BoxMesh = BoxMesh.new()
	ceil_box.size = Vector3(MAZE_W * CELL_SIZE + 2, 0.2, MAZE_H * CELL_SIZE + 2)
	var ceil_mat: StandardMaterial3D = StandardMaterial3D.new()
	ceil_mat.albedo_color = Color(0.08, 0.08, 0.1)
	ceil_mat.roughness = 0.95
	ceil_box.material = ceil_mat
	ceil_mi.mesh = ceil_box
	ceil_mi.position = Vector3(MAZE_W * CELL_SIZE / 2.0, WALL_HEIGHT + 0.1, MAZE_H * CELL_SIZE / 2.0)
	add_child(ceil_mi)

func _build_walls() -> void:
	var wall_mat: StandardMaterial3D = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.18, 0.18, 0.2)
	wall_mat.roughness = 0.85
	wall_mat.metallic = 0.1
	for x in range(MAZE_W):
		for y in range(MAZE_H):
			var cell: Dictionary = maze_cells[x][y]
			var cx: float = x * CELL_SIZE + CELL_SIZE / 2.0
			var cy: float = y * CELL_SIZE + CELL_SIZE / 2.0
			# top wall (north, -z)
			if cell.walls[0]:
				_add_wall(cx, WALL_HEIGHT / 2.0, cy - CELL_SIZE / 2.0, CELL_SIZE + WALL_THICK, WALL_HEIGHT, WALL_THICK, wall_mat)
			# right wall (east, +x)
			if cell.walls[1]:
				_add_wall(cx + CELL_SIZE / 2.0, WALL_HEIGHT / 2.0, cy, WALL_THICK, WALL_HEIGHT, CELL_SIZE + WALL_THICK, wall_mat)
			# bottom wall (south, +z) - only for last row to avoid duplicates
			if cell.walls[2] and y == MAZE_H - 1:
				_add_wall(cx, WALL_HEIGHT / 2.0, cy + CELL_SIZE / 2.0, CELL_SIZE + WALL_THICK, WALL_HEIGHT, WALL_THICK, wall_mat)
			# left wall (west, -x) - only for first col
			if cell.walls[3] and x == 0:
				_add_wall(cx - CELL_SIZE / 2.0, WALL_HEIGHT / 2.0, cy, WALL_THICK, WALL_HEIGHT, CELL_SIZE + WALL_THICK, wall_mat)

func _add_wall(px: float, py: float, pz: float, sx: float, sy: float, sz: float, mat: StandardMaterial3D) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	var mi: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(sx, sy, sz)
	box.material = mat
	mi.mesh = box
	body.add_child(mi)
	var cs: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(sx, sy, sz)
	cs.shape = shape
	body.add_child(cs)
	body.position = Vector3(px, py, pz)
	add_child(body)
	walls.append(body)

# ============================================================
# Lighting - 极暗
# ============================================================
func _build_lighting() -> void:
	var env: WorldEnvironment = WorldEnvironment.new()
	var env_res: Environment = Environment.new()
	env_res.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env_res.ambient_light_color = Color(0.1, 0.1, 0.12)
	env_res.ambient_light_energy = 0.9
	env_res.background_mode = Environment.BG_COLOR
	env_res.background_color = Color(0, 0, 0)
	env_res.tonemap_exposure = 1.0
	env.environment = env_res
	add_child(env)
	# 应急灯: 迷宫中随机放一些红色闪烁灯
	var light_count: int = 28
	for i in range(light_count):
		var lx: int = randi() % MAZE_W
		var ly: int = randi() % MAZE_H
		var light: OmniLight3D = OmniLight3D.new()
		light.light_color = Color(1.0, 0.2, 0.15)
		light.light_energy = 1.4
		light.omni_range = 7.0
		light.position = Vector3(lx * CELL_SIZE + CELL_SIZE / 2.0, WALL_HEIGHT - 0.3, ly * CELL_SIZE + CELL_SIZE / 2.0)
		light.script = null
		add_child(light)
		# 发光灯管
		var tube: MeshInstance3D = MeshInstance3D.new()
		var tube_box: BoxMesh = BoxMesh.new()
		tube_box.size = Vector3(0.8, 0.08, 0.08)
		var tube_mat: StandardMaterial3D = StandardMaterial3D.new()
		tube_mat.emission_enabled = true
		tube_mat.emission = Color(1.0, 0.2, 0.15)
		tube_mat.emission_energy_multiplier = 3.0
		tube_box.material = tube_mat
		tube.mesh = tube_box
		tube.position = light.position
		add_child(tube)

# ============================================================
# Spawn entities
# ============================================================
func _spawn_player() -> void:
	var player_scene: PackedScene = load("res://modules/player/player.tscn")
	if player_scene == null:
		return
	var player: CharacterBody3D = player_scene.instantiate()
	player.position = Vector3(CELL_SIZE / 2.0, 1.0, CELL_SIZE / 2.0)
	player.name = "Player"
	add_child(player)


func _spawn_flashlights() -> void:
	# 根据玩家数量在出生点附近生成手电筒
	var player_count: int = get_tree().get_nodes_in_group("player").size()
	if player_count <= 0:
		player_count = 1
	var flash_scene: PackedScene = load("res://modules/item/flashlight.tscn")
	if flash_scene == null:
		return
	for i in range(player_count):
		var flash: Node3D = flash_scene.instantiate()
		# 出生点附近随机位置, 避免重叠
		var fx: float = 2.0 + randf() * 6.0
		var fz: float = 2.0 + randf() * 6.0
		flash.position = Vector3(fx, 0.5, fz)
		add_child(flash)
func _spawn_key() -> void:
	# 钥匙放在迷宫中间偏远处
	var kx: int = MAZE_W / 2 + randi() % 5 - 2
	var ky: int = MAZE_H / 2 + randi() % 5 - 2
	kx = clamp(kx, 2, MAZE_W - 3)
	ky = clamp(ky, 2, MAZE_H - 3)
	var key_area: Area3D = Area3D.new()
	key_area.name = "MazeKey"
	var key_mi: MeshInstance3D = MeshInstance3D.new()
	var key_box: BoxMesh = BoxMesh.new()
	key_box.size = Vector3(0.3, 0.1, 0.5)
	var key_mat: StandardMaterial3D = StandardMaterial3D.new()
	key_mat.albedo_color = Color(0.9, 0.8, 0.2)
	key_mat.emission_enabled = true
	key_mat.emission = Color(1.0, 0.9, 0.3)
	key_mat.emission_energy_multiplier = 2.0
	key_box.material = key_mat
	key_mi.mesh = key_box
	key_mi.position.y = 0.5
	key_area.add_child(key_mi)
	var key_cs: CollisionShape3D = CollisionShape3D.new()
	var key_shape: BoxShape3D = BoxShape3D.new()
	key_shape.size = Vector3(1.5, 1.5, 1.5)
	key_cs.shape = key_shape
	key_area.add_child(key_cs)
	key_area.position = Vector3(kx * CELL_SIZE + CELL_SIZE / 2.0, 0, ky * CELL_SIZE + CELL_SIZE / 2.0)
	key_area.body_entered.connect(_on_key_entered)
	add_child(key_area)
	# 钥匙旁边放个小灯方便找
	var key_light: OmniLight3D = OmniLight3D.new()
	key_light.light_color = Color(1.0, 0.9, 0.3)
	key_light.light_energy = 1.5
	key_light.omni_range = 4.0
	key_light.position = Vector3(0, 1.0, 0)
	key_area.add_child(key_light)

func _on_key_entered(body: Node) -> void:
	if body.is_in_group("player") and not key_picked:
		key_picked = true
		elevator_unlocked = true
		if UIManager != null:
			UIManager.show_toast("获得钥匙卡! 电梯已解锁")
			UIManager.show_announcement("钥匙卡已获取, 前往电梯撤离", 4.0)
		var key_node: Node = get_node_or_null("MazeKey")
		if key_node != null:
			key_node.queue_free()

func _spawn_elevator() -> void:
	# 电梯在迷宫对角(右下角)
	var ex: float = (MAZE_W - 2) * CELL_SIZE + CELL_SIZE / 2.0
	var ez: float = (MAZE_H - 2) * CELL_SIZE + CELL_SIZE / 2.0
	# 电梯井(一个大的区域)
	var elevator_area: Area3D = Area3D.new()
	elevator_area.name = "ElevatorExit"
	var elevator_cs: CollisionShape3D = CollisionShape3D.new()
	var elevator_shape: BoxShape3D = BoxShape3D.new()
	elevator_shape.size = Vector3(CELL_SIZE * 1.5, 3.0, CELL_SIZE * 1.5)
	elevator_cs.shape = elevator_shape
	elevator_area.add_child(elevator_cs)
	elevator_area.position = Vector3(ex, 1.5, ez)
	elevator_area.body_entered.connect(_on_elevator_entered)
	add_child(elevator_area)
	# 电梯门视觉
	var door_mi: MeshInstance3D = MeshInstance3D.new()
	var door_box: BoxMesh = BoxMesh.new()
	door_box.size = Vector3(CELL_SIZE * 1.2, WALL_HEIGHT, 0.3)
	var door_mat: StandardMaterial3D = StandardMaterial3D.new()
	door_mat.albedo_color = Color(0.3, 0.3, 0.35)
	door_mat.metallic = 0.8
	door_mat.roughness = 0.3
	door_box.material = door_mat
	door_mi.mesh = door_box
	door_mi.position = Vector3(ex, WALL_HEIGHT / 2.0, ez - CELL_SIZE / 2.0)
	add_child(door_mi)
	# 电梯指示灯
	var elev_light: OmniLight3D = OmniLight3D.new()
	elev_light.light_color = Color(0.2, 1.0, 0.3)
	elev_light.light_energy = 2.0
	elev_light.omni_range = 6.0
	elev_light.position = Vector3(ex, WALL_HEIGHT - 0.5, ez)
	add_child(elev_light)
	# 发光箭头指示
	var arrow: MeshInstance3D = MeshInstance3D.new()
	var arrow_box: BoxMesh = BoxMesh.new()
	arrow_box.size = Vector3(1.0, 0.1, 0.3)
	var arrow_mat: StandardMaterial3D = StandardMaterial3D.new()
	arrow_mat.emission_enabled = true
	arrow_mat.emission = Color(0.2, 1.0, 0.3)
	arrow_mat.emission_energy_multiplier = 3.0
	arrow_box.material = arrow_mat
	arrow.mesh = arrow_box
	arrow.position = Vector3(ex, WALL_HEIGHT - 0.8, ez - CELL_SIZE / 2.0 + 0.3)
	add_child(arrow)

func _on_elevator_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if elevator_unlocked:
			if UIManager != null:
				UIManager.show_announcement("电梯到达, 撤离成功!", 4.0)
			get_tree().create_timer(2.0).timeout.connect(func():
				get_tree().quit()
			)
		else:
			if UIManager != null:
				UIManager.show_toast("电梯未解锁, 需要找到钥匙卡")

func _spawn_wall_crawlers() -> void:
	# 贴墙怪物: 放在迷宫中几个位置, 贴在墙上
	var crawler_scene: PackedScene = load("res://scenes/entities/wall_crawler.tscn")
	if crawler_scene == null:
		return
	var positions: Array = [
		Vector2i(5, 5),
		Vector2i(10, 8),
		Vector2i(15, 12),
		Vector2i(8, 15),
		Vector2i(12, 3),
	]
	for pos in positions:
		var crawler: Node3D = crawler_scene.instantiate()
		crawler.position = Vector3(pos.x * CELL_SIZE + CELL_SIZE / 2.0, 1.0, pos.y * CELL_SIZE + CELL_SIZE / 2.0)
		add_child(crawler)

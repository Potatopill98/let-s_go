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
var key_pos: Vector3 = Vector3.ZERO
var elevator_pos: Vector3 = Vector3.ZERO
var map_picked: bool = false
var elevator_triggered: bool = false
var victory_panel: Control = null
var map_inside_area: Area3D = null

func _ready() -> void:
	if AudioManager != null:
		AudioManager.play_music("bass_hum", 0.4, 2.0)
	_generate_maze()
	_build_floor()
	_build_ceiling()
	_build_walls()
	_build_lighting()
	_spawn_player()
	_build_entry_tunnel()
	_spawn_flashlights()
	_spawn_key()
	_spawn_elevator()
	_build_guidance_markers()
	_spawn_map()
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
	var ceil_mat: StandardMaterial3D = StandardMaterial3D.new()
	ceil_mat.albedo_color = Color(0.08, 0.08, 0.1)
	ceil_mat.roughness = 0.95
	var total_w: float = MAZE_W * CELL_SIZE + 2
	var total_h: float = MAZE_H * CELL_SIZE + 2
	var hole_size: float = 5.0
	# 右半部分(洞右边)
	var c1: MeshInstance3D = MeshInstance3D.new()
	var b1: BoxMesh = BoxMesh.new()
	b1.size = Vector3(total_w - hole_size, 0.2, total_h)
	b1.material = ceil_mat
	c1.mesh = b1
	c1.position = Vector3(hole_size + (total_w - hole_size) / 2.0 - 1, WALL_HEIGHT + 0.1, total_h / 2.0 - 1)
	add_child(c1)
	# 左下部分(洞下方)
	var c2: MeshInstance3D = MeshInstance3D.new()
	var b2: BoxMesh = BoxMesh.new()
	b2.size = Vector3(hole_size, 0.2, total_h - hole_size)
	b2.material = ceil_mat
	c2.mesh = b2
	c2.position = Vector3(hole_size / 2.0 - 1, WALL_HEIGHT + 0.1, hole_size + (total_h - hole_size) / 2.0 - 1)
	add_child(c2)

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
	player.position = Vector3(CELL_SIZE / 2.0, 100.0, CELL_SIZE / 2.0)
	player.name = "Player"
	add_child(player)
	# 出生点光源, 让玩家看清周围
	var spawn_light: OmniLight3D = OmniLight3D.new()
	spawn_light.light_color = Color(0.9, 0.95, 1.0)
	spawn_light.light_energy = 2.5
	spawn_light.omni_range = 10.0
	spawn_light.position = Vector3(CELL_SIZE / 2.0, 2.5, CELL_SIZE / 2.0)
	add_child(spawn_light)
	# 出生点发光灯管
	var spawn_tube: MeshInstance3D = MeshInstance3D.new()
	var tube_box: BoxMesh = BoxMesh.new()
	tube_box.size = Vector3(1.5, 0.1, 0.1)
	var tube_mat: StandardMaterial3D = StandardMaterial3D.new()
	tube_mat.emission_enabled = true
	tube_mat.emission = Color(0.9, 0.95, 1.0)
	tube_mat.emission_energy_multiplier = 3.0
	tube_box.material = tube_mat
	spawn_tube.mesh = tube_box
	spawn_tube.position = Vector3(CELL_SIZE / 2.0, WALL_HEIGHT - 0.3, CELL_SIZE / 2.0)
	add_child(spawn_tube)


func _spawn_flashlights() -> void:
	# 根据玩家数量在出生点附近生成手电筒
	var player_count: int = get_tree().get_nodes_in_group("player").size()
	if player_count <= 0:
		player_count = 1
	var flash_scene: PackedScene = load("res://modules/item/flashlight.tscn")
	if flash_scene == null:
		return
	var flash_offsets: Array = [Vector2(1.5, 0), Vector2(1.5, 1.0), Vector2(-1.5, 0), Vector2(-1.5, 1.0)]
	for i in range(player_count):
		var flash: Node3D = flash_scene.instantiate()
		var fidx: int = i % flash_offsets.size()
		var fx: float = CELL_SIZE / 2.0 + flash_offsets[fidx].x
		var fz: float = CELL_SIZE / 2.0 + flash_offsets[fidx].y
		flash.position = Vector3(fx, 0.5, fz)
		add_child(flash)
func _build_entry_tunnel() -> void:
	# 出生点上方的隧道(100米高, 从第二关掉下来的通道)
	var tx: float = CELL_SIZE / 2.0
	var tz: float = CELL_SIZE / 2.0
	var tunnel_h: float = 100.0
	var tunnel_w: float = 3.5
	var tunnel_mat: StandardMaterial3D = StandardMaterial3D.new()
	tunnel_mat.albedo_color = Color(0.2, 0.2, 0.25)
	tunnel_mat.metallic = 0.7
	tunnel_mat.roughness = 0.6
	# 隧道四壁(带碰撞)
	for sx in [-tunnel_w/2.0, tunnel_w/2.0]:
		var wall_body: StaticBody3D = StaticBody3D.new()
		var wall: MeshInstance3D = MeshInstance3D.new()
		var wb: BoxMesh = BoxMesh.new()
		wb.size = Vector3(0.2, tunnel_h, tunnel_w)
		wb.material = tunnel_mat
		wall.mesh = wb
		wall_body.add_child(wall)
		var wcs: CollisionShape3D = CollisionShape3D.new()
		var ws: BoxShape3D = BoxShape3D.new()
		ws.size = Vector3(0.2, tunnel_h, tunnel_w)
		wcs.shape = ws
		wall_body.add_child(wcs)
		wall_body.position = Vector3(tx + sx, WALL_HEIGHT + tunnel_h/2.0, tz)
		add_child(wall_body)
	for sz in [-tunnel_w/2.0, tunnel_w/2.0]:
		var wall_body2: StaticBody3D = StaticBody3D.new()
		var wall2: MeshInstance3D = MeshInstance3D.new()
		var wb2: BoxMesh = BoxMesh.new()
		wb2.size = Vector3(tunnel_w, tunnel_h, 0.2)
		wb2.material = tunnel_mat
		wall2.mesh = wb2
		wall_body2.add_child(wall2)
		var wcs2: CollisionShape3D = CollisionShape3D.new()
		var ws2: BoxShape3D = BoxShape3D.new()
		ws2.size = Vector3(tunnel_w, tunnel_h, 0.2)
		wcs2.shape = ws2
		wall_body2.add_child(wcs2)
		wall_body2.position = Vector3(tx, WALL_HEIGHT + tunnel_h/2.0, tz + sz)
		add_child(wall_body2)
	# 梯子(一侧, 每2米一根)
	for i in range(50):
		var rung: MeshInstance3D = MeshInstance3D.new()
		var rb: BoxMesh = BoxMesh.new()
		rb.size = Vector3(0.1, 0.05, 1.8)
		var rung_mat: StandardMaterial3D = StandardMaterial3D.new()
		rung_mat.albedo_color = Color(0.5, 0.5, 0.55)
		rung_mat.metallic = 0.9
		rb.material = rung_mat
		rung.mesh = rb
		rung.position = Vector3(tx - tunnel_w/2.0 + 0.15, WALL_HEIGHT + 1.0 + i * 2.0, tz)
		add_child(rung)
	# 隧道顶部入口框
	var top_frame: MeshInstance3D = MeshInstance3D.new()
	var tf_box: BoxMesh = BoxMesh.new()
	tf_box.size = Vector3(tunnel_w + 0.6, 0.4, tunnel_w + 0.6)
	var tf_mat: StandardMaterial3D = StandardMaterial3D.new()
	tf_mat.albedo_color = Color(0.4, 0.4, 0.45)
	tf_mat.metallic = 0.8
	tf_box.material = tf_mat
	top_frame.mesh = tf_box
	top_frame.position = Vector3(tx, WALL_HEIGHT + tunnel_h + 0.2, tz)
	add_child(top_frame)
	# 隧道内每隔20米一盏灯
	for i in range(5):
		var tunnel_light: OmniLight3D = OmniLight3D.new()
		tunnel_light.light_color = Color(0.7, 0.8, 1.0)
		tunnel_light.light_energy = 1.2
		tunnel_light.omni_range = 8.0
		tunnel_light.position = Vector3(tx, WALL_HEIGHT + 10.0 + i * 20.0, tz)
		add_child(tunnel_light)

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
	key_pos = Vector3(kx * CELL_SIZE + CELL_SIZE / 2.0, 0, ky * CELL_SIZE + CELL_SIZE / 2.0)
	key_area.position = key_pos
	key_area.body_entered.connect(_on_key_entered)
	add_child(key_area)
	# 钥匙旁边放个强光灯方便找
	var key_light: OmniLight3D = OmniLight3D.new()
	key_light.light_color = Color(1.0, 0.9, 0.3)
	key_light.light_energy = 3.5
	key_light.omni_range = 9.0
	key_light.position = Vector3(0, 1.2, 0)
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
	elevator_pos = Vector3(ex, 0, ez)
	var elev_light: OmniLight3D = OmniLight3D.new()
	elev_light.light_color = Color(0.2, 1.0, 0.3)
	elev_light.light_energy = 4.0
	elev_light.omni_range = 11.0
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
	if not body.is_in_group("player") or elevator_triggered:
		return
	elevator_triggered = true
	if elevator_unlocked:
		_show_victory()
	else:
		elevator_triggered = false
		if UIManager != null:
			UIManager.show_toast("电梯未解锁, 需要找到钥匙卡")

func _show_victory() -> void:
	if AudioManager != null:
		AudioManager.play_sfx("elevator", 0.8)
		AudioManager.play_sfx("unlock", 0.6)
	# 显示撤离成功结束画面
	victory_panel = Control.new()
	victory_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	victory_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(victory_panel)
	var bg: ColorRect = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.85)
	victory_panel.add_child(bg)
	var title: Label = Label.new()
	title.text = "撤离成功!"
	title.anchor_left = 0.5
	title.anchor_right = 0.5
	title.offset_left = -300
	title.offset_top = -60
	title.offset_right = 300
	title.offset_bottom = 0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 1))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	title.add_theme_constant_override("outline_size", 8)
	victory_panel.add_child(title)
	var subtitle: Label = Label.new()
	subtitle.text = "你成功逃出了地下实验区\n按 ESC 退出游戏"
	subtitle.anchor_left = 0.5
	subtitle.anchor_right = 0.5
	subtitle.offset_left = -300
	subtitle.offset_top = 20
	subtitle.offset_right = 300
	subtitle.offset_bottom = 100
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 28)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0, 1))
	subtitle.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	subtitle.add_theme_constant_override("outline_size", 5)
	victory_panel.add_child(subtitle)
	if UIManager != null:
		UIManager.show_announcement("撤离成功!", 3.0)

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

# ============================================================
# Guidance markers - 地上指示灯指引
# 离钥匙近=黄色亮, 离电梯近=绿色亮, 远=暗红微弱
# ============================================================
func _build_guidance_markers() -> void:
	var max_dist: float = MAZE_W * CELL_SIZE * 0.7
	for x in range(MAZE_W):
		for y in range(MAZE_H):
			var cx: float = x * CELL_SIZE + CELL_SIZE / 2.0
			var cy: float = y * CELL_SIZE + CELL_SIZE / 2.0
			var cell_pos: Vector3 = Vector3(cx, 0, cy)
			var dist_key: float = cell_pos.distance_to(key_pos)
			var dist_elev: float = cell_pos.distance_to(elevator_pos)
			var target_dist: float = dist_key
			var target_color: Color = Color(1.0, 0.85, 0.2)
			if dist_elev < dist_key:
				target_dist = dist_elev
				target_color = Color(0.2, 1.0, 0.35)
			var brightness: float = clamp(1.0 - target_dist / max_dist, 0.04, 1.0)
			var marker: MeshInstance3D = MeshInstance3D.new()
			var box: BoxMesh = BoxMesh.new()
			box.size = Vector3(0.3, 0.04, 0.3)
			var mat: StandardMaterial3D = StandardMaterial3D.new()
			mat.emission_enabled = true
			mat.emission = target_color
			mat.emission_energy_multiplier = brightness * 2.5
			mat.albedo_color = Color(0, 0, 0)
			box.material = mat
			marker.mesh = box
			marker.position = Vector3(cx, 0.03, cy)
			add_child(marker)

# ============================================================
# Pickable map - 可拾取迷宫地图
# ============================================================
func _spawn_map() -> void:
	var player_count: int = get_tree().get_nodes_in_group("player").size()
	if player_count <= 0:
		player_count = 1
	for i in range(player_count):
		_spawn_single_map(i)

func _spawn_single_map(index: int) -> void:
	# 固定在出生点周围, 确保在通道里
	var spawn_x: float = CELL_SIZE / 2.0
	var spawn_z: float = CELL_SIZE / 2.0
	var offsets: Array = [Vector2(0, 1.5), Vector2(1.2, 1.5), Vector2(-1.2, 1.5), Vector2(0, 2.5)]
	var idx: int = index % offsets.size()
	var mx: float = spawn_x + offsets[idx].x
	var my: float = spawn_z + offsets[idx].y
	var map_area: Area3D = Area3D.new()
	map_area.name = "MazeMap_" + str(index)
	var map_mi: MeshInstance3D = MeshInstance3D.new()
	var map_box: BoxMesh = BoxMesh.new()
	map_box.size = Vector3(0.6, 0.04, 0.8)
	var map_mat: StandardMaterial3D = StandardMaterial3D.new()
	map_mat.albedo_color = Color(0.75, 0.65, 0.4)
	map_mat.emission_enabled = true
	map_mat.emission = Color(0.8, 0.7, 0.35)
	map_mat.emission_energy_multiplier = 1.5
	map_box.material = map_mat
	map_mi.mesh = map_box
	map_mi.position.y = 0.3
	map_area.add_child(map_mi)
	var map_cs: CollisionShape3D = CollisionShape3D.new()
	var map_shape: BoxShape3D = BoxShape3D.new()
	map_shape.size = Vector3(1.5, 1.5, 1.5)
	map_cs.shape = map_shape
	map_area.add_child(map_cs)
	map_area.position = Vector3(mx, 0, my)
	map_area.body_entered.connect(func(body): _on_map_body_enter(body, map_area))
	map_area.body_exited.connect(func(body): _on_map_body_exit(body, map_area))
	add_child(map_area)
	var map_light: OmniLight3D = OmniLight3D.new()
	map_light.light_color = Color(0.9, 0.8, 0.4)
	map_light.light_energy = 2.0
	map_light.omni_range = 5.0
	map_light.position = Vector3(0, 1.0, 0)
	map_area.add_child(map_light)

func _on_map_body_enter(body: Node, map_area: Area3D) -> void:
	if body.is_in_group("player") and not map_picked:
		map_inside_area = map_area
		if UIManager != null:
			UIManager.show_interaction_prompt("按E拾取迷宫地图")

func _on_map_body_exit(body: Node, map_area: Area3D) -> void:
	if body.is_in_group("player") and map_inside_area == map_area:
		map_inside_area = null
		if UIManager != null:
			UIManager.hide_interaction_prompt()

func _process(delta: float) -> void:
	if map_inside_area != null and Input.is_action_just_pressed("interact") and not map_picked:
		var player: Node = get_tree().get_first_node_in_group("player")
		if player != null:
			map_picked = true
			_render_maze_map(player)
			if UIManager != null:
				UIManager.show_toast("获得迷宫地图! 按M查看")
				UIManager.show_announcement("地图已获取", 3.0)
				UIManager.hide_interaction_prompt()
			var area: Area3D = map_inside_area
			map_inside_area = null
			area.queue_free()

func _render_maze_map(player: Node) -> void:
	var cell_px: int = 16
	var img_w: int = MAZE_W * cell_px + 4
	var img_h: int = MAZE_H * cell_px + 4
	var img: Image = Image.create(img_w, img_h, false, Image.FORMAT_RGB8)
	img.fill(Color(0.05, 0.05, 0.08))
	# 画迷宫墙和通道
	for x in range(MAZE_W):
		for y in range(MAZE_H):
			var cell: Dictionary = maze_cells[x][y]
			var px: int = x * cell_px + 2
			var py: int = y * cell_px + 2
			# 通道底色
			img.fill_rect(Rect2i(px, py, cell_px, cell_px), Color(0.15, 0.15, 0.18))
			# 画墙
			if cell.walls[0]:
				img.fill_rect(Rect2i(px, py, cell_px, 2), Color(0.6, 0.6, 0.65))
			if cell.walls[1]:
				img.fill_rect(Rect2i(px + cell_px - 2, py, 2, cell_px), Color(0.6, 0.6, 0.65))
			if cell.walls[2] and y == MAZE_H - 1:
				img.fill_rect(Rect2i(px, py + cell_px - 2, cell_px, 2), Color(0.6, 0.6, 0.65))
			if cell.walls[3] and x == 0:
				img.fill_rect(Rect2i(px, py, 2, cell_px), Color(0.6, 0.6, 0.65))
	# 标记钥匙(黄点)
	if not key_picked:
		var kx: int = int(key_pos.x / CELL_SIZE) * cell_px + 2 + cell_px / 2
		var ky: int = int(key_pos.z / CELL_SIZE) * cell_px + 2 + cell_px / 2
		img.fill_rect(Rect2i(kx - 3, ky - 3, 6, 6), Color(1.0, 0.9, 0.2))
	# 标记电梯(绿点)
	var ex: int = int(elevator_pos.x / CELL_SIZE) * cell_px + 2 + cell_px / 2
	var ey: int = int(elevator_pos.z / CELL_SIZE) * cell_px + 2 + cell_px / 2
	img.fill_rect(Rect2i(ex - 3, ey - 3, 6, 6), Color(0.2, 1.0, 0.3))
	var texture: ImageTexture = ImageTexture.create_from_image(img)
	if UIManager != null:
		UIManager.set_maze_map(texture, CELL_SIZE, MAZE_W, MAZE_H)
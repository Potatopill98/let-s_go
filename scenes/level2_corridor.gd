extends Node3D

## ============================================================
## 第二关：狭长逃生走廊（重做版）
## 连接室 -> 主走廊(黑暗/警报灯) -> 侧面安全门 -> 逃生走廊 -> 安全中间层
## 门板为独立可移动 StaticBody，碰撞直接挂 CollisionObject（最可靠）
## ============================================================

# ---- 主走廊尺寸 ----
const CORRIDOR_WIDTH: float = 7.0
const CORRIDOR_HEIGHT: float = 4.0
const CONNECTION_ROOM_END: float = 20.0
const MAIN_END: float = 460.0
const HALF_W: float = 3.5

# ---- 门 / 小房间 ----
const DOOR_SPACING: float = 22.0
const DOOR_WIDTH: float = 2.0
const DOOR_HEIGHT: float = 4.0
const ROOM_DEPTH: float = 2.2
const FIRST_DOOR_Z: float = 55.0
const WALL_THICK: float = 0.3

# ---- 出口 / 逃生走廊 / 中间层 ----
const EXIT_Z: float = 451.0
const ESCAPE_LENGTH: float = 50.0
const ESCAPE_WIDTH: float = 3.0
const HUB_SIZE: float = 16.0
const HUB_HEIGHT: float = 5.0

# ---- 场景 ----
const MONSTER_SCENE: PackedScene = preload("res://modules/monster/base_monster.tscn")
const CHASER_SCENE: PackedScene = preload("res://modules/monster/chaser_monster.tscn")
const HEALTH_SCENE: PackedScene = preload("res://modules/item/health_pickup.tscn")

# ---- 运行状态 ----
var chaser: Node = null
var test_started: bool = false
var countdown: float = 0.0
var chaser_released: bool = false
var warning_shown: bool = false
var ceiling_trap: MeshInstance3D = null
var alarm_lights: Array = []
var alarm_timer: float = 0.0
var current_door_area: Area3D = null
var current_gate_area: Area3D = null
var door_z_list: Array = []
var hub_reached: bool = false
var well_inside: bool = false
var well_area: Area3D = null
var well_opened: bool = false
var button_inside: bool = false
var button_pressed: bool = false

# ---- 材质 ----
var mat_floor: StandardMaterial3D
var mat_wall: StandardMaterial3D
var mat_ceiling: StandardMaterial3D
var mat_frame: StandardMaterial3D
var mat_panel: StandardMaterial3D
var mat_handle: StandardMaterial3D
var mat_window: StandardMaterial3D

func _ready() -> void:
	if AudioManager != null:
		AudioManager.play_music("horror_sweep", 0.35, 2.0)
	randomize()
	_init_materials()
	_build_door_z_list()
	_build_base()
	_build_connection_room()
	_build_main_walls()
	_build_rooms_and_doors()
	_build_escape_and_hub()
	build_alarm_system()
	_build_navigation()
	if UIManager != null:
		UIManager.show_announcement("紧急疏散通道 - B区", 3.0)
		UIManager.show_announcement("前方通道已封锁 - 请寻找安全出口", 3.5)
		UIManager.show_announcement("警告：部分房门后可能有实验体", 4.0)

# ============================================================
# 材质
# ============================================================
func _init_materials() -> void:
	mat_floor = StandardMaterial3D.new()
	mat_floor.albedo_color = Color(0.2, 0.2, 0.22)
	mat_floor.roughness = 0.9
	mat_wall = StandardMaterial3D.new()
	mat_wall.albedo_color = Color(0.28, 0.28, 0.32)
	mat_wall.roughness = 0.85
	mat_ceiling = StandardMaterial3D.new()
	mat_ceiling.albedo_color = Color(0.18, 0.18, 0.2)
	mat_ceiling.roughness = 0.9
	mat_frame = StandardMaterial3D.new()
	mat_frame.albedo_color = Color(0.4, 0.43, 0.48)
	mat_frame.metallic = 0.8
	mat_frame.roughness = 0.35
	mat_panel = StandardMaterial3D.new()
	mat_panel.albedo_color = Color(0.55, 0.58, 0.62)
	mat_panel.metallic = 0.7
	mat_panel.roughness = 0.4
	mat_handle = StandardMaterial3D.new()
	mat_handle.albedo_color = Color(0.7, 0.7, 0.75)
	mat_handle.metallic = 0.9
	mat_handle.roughness = 0.2
	mat_window = StandardMaterial3D.new()
	mat_window.albedo_color = Color(0.2, 0.3, 0.4, 0.7)
	mat_window.emission_enabled = false
	mat_window.emission = Color(0.1, 0.2, 0.3)
	mat_window.emission_energy_multiplier = 0.5
	mat_window.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func _build_door_z_list() -> void:
	door_z_list.clear()
	var z: float = FIRST_DOOR_Z
	while z <= EXIT_Z:
		door_z_list.append(z)
		z += DOOR_SPACING

# ============================================================
# 基础：地板 / 天花板（一整块覆盖走廊+两侧房间）
# ============================================================
func _build_base() -> void:
	var cover_width: float = CORRIDOR_WIDTH + ROOM_DEPTH * 2.0
	_make_solid(Vector3(0, -0.1, MAIN_END / 2.0), Vector3(cover_width, 0.2, MAIN_END), mat_floor)
	_make_solid(Vector3(0, CORRIDOR_HEIGHT + 0.1, MAIN_END / 2.0), Vector3(cover_width, 0.2, MAIN_END), mat_ceiling)
	_make_solid(Vector3(0, 3.0, MAIN_END), Vector3(cover_width, 6.0, 0.4), mat_wall)

func _make_solid(pos: Vector3, size: Vector3, mat: Material) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	box.material = mat
	mesh.mesh = box
	body.add_child(mesh)
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	body.position = pos
	add_child(body)
	return body

# ============================================================
# 连接室（z=0~20，亮灯准备区）
# ============================================================
func _build_connection_room() -> void:
	_make_solid(Vector3(-HALF_W, CORRIDOR_HEIGHT / 2.0, CONNECTION_ROOM_END / 2.0), Vector3(WALL_THICK, CORRIDOR_HEIGHT, CONNECTION_ROOM_END), mat_wall)
	_make_solid(Vector3(HALF_W, CORRIDOR_HEIGHT / 2.0, CONNECTION_ROOM_END / 2.0), Vector3(WALL_THICK, CORRIDOR_HEIGHT, CONNECTION_ROOM_END), mat_wall)
	_make_solid(Vector3(-2.0, CORRIDOR_HEIGHT / 2.0, 0.0), Vector3(3.0, CORRIDOR_HEIGHT, WALL_THICK), mat_wall)
	_make_solid(Vector3(2.0, CORRIDOR_HEIGHT / 2.0, 0.0), Vector3(3.0, CORRIDOR_HEIGHT, WALL_THICK), mat_wall)
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = Color(1.0, 0.97, 0.9)
	light.light_energy = 2.5
	light.omni_range = 16.0
	light.position = Vector3(0, CORRIDOR_HEIGHT - 0.5, 10.0)
	add_child(light)
	ceiling_trap = MeshInstance3D.new()
	var trap_box: BoxMesh = BoxMesh.new()
	trap_box.size = Vector3(5.0, 0.2, 5.0)
	var trap_mat: StandardMaterial3D = StandardMaterial3D.new()
	trap_mat.albedo_color = Color(0.3, 0.3, 0.35)
	trap_box.material = trap_mat
	ceiling_trap.mesh = trap_box
	ceiling_trap.position = Vector3(0, CORRIDOR_HEIGHT - 0.05, 10.0)
	add_child(ceiling_trap)
	_build_gate()

# 连接室出口大门（门板独立 StaticBody，向上滑动）
func _build_gate() -> void:
	# ---- 门板 StaticBody ----
	var gate: StaticBody3D = StaticBody3D.new()
	gate.name = "TestGate"
	var panel: MeshInstance3D = MeshInstance3D.new()
	var pbox: BoxMesh = BoxMesh.new()
	pbox.size = Vector3(CORRIDOR_WIDTH - 0.2, CORRIDOR_HEIGHT - 0.2, 0.2)
	pbox.material = mat_panel
	panel.mesh = pbox
	panel.position = Vector3(0, CORRIDOR_HEIGHT / 2.0, 0)
	gate.add_child(panel)
	for i in range(5):
		var rib: MeshInstance3D = MeshInstance3D.new()
		var rbox: BoxMesh = BoxMesh.new()
		rbox.size = Vector3(CORRIDOR_WIDTH - 0.5, 0.1, 0.25)
		rbox.material = mat_frame
		rib.mesh = rbox
		rib.position = Vector3(0, 0.8 + i * 0.7, 0)
		gate.add_child(rib)
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(CORRIDOR_WIDTH - 0.2, CORRIDOR_HEIGHT - 0.2, 0.6)
	col.shape = shape
	col.position = Vector3(0, CORRIDOR_HEIGHT / 2.0, 0)
	gate.add_child(col)
	gate.position = Vector3(0, 0, CONNECTION_ROOM_END)
	add_child(gate)
	# ---- 交互 Area（独立 holder）----
	var holder: Node3D = Node3D.new()
	holder.name = "GateAreaHolder"
	var area: Area3D = Area3D.new()
	var ac: CollisionShape3D = CollisionShape3D.new()
	var ashape: BoxShape3D = BoxShape3D.new()
	ashape.size = Vector3(CORRIDOR_WIDTH, CORRIDOR_HEIGHT, 4.0)
	ac.shape = ashape
	ac.position.y = CORRIDOR_HEIGHT / 2.0
	area.add_child(ac)
	area.set_meta("kind", "gate")
	area.set_meta("gate", gate)
	area.body_entered.connect(func(b): _on_gate_enter(b, area))
	area.body_exited.connect(func(b): _on_gate_exit(b))
	holder.add_child(area)
	holder.position = Vector3(0, 0, CONNECTION_ROOM_END)
	add_child(holder)

func _on_gate_enter(body: Node, area: Area3D) -> void:
	if body.is_in_group("player") and not test_started and current_gate_area == null:
		current_gate_area = area
		if UIManager != null:
			UIManager.show_interaction_prompt("按E - 开启测试通道")

func _on_gate_exit(body: Node) -> void:
	if body.is_in_group("player") and not test_started:
		current_gate_area = null
		if UIManager != null:
			UIManager.hide_interaction_prompt()

func _start_test(area: Area3D) -> void:
	if test_started:
		return
	test_started = true
	countdown = 60.0
	warning_shown = false
	if AudioManager != null:
		AudioManager.play_sfx("button_click", 0.8)
		AudioManager.play_sfx("alarm_breach", 0.6)
	current_gate_area = null
	if UIManager != null:
		UIManager.hide_interaction_prompt()
		UIManager.show_announcement("测试程序已启动", 3.0)
		UIManager.show_announcement("警告：检测到异常生物信号", 3.5)
		UIManager.show_announcement("收容协议正在解除...", 3.5)
		UIManager.show_announcement("所有人员请立即前往安全区域", 4.0)
	var gate: Node = area.get_meta("gate")
	var tw: Tween = create_tween()
	tw.tween_property(gate, "position:y", CORRIDOR_HEIGHT + 1.5, 1.5)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.set_ease(Tween.EASE_IN_OUT)

# ============================================================
# 主走廊外墙（留门洞）
# ============================================================
func _build_main_walls() -> void:
	_build_wall_side(-HALF_W)
	_build_wall_side(HALF_W)

func _build_wall_side(x: float) -> void:
	var cursor: float = CONNECTION_ROOM_END
	for dz in door_z_list:
		var door_lo: float = dz - DOOR_WIDTH / 2.0
		var door_hi: float = dz + DOOR_WIDTH / 2.0
		if door_lo > cursor:
			_make_solid(Vector3(x, CORRIDOR_HEIGHT / 2.0, (cursor + door_lo) / 2.0), Vector3(WALL_THICK, CORRIDOR_HEIGHT, door_lo - cursor), mat_wall)
		cursor = door_hi
	if MAIN_END > cursor:
		_make_solid(Vector3(x, CORRIDOR_HEIGHT / 2.0, (cursor + MAIN_END) / 2.0), Vector3(WALL_THICK, CORRIDOR_HEIGHT, MAIN_END - cursor), mat_wall)

# ============================================================
# 小房间 + 两侧门
# ============================================================
func _build_rooms_and_doors() -> void:
	var idx: int = 0
	for k in range(door_z_list.size()):
		var dz: float = door_z_list[k]
		var is_exit_group: bool = (k == door_z_list.size() - 1)
		_build_small_room(dz, true)
		_build_one_door(dz, true, idx, false)
		idx += 1
		if is_exit_group:
			_build_one_door(dz, false, idx, true)
		else:
			_build_small_room(dz, false)
			_build_one_door(dz, false, idx, false)
		idx += 1

func _build_small_room(dz: float, is_left: bool) -> void:
	var dir_sign: float = -1.0 if is_left else 1.0
	var room_center_x: float = dir_sign * (HALF_W + ROOM_DEPTH / 2.0)
	var back_x: float = dir_sign * (HALF_W + ROOM_DEPTH)
	var room_z_half: float = ROOM_DEPTH / 2.0
	_make_solid(Vector3(back_x, CORRIDOR_HEIGHT / 2.0, dz), Vector3(WALL_THICK, CORRIDOR_HEIGHT, ROOM_DEPTH), mat_wall)
	_make_solid(Vector3(room_center_x, CORRIDOR_HEIGHT / 2.0, dz - room_z_half), Vector3(ROOM_DEPTH, CORRIDOR_HEIGHT, WALL_THICK), mat_wall)
	_make_solid(Vector3(room_center_x, CORRIDOR_HEIGHT / 2.0, dz + room_z_half), Vector3(ROOM_DEPTH, CORRIDOR_HEIGHT, WALL_THICK), mat_wall)

# 单扇门：门框 StaticBody（固定）+ 门板 StaticBody（滑动，碰撞直接挂）
func _build_one_door(dz: float, is_left: bool, idx: int, is_exit: bool) -> void:
	var dir_sign: float = -1.0 if is_left else 1.0
	var door_x: float = dir_sign * HALF_W
	var door_type: String = "monster"
	if is_exit:
		door_type = "exit"
	elif idx % 3 == 0:
		door_type = "locked"
	elif idx % 5 == 2:
		door_type = "health"

	# ---- 门框（固定 StaticBody）----
	var frame_body: StaticBody3D = StaticBody3D.new()
	frame_body.name = "DoorFrame_%d" % idx
	var ft: float = 0.15
	frame_body.add_child(_frame_piece(Vector3(0, DOOR_HEIGHT / 2.0, -DOOR_WIDTH / 2.0 - ft / 2.0), Vector3(0.2, DOOR_HEIGHT, ft)))
	frame_body.add_child(_frame_piece(Vector3(0, DOOR_HEIGHT / 2.0, DOOR_WIDTH / 2.0 + ft / 2.0), Vector3(0.2, DOOR_HEIGHT, ft)))
	frame_body.add_child(_frame_piece(Vector3(0, DOOR_HEIGHT - ft / 2.0, 0), Vector3(0.2, ft, DOOR_WIDTH + ft * 2.0)))
	# 门上方指引灯
	var dl: OmniLight3D = OmniLight3D.new()
	dl.light_color = Color(0.6, 0.6, 0.7)
	dl.light_energy = 0.3
	dl.omni_range = 4.0
	dl.position = Vector3(0, CORRIDOR_HEIGHT - 0.5, 0)
	frame_body.add_child(dl)

	# ---- 门板（可移动 StaticBody，碰撞直接挂）----
	var panel_body: StaticBody3D = StaticBody3D.new()
	panel_body.name = "DoorPanel_%d" % idx
	var panel: MeshInstance3D = MeshInstance3D.new()
	var pbox: BoxMesh = BoxMesh.new()
	pbox.size = Vector3(0.15, DOOR_HEIGHT - 0.2, DOOR_WIDTH - 0.1)
	pbox.material = mat_panel
	panel.mesh = pbox
	panel.position = Vector3(0, DOOR_HEIGHT / 2.0, 0)
	panel_body.add_child(panel)
	for i in range(3):
		var rib: MeshInstance3D = MeshInstance3D.new()
		var rbox: BoxMesh = BoxMesh.new()
		rbox.size = Vector3(0.04, 0.08, DOOR_WIDTH - 0.3)
		rbox.material = mat_frame
		rib.mesh = rbox
		rib.position = Vector3(0, 1.0 + i * 1.2, 0)
		panel_body.add_child(rib)
	var window: MeshInstance3D = MeshInstance3D.new()
	var wbox: BoxMesh = BoxMesh.new()
	wbox.size = Vector3(0.04, 0.5, 0.6)
	wbox.material = mat_window
	window.mesh = wbox
	window.position = Vector3(0, 2.8, 0)
	panel_body.add_child(window)
	var hb: BoxMesh = BoxMesh.new()
	hb.size = Vector3(0.05, 0.12, 0.15)
	hb.material = mat_handle
	var h1: MeshInstance3D = MeshInstance3D.new()
	h1.mesh = hb
	h1.position = Vector3(0.1, 1.5, 0.6)
	panel_body.add_child(h1)
	var h2: MeshInstance3D = MeshInstance3D.new()
	h2.mesh = hb
	h2.position = Vector3(-0.1, 1.5, 0.6)
	panel_body.add_child(h2)
	if is_exit:
		panel_body.add_child(_indicator(0.1))
		panel_body.add_child(_indicator(-0.1))
	# 门板碰撞（直接挂 panel_body，x 厚 0.6）
	var col: CollisionShape3D = CollisionShape3D.new()
	var dshape: BoxShape3D = BoxShape3D.new()
	dshape.size = Vector3(0.6, DOOR_HEIGHT - 0.2, DOOR_WIDTH - 0.1)
	col.shape = dshape
	col.position = Vector3(0, DOOR_HEIGHT / 2.0, 0)
	panel_body.add_child(col)

	# ---- 交互 Area（挂门框下，独立 CollisionObject）----
	var area: Area3D = Area3D.new()
	var ac: CollisionShape3D = CollisionShape3D.new()
	var ashape: BoxShape3D = BoxShape3D.new()
	ashape.size = Vector3(3.0, DOOR_HEIGHT, DOOR_WIDTH + 2.0)
	ac.shape = ashape
	ac.position.y = DOOR_HEIGHT / 2.0
	area.add_child(ac)
	area.set_meta("kind", "door")
	area.set_meta("door_type", door_type)
	area.set_meta("panel_body", panel_body)
	area.set_meta("door_z", dz)
	area.set_meta("is_left", is_left)
	area.set_meta("opening", false)
	area.set_meta("spawned", false)
	area.body_entered.connect(func(b): _on_door_enter(b, area))
	area.body_exited.connect(func(b): _on_door_exit(b))
	frame_body.add_child(area)

	frame_body.position = Vector3(door_x, 0, dz)
	panel_body.position = Vector3(door_x, 0, dz)
	add_child(frame_body)
	add_child(panel_body)

func _frame_piece(pos: Vector3, size: Vector3) -> MeshInstance3D:
	var m: MeshInstance3D = MeshInstance3D.new()
	var b: BoxMesh = BoxMesh.new()
	b.size = size
	b.material = mat_frame
	m.mesh = b
	m.position = pos
	return m

func _indicator(x: float) -> MeshInstance3D:
	var m: MeshInstance3D = MeshInstance3D.new()
	var b: BoxMesh = BoxMesh.new()
	b.size = Vector3(0.08, 0.25, 0.9)
	var imat: StandardMaterial3D = StandardMaterial3D.new()
	imat.albedo_color = Color(0.1, 1.0, 0.2)
	imat.emission_enabled = true
	imat.emission = Color(0.1, 1.0, 0.2)
	imat.emission_energy_multiplier = 5.0
	b.material = imat
	m.mesh = b
	m.position = Vector3(x, 3.75, 0.5)
	return m

func _on_door_enter(body: Node, area: Area3D) -> void:
	if body.is_in_group("player") and current_door_area == null:
		current_door_area = area
		var dt: String = area.get_meta("door_type")
		if UIManager != null:
			if dt == "exit":
				UIManager.show_interaction_prompt("按E - 打开安全门逃离")
			elif dt == "locked":
				UIManager.show_interaction_prompt("按E - 门已锁死")
			else:
				UIManager.show_interaction_prompt("按E - 打开房门")

func _on_door_exit(body: Node) -> void:
	if body.is_in_group("player"):
		current_door_area = null
		if UIManager != null:
			UIManager.hide_interaction_prompt()

func _use_door(area: Area3D) -> void:
	var dt: String = area.get_meta("door_type")
	var opening: bool = area.get_meta("opening")
	if opening:
		return
	if dt == "locked":
		if UIManager != null:
			UIManager.show_toast("门已锁死")
		return
	area.set_meta("opening", true)
	var panel_body: Node = area.get_meta("panel_body")
	var tw: Tween = create_tween()
	tw.tween_property(panel_body, "position:z", panel_body.position.z + DOOR_WIDTH + 0.3, 0.8)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.set_ease(Tween.EASE_IN_OUT)
	if dt == "exit":
		if UIManager != null:
			UIManager.show_announcement("安全门已打开 - 快进去！", 3.0)
		var close_t: Timer = Timer.new()
		close_t.wait_time = 2.0
		close_t.one_shot = true
		close_t.timeout.connect(func():
			var door_x: float = panel_body.position.x
			var door_z_orig: float = area.get_meta("door_z")
			var tw2: Tween = create_tween()
			tw2.tween_property(panel_body, "position", Vector3(door_x, 0.0, door_z_orig), 0.6)
			tw2.set_trans(Tween.TRANS_QUAD)
			tw2.set_ease(Tween.EASE_IN_OUT)
			area.set_meta("opening", false)
			close_t.queue_free()
		)
		add_child(close_t)
		close_t.start()
		return
	if dt == "monster":
		var spawned: bool = area.get_meta("spawned")
		if not spawned:
			area.set_meta("spawned", true)
			var dz: float = area.get_meta("door_z")
			var is_left: bool = area.get_meta("is_left")
			var sign: float = -1.0 if is_left else 1.0
			var sx: float = sign * (HALF_W + ROOM_DEPTH / 2.0)
			var delay_t: Timer = Timer.new()
			delay_t.wait_time = 0.5
			delay_t.one_shot = true
			delay_t.timeout.connect(func():
				var m: Node = MONSTER_SCENE.instantiate()
				m.position = Vector3(sx, 1.0, dz)
				add_child(m)
				if UIManager != null:
					UIManager.show_toast("房间里有怪物！")
				delay_t.queue_free()
			)
			add_child(delay_t)
			delay_t.start()
	elif dt == "health":
		var dz2: float = area.get_meta("door_z")
		var is_left2: bool = area.get_meta("is_left")
		var sign2: float = -1.0 if is_left2 else 1.0
		var hx: float = sign2 * (HALF_W + ROOM_DEPTH / 2.0)
		var hp: Node = HEALTH_SCENE.instantiate()
		hp.position = Vector3(hx, 1.0, dz2)
		add_child(hp)

# ============================================================
# 逃生走廊 + 安全中间层
# ============================================================
func _build_escape_and_hub() -> void:
	var ec_start_x: float = HALF_W
	var ec_end_x: float = ec_start_x + ESCAPE_LENGTH
	var ec_center_x: float = (ec_start_x + ec_end_x) / 2.0
	var ec_half_w: float = ESCAPE_WIDTH / 2.0
	_make_solid(Vector3(ec_center_x, -0.1, EXIT_Z), Vector3(ESCAPE_LENGTH, 0.2, ESCAPE_WIDTH), mat_floor)
	_make_solid(Vector3(ec_center_x, CORRIDOR_HEIGHT + 0.1, EXIT_Z), Vector3(ESCAPE_LENGTH, 0.2, ESCAPE_WIDTH), mat_ceiling)
	_make_solid(Vector3(ec_center_x, CORRIDOR_HEIGHT / 2.0, EXIT_Z - ec_half_w), Vector3(ESCAPE_LENGTH, CORRIDOR_HEIGHT, WALL_THICK), mat_wall)
	_make_solid(Vector3(ec_center_x, CORRIDOR_HEIGHT / 2.0, EXIT_Z + ec_half_w), Vector3(ESCAPE_LENGTH, CORRIDOR_HEIGHT, WALL_THICK), mat_wall)
	for i in range(4):
		var elx: float = ec_start_x + 7.0 + i * 12.0
		var el: OmniLight3D = OmniLight3D.new()
		el.light_color = Color(0.5, 0.9, 0.6)
		el.light_energy = 1.3
		el.omni_range = 8.0
		el.position = Vector3(elx, CORRIDOR_HEIGHT - 0.5, EXIT_Z)
		add_child(el)
	# 安全中间层
	var hub_start_x: float = ec_end_x
	var hub_end_x: float = hub_start_x + HUB_SIZE
	var hub_center_x: float = (hub_start_x + hub_end_x) / 2.0
	var hub_half: float = HUB_SIZE / 2.0
	var hub_start_z: float = EXIT_Z - hub_half
	var hub_end_z: float = EXIT_Z + hub_half
	_make_solid(Vector3(hub_center_x, -0.1, EXIT_Z), Vector3(HUB_SIZE, 0.2, HUB_SIZE), mat_floor)
	_make_solid(Vector3(hub_center_x, HUB_HEIGHT + 0.1, EXIT_Z), Vector3(HUB_SIZE, 0.2, HUB_SIZE), mat_ceiling)
	_make_solid(Vector3(hub_end_x, HUB_HEIGHT / 2.0, EXIT_Z), Vector3(WALL_THICK, HUB_HEIGHT, HUB_SIZE), mat_wall)
	_make_solid(Vector3(hub_center_x, HUB_HEIGHT / 2.0, hub_start_z), Vector3(HUB_SIZE, HUB_HEIGHT, WALL_THICK), mat_wall)
	_make_solid(Vector3(hub_center_x, HUB_HEIGHT / 2.0, hub_end_z), Vector3(HUB_SIZE, HUB_HEIGHT, WALL_THICK), mat_wall)
	_make_solid(Vector3(hub_start_x, HUB_HEIGHT / 2.0, 446.25), Vector3(WALL_THICK, HUB_HEIGHT, 6.5), mat_wall)
	_make_solid(Vector3(hub_start_x, HUB_HEIGHT / 2.0, 455.75), Vector3(WALL_THICK, HUB_HEIGHT, 6.5), mat_wall)
	for i in range(4):
		var lx: float = hub_start_x + 3.0 + (i % 2) * 8.0
		var lz: float = EXIT_Z - 5.0 + int(i / 2) * 10.0
		var l: OmniLight3D = OmniLight3D.new()
		l.light_color = Color(1.0, 0.98, 0.9)
		l.light_energy = 3.0
		l.omni_range = 12.0
		l.position = Vector3(lx, HUB_HEIGHT - 0.5, lz)
		add_child(l)
	var sign: MeshInstance3D = MeshInstance3D.new()
	var sb: BoxMesh = BoxMesh.new()
	sb.size = Vector3(0.1, 0.8, 3.0)
	var smat: StandardMaterial3D = StandardMaterial3D.new()
	smat.albedo_color = Color(0.1, 0.8, 0.2)
	smat.emission_enabled = true
	smat.emission = Color(0.1, 1.0, 0.2)
	smat.emission_energy_multiplier = 2.0
	sb.material = smat
	sign.mesh = sb
	sign.position = Vector3(hub_start_x + 1.5, 3.5, EXIT_Z)
	add_child(sign)
	# 井口(hub右下角) - 默认隐藏, 按按钮后出现
	var well_x: float = hub_end_x - 3.0
	var well_z: float = hub_end_z - 3.0
	var well_group: Node3D = Node3D.new()
	well_group.name = "WellGroup"
	well_group.visible = false
	add_child(well_group)
	# 井口黑洞
	var well_hole: MeshInstance3D = MeshInstance3D.new()
	var hole_box: BoxMesh = BoxMesh.new()
	hole_box.size = Vector3(2.5, 0.1, 2.5)
	var hole_mat: StandardMaterial3D = StandardMaterial3D.new()
	hole_mat.albedo_color = Color(0, 0, 0)
	hole_box.material = hole_mat
	well_hole.mesh = hole_box
	well_hole.position = Vector3(well_x, 0.05, well_z)
	well_group.add_child(well_hole)
	# 井沿
	var well_ring: MeshInstance3D = MeshInstance3D.new()
	var ring_box: BoxMesh = BoxMesh.new()
	ring_box.size = Vector3(3.0, 0.3, 3.0)
	var ring_mat: StandardMaterial3D = StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.3, 0.3, 0.35)
	ring_mat.metallic = 0.8
	ring_box.material = ring_mat
	well_ring.mesh = ring_box
	well_ring.position = Vector3(well_x, 0.1, well_z)
	well_group.add_child(well_ring)
	# 井壁(垂直向下)
	for sx in [-1.4, 1.4]:
		var wall: MeshInstance3D = MeshInstance3D.new()
		var wb: BoxMesh = BoxMesh.new()
		wb.size = Vector3(0.2, 4.0, 2.8)
		wb.material = ring_mat
		wall.mesh = wb
		wall.position = Vector3(well_x + sx, -2.0, well_z)
		well_group.add_child(wall)
	for sz in [-1.4, 1.4]:
		var wall2: MeshInstance3D = MeshInstance3D.new()
		var wb2: BoxMesh = BoxMesh.new()
		wb2.size = Vector3(2.8, 4.0, 0.2)
		wb2.material = ring_mat
		wall2.mesh = wb2
		wall2.position = Vector3(well_x, -2.0, well_z + sz)
		well_group.add_child(wall2)
	# 井口交互区域(默认隐藏)
	well_area = Area3D.new()
	well_area.name = "WellToLevel3"
	var well_cs: CollisionShape3D = CollisionShape3D.new()
	var well_shape: BoxShape3D = BoxShape3D.new()
	well_shape.size = Vector3(2.5, 3.0, 2.5)
	well_cs.shape = well_shape
	well_area.add_child(well_cs)
	well_area.position = Vector3(well_x, 1.0, well_z)
	well_area.body_entered.connect(_on_well_enter)
	well_area.visible = false
	well_area.monitoring = false
	add_child(well_area)
	# 井口指示灯
	var well_light: OmniLight3D = OmniLight3D.new()
	well_light.light_color = Color(0.3, 0.6, 1.0)
	well_light.light_energy = 2.0
	well_light.omni_range = 6.0
	well_light.position = Vector3(well_x, 2.5, well_z)
	well_group.add_child(well_light)
	# 开启井口的按钮(安全房左墙)
	var btn_x: float = hub_start_x + 2.0
	var btn_z: float = EXIT_Z - 5.0
	var btn_base: MeshInstance3D = MeshInstance3D.new()
	var bb: BoxMesh = BoxMesh.new()
	bb.size = Vector3(0.15, 0.8, 0.5)
	var bmat: StandardMaterial3D = StandardMaterial3D.new()
	bmat.albedo_color = Color(0.3, 0.3, 0.35)
	bmat.metallic = 0.8
	bb.material = bmat
	btn_base.mesh = bb
	btn_base.position = Vector3(btn_x, 1.5, btn_z)
	add_child(btn_base)
	var btn_top: MeshInstance3D = MeshInstance3D.new()
	var bt: CylinderMesh = CylinderMesh.new()
	bt.top_radius = 0.15
	bt.bottom_radius = 0.15
	bt.height = 0.12
	var btmat: StandardMaterial3D = StandardMaterial3D.new()
	btmat.albedo_color = Color(0.8, 0.1, 0.1)
	btmat.emission_enabled = true
	btmat.emission = Color(1.0, 0.2, 0.15)
	btmat.emission_energy_multiplier = 2.0
	bt.material = btmat
	btn_top.mesh = bt
	btn_top.rotation.x = deg_to_rad(90)
	btn_top.position = Vector3(btn_x + 0.1, 1.8, btn_z)
	add_child(btn_top)
	var btn_area: Area3D = Area3D.new()
	btn_area.name = "WellButton"
	var btn_cs: CollisionShape3D = CollisionShape3D.new()
	var btn_shape: BoxShape3D = BoxShape3D.new()
	btn_shape.size = Vector3(2.0, 2.5, 2.0)
	btn_cs.shape = btn_shape
	btn_area.add_child(btn_cs)
	btn_area.position = Vector3(btn_x + 0.5, 1.5, btn_z)
	btn_area.body_entered.connect(_on_button_enter)
	btn_area.body_exited.connect(_on_button_exit)
	add_child(btn_area)

# ============================================================
# 警报灯系统
# ============================================================
func build_alarm_system() -> void:
	var we: WorldEnvironment = WorldEnvironment.new()
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0, 0, 0)
	env.ambient_light_energy = 0.0
	env.tonemap_exposure = 0.6
	we.environment = env
	add_child(we)
	var z: float = 25.0
	while z < MAIN_END - 10.0:
		var ll: OmniLight3D = OmniLight3D.new()
		ll.light_color = Color(1.0, 0.1, 0.1)
		ll.light_energy = 1.0
		ll.omni_range = 6.0
		ll.position = Vector3(-HALF_W + 0.5, CORRIDOR_HEIGHT - 0.4, z)
		var ll_bulb: MeshInstance3D = MeshInstance3D.new()
		var ll_box: BoxMesh = BoxMesh.new()
		ll_box.size = Vector3(0.15, 0.15, 0.6)
		var ll_mat: StandardMaterial3D = StandardMaterial3D.new()
		ll_mat.emission_enabled = true
		ll_mat.emission = Color(1.0, 0.1, 0.1)
		ll_mat.emission_energy_multiplier = 4.0
		ll_box.material = ll_mat
		ll_bulb.mesh = ll_box
		ll.add_child(ll_bulb)
		add_child(ll)
		alarm_lights.append(ll)
		var lr: OmniLight3D = OmniLight3D.new()
		lr.light_color = Color(1.0, 0.1, 0.1)
		lr.light_energy = 1.0
		lr.omni_range = 6.0
		lr.position = Vector3(HALF_W - 0.5, CORRIDOR_HEIGHT - 0.4, z)
		var lr_bulb: MeshInstance3D = MeshInstance3D.new()
		var lr_box: BoxMesh = BoxMesh.new()
		lr_box.size = Vector3(0.15, 0.15, 0.6)
		var lr_mat: StandardMaterial3D = StandardMaterial3D.new()
		lr_mat.emission_enabled = true
		lr_mat.emission = Color(1.0, 0.1, 0.1)
		lr_mat.emission_energy_multiplier = 4.0
		lr_box.material = lr_mat
		lr_bulb.mesh = lr_box
		lr.add_child(lr_bulb)
		add_child(lr)
		alarm_lights.append(lr)
		_build_floor_light(-2.5, z)
		_build_floor_light(2.5, z)
		z += 30.0

func _build_floor_light(x: float, z: float) -> void:
	var m: MeshInstance3D = MeshInstance3D.new()
	var b: BoxMesh = BoxMesh.new()
	b.size = Vector3(0.3, 0.05, 0.3)
	var fm: StandardMaterial3D = StandardMaterial3D.new()
	fm.albedo_color = Color(1.0, 0.3, 0.1)
	fm.emission_enabled = true
	fm.emission = Color(1.0, 0.2, 0.05)
	fm.emission_energy_multiplier = 0.7
	b.material = fm
	m.mesh = b
	m.position = Vector3(x, 0.03, z + 10.0)
	add_child(m)

# ============================================================
# 导航
# ============================================================
func _build_navigation() -> void:
	var nav: NavigationRegion3D = NavigationRegion3D.new()
	var nm: NavigationMesh = NavigationMesh.new()
	nm.agent_radius = 0.6
	nm.agent_height = 2.0
	nm.agent_max_climb = 0.5
	nm.cell_size = 0.3
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav.navigation_mesh = nm
	add_child(nav)
	nav.bake_navigation_mesh(false)

# ============================================================
# 每帧
# ============================================================
func _process(delta: float) -> void:
	alarm_timer += delta
	var phase: int = int(alarm_timer / 0.6) % 3
	for i in range(alarm_lights.size()):
		var l: OmniLight3D = alarm_lights[i]
		if l == null or not is_instance_valid(l):
			continue
		if phase == 0:
			l.visible = (i % 2 == 0)
		elif phase == 1:
			l.visible = (i % 2 == 1)
		else:
			l.visible = false
	if Input.is_action_just_pressed("interact"):
		if button_inside and not button_pressed:
			_open_well()
		elif current_door_area != null:
			_use_door(current_door_area)
		elif current_gate_area != null:
			_start_test(current_gate_area)
	if test_started and countdown > 0.0:
		countdown -= delta
		if countdown <= 20.0 and not warning_shown:
			if AudioManager != null:
				AudioManager.play_sfx("alarm_breach", 0.7)
			warning_shown = true
			if UIManager != null:
				UIManager.show_announcement("温馨提示：请快速前往安全房间，实验体即将释放", 4.0)
		if countdown <= 0.0 and not chaser_released:
			_release_chaser()
	_check_hub_reached()

func _release_chaser() -> void:
	chaser_released = true
	if AudioManager != null:
		AudioManager.play_sfx("metal_collapse", 0.9)
		AudioManager.play_sfx("boss_roar", 0.8)
	if ceiling_trap != null:
		var tw: Tween = create_tween()
		tw.tween_property(ceiling_trap, "position:y", CORRIDOR_HEIGHT + 3.0, 1.2)
	chaser = CHASER_SCENE.instantiate()
	chaser.position = Vector3(0, 2.0, 10.0)
	add_child(chaser)
	if UIManager != null:
		UIManager.show_announcement("实验体已释放！立即撤离！", 5.0)

func _on_button_enter(body: Node) -> void:
	if body.is_in_group("player") and hub_reached and not button_pressed:
		button_inside = true
		if UIManager != null:
			UIManager.show_interaction_prompt("按E - 开启地下通道")

func _on_button_exit(body: Node) -> void:
	if body.is_in_group("player"):
		button_inside = false
		if UIManager != null:
			UIManager.hide_interaction_prompt()

func _open_well() -> void:
	button_pressed = true
	well_opened = true
	var wg: Node = get_node_or_null("WellGroup")
	if wg != null:
		wg.visible = true
	if well_area != null:
		well_area.visible = true
		well_area.monitoring = true
	if UIManager != null:
		UIManager.show_toast("地下通道已开启! 跳进去!")
		UIManager.show_announcement("地下通道已开启 - 跳入洞口前往地下实验区", 4.0)

func _on_well_enter(body: Node) -> void:
	if body.is_in_group("player") and well_opened:
		# 玩家跳进洞, 自动传送到第三关
		if UIManager != null:
			UIManager.hide_interaction_prompt()
		get_tree().change_scene_to_file("res://scenes/level3_maze.tscn")

func _check_hub_reached() -> void:
	if hub_reached:
		return
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	if player.global_position.x > HALF_W + ESCAPE_LENGTH - 1.0:
		hub_reached = true
		if UIManager != null:
			UIManager.show_announcement("已抵达安全区 - 暂时安全", 5.0)

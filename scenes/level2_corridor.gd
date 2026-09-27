extends Node3D

## 第二关：狭长逃生走廊 v4
## 通道7米宽，两侧实心墙，有怪门后建独立小房间，锁死门直接贴墙

const CORRIDOR_LENGTH: float = 500.0
const CORRIDOR_WIDTH: float = 7.0
const CORRIDOR_HEIGHT: float = 4.0
const ROOM_SIZE: float = 2.2
const DOOR_SPACING: float = 22.0
const DOOR_WIDTH: float = 2.0
const DOOR_HEIGHT: float = 4.0

var chaser_scene: PackedScene = preload("res://modules/monster/chaser_monster.tscn")
var monster_scene: PackedScene = preload("res://modules/monster/base_monster.tscn")
var health_scene: PackedScene = preload("res://modules/item/health_pickup.tscn")
var chaser: Node = null
var button_pressed: bool = false
var countdown_timer: float = 0.0
var ceiling_open: bool = false
var ceiling_trap: MeshInstance3D = null
var exit_door_open: bool = false
var alarm_lights: Array = []
var alarm_state: bool = false
var alarm_timer: float = 0.0

func _ready() -> void:
	randomize()
	_build_structure()
	_build_connection_room()
	_build_doors_and_rooms()
	_build_alarm_lights()
	_build_floor_lights()
	_build_safe_zone()
	_build_navigation()
	if UIManager != null:
		UIManager.show_announcement("紧急疏散通道 - B区", 3.0)
		UIManager.show_announcement("前方通道已封锁 - 请寻找安全出口", 3.0)
		UIManager.show_announcement("警告：部分房门后可能有实验体", 3.0)

func _build_structure() -> void:
	var half_w: float = CORRIDOR_WIDTH / 2
	# 地板（只有通道宽度）
	_make_floor(Vector3(0, -0.1, CORRIDOR_LENGTH / 2), Vector3(CORRIDOR_WIDTH + ROOM_SIZE * 2 + 4.0, 0.2, CORRIDOR_LENGTH))
	# 天花板（只有通道宽度）
	_make_ceiling(Vector3(0, CORRIDOR_HEIGHT + 0.1, CORRIDOR_LENGTH / 2), Vector3(CORRIDOR_WIDTH + ROOM_SIZE * 2 + 4.0, 0.2, CORRIDOR_LENGTH))
	# 尽头墙（封死走廊正前方，加高到6米防止透光）
	_make_wall(Vector3(0, 3.0, CORRIDOR_LENGTH), Vector3(CORRIDOR_WIDTH + ROOM_SIZE * 2 + 4.0, 6.0, 0.3))
	# 入口由连接室处理
	# 左右外墙（分段，留门洞）
	var door_count: int = int((CORRIDOR_LENGTH - 40) / DOOR_SPACING)
	for i in range(door_count):
		var z_center: float = 55.0 + i * DOOR_SPACING
		if z_center > CORRIDOR_LENGTH - 30:
			break
		var seg_start: float = z_center - DOOR_SPACING / 2
		var seg_end: float = z_center + DOOR_SPACING / 2
		var door_start: float = z_center - DOOR_WIDTH / 2
		var door_end: float = z_center + DOOR_WIDTH / 2
		# 左墙
		if door_start > seg_start:
			_make_wall(Vector3(-half_w, CORRIDOR_HEIGHT / 2, (seg_start + door_start) / 2), Vector3(0.3, CORRIDOR_HEIGHT, door_start - seg_start))
		if seg_end > door_end:
			_make_wall(Vector3(-half_w, CORRIDOR_HEIGHT / 2, (door_end + seg_end) / 2), Vector3(0.3, CORRIDOR_HEIGHT, seg_end - door_end))
		# 右墙
		if door_start > seg_start:
			_make_wall(Vector3(half_w, CORRIDOR_HEIGHT / 2, (seg_start + door_start) / 2), Vector3(0.3, CORRIDOR_HEIGHT, door_start - seg_start))
		if seg_end > door_end:
			_make_wall(Vector3(half_w, CORRIDOR_HEIGHT / 2, (door_end + seg_end) / 2), Vector3(0.3, CORRIDOR_HEIGHT, seg_end - door_end))
	# 补充墙段（第一个门之前和最后一个门之后）
	var first_z: float = 55.0 - DOOR_SPACING / 2
	if first_z > 0:
		_make_wall(Vector3(-half_w, CORRIDOR_HEIGHT / 2, first_z / 2), Vector3(0.3, CORRIDOR_HEIGHT, first_z))
		_make_wall(Vector3(half_w, CORRIDOR_HEIGHT / 2, first_z / 2), Vector3(0.3, CORRIDOR_HEIGHT, first_z))


func _build_connection_room() -> void:
	# 入口连接室：z=0到z=20，玩家从第一关过来后进入这里
	var half_w: float = CORRIDOR_WIDTH / 2
	# 连接室地板和天花板（已经由主结构覆盖，这里只建墙）
	# 两侧墙
	_make_wall(Vector3(-half_w, CORRIDOR_HEIGHT / 2, 10.0), Vector3(0.3, CORRIDOR_HEIGHT, 20.0))
	_make_wall(Vector3(half_w, CORRIDOR_HEIGHT / 2, 10.0), Vector3(0.3, CORRIDOR_HEIGHT, 20.0))
	# 入口墙（z=0，留中间通道口给第一关过来）
	_make_wall(Vector3(-half_w / 2 - 0.15, CORRIDOR_HEIGHT / 2, 0), Vector3(half_w, CORRIDOR_HEIGHT, 0.3))
	_make_wall(Vector3(half_w / 2 + 0.15, CORRIDOR_HEIGHT / 2, 0), Vector3(half_w, CORRIDOR_HEIGHT, 0.3))
	# 连接室里的灯（亮的，玩家在这里准备）
	var room_light: OmniLight3D = OmniLight3D.new()
	room_light.light_color = Color(0.9, 0.9, 0.95)
	room_light.light_energy = 2.0
	room_light.omni_range = 15.0
	room_light.position = Vector3(0, CORRIDOR_HEIGHT - 0.5, 10.0)
	add_child(room_light)
	# 出口大门（整个通道大小，z=20）
	var big_door: StaticBody3D = StaticBody3D.new()
	big_door.name = "ConnectionDoor"
	# 门框
	var frame_mat: StandardMaterial3D = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.4, 0.43, 0.48)
	frame_mat.metallic = 0.8
	frame_mat.roughness = 0.35
	# 门板材质
	var panel_mat: StandardMaterial3D = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.55, 0.58, 0.62)
	panel_mat.metallic = 0.7
	panel_mat.roughness = 0.4
	panel_mat.emission_enabled = true
	panel_mat.emission = Color(0.2, 0.15, 0.05)
	panel_mat.emission_energy_multiplier = 0.5
	# 门板容器
	var door_hinge: Node3D = Node3D.new()
	door_hinge.name = "BigDoorPanel"
	big_door.add_child(door_hinge)
	# 门板（整个通道大小）
	var panel: MeshInstance3D = MeshInstance3D.new()
	var p_box: BoxMesh = BoxMesh.new()
	p_box.size = Vector3(CORRIDOR_WIDTH - 0.2, CORRIDOR_HEIGHT - 0.2, 0.2)
	p_box.material = panel_mat
	panel.mesh = p_box
	panel.position = Vector3(0, CORRIDOR_HEIGHT / 2, 0)
	door_hinge.add_child(panel)
	# 加强筋
	for i in range(5):
		var rib: MeshInstance3D = MeshInstance3D.new()
		var rib_box: BoxMesh = BoxMesh.new()
		rib_box.size = Vector3(CORRIDOR_WIDTH - 0.5, 0.1, 0.25)
		rib_box.material = frame_mat
		rib.mesh = rib_box
		rib.position = Vector3(0, 0.8 + i * 0.7, 0)
		door_hinge.add_child(rib)
	# 碰撞
	var col: CollisionShape3D = CollisionShape3D.new()
	var col_shape: BoxShape3D = BoxShape3D.new()
	col_shape.size = Vector3(CORRIDOR_WIDTH - 0.2, CORRIDOR_HEIGHT - 0.2, 0.25)
	col.shape = col_shape
	col.position = Vector3(0, CORRIDOR_HEIGHT / 2, 0)
	door_hinge.add_child(col)
	# 交互区域
	var area: Area3D = Area3D.new()
	var ac: CollisionShape3D = CollisionShape3D.new()
	var ashape: BoxShape3D = BoxShape3D.new()
	ashape.size = Vector3(CORRIDOR_WIDTH, CORRIDOR_HEIGHT, 4.0)
	ac.shape = ashape
	ac.position.y = CORRIDOR_HEIGHT / 2
	area.add_child(ac)
	area.set_meta("is_big_door", true)
	area.set_meta("hinge", door_hinge)
	area.set_meta("is_opening", false)
	area.body_entered.connect(func(body): _on_big_door_enter(body, area))
	area.body_exited.connect(func(body): _on_big_door_exit(body))
	big_door.add_child(area)
	big_door.position = Vector3(0, 0, 20.0)
	add_child(big_door)
	# 天花板陷阱（怪物从这里掉下来）
	ceiling_trap = MeshInstance3D.new()
	var b: BoxMesh = BoxMesh.new()
	b.size = Vector3(4.0, 0.2, 4.0)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.3, 0.35)
	b.material = mat
	ceiling_trap.mesh = b
	ceiling_trap.position = Vector3(0, CORRIDOR_HEIGHT - 0.1, 10.0)
	add_child(ceiling_trap)

func _on_big_door_enter(body: Node, area: Area3D) -> void:
	if body.is_in_group("player") and not button_pressed and not _btn_prompt:
		_btn_prompt = true
		_cur_big_door = area
		if UIManager != null:
			UIManager.show_interaction_prompt("按E - 开启测试通道")

func _on_big_door_exit(body: Node) -> void:
	if body.is_in_group("player"):
		_btn_prompt = false
		_cur_big_door = null
		if UIManager != null:
			UIManager.hide_interaction_prompt()

func _open_big_door(area: Area3D) -> void:
	if button_pressed:
		return
	button_pressed = true
	countdown_timer = 15.0
	_btn_prompt = false
	_cur_big_door = null
	if UIManager != null:
		UIManager.hide_interaction_prompt()
		UIManager.show_announcement("测试程序已启动", 3.0)
		UIManager.show_announcement("警告：实验体收容协议解除", 3.0)
		UIManager.show_announcement("所有人员请立即前往安全门", 3.0)
		UIManager.show_announcement("15秒后实验体将被释放", 4.0)
	var hinge: Node = area.get_meta("hinge")
	# 大门向上收起（滑动开门）
	var tw: Tween = create_tween()
	tw.tween_property(hinge, "position:y", CORRIDOR_HEIGHT + 1.0, 1.5)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.set_ease(Tween.EASE_IN_OUT)

func _build_safe_zone() -> void:
	# 安全区建在走廊右侧（出口门旁边），大房间亮灯
	# 出口门在z=470左右的右侧，安全区从x=5.7到x=25.7，z=440到z=500
	var room_left: float = CORRIDOR_WIDTH / 2 + ROOM_SIZE  # x=5.7
	var room_right: float = room_left + 20.0  # x=25.7
	var room_center_x: float = (room_left + room_right) / 2  # x=15.7
	var room_z_start: float = 440.0
	var room_z_end: float = 500.0
	var room_center_z: float = (room_z_start + room_z_end) / 2  # z=470
	var room_width: float = room_right - room_left  # 20米
	var room_length: float = room_z_end - room_z_start  # 60米
	# 地板
	_make_floor(Vector3(room_center_x, -0.1, room_center_z), Vector3(room_width, 0.2, room_length))
	# 天花板（高6米）
	_make_ceiling(Vector3(room_center_x, 6.1, room_center_z), Vector3(room_width, 0.2, room_length))
	# 右侧墙
	_make_wall(Vector3(room_right, 3.0, room_center_z), Vector3(0.3, 6.0, room_length))
	# 前墙（z=440）
	_make_wall(Vector3(room_center_x, 3.0, room_z_start), Vector3(room_width, 6.0, 0.3))
	# 后墙（z=500）
	_make_wall(Vector3(room_center_x, 3.0, room_z_end), Vector3(room_width, 6.0, 0.3))
	# 左侧墙（x=5.7），只在出口门位置(z=451)留2米宽的口
	# 第一段：z=440到450
	_make_wall(Vector3(room_left, 3.0, 445.0), Vector3(0.3, 6.0, 10.0))
	# 第二段：z=452到500
	_make_wall(Vector3(room_left, 3.0, 476.0), Vector3(0.3, 6.0, 48.0))
	# 安全区门（在留口位置，z=451，朝向走廊）
	var safe_door: StaticBody3D = StaticBody3D.new()
	var sd_panel: MeshInstance3D = MeshInstance3D.new()
	var sd_box: BoxMesh = BoxMesh.new()
	sd_box.size = Vector3(0.15, 3.8, 1.9)
	var sd_mat: StandardMaterial3D = StandardMaterial3D.new()
	sd_mat.albedo_color = Color(0.2, 0.5, 0.25)
	sd_mat.metallic = 0.6
	sd_mat.roughness = 0.4
	sd_mat.emission_enabled = true
	sd_mat.emission = Color(0.05, 0.2, 0.08)
	sd_mat.emission_energy_multiplier = 0.5
	sd_box.material = sd_mat
	sd_panel.mesh = sd_box
	sd_panel.position = Vector3(0, 1.9, 0)
	safe_door.add_child(sd_panel)
	var sd_col: CollisionShape3D = CollisionShape3D.new()
	var sd_colshape: BoxShape3D = BoxShape3D.new()
	sd_colshape.size = Vector3(0.17, 3.8, 1.9)
	sd_col.shape = sd_colshape
	sd_col.position.y = 1.9
	safe_door.add_child(sd_col)
	safe_door.position = Vector3(room_left, 0, 451.0)
	add_child(safe_door)
	# 安全区灯光（亮的，4盏）
	for i in range(4):
		var lx: float = room_left + 4.0 + (i % 2) * 12.0
		var lz: float = room_z_start + 15.0 + int(i / 2) * 30.0
		var l: OmniLight3D = OmniLight3D.new()
		l.light_color = Color(1.0, 0.98, 0.9)
		l.light_energy = 3.0
		l.omni_range = 15.0
		l.position = Vector3(lx, 5.5, lz)
		add_child(l)
	# 安全区标识（绿色发光牌）
	var sign: MeshInstance3D = MeshInstance3D.new()
	var sb: BoxMesh = BoxMesh.new()
	sb.size = Vector3(0.1, 1.0, 3.0)
	var smat: StandardMaterial3D = StandardMaterial3D.new()
	smat.albedo_color = Color(0.1, 0.8, 0.2)
	smat.emission_enabled = true
	smat.emission = Color(0.1, 1.0, 0.2)
	smat.emission_energy_multiplier = 2.0
	sb.material = smat
	sign.mesh = sb
	sign.position = Vector3(room_left + 1.0, 4.0, room_center_z)
	add_child(sign)

func _make_floor(pos: Vector3, size: Vector3) -> void:
	var floor: StaticBody3D = StaticBody3D.new()
	var m: MeshInstance3D = MeshInstance3D.new()
	var b: BoxMesh = BoxMesh.new()
	b.size = size
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.22)
	mat.roughness = 0.9
	b.material = mat
	m.mesh = b
	floor.add_child(m)
	var c: CollisionShape3D = CollisionShape3D.new()
	var s: BoxShape3D = BoxShape3D.new()
	s.size = size
	c.shape = s
	floor.add_child(c)
	floor.position = pos
	add_child(floor)

func _make_ceiling(pos: Vector3, size: Vector3) -> void:
	var m: MeshInstance3D = MeshInstance3D.new()
	var b: BoxMesh = BoxMesh.new()
	b.size = size
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.18, 0.2)
	b.material = mat
	m.mesh = b
	m.position = pos
	add_child(m)

func _make_wall(pos: Vector3, size: Vector3) -> void:
	var wall: StaticBody3D = StaticBody3D.new()
	var m: MeshInstance3D = MeshInstance3D.new()
	var b: BoxMesh = BoxMesh.new()
	b.size = size
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.28, 0.28, 0.32)
	mat.roughness = 0.85
	b.material = mat
	m.mesh = b
	wall.add_child(m)
	var c: CollisionShape3D = CollisionShape3D.new()
	var s: BoxShape3D = BoxShape3D.new()
	s.size = size
	c.shape = s
	wall.add_child(c)
	wall.position = pos
	add_child(wall)

func _build_doors_and_rooms() -> void:
	var half_w: float = CORRIDOR_WIDTH / 2
	var door_count: int = int((CORRIDOR_LENGTH - 40) / DOOR_SPACING)
	var idx: int = 0
	for i in range(door_count):
		var z_pos: float = 55.0 + i * DOOR_SPACING
		if z_pos > CORRIDOR_LENGTH - 30:
			break
		var is_exit: bool = (i == door_count - 1)
		# 左侧门（不是出口）
		_make_door(z_pos, true, idx, false, half_w)
		idx += 1
		# 右侧门（最后一扇是出口）
		_make_door(z_pos, false, idx, is_exit, half_w)
		idx += 1

func _make_door(z_pos: float, is_left: bool, index: int, is_exit: bool, half_w: float) -> void:
	var door_x: float = -half_w if is_left else half_w
	var is_locked: bool = not is_exit and (index % 3 == 0)
	var has_monster: bool = not is_exit and not is_locked and (index % 5 != 2)
	var has_health: bool = not is_exit and not is_locked and (index % 5 == 2)
	# 所有门都建小房间，外观一致；出口门不建后墙，直接连通安全区
	_build_small_room(z_pos, is_left, half_w, is_exit)
	# 门的根节点
	var door: StaticBody3D = StaticBody3D.new()
	door.name = "Door_%d" % index
	# 门框材质
	var frame_mat: StandardMaterial3D = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.4, 0.43, 0.48)
	frame_mat.metallic = 0.8
	frame_mat.roughness = 0.35
	# 门板材质（统一钢门颜色）
	var panel_mat: StandardMaterial3D = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.55, 0.58, 0.62)
	panel_mat.metallic = 0.7
	panel_mat.roughness = 0.4
	panel_mat.emission_enabled = true
	panel_mat.emission = Color(0.15, 0.15, 0.18)
	panel_mat.emission_energy_multiplier = 0.3
	# 门框（上下左右四条）
	var frame_thickness: float = 0.15
	var frame_depth: float = 0.2
	# 左门框
	var frame_l: MeshInstance3D = MeshInstance3D.new()
	var fl_box: BoxMesh = BoxMesh.new()
	fl_box.size = Vector3(frame_depth, DOOR_HEIGHT, frame_thickness)
	fl_box.material = frame_mat
	frame_l.mesh = fl_box
	frame_l.position = Vector3(0, DOOR_HEIGHT / 2, -DOOR_WIDTH / 2 - frame_thickness / 2)
	door.add_child(frame_l)
	# 右门框
	var frame_r: MeshInstance3D = MeshInstance3D.new()
	var fr_box: BoxMesh = BoxMesh.new()
	fr_box.size = Vector3(frame_depth, DOOR_HEIGHT, frame_thickness)
	fr_box.material = frame_mat
	frame_r.mesh = fr_box
	frame_r.position = Vector3(0, DOOR_HEIGHT / 2, DOOR_WIDTH / 2 + frame_thickness / 2)
	door.add_child(frame_r)
	# 上门框
	var frame_t: MeshInstance3D = MeshInstance3D.new()
	var ft_box: BoxMesh = BoxMesh.new()
	ft_box.size = Vector3(frame_depth, frame_thickness, DOOR_WIDTH + frame_thickness * 2)
	ft_box.material = frame_mat
	frame_t.mesh = ft_box
	frame_t.position = Vector3(0, DOOR_HEIGHT - frame_thickness / 2, 0)
	door.add_child(frame_t)
	# 门板容器（用于滑动开门）
	var hinge: Node3D = Node3D.new()
	hinge.name = "PanelContainer"
	door.add_child(hinge)
	# 门板
	var panel: MeshInstance3D = MeshInstance3D.new()
	panel.name = "Panel"
	var p_box: BoxMesh = BoxMesh.new()
	p_box.size = Vector3(0.15, DOOR_HEIGHT - 0.2, DOOR_WIDTH - 0.1)
	p_box.material = panel_mat
	panel.mesh = p_box
	panel.position = Vector3(0, DOOR_HEIGHT / 2, 0)
	hinge.add_child(panel)
	# 门板加强筋（横向三条）
	for i in range(3):
		var rib: MeshInstance3D = MeshInstance3D.new()
		var rib_box: BoxMesh = BoxMesh.new()
		rib_box.size = Vector3(0.02, 0.08, DOOR_WIDTH - 0.3)
		rib_box.material = frame_mat
		rib.mesh = rib_box
		rib.position = Vector3(0, 1.0 + i * 1.2, 0)
		hinge.add_child(rib)
	# 门把手
	var handle: MeshInstance3D = MeshInstance3D.new()
	var h_box: BoxMesh = BoxMesh.new()
	h_box.size = Vector3(0.15, 0.12, 0.04)
	var h_mat: StandardMaterial3D = StandardMaterial3D.new()
	h_mat.albedo_color = Color(0.7, 0.7, 0.75)
	h_mat.metallic = 0.9
	h_mat.roughness = 0.2
	h_box.material = h_mat
	handle.mesh = h_box
	handle.position = Vector3(0.1, 1.5, 0.6)
	hinge.add_child(handle)
	# 背面门把手
	var handle2: MeshInstance3D = MeshInstance3D.new()
	var h2_box: BoxMesh = BoxMesh.new()
	h2_box.size = Vector3(0.15, 0.12, 0.04)
	h2_box.material = h_mat
	handle2.mesh = h2_box
	handle2.position = Vector3(-0.1, 1.5, 0.6)
	hinge.add_child(handle2)
	# 观察窗
	var window: MeshInstance3D = MeshInstance3D.new()
	var w_box: BoxMesh = BoxMesh.new()
	w_box.size = Vector3(0.02, 0.5, 0.6)
	var w_mat: StandardMaterial3D = StandardMaterial3D.new()
	w_mat.albedo_color = Color(0.2, 0.3, 0.4)
	w_mat.emission_enabled = true
	w_mat.emission = Color(0.1, 0.2, 0.3)
	w_mat.emission_energy_multiplier = 0.5
	w_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	w_mat.albedo_color = Color(0.2, 0.3, 0.4, 0.7)
	w_box.material = w_mat
	window.mesh = w_box
	window.position = Vector3(0, 2.8, 0)
	hinge.add_child(window)
	# 出口门指示灯（绿色小灯）
	if is_exit:
		var indicator: MeshInstance3D = MeshInstance3D.new()
		var ind_box: BoxMesh = BoxMesh.new()
		ind_box.size = Vector3(0.05, 0.15, 0.15)
		var ind_mat: StandardMaterial3D = StandardMaterial3D.new()
		ind_mat.albedo_color = Color(0.1, 1.0, 0.2)
		ind_mat.emission_enabled = true
		ind_mat.emission = Color(0.1, 1.0, 0.2)
		ind_mat.emission_energy_multiplier = 2.0
		ind_box.material = ind_mat
		indicator.mesh = ind_box
		indicator.position = Vector3(0.1, 3.5, 0.5)
		hinge.add_child(indicator)
		var indicator2: MeshInstance3D = MeshInstance3D.new()
		var ind2_box: BoxMesh = BoxMesh.new()
		ind2_box.size = Vector3(0.05, 0.15, 0.15)
		ind2_box.material = ind_mat
		indicator2.mesh = ind2_box
		indicator2.position = Vector3(-0.1, 3.5, 0.5)
		hinge.add_child(indicator2)
	# 门的碰撞（跟随门板）
	var col: CollisionShape3D = CollisionShape3D.new()
	var col_shape: BoxShape3D = BoxShape3D.new()
	col_shape.size = Vector3(0.17, DOOR_HEIGHT - 0.2, DOOR_WIDTH - 0.1)
	col.shape = col_shape
	col.position = Vector3(0, DOOR_HEIGHT / 2, 0)
	hinge.add_child(col)
	# 交互区域
	var area: Area3D = Area3D.new()
	var ac: CollisionShape3D = CollisionShape3D.new()
	var ashape: BoxShape3D = BoxShape3D.new()
	ashape.size = Vector3(3.0, DOOR_HEIGHT, DOOR_WIDTH + 2.0)
	ac.shape = ashape
	ac.position.y = DOOR_HEIGHT / 2
	area.add_child(ac)
	area.set_meta("door_type", "exit" if is_exit else ("locked" if is_locked else "monster"))
	area.set_meta("door_node", door)
	area.set_meta("hinge", hinge)
	area.set_meta("room_z", z_pos)
	area.set_meta("room_is_left", is_left)
	area.set_meta("has_monster", has_monster)
	area.set_meta("has_health", has_health)
	area.set_meta("spawned", false)
	area.set_meta("is_opening", false)
	area.body_entered.connect(func(body): _on_door_enter(body, area))
	area.body_exited.connect(func(body): _on_door_exit(body))
	door.add_child(area)
	# 门上方小灯指引（微弱发光，让玩家知道这里有门）
	var door_light: OmniLight3D = OmniLight3D.new()
	door_light.light_color = Color(0.6, 0.6, 0.7)
	door_light.light_energy = 0.8
	door_light.omni_range = 4.0
	door_light.position = Vector3(0, CORRIDOR_HEIGHT - 0.5, 0)
	door.add_child(door_light)
	door.position = Vector3(door_x, 0, z_pos)
	add_child(door)

func _build_small_room(z_pos: float, is_left: bool, half_w: float, no_back_wall: bool = false) -> void:
	var room_x: float = 0.0
	var back_x: float = 0.0
	if is_left:
		room_x = -half_w - ROOM_SIZE / 2
		back_x = -half_w - ROOM_SIZE
	else:
		room_x = half_w + ROOM_SIZE / 2
		back_x = half_w + ROOM_SIZE
	# 房间地板
	_make_floor(Vector3(room_x, -0.1, z_pos), Vector3(ROOM_SIZE, 0.2, ROOM_SIZE))
	# 房间天花板
	_make_ceiling(Vector3(room_x, CORRIDOR_HEIGHT + 0.1, z_pos), Vector3(ROOM_SIZE, 0.2, ROOM_SIZE))
	# 后墙（出口门不建后墙，直接连通安全区）
	if not no_back_wall:
		_make_wall(Vector3(back_x, CORRIDOR_HEIGHT / 2, z_pos), Vector3(0.3, CORRIDOR_HEIGHT, ROOM_SIZE))
	# 左侧墙（z-方向）
	_make_wall(Vector3(room_x, CORRIDOR_HEIGHT / 2, z_pos - ROOM_SIZE / 2), Vector3(ROOM_SIZE, CORRIDOR_HEIGHT, 0.3))
	# 右侧墙（z+方向）
	_make_wall(Vector3(room_x, CORRIDOR_HEIGHT / 2, z_pos + ROOM_SIZE / 2), Vector3(ROOM_SIZE, CORRIDOR_HEIGHT, 0.3))

var _door_prompt: bool = false
var _cur_door: Area3D = null

func _on_door_enter(body: Node, area: Area3D) -> void:
	if body.is_in_group("player") and not _door_prompt:
		_door_prompt = true
		_cur_door = area
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
		_door_prompt = false
		_cur_door = null
		if UIManager != null:
			UIManager.hide_interaction_prompt()

func _try_open_door(area: Area3D) -> void:
	var dt: String = area.get_meta("door_type")
	var is_opening: bool = area.get_meta("is_opening")
	if is_opening:
		return
	if dt == "locked":
		if UIManager != null:
			UIManager.show_toast("门已锁死")
		return
	area.set_meta("is_opening", true)
	var hinge: Node = area.get_meta("hinge")
	var door: Node = area.get_meta("door_node")
	# 开门动画：门板向一侧滑动收进墙里
	# 门统一往右侧滑动收进墙里
	var tw: Tween = create_tween()
	tw.tween_property(hinge, "position:z", DOOR_WIDTH + 0.3, 0.8)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.set_ease(Tween.EASE_IN_OUT)
	# 出口门：开门2秒后自动关闭
	if dt == "exit":
		exit_door_open = true
		if UIManager != null:
			UIManager.show_announcement("安全门已打开 - 快进去！", 3.0)
		# 2秒后自动关门
		var close_timer: Timer = Timer.new()
		close_timer.wait_time = 2.0
		close_timer.one_shot = true
		close_timer.timeout.connect(func():
			var tw2: Tween = create_tween()
			tw2.tween_property(hinge, "position:z", 0.0, 0.6)
			tw2.set_trans(Tween.TRANS_QUAD)
			tw2.set_ease(Tween.EASE_IN_OUT)
			area.set_meta("is_opening", false)
			close_timer.queue_free()
		)
		add_child(close_timer)
		close_timer.start()
		# 出口门直接连通安全区（小房间后墙已去掉）
		return
	# 普通门：开门后放怪
	var has_m: bool = area.get_meta("has_monster")
	var spawned: bool = area.get_meta("spawned")
	if has_m and not spawned:
		# 延迟0.5秒放怪（等门开一点）
		var delay_timer: Timer = Timer.new()
		delay_timer.wait_time = 0.5
		delay_timer.one_shot = true
		delay_timer.timeout.connect(func():
			area.set_meta("spawned", true)
			var z_pos: float = area.get_meta("room_z")
			var is_left: bool = area.get_meta("room_is_left")
			var half_w: float = CORRIDOR_WIDTH / 2
			var sx: float = -half_w - ROOM_SIZE / 2 if is_left else half_w + ROOM_SIZE / 2
			var m: Node = monster_scene.instantiate()
			m.position = Vector3(sx, 1.0, z_pos)
			add_child(m)
			if UIManager != null:
				UIManager.show_toast("房间里有怪物！")
			delay_timer.queue_free()
		)
		add_child(delay_timer)
		delay_timer.start()
	# 医疗包门：开门后在房间里生成医疗包
	var has_h: bool = area.get_meta("has_health")
	if has_h:
		var z_pos2: float = area.get_meta("room_z")
		var is_left2: bool = area.get_meta("room_is_left")
		var half_w2: float = CORRIDOR_WIDTH / 2
		var hx: float = -half_w2 - ROOM_SIZE / 2 if is_left2 else half_w2 + ROOM_SIZE / 2
		var hp: Node = health_scene.instantiate()
		hp.position = Vector3(hx, 1.0, z_pos2)
		add_child(hp)

func _build_obstacles() -> void:
	for i in range(1, 16):
		var z_pos: float = 35.0 + i * 28.0
		if z_pos > CORRIDOR_LENGTH - 40:
			break
		var r: int = randi() % 3
		if r == 0:
			_make_box(Vector3(-1.5, 0, z_pos), 1.0)
			_make_table(Vector3(1.5, 0, z_pos + 2.0))
		elif r == 1:
			_make_box(Vector3(0, 0, z_pos), 1.2)
			_make_box(Vector3(-1.5, 0, z_pos + 1.5), 0.8)
		else:
			_make_table(Vector3(1.0, 0, z_pos))

func _make_table(pos: Vector3) -> void:
	var t: StaticBody3D = StaticBody3D.new()
	var m: MeshInstance3D = MeshInstance3D.new()
	var b: BoxMesh = BoxMesh.new()
	b.size = Vector3(1.8, 0.1, 1.0)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.3, 0.2)
	b.material = mat
	m.mesh = b
	m.position.y = 1.0
	t.add_child(m)
	var c: CollisionShape3D = CollisionShape3D.new()
	var s: BoxShape3D = BoxShape3D.new()
	s.size = Vector3(1.8, 1.0, 1.0)
	c.shape = s
	c.position.y = 0.5
	t.add_child(c)
	t.position = pos
	add_child(t)

func _make_box(pos: Vector3, sz: float) -> void:
	var b: StaticBody3D = StaticBody3D.new()
	var m: MeshInstance3D = MeshInstance3D.new()
	var bm: BoxMesh = BoxMesh.new()
	bm.size = Vector3(sz, sz, sz)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.45, 0.35)
	bm.material = mat
	m.mesh = bm
	m.position.y = sz / 2
	b.add_child(m)
	var c: CollisionShape3D = CollisionShape3D.new()
	var s: BoxShape3D = BoxShape3D.new()
	s.size = Vector3(sz, sz, sz)
	c.shape = s
	c.position.y = sz / 2
	b.add_child(c)
	b.position = pos
	add_child(b)

func _build_button() -> void:
	var btn: StaticBody3D = StaticBody3D.new()
	btn.name = "TriggerButton"
	var m: MeshInstance3D = MeshInstance3D.new()
	var b: BoxMesh = BoxMesh.new()
	b.size = Vector3(0.8, 0.25, 0.8)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.15, 0.15)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.1, 0.1)
	mat.emission_energy_multiplier = 2.0
	b.material = mat
	m.mesh = b
	m.position.y = 1.1
	btn.add_child(m)
	var c: CollisionShape3D = CollisionShape3D.new()
	var s: BoxShape3D = BoxShape3D.new()
	s.size = Vector3(1.2, 1.2, 1.2)
	c.shape = s
	c.position.y = 0.6
	btn.add_child(c)
	var area: Area3D = Area3D.new()
	var ac: CollisionShape3D = CollisionShape3D.new()
	var ashape: SphereShape3D = SphereShape3D.new()
	ashape.radius = 2.5
	ac.shape = ashape
	area.add_child(ac)
	area.body_entered.connect(_on_btn_enter)
	area.body_exited.connect(_on_btn_exit)
	btn.add_child(area)
	btn.position = Vector3(0, 0, 45.0)
	add_child(btn)

var _btn_prompt: bool = false
var _cur_big_door: Area3D = null

func _on_btn_enter(body: Node) -> void:
	if body.is_in_group("player") and not button_pressed and not _btn_prompt:
		_btn_prompt = true
		if UIManager != null:
			UIManager.show_interaction_prompt("按E - 启动测试程序")

func _on_btn_exit(body: Node) -> void:
	if body.is_in_group("player"):
		_btn_prompt = false
		if UIManager != null:
			UIManager.hide_interaction_prompt()

func _build_ceiling_trap() -> void:
	ceiling_trap = MeshInstance3D.new()
	var b: BoxMesh = BoxMesh.new()
	b.size = Vector3(4.0, 0.2, 4.0)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.3, 0.35)
	b.material = mat
	ceiling_trap.mesh = b
	ceiling_trap.position = Vector3(0, CORRIDOR_HEIGHT - 0.1, 15.0)
	add_child(ceiling_trap)

func _build_alarm_lights() -> void:
	for i in range(15):
		var z: float = 20.0 + i * 32.0
		if z > CORRIDOR_LENGTH - 20:
			break
		var ll: OmniLight3D = OmniLight3D.new()
		ll.light_color = Color(1.0, 0.1, 0.1)
		ll.light_energy = 3.0
		ll.omni_range = 10.0
		ll.position = Vector3(-CORRIDOR_WIDTH / 2 + 0.5, CORRIDOR_HEIGHT - 0.4, z)
		ll.visible = (i % 2 == 0)
		add_child(ll)
		alarm_lights.append(ll)
		var lr: OmniLight3D = OmniLight3D.new()
		lr.light_color = Color(1.0, 0.1, 0.1)
		lr.light_energy = 3.0
		lr.omni_range = 10.0
		lr.position = Vector3(CORRIDOR_WIDTH / 2 - 0.5, CORRIDOR_HEIGHT - 0.4, z)
		lr.visible = (i % 2 == 1)
		add_child(lr)
		alarm_lights.append(lr)
	var env: WorldEnvironment = WorldEnvironment.new()
	var env_res: Environment = Environment.new()
	env_res.ambient_light_color = Color(0.08, 0.08, 0.1)
	env_res.ambient_light_energy = 0.12
	env.environment = env_res
	add_child(env)

func _build_floor_lights() -> void:
	# 地板警示灯：每隔一段距离一个小的红色发光方块，照亮环境
	for i in range(25):
		var z: float = 15.0 + i * 20.0
		if z > CORRIDOR_LENGTH - 15:
			break
		# 左侧地板灯
		var fl: MeshInstance3D = MeshInstance3D.new()
		var fb: BoxMesh = BoxMesh.new()
		fb.size = Vector3(0.3, 0.05, 0.3)
		var fmat: StandardMaterial3D = StandardMaterial3D.new()
		fmat.albedo_color = Color(1.0, 0.3, 0.1)
		fmat.emission_enabled = true
		fmat.emission = Color(1.0, 0.2, 0.05)
		fmat.emission_energy_multiplier = 3.0
		fb.material = fmat
		fl.mesh = fb
		fl.position = Vector3(-2.5, 0.03, z)
		add_child(fl)
		# 右侧地板灯
		var fr: MeshInstance3D = MeshInstance3D.new()
		var frb: BoxMesh = BoxMesh.new()
		frb.size = Vector3(0.3, 0.05, 0.3)
		frb.material = fmat
		fr.mesh = frb
		fr.position = Vector3(2.5, 0.03, z)
		add_child(fr)

func _build_navigation() -> void:
	var nav: NavigationRegion3D = NavigationRegion3D.new()
	var nm: NavigationMesh = NavigationMesh.new()
	nm.agent_radius = 0.6
	nm.agent_height = 2.2
	nm.cell_size = 0.3
	nav.navigation_mesh = nm
	add_child(nav)
	nav.bake_navigation_mesh(true)

func _process(delta: float) -> void:
	# 警报灯：左闪→右闪→全黑→循环
	alarm_timer += delta
	var phase: int = int(alarm_timer / 0.6) % 3
	for i in range(alarm_lights.size()):
		if alarm_lights[i] != null and is_instance_valid(alarm_lights[i]):
			if phase == 0:
				# 左闪
				alarm_lights[i].visible = (i % 2 == 0)
			elif phase == 1:
				# 右闪
				alarm_lights[i].visible = (i % 2 == 1)
			else:
				# 全黑
				alarm_lights[i].visible = false
	if Input.is_action_just_pressed("interact"):
		if _door_prompt and _cur_door != null:
			_try_open_door(_cur_door)
		if _btn_prompt and _cur_big_door != null and not button_pressed:
			_open_big_door(_cur_big_door)
	if button_pressed and countdown_timer > 0:
		countdown_timer -= delta
		if countdown_timer <= 0 and not ceiling_open:
			_spawn_chaser()

func _spawn_chaser() -> void:
	ceiling_open = true
	if ceiling_trap != null:
		var tw: Tween = create_tween()
		tw.tween_property(ceiling_trap, "position:y", CORRIDOR_HEIGHT + 3.0, 1.5)
	if chaser_scene != null:
		chaser = chaser_scene.instantiate()
		chaser.position = Vector3(0, CORRIDOR_HEIGHT - 1.0, 10.0)
		add_child(chaser)
	if UIManager != null:
		UIManager.show_announcement("实验体已释放 - 快跑！！！", 5.0)
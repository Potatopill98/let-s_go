extends Node3D

## 第二关：狭长逃生走廊 v3
## 500米长x7米宽通道，两侧3.5米深房间，门贴墙，警报灯闪烁

const CORRIDOR_LENGTH: float = 500.0
const CORRIDOR_WIDTH: float = 7.0
const CORRIDOR_HEIGHT: float = 4.0
const ROOM_DEPTH: float = 3.5
const DOOR_SPACING: float = 20.0
const DOOR_WIDTH: float = 2.0
const DOOR_HEIGHT: float = 2.5

var chaser_scene: PackedScene = preload("res://modules/monster/chaser_monster.tscn")
var monster_scene: PackedScene = preload("res://modules/monster/base_monster.tscn")
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
	_build_doors()
	_build_obstacles()
	_build_button()
	_build_ceiling_trap()
	_build_alarm_lights()
	_build_navigation()
	if UIManager != null:
		UIManager.show_announcement("紧急疏散通道 - B区", 3.0)
		UIManager.show_announcement("前方通道已封锁 - 请寻找安全出口", 3.0)
		UIManager.show_announcement("警告：部分房间内可能有实验体", 3.0)

func _build_structure() -> void:
	var total_w: float = CORRIDOR_WIDTH + ROOM_DEPTH * 2
	var half_w: float = total_w / 2
	# 地板（BoxMesh，更可靠）
	var floor: StaticBody3D = StaticBody3D.new()
	var floor_mesh: MeshInstance3D = MeshInstance3D.new()
	var fbox: BoxMesh = BoxMesh.new()
	fbox.size = Vector3(total_w, 0.2, CORRIDOR_LENGTH)
	var fmat: StandardMaterial3D = StandardMaterial3D.new()
	fmat.albedo_color = Color(0.2, 0.2, 0.22)
	fmat.roughness = 0.9
	fbox.material = fmat
	floor_mesh.mesh = fbox
	floor_mesh.position.y = -0.1
	floor.add_child(floor_mesh)
	var fcol: CollisionShape3D = CollisionShape3D.new()
	var fshape: BoxShape3D = BoxShape3D.new()
	fshape.size = Vector3(total_w, 0.2, CORRIDOR_LENGTH)
	fcol.shape = fshape
	floor.add_child(fcol)
	floor.position.z = CORRIDOR_LENGTH / 2
	add_child(floor)
	# 天花板（BoxMesh）
	var ceil_mesh: MeshInstance3D = MeshInstance3D.new()
	var cbox: BoxMesh = BoxMesh.new()
	cbox.size = Vector3(total_w, 0.2, CORRIDOR_LENGTH)
	var cmat: StandardMaterial3D = StandardMaterial3D.new()
	cmat.albedo_color = Color(0.18, 0.18, 0.2)
	cbox.material = cmat
	ceil_mesh.mesh = cbox
	ceil_mesh.position = Vector3(0, CORRIDOR_HEIGHT + 0.1, CORRIDOR_LENGTH / 2)
	add_child(ceil_mesh)
	# 外墙（左右）
	_make_wall(Vector3(-half_w, CORRIDOR_HEIGHT / 2, CORRIDOR_LENGTH / 2), Vector3(0.3, CORRIDOR_HEIGHT, CORRIDOR_LENGTH))
	_make_wall(Vector3(half_w, CORRIDOR_HEIGHT / 2, CORRIDOR_LENGTH / 2), Vector3(0.3, CORRIDOR_HEIGHT, CORRIDOR_LENGTH))
	# 尽头墙
	_make_wall(Vector3(0, CORRIDOR_HEIGHT / 2, CORRIDOR_LENGTH), Vector3(total_w, CORRIDOR_HEIGHT, 0.3))
	# 入口墙（留通道口）
	_make_wall(Vector3(-half_w / 2 - 0.15, CORRIDOR_HEIGHT / 2, 0), Vector3(half_w, CORRIDOR_HEIGHT, 0.3))
	_make_wall(Vector3(half_w / 2 + 0.15, CORRIDOR_HEIGHT / 2, 0), Vector3(half_w, CORRIDOR_HEIGHT, 0.3))
	# 内墙（通道与房间之间，留门洞）
	var left_x: float = -CORRIDOR_WIDTH / 2
	var right_x: float = CORRIDOR_WIDTH / 2
	var door_count: int = int((CORRIDOR_LENGTH - 30) / DOOR_SPACING)
	for i in range(door_count):
		var z_center: float = 20.0 + i * DOOR_SPACING
		if z_center > CORRIDOR_LENGTH - 30:
			break
		var seg_start: float = z_center - DOOR_SPACING / 2
		var seg_end: float = z_center + DOOR_SPACING / 2
		var door_start: float = z_center - DOOR_WIDTH / 2
		var door_end: float = z_center + DOOR_WIDTH / 2
		# 左侧内墙
		if door_start > seg_start:
			_make_wall(Vector3(left_x, CORRIDOR_HEIGHT / 2, (seg_start + door_start) / 2), Vector3(0.15, CORRIDOR_HEIGHT, door_start - seg_start))
		if seg_end > door_end:
			_make_wall(Vector3(left_x, CORRIDOR_HEIGHT / 2, (door_end + seg_end) / 2), Vector3(0.15, CORRIDOR_HEIGHT, seg_end - door_end))
		# 右侧内墙
		if door_start > seg_start:
			_make_wall(Vector3(right_x, CORRIDOR_HEIGHT / 2, (seg_start + door_start) / 2), Vector3(0.15, CORRIDOR_HEIGHT, door_start - seg_start))
		if seg_end > door_end:
			_make_wall(Vector3(right_x, CORRIDOR_HEIGHT / 2, (door_end + seg_end) / 2), Vector3(0.15, CORRIDOR_HEIGHT, seg_end - door_end))

func _make_wall(pos: Vector3, size: Vector3) -> void:
	var wall: StaticBody3D = StaticBody3D.new()
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.28, 0.28, 0.32)
	mat.roughness = 0.85
	box.material = mat
	mesh.mesh = box
	wall.add_child(mesh)
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	wall.add_child(col)
	wall.position = pos
	add_child(wall)

func _build_doors() -> void:
	var door_count: int = int((CORRIDOR_LENGTH - 30) / DOOR_SPACING)
	var idx: int = 0
	for i in range(door_count):
		var z_pos: float = 20.0 + i * DOOR_SPACING
		if z_pos > CORRIDOR_LENGTH - 30:
			break
		# 判断是否是出口门（最后一个左侧门）
		var is_exit: bool = (i == door_count - 1)
		# 左侧门
		_make_door(z_pos, true, idx, is_exit)
		idx += 1
		# 右侧门（不是出口）
		_make_door(z_pos, false, idx, false)
		idx += 1

func _make_door(z_pos: float, is_left: bool, index: int, is_exit: bool) -> void:
	var door_x: float = -CORRIDOR_WIDTH / 2 if is_left else CORRIDOR_WIDTH / 2
	var is_locked: bool = not is_exit and (index % 3 == 0)
	var has_monster: bool = not is_exit and not is_locked
	var door: StaticBody3D = StaticBody3D.new()
	door.name = "Door_%d" % index
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(0.12, DOOR_HEIGHT, DOOR_WIDTH)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	if is_exit:
		mat.albedo_color = Color(0.2, 0.6, 0.2)
		mat.emission_enabled = true
		mat.emission = Color(0.1, 0.9, 0.2)
		mat.emission_energy_multiplier = 1.0
	elif is_locked:
		mat.albedo_color = Color(0.45, 0.35, 0.25)
	else:
		mat.albedo_color = Color(0.35, 0.35, 0.4)
	mat.metallic = 0.4
	mat.roughness = 0.6
	box.material = mat
	mesh.mesh = box
	mesh.position.y = DOOR_HEIGHT / 2
	door.add_child(mesh)
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(0.12, DOOR_HEIGHT, DOOR_WIDTH)
	col.shape = shape
	col.position.y = DOOR_HEIGHT / 2
	door.add_child(col)
	var area: Area3D = Area3D.new()
	var acol: CollisionShape3D = CollisionShape3D.new()
	var ashape: BoxShape3D = BoxShape3D.new()
	ashape.size = Vector3(3.0, DOOR_HEIGHT, DOOR_WIDTH + 1.5)
	acol.shape = ashape
	acol.position.y = DOOR_HEIGHT / 2
	area.add_child(acol)
	area.set_meta("door_type", "exit" if is_exit else ("locked" if is_locked else "monster"))
	area.set_meta("door_node", door)
	area.set_meta("room_z", z_pos)
	area.set_meta("room_is_left", is_left)
	area.set_meta("has_monster", has_monster)
	area.set_meta("spawned", false)
	area.body_entered.connect(func(body): _on_door_enter(body, area))
	area.body_exited.connect(func(body): _on_door_exit(body))
	door.add_child(area)
	door.position = Vector3(door_x, 0, z_pos)
	add_child(door)

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
	var door: Node = area.get_meta("door_node")
	var dt: String = area.get_meta("door_type")
	if dt == "locked":
		if UIManager != null:
			UIManager.show_toast("门已锁死")
		return
	if dt == "exit":
		exit_door_open = true
		door.queue_free()
		if UIManager != null:
			UIManager.show_announcement("安全门已打开 - 进入下一关！", 5.0)
		return
	door.queue_free()
	var has_m: bool = area.get_meta("has_monster")
	var spawned: bool = area.get_meta("spawned")
	if has_m and not spawned:
		area.set_meta("spawned", true)
		var z_pos: float = area.get_meta("room_z")
		var is_left: bool = area.get_meta("room_is_left")
		var sx: float = -CORRIDOR_WIDTH / 2 - ROOM_DEPTH / 2 if is_left else CORRIDOR_WIDTH / 2 + ROOM_DEPTH / 2
		var m: Node = monster_scene.instantiate()
		m.position = Vector3(sx, 1.0, z_pos)
		add_child(m)
		if UIManager != null:
			UIManager.show_toast("房间里有怪物！")

func _build_obstacles() -> void:
	for i in range(1, 18):
		var z_pos: float = 30.0 + i * 25.0
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
	btn.position = Vector3(0, 0, 40.0)
	add_child(btn)

var _btn_prompt: bool = false

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
	ceiling_trap.position = Vector3(0, CORRIDOR_HEIGHT - 0.1, 12.0)
	add_child(ceiling_trap)

func _build_alarm_lights() -> void:
	for i in range(16):
		var z: float = 15.0 + i * 30.0
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
	# 环境光
	var env: WorldEnvironment = WorldEnvironment.new()
	var env_res: Environment = Environment.new()
	env_res.ambient_light_color = Color(0.3, 0.3, 0.35)
	env_res.ambient_light_energy = 0.6
	env.environment = env_res
	add_child(env)

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
	alarm_timer += delta
	if alarm_timer >= 0.7:
		alarm_timer = 0.0
		alarm_state = not alarm_state
		for i in range(alarm_lights.size()):
			if alarm_lights[i] != null and is_instance_valid(alarm_lights[i]):
				alarm_lights[i].visible = (i % 2 == 0) == alarm_state
	if Input.is_action_just_pressed("interact"):
		if _door_prompt and _cur_door != null:
			_try_open_door(_cur_door)
		if _btn_prompt and not button_pressed:
			_press_button()
	if button_pressed and countdown_timer > 0:
		countdown_timer -= delta
		if countdown_timer <= 0 and not ceiling_open:
			_spawn_chaser()

func _press_button() -> void:
	button_pressed = true
	countdown_timer = 10.0
	_btn_prompt = false
	if UIManager != null:
		UIManager.hide_interaction_prompt()
		UIManager.show_announcement("测试程序已启动", 3.0)
		UIManager.show_announcement("警告：实验体收容协议解除", 3.0)
		UIManager.show_announcement("所有人员请立即前往安全门", 3.0)
		UIManager.show_announcement("10秒后实验体将被释放", 4.0)

func _spawn_chaser() -> void:
	ceiling_open = true
	if ceiling_trap != null:
		var tw: Tween = create_tween()
		tw.tween_property(ceiling_trap, "position:y", CORRIDOR_HEIGHT + 3.0, 1.5)
	if chaser_scene != null:
		chaser = chaser_scene.instantiate()
		chaser.position = Vector3(0, CORRIDOR_HEIGHT - 1.0, 12.0)
		add_child(chaser)
	if UIManager != null:
		UIManager.show_announcement("实验体已释放 - 快跑！！！", 5.0)
extends Node3D

## 第二关：狭长逃生走廊 v2
## 500米长x7米宽，两侧小房间，一半门锁死一半有怪，警报灯闪烁

const CORRIDOR_LENGTH: float = 500.0
const CORRIDOR_WIDTH: float = 7.0
const CORRIDOR_HEIGHT: float = 4.0
const ROOM_DEPTH: float = 3.5
const DOOR_SPACING: float = 18.0
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
	_build_corridor()
	_build_rooms_and_doors()
	_build_obstacles()
	_build_button()
	_build_ceiling_trap()
	_build_alarm_lights()
	_build_navigation()
	# 开场广播
	if UIManager != null:
		UIManager.show_announcement("紧急疏散通道 - B区", 3.0)
		UIManager.show_announcement("前方通道已封锁 - 请寻找安全出口", 3.0)
		UIManager.show_announcement("警告：部分房间内可能有实验体", 3.0)

func _build_corridor() -> void:
	var total_width: float = CORRIDOR_WIDTH + ROOM_DEPTH * 2
	# 地板
	var floor: MeshInstance3D = MeshInstance3D.new()
	var floor_mesh: PlaneMesh = PlaneMesh.new()
	floor_mesh.size = Vector2(total_width, CORRIDOR_LENGTH)
	var floor_mat: StandardMaterial3D = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.22, 0.22, 0.25)
	floor_mat.roughness = 0.9
	floor_mesh.material = floor_mat
	floor.mesh = floor_mesh
	floor.rotation.x = -PI / 2
	floor.position.z = CORRIDOR_LENGTH / 2
	add_child(floor)
	var floor_col: StaticBody3D = StaticBody3D.new()
	var floor_col_shape: CollisionShape3D = CollisionShape3D.new()
	var floor_shape: BoxShape3D = BoxShape3D.new()
	floor_shape.size = Vector3(total_width, 0.2, CORRIDOR_LENGTH)
	floor_col_shape.shape = floor_shape
	floor_col.add_child(floor_col_shape)
	floor_col.position.z = CORRIDOR_LENGTH / 2
	add_child(floor_col)
	# 天花板（法线朝下）
	var ceiling: MeshInstance3D = MeshInstance3D.new()
	var ceiling_mesh: PlaneMesh = PlaneMesh.new()
	ceiling_mesh.size = Vector2(total_width, CORRIDOR_LENGTH)
	var ceiling_mat: StandardMaterial3D = StandardMaterial3D.new()
	ceiling_mat.albedo_color = Color(0.18, 0.18, 0.2)
	ceiling_mesh.material = ceiling_mat
	ceiling.mesh = ceiling_mesh
	ceiling.rotation.x = -PI / 2
	ceiling.position = Vector3(0, CORRIDOR_HEIGHT, CORRIDOR_LENGTH / 2)
	add_child(ceiling)
	# 外墙
	_build_wall(Vector3(-total_width / 2, CORRIDOR_HEIGHT / 2, CORRIDOR_LENGTH / 2), Vector3(0.3, CORRIDOR_HEIGHT, CORRIDOR_LENGTH))
	_build_wall(Vector3(total_width / 2, CORRIDOR_HEIGHT / 2, CORRIDOR_LENGTH / 2), Vector3(0.3, CORRIDOR_HEIGHT, CORRIDOR_LENGTH))
	# 尽头死角墙
	_build_wall(Vector3(0, CORRIDOR_HEIGHT / 2, CORRIDOR_LENGTH), Vector3(total_width, CORRIDOR_HEIGHT, 0.3))
	# 通道和房间之间的隔墙（有门洞）
	_build_inner_walls()

func _build_wall(pos: Vector3, size: Vector3) -> void:
	var wall: StaticBody3D = StaticBody3D.new()
	var wall_mesh: MeshInstance3D = MeshInstance3D.new()
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = size
	var wall_mat: StandardMaterial3D = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.28, 0.28, 0.32)
	wall_mat.roughness = 0.85
	box_mesh.material = wall_mat
	wall_mesh.mesh = box_mesh
	wall.add_child(wall_mesh)
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	wall.add_child(col)
	wall.position = pos
	add_child(wall)

func _build_inner_walls() -> void:
	# 左侧隔墙（通道和左房间之间），留门洞
	var left_x: float = -CORRIDOR_WIDTH / 2
	var right_x: float = CORRIDOR_WIDTH / 2
	var door_count: int = int(CORRIDOR_LENGTH / DOOR_SPACING)
	for i in range(door_count):
		var z_center: float = 15.0 + i * DOOR_SPACING
		if z_center > CORRIDOR_LENGTH - 25:
			break
		var z_start: float = z_center - DOOR_SPACING / 2
		var z_end: float = z_center + DOOR_SPACING / 2
		var door_z_start: float = z_center - DOOR_WIDTH / 2
		var door_z_end: float = z_center + DOOR_WIDTH / 2
		# 左侧墙：门洞前半段
		if door_z_start > z_start:
			_build_inner_wall_segment(left_x, z_start, door_z_start, true)
		# 左侧墙：门洞后半段
		if z_end > door_z_end:
			_build_inner_wall_segment(left_x, door_z_end, z_end, true)
		# 右侧墙：门洞前半段
		if door_z_start > z_start:
			_build_inner_wall_segment(right_x, z_start, door_z_start, false)
		# 右侧墙：门洞后半段
		if z_end > door_z_end:
			_build_inner_wall_segment(right_x, door_z_end, z_end, false)

func _build_inner_wall_segment(x_pos: float, z_start: float, z_end: float, is_left: bool) -> void:
	var length: float = z_end - z_start
	if length <= 0.1:
		return
	var wall: StaticBody3D = StaticBody3D.new()
	var wall_mesh: MeshInstance3D = MeshInstance3D.new()
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = Vector3(0.15, CORRIDOR_HEIGHT, length)
	var wall_mat: StandardMaterial3D = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.25, 0.25, 0.28)
	box_mesh.material = wall_mat
	wall_mesh.mesh = box_mesh
	wall_mesh.position.y = CORRIDOR_HEIGHT / 2
	wall.add_child(wall_mesh)
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(0.15, CORRIDOR_HEIGHT, length)
	col.shape = shape
	col.position.y = CORRIDOR_HEIGHT / 2
	wall.add_child(col)
	wall.position = Vector3(x_pos, 0, (z_start + z_end) / 2)
	add_child(wall)

func _build_rooms_and_doors() -> void:
	var door_count: int = int(CORRIDOR_LENGTH / DOOR_SPACING)
	var room_index: int = 0
	for i in range(door_count):
		var z_pos: float = 15.0 + i * DOOR_SPACING
		if z_pos > CORRIDOR_LENGTH - 25:
			break
		# 左右各一个房间
		_build_room(z_pos, true, room_index)
		room_index += 1
		_build_room(z_pos, false, room_index)
		room_index += 1

func _build_room(z_pos: float, is_left: bool, index: int) -> void:
	var room_x: float = 0.0
	var door_x: float = 0.0
	if is_left:
		room_x = -CORRIDOR_WIDTH / 2 - ROOM_DEPTH / 2
		door_x = -CORRIDOR_WIDTH / 2
	else:
		room_x = CORRIDOR_WIDTH / 2 + ROOM_DEPTH / 2
		door_x = CORRIDOR_WIDTH / 2
	# 房间地板（已经有大地板了，不用单独建）
	# 判断门类型：最后一个是出口，一半锁死，一半有怪
	var is_exit: bool = (z_pos > CORRIDOR_LENGTH - 40) and (index % 2 == 0)
	var is_locked: bool = not is_exit and (index % 3 == 0)
	var has_monster: bool = not is_exit and not is_locked
	# 门
	var door: StaticBody3D = StaticBody3D.new()
	door.name = "RoomDoor_%d" % index
	var door_mesh: MeshInstance3D = MeshInstance3D.new()
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = Vector3(0.12, DOOR_HEIGHT, DOOR_WIDTH)
	var door_mat: StandardMaterial3D = StandardMaterial3D.new()
	if is_exit:
		door_mat.albedo_color = Color(0.2, 0.6, 0.2)
		door_mat.emission_enabled = true
		door_mat.emission = Color(0.1, 0.8, 0.2)
		door_mat.emission_energy_multiplier = 0.8
	elif is_locked:
		door_mat.albedo_color = Color(0.4, 0.35, 0.3)
	else:
		door_mat.albedo_color = Color(0.35, 0.35, 0.4)
	door_mat.metallic = 0.4
	door_mat.roughness = 0.6
	box_mesh.material = door_mat
	door_mesh.mesh = box_mesh
	door_mesh.position.y = DOOR_HEIGHT / 2
	door.add_child(door_mesh)
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(0.12, DOOR_HEIGHT, DOOR_WIDTH)
	col.shape = shape
	col.position.y = DOOR_HEIGHT / 2
	door.add_child(col)
	# 交互区域
	var area: Area3D = Area3D.new()
	var area_col: CollisionShape3D = CollisionShape3D.new()
	var area_shape: BoxShape3D = BoxShape3D.new()
	area_shape.size = Vector3(3.0, DOOR_HEIGHT, DOOR_WIDTH + 1.0)
	area_col.shape = area_shape
	area_col.position.y = DOOR_HEIGHT / 2
	area.add_child(area_col)
	area.set_meta("door_type", "exit" if is_exit else ("locked" if is_locked else "monster"))
	area.set_meta("door_node", door)
	area.set_meta("room_z", z_pos)
	area.set_meta("room_is_left", is_left)
	area.set_meta("has_monster", has_monster)
	area.set_meta("monster_spawned", false)
	area.body_entered.connect(func(body): _on_door_area_entered(body, area))
	area.body_exited.connect(func(body): _on_door_area_exited(body))
	door.add_child(area)
	door.position = Vector3(door_x, 0, z_pos)
	add_child(door)

var _door_prompt_active: bool = false
var _current_door_area: Area3D = null

func _on_door_area_entered(body: Node, area: Area3D) -> void:
	if body.is_in_group("player") and not _door_prompt_active:
		_door_prompt_active = true
		_current_door_area = area
		var door_type: String = area.get_meta("door_type")
		if UIManager != null:
			if door_type == "exit":
				UIManager.show_interaction_prompt("按E - 打开安全门逃离")
			elif door_type == "locked":
				UIManager.show_interaction_prompt("按E - 门已锁死")
			else:
				UIManager.show_interaction_prompt("按E - 打开房门")

func _on_door_area_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_door_prompt_active = false
		_current_door_area = null
		if UIManager != null:
			UIManager.hide_interaction_prompt()

func _open_door(area: Area3D) -> void:
	var door: Node = area.get_meta("door_node")
	var door_type: String = area.get_meta("door_type")
	if door_type == "locked":
		if UIManager != null:
			UIManager.show_toast("门已锁死，无法打开")
		return
	if door_type == "exit":
		exit_door_open = true
		door.queue_free()
		if UIManager != null:
			UIManager.show_announcement("安全门已打开 - 进入下一关！", 5.0)
		return
	# 普通门：打开+放怪
	door.queue_free()
	var has_monster: bool = area.get_meta("has_monster")
	var monster_spawned: bool = area.get_meta("monster_spawned")
	if has_monster and not monster_spawned:
		area.set_meta("monster_spawned", true)
		var z_pos: float = area.get_meta("room_z")
		var is_left: bool = area.get_meta("room_is_left")
		var spawn_x: float = 0.0
		if is_left:
			spawn_x = -CORRIDOR_WIDTH / 2 - ROOM_DEPTH / 2
		else:
			spawn_x = CORRIDOR_WIDTH / 2 + ROOM_DEPTH / 2
		var monster: Node = monster_scene.instantiate()
		monster.position = Vector3(spawn_x, 1.0, z_pos)
		add_child(monster)
		if UIManager != null:
			UIManager.show_toast("房间里有怪物！")

func _build_obstacles() -> void:
	for i in range(1, int(CORRIDOR_LENGTH / 25)):
		var z_pos: float = 25.0 + i * 25.0
		if z_pos > CORRIDOR_LENGTH - 30:
			break
		var rng: int = randi() % 3
		if rng == 0:
			_build_table(Vector3(-1.5, 0, z_pos))
			_build_box(Vector3(1.5, 0, z_pos + 2.0))
		elif rng == 1:
			_build_box(Vector3(0, 0, z_pos))
			_build_box(Vector3(-1.2, 0, z_pos + 1.5))
		else:
			_build_table(Vector3(1.2, 0, z_pos))

func _build_table(pos: Vector3) -> void:
	var table: StaticBody3D = StaticBody3D.new()
	var top: MeshInstance3D = MeshInstance3D.new()
	var top_mesh: BoxMesh = BoxMesh.new()
	top_mesh.size = Vector3(1.8, 0.1, 1.0)
	var table_mat: StandardMaterial3D = StandardMaterial3D.new()
	table_mat.albedo_color = Color(0.4, 0.3, 0.2)
	top_mesh.material = table_mat
	top.mesh = top_mesh
	top.position.y = 1.0
	table.add_child(top)
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(1.8, 1.0, 1.0)
	col.shape = shape
	col.position.y = 0.5
	table.add_child(col)
	table.position = pos
	add_child(table)

func _build_box(pos: Vector3) -> void:
	var box: StaticBody3D = StaticBody3D.new()
	var box_mesh_inst: MeshInstance3D = MeshInstance3D.new()
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = Vector3(1.0, 1.0, 1.0)
	var box_mat: StandardMaterial3D = StandardMaterial3D.new()
	box_mat.albedo_color = Color(0.5, 0.45, 0.35)
	box_mesh.material = box_mat
	box_mesh_inst.mesh = box_mesh
	box_mesh_inst.position.y = 0.5
	box.add_child(box_mesh_inst)
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(1.0, 1.0, 1.0)
	col.shape = shape
	col.position.y = 0.5
	box.add_child(col)
	box.position = pos
	add_child(box)

func _build_button() -> void:
	var button: StaticBody3D = StaticBody3D.new()
	button.name = "TriggerButton"
	var btn_mesh: MeshInstance3D = MeshInstance3D.new()
	var btn_box: BoxMesh = BoxMesh.new()
	btn_box.size = Vector3(0.8, 0.25, 0.8)
	var btn_mat: StandardMaterial3D = StandardMaterial3D.new()
	btn_mat.albedo_color = Color(0.8, 0.2, 0.2)
	btn_mat.emission_enabled = true
	btn_mat.emission = Color(1.0, 0.1, 0.1)
	btn_mat.emission_energy_multiplier = 1.5
	btn_box.material = btn_mat
	btn_mesh.mesh = btn_box
	btn_mesh.position.y = 1.1
	button.add_child(btn_mesh)
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(1.2, 1.2, 1.2)
	col.shape = shape
	col.position.y = 0.6
	button.add_child(col)
	var area: Area3D = Area3D.new()
	var area_col: CollisionShape3D = CollisionShape3D.new()
	var area_shape: SphereShape3D = SphereShape3D.new()
	area_shape.radius = 2.5
	area_col.shape = area_shape
	area.add_child(area_col)
	area.body_entered.connect(_on_button_area_entered)
	area.body_exited.connect(_on_button_area_exited)
	button.add_child(area)
	button.position = Vector3(0, 0, 40.0)
	add_child(button)

var _button_prompt: bool = false

func _on_button_area_entered(body: Node) -> void:
	if body.is_in_group("player") and not button_pressed and not _button_prompt:
		_button_prompt = true
		if UIManager != null:
			UIManager.show_interaction_prompt("按E - 启动测试程序")

func _on_button_area_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_button_prompt = false
		if UIManager != null:
			UIManager.hide_interaction_prompt()

func _build_ceiling_trap() -> void:
	ceiling_trap = MeshInstance3D.new()
	var trap_mesh: BoxMesh = BoxMesh.new()
	trap_mesh.size = Vector3(5.0, 0.25, 5.0)
	var trap_mat: StandardMaterial3D = StandardMaterial3D.new()
	trap_mat.albedo_color = Color(0.25, 0.25, 0.28)
	trap_mesh.material = trap_mat
	ceiling_trap.mesh = trap_mesh
	ceiling_trap.position = Vector3(0, CORRIDOR_HEIGHT - 0.12, 12.0)
	add_child(ceiling_trap)

func _build_alarm_lights() -> void:
	for i in range(int(CORRIDOR_LENGTH / 20)):
		var z_pos: float = 10.0 + i * 20.0
		# 左侧警报灯
		var light_l: OmniLight3D = OmniLight3D.new()
		light_l.light_color = Color(1.0, 0.1, 0.1)
		light_l.light_energy = 2.0
		light_l.omni_range = 8.0
		light_l.position = Vector3(-CORRIDOR_WIDTH / 2 + 0.5, CORRIDOR_HEIGHT - 0.3, z_pos)
		light_l.visible = (i % 2 == 0)
		add_child(light_l)
		alarm_lights.append(light_l)
		# 右侧警报灯
		var light_r: OmniLight3D = OmniLight3D.new()
		light_r.light_color = Color(1.0, 0.1, 0.1)
		light_r.light_energy = 2.0
		light_r.omni_range = 8.0
		light_r.position = Vector3(CORRIDOR_WIDTH / 2 - 0.5, CORRIDOR_HEIGHT - 0.3, z_pos)
		light_r.visible = (i % 2 == 1)
		add_child(light_r)
		alarm_lights.append(light_r)

func _build_navigation() -> void:
	var nav: NavigationRegion3D = NavigationRegion3D.new()
	var nav_mesh: NavigationMesh = NavigationMesh.new()
	nav_mesh.agent_radius = 0.6
	nav_mesh.agent_height = 2.2
	nav_mesh.cell_size = 0.3
	nav.navigation_mesh = nav_mesh
	add_child(nav)
	nav.bake_navigation_mesh(true)

func _process(delta: float) -> void:
	# 警报灯闪烁
	alarm_timer += delta
	if alarm_timer >= 0.8:
		alarm_timer = 0.0
		alarm_state = not alarm_state
		for i in range(alarm_lights.size()):
			if alarm_lights[i] != null and is_instance_valid(alarm_lights[i]):
				alarm_lights[i].visible = (i % 2 == 0) == alarm_state
	# 检测门交互
	if Input.is_action_just_pressed("interact") or Input.is_key_pressed(KEY_E):
		if _door_prompt_active and _current_door_area != null:
			_open_door(_current_door_area)
		if _button_prompt and not button_pressed:
			_press_button()
	# 倒计时
	if button_pressed and countdown_timer > 0:
		countdown_timer -= delta
		if countdown_timer <= 0 and not ceiling_open:
			_open_ceiling_and_spawn_chaser()

func _press_button() -> void:
	button_pressed = true
	countdown_timer = 10.0
	_button_prompt = false
	if UIManager != null:
		UIManager.hide_interaction_prompt()
		UIManager.show_announcement("测试程序已启动", 3.0)
		UIManager.show_announcement("警告：实验体收容协议解除", 3.0)
		UIManager.show_announcement("所有人员请立即前往安全门", 3.0)
		UIManager.show_announcement("10秒后实验体将被释放", 4.0)

func _open_ceiling_and_spawn_chaser() -> void:
	ceiling_open = true
	if ceiling_trap != null:
		var tween: Tween = create_tween()
		tween.tween_property(ceiling_trap, "position:y", CORRIDOR_HEIGHT + 2.0, 1.5)
	if chaser_scene != null:
		chaser = chaser_scene.instantiate()
		chaser.position = Vector3(0, CORRIDOR_HEIGHT - 1.0, 12.0)
		add_child(chaser)
	if UIManager != null:
		UIManager.show_announcement("实验体已释放 - 快跑！！！", 5.0)
extends Node3D

## 第二关：狭长逃生走廊
## 1000米长走廊，两侧锁门，障碍物，按钮触发大怪物追逐

const CORRIDOR_LENGTH: float = 1000.0
const CORRIDOR_WIDTH: float = 10.0
const CORRIDOR_HEIGHT: float = 4.0
const DOOR_SPACING: float = 15.0
const DOOR_WIDTH: float = 2.0
const DOOR_HEIGHT: float = 2.5

var chaser_scene: PackedScene = preload("res://modules/monster/chaser_monster.tscn")
var chaser: Node = null
var button_pressed: bool = false
var countdown_timer: float = 0.0
var ceiling_open: bool = false
var ceiling_trap: MeshInstance3D = null
var exit_door: StaticBody3D = null
var exit_door_open: bool = false

func _ready() -> void:
	_build_corridor()
	_build_doors()
	_build_obstacles()
	_build_button()
	_build_ceiling_trap()
	_build_exit()
	_build_lights()
	# 导航区域
	_build_navigation()

func _build_corridor() -> void:
	# 地板
	var floor: MeshInstance3D = MeshInstance3D.new()
	var floor_mesh: PlaneMesh = PlaneMesh.new()
	floor_mesh.size = Vector2(CORRIDOR_WIDTH, CORRIDOR_LENGTH)
	var floor_mat: StandardMaterial3D = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.25, 0.25, 0.28)
	floor_mat.roughness = 0.9
	floor_mesh.material = floor_mat
	floor.mesh = floor_mesh
	floor.rotation.x = -PI / 2
	floor.position.z = CORRIDOR_LENGTH / 2
	add_child(floor)
	var floor_col: StaticBody3D = StaticBody3D.new()
	var floor_col_shape: CollisionShape3D = CollisionShape3D.new()
	var floor_shape: BoxShape3D = BoxShape3D.new()
	floor_shape.size = Vector3(CORRIDOR_WIDTH, 0.2, CORRIDOR_LENGTH)
	floor_col_shape.shape = floor_shape
	floor_col.add_child(floor_col_shape)
	floor_col.position.z = CORRIDOR_LENGTH / 2
	add_child(floor_col)
	# 天花板
	var ceiling: MeshInstance3D = MeshInstance3D.new()
	var ceiling_mesh: PlaneMesh = PlaneMesh.new()
	ceiling_mesh.size = Vector2(CORRIDOR_WIDTH, CORRIDOR_LENGTH)
	var ceiling_mat: StandardMaterial3D = StandardMaterial3D.new()
	ceiling_mat.albedo_color = Color(0.2, 0.2, 0.22)
	ceiling_mesh.material = ceiling_mat
	ceiling.mesh = ceiling_mesh
	ceiling.rotation.x = PI / 2
	ceiling.position = Vector3(0, CORRIDOR_HEIGHT, CORRIDOR_LENGTH / 2)
	add_child(ceiling)
	# 左墙
	_build_wall(Vector3(-CORRIDOR_WIDTH / 2, CORRIDOR_HEIGHT / 2, CORRIDOR_LENGTH / 2), Vector3(0.3, CORRIDOR_HEIGHT, CORRIDOR_LENGTH))
	# 右墙
	_build_wall(Vector3(CORRIDOR_WIDTH / 2, CORRIDOR_HEIGHT / 2, CORRIDOR_LENGTH / 2), Vector3(0.3, CORRIDOR_HEIGHT, CORRIDOR_LENGTH))

func _build_wall(pos: Vector3, size: Vector3) -> void:
	var wall: StaticBody3D = StaticBody3D.new()
	var wall_mesh: MeshInstance3D = MeshInstance3D.new()
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = size
	var wall_mat: StandardMaterial3D = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.3, 0.3, 0.35)
	wall_mat.roughness = 0.8
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

func _build_doors() -> void:
	var door_count: int = int(CORRIDOR_LENGTH / DOOR_SPACING)
	for i in range(door_count):
		var z_pos: float = 10.0 + i * DOOR_SPACING
		if z_pos > CORRIDOR_LENGTH - 20:
			break
		# 左右交替放门
		if i % 2 == 0:
			_build_locked_door(Vector3(-CORRIDOR_WIDTH / 2 + 0.2, 0, z_pos), true)
		else:
			_build_locked_door(Vector3(CORRIDOR_WIDTH / 2 - 0.2, 0, z_pos), false)

func _build_locked_door(pos: Vector3, is_left: bool) -> void:
	var door: StaticBody3D = StaticBody3D.new()
	door.name = "LockedDoor"
	var door_mesh: MeshInstance3D = MeshInstance3D.new()
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = Vector3(0.15, DOOR_HEIGHT, DOOR_WIDTH)
	var door_mat: StandardMaterial3D = StandardMaterial3D.new()
	door_mat.albedo_color = Color(0.4, 0.35, 0.3)
	door_mat.metallic = 0.3
	door_mat.roughness = 0.6
	box_mesh.material = door_mat
	door_mesh.mesh = box_mesh
	door_mesh.position.y = DOOR_HEIGHT / 2
	door.add_child(door_mesh)
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(0.15, DOOR_HEIGHT, DOOR_WIDTH)
	col.shape = shape
	col.position.y = DOOR_HEIGHT / 2
	door.add_child(col)
	# 门框
	var frame_mat: StandardMaterial3D = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.5, 0.45, 0.4)
	frame_mat.metallic = 0.5
	# 交互区域
	var area: Area3D = Area3D.new()
	var area_col: CollisionShape3D = CollisionShape3D.new()
	var area_shape: BoxShape3D = BoxShape3D.new()
	area_shape.size = Vector3(2.0, DOOR_HEIGHT, DOOR_WIDTH + 1.0)
	area_col.shape = area_shape
	area_col.position.y = DOOR_HEIGHT / 2
	area.add_child(area_col)
	area.set_meta("is_locked_door", true)
	area.body_entered.connect(func(body): _on_door_area_entered(body, area))
	area.body_exited.connect(func(body): _on_door_area_exited(body))
	door.add_child(area)
	door.position = pos
	if is_left:
		door.rotation.y = PI / 2
	else:
		door.rotation.y = -PI / 2
	add_child(door)

var _door_prompt_active: bool = false

func _on_door_area_entered(body: Node, area: Area3D) -> void:
	if body.is_in_group("player") and not _door_prompt_active:
		_door_prompt_active = true
		if UIManager != null:
			UIManager.show_interaction_prompt("按E - 门已锁死，无法打开")

func _on_door_area_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_door_prompt_active = false
		if UIManager != null:
			UIManager.hide_interaction_prompt()

func _build_obstacles() -> void:
	# 每隔30米放一组障碍物
	for i in range(1, int(CORRIDOR_LENGTH / 30)):
		var z_pos: float = 30.0 + i * 30.0
		if z_pos > CORRIDOR_LENGTH - 30:
			break
		# 随机放桌子或箱子
		var rng: int = randi() % 3
		if rng == 0:
			_build_table(Vector3(-2.0, 0, z_pos))
			_build_box(Vector3(2.0, 0, z_pos + 2.0))
		elif rng == 1:
			_build_box(Vector3(0, 0, z_pos))
			_build_box(Vector3(-1.5, 0, z_pos + 1.5))
		else:
			_build_table(Vector3(1.5, 0, z_pos))

func _build_table(pos: Vector3) -> void:
	var table: StaticBody3D = StaticBody3D.new()
	var top: MeshInstance3D = MeshInstance3D.new()
	var top_mesh: BoxMesh = BoxMesh.new()
	top_mesh.size = Vector3(2.0, 0.1, 1.2)
	var table_mat: StandardMaterial3D = StandardMaterial3D.new()
	table_mat.albedo_color = Color(0.4, 0.3, 0.2)
	top_mesh.material = table_mat
	top.mesh = top_mesh
	top.position.y = 1.0
	table.add_child(top)
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(2.0, 1.0, 1.2)
	col.shape = shape
	col.position.y = 0.5
	table.add_child(col)
	table.position = pos
	add_child(table)

func _build_box(pos: Vector3) -> void:
	var box: StaticBody3D = StaticBody3D.new()
	var box_mesh_inst: MeshInstance3D = MeshInstance3D.new()
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = Vector3(1.2, 1.2, 1.2)
	var box_mat: StandardMaterial3D = StandardMaterial3D.new()
	box_mat.albedo_color = Color(0.5, 0.45, 0.35)
	box_mesh.material = box_mat
	box_mesh_inst.mesh = box_mesh
	box_mesh_inst.position.y = 0.6
	box.add_child(box_mesh_inst)
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(1.2, 1.2, 1.2)
	col.shape = shape
	col.position.y = 0.6
	box.add_child(col)
	box.position = pos
	add_child(box)

func _build_button() -> void:
	var button: StaticBody3D = StaticBody3D.new()
	button.name = "TriggerButton"
	var btn_mesh: MeshInstance3D = MeshInstance3D.new()
	var btn_box: BoxMesh = BoxMesh.new()
	btn_box.size = Vector3(1.0, 0.3, 1.0)
	var btn_mat: StandardMaterial3D = StandardMaterial3D.new()
	btn_mat.albedo_color = Color(0.8, 0.2, 0.2)
	btn_mat.emission_enabled = true
	btn_mat.emission = Color(1.0, 0.1, 0.1)
	btn_mat.emission_energy_multiplier = 1.0
	btn_box.material = btn_mat
	btn_mesh.mesh = btn_box
	btn_mesh.position.y = 1.2
	button.add_child(btn_mesh)
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(1.5, 1.5, 1.5)
	col.shape = shape
	col.position.y = 0.75
	button.add_child(col)
	var area: Area3D = Area3D.new()
	var area_col: CollisionShape3D = CollisionShape3D.new()
	var area_shape: SphereShape3D = SphereShape3D.new()
	area_shape.radius = 3.0
	area_col.shape = area_shape
	area.add_child(area_col)
	area.body_entered.connect(_on_button_area_entered)
	area.body_exited.connect(_on_button_area_exited)
	button.add_child(area)
	button.position = Vector3(0, 0, 50.0)
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
	trap_mesh.size = Vector3(6.0, 0.3, 6.0)
	var trap_mat: StandardMaterial3D = StandardMaterial3D.new()
	trap_mat.albedo_color = Color(0.15, 0.15, 0.18)
	trap_mesh.material = trap_mat
	ceiling_trap.mesh = trap_mesh
	ceiling_trap.position = Vector3(0, CORRIDOR_HEIGHT - 0.15, 15.0)
	add_child(ceiling_trap)

func _build_exit() -> void:
	exit_door = StaticBody3D.new()
	exit_door.name = "ExitDoor"
	var door_mesh: MeshInstance3D = MeshInstance3D.new()
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = Vector3(CORRIDOR_WIDTH, DOOR_HEIGHT + 1.0, 0.3)
	var door_mat: StandardMaterial3D = StandardMaterial3D.new()
	door_mat.albedo_color = Color(0.2, 0.5, 0.2)
	door_mat.emission_enabled = true
	door_mat.emission = Color(0.1, 0.8, 0.2)
	door_mat.emission_energy_multiplier = 0.5
	box_mesh.material = door_mat
	door_mesh.mesh = box_mesh
	door_mesh.position.y = (DOOR_HEIGHT + 1.0) / 2
	exit_door.add_child(door_mesh)
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(CORRIDOR_WIDTH, DOOR_HEIGHT + 1.0, 0.3)
	col.shape = shape
	col.position.y = (DOOR_HEIGHT + 1.0) / 2
	exit_door.add_child(col)
	var area: Area3D = Area3D.new()
	var area_col: CollisionShape3D = CollisionShape3D.new()
	var area_shape: BoxShape3D = BoxShape3D.new()
	area_shape.size = Vector3(CORRIDOR_WIDTH, DOOR_HEIGHT + 1.0, 3.0)
	area_col.shape = area_shape
	area_col.position.y = (DOOR_HEIGHT + 1.0) / 2
	area.add_child(area_col)
	area.body_entered.connect(_on_exit_area_entered)
	area.body_exited.connect(_on_exit_area_exited)
	exit_door.add_child(area)
	exit_door.position = Vector3(0, 0, CORRIDOR_LENGTH - 5.0)
	add_child(exit_door)

var _exit_prompt: bool = false

func _on_exit_area_entered(body: Node) -> void:
	if body.is_in_group("player") and not _exit_prompt:
		_exit_prompt = true
		if UIManager != null:
			if button_pressed:
				UIManager.show_interaction_prompt("按E - 打开安全门逃离")
			else:
				UIManager.show_interaction_prompt("安全门已锁定 - 请先启动测试程序")

func _on_exit_area_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_exit_prompt = false
		if UIManager != null:
			UIManager.hide_interaction_prompt()

func _build_lights() -> void:
	# 每隔20米一盏灯
	for i in range(int(CORRIDOR_LENGTH / 20)):
		var light: OmniLight3D = OmniLight3D.new()
		light.light_color = Color(0.9, 0.85, 0.7)
		light.light_energy = 1.5
		light.omni_range = 15.0
		light.position = Vector3(0, CORRIDOR_HEIGHT - 0.5, 10.0 + i * 20.0)
		add_child(light)

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
	# 检测按钮交互
	if not button_pressed and Input.is_action_just_pressed("interact") and _button_prompt:
		_press_button()
	# 检测出口交互
	if Input.is_action_just_pressed("interact") and _exit_prompt and button_pressed:
		_open_exit()
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
		UIManager.show_toast("倒计时：10秒")

func _open_ceiling_and_spawn_chaser() -> void:
	ceiling_open = true
	# 天花板打开动画（用tween移动）
	if ceiling_trap != null:
		var tween: Tween = create_tween()
		tween.tween_property(ceiling_trap, "position:y", CORRIDOR_HEIGHT + 2.0, 1.5)
	# 生成怪物
	if chaser_scene != null:
		chaser = chaser_scene.instantiate()
		chaser.position = Vector3(0, CORRIDOR_HEIGHT - 1.0, 15.0)
		add_child(chaser)
	if UIManager != null:
		UIManager.show_announcement("实验体已释放 - 快跑！！！", 5.0)

func _open_exit() -> void:
	exit_door_open = true
	exit_door.queue_free()
	if UIManager != null:
		UIManager.show_announcement("安全门已打开 - 你逃脱了！", 5.0)
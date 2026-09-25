extends Node3D
class_name ProceduralLevelGenerator

# ============================================================
# Procedural Level Generator
# Randomly generates obstacles, props, and decorations
# ============================================================

@export var area_size: Vector2 = Vector2(40, 40)
@export var obstacle_count: int = 15
@export var prop_count: int = 20
@export var light_count: int = 5
@export var seed: int = 0
@export var generate_on_ready: bool = true

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var occupied_positions: Array[Vector2] = []

func _ready() -> void:
	if generate_on_ready:
		generate()

func generate() -> void:
	rng.seed = seed
	if seed == 0:
		rng.randomize()
	occupied_positions.clear()
	_clear_children()
	_generate_floor()
	_generate_obstacles()
	_generate_props()
	_generate_lights()
	_generate_boundary_walls()

func _clear_children() -> void:
	for child in get_children():
		child.queue_free()

func _generate_floor() -> void:
	var floor: MeshInstance3D = MeshInstance3D.new()
	var floor_mesh: PlaneMesh = PlaneMesh.new()
	floor_mesh.size = area_size
	var floor_mat: StandardMaterial3D = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.25, 0.25, 0.28)
	floor_mat.roughness = 0.8
	floor_mesh.material = floor_mat
	floor.mesh = floor_mesh
	floor.rotation.x = deg_to_rad(-90)
	add_child(floor)
	# Floor collision
	var floor_col: StaticBody3D = StaticBody3D.new()
	var floor_shape: CollisionShape3D = CollisionShape3D.new()
	var plane_shape: BoxShape3D = BoxShape3D.new()
	plane_shape.size = Vector3(area_size.x, 0.1, area_size.y)
	floor_shape.shape = plane_shape
	floor_shape.position.y = -0.05
	floor_col.add_child(floor_shape)
	add_child(floor_col)

func _generate_obstacles() -> void:
	for i in range(obstacle_count):
		var pos: Vector2 = _get_random_position(3.0)
		if pos == Vector2.ZERO:
			continue
		var obstacle_type: int = rng.randi_range(0, 2)
		match obstacle_type:
			0:
				_spawn_pillar(pos)
			1:
				_spawn_crate(pos)
			2:
				_spawn_barrel(pos)

func _generate_props() -> void:
	for i in range(prop_count):
		var pos: Vector2 = _get_random_position(1.5)
		if pos == Vector2.ZERO:
			continue
		var prop_type: int = rng.randi_range(0, 3)
		match prop_type:
			0:
				_spawn_small_crate(pos)
			1:
				_spawn_pipe(pos)
			2:
				_spawn_debris(pos)
			3:
				_spawn_cone(pos)

func _generate_lights() -> void:
	for i in range(light_count):
		var pos: Vector2 = _get_random_position(5.0)
		if pos == Vector2.ZERO:
			continue
		_spawn_ceiling_light(pos)

func _generate_boundary_walls() -> void:
	var wall_height: float = 4.0
	var wall_thickness: float = 0.5
	# North wall
	_spawn_wall(Vector3(0, wall_height/2, -area_size.y/2), Vector3(area_size.x, wall_height, wall_thickness))
	# South wall
	_spawn_wall(Vector3(0, wall_height/2, area_size.y/2), Vector3(area_size.x, wall_height, wall_thickness))
	# East wall
	_spawn_wall(Vector3(area_size.x/2, wall_height/2, 0), Vector3(wall_thickness, wall_height, area_size.y))
	# West wall
	_spawn_wall(Vector3(-area_size.x/2, wall_height/2, 0), Vector3(wall_thickness, wall_height, area_size.y))

func _spawn_wall(pos: Vector3, size: Vector3) -> void:
	var wall: StaticBody3D = StaticBody3D.new()
	var wall_mesh: MeshInstance3D = MeshInstance3D.new()
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = size
	var wall_mat: StandardMaterial3D = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.2, 0.2, 0.22)
	wall_mat.roughness = 0.9
	box_mesh.material = wall_mat
	wall_mesh.mesh = box_mesh
	wall.add_child(wall_mesh)
	var wall_col: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = size
	wall_col.shape = box_shape
	wall.add_child(wall_col)
	wall.position = pos
	add_child(wall)

func _spawn_pillar(pos: Vector2) -> void:
	var pillar: StaticBody3D = StaticBody3D.new()
	var pillar_mesh: MeshInstance3D = MeshInstance3D.new()
	var cylinder_mesh: CylinderMesh = CylinderMesh.new()
	cylinder_mesh.top_radius = 0.5
	cylinder_mesh.bottom_radius = 0.6
	cylinder_mesh.height = 3.0
	var pillar_mat: StandardMaterial3D = StandardMaterial3D.new()
	pillar_mat.albedo_color = Color(0.4, 0.4, 0.45)
	pillar_mat.roughness = 0.6
	pillar_mat.metallic = 0.3
	cylinder_mesh.material = pillar_mat
	pillar_mesh.mesh = cylinder_mesh
	pillar_mesh.position.y = 1.5
	pillar.add_child(pillar_mesh)
	var pillar_col: CollisionShape3D = CollisionShape3D.new()
	var cylinder_shape: CylinderShape3D = CylinderShape3D.new()
	cylinder_shape.radius = 0.6
	cylinder_shape.height = 3.0
	pillar_col.shape = cylinder_shape
	pillar_col.position.y = 1.5
	pillar.add_child(pillar_col)
	pillar.position = Vector3(pos.x, 0, pos.y)
	add_child(pillar)

func _spawn_crate(pos: Vector2) -> void:
	var crate: StaticBody3D = StaticBody3D.new()
	var crate_mesh: MeshInstance3D = MeshInstance3D.new()
	var box_mesh: BoxMesh = BoxMesh.new()
	var size: float = rng.randf_range(1.0, 1.8)
	box_mesh.size = Vector3(size, size, size)
	var crate_mat: StandardMaterial3D = StandardMaterial3D.new()
	crate_mat.albedo_color = Color(0.55, 0.4, 0.25)
	crate_mat.roughness = 0.8
	box_mesh.material = crate_mat
	crate_mesh.mesh = box_mesh
	crate_mesh.position.y = size / 2
	crate.add_child(crate_mesh)
	var crate_col: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(size, size, size)
	crate_col.shape = box_shape
	crate_col.position.y = size / 2
	crate.add_child(crate_col)
	crate.position = Vector3(pos.x, 0, pos.y)
	crate.rotation.y = rng.randf_range(0, PI)
	add_child(crate)

func _spawn_barrel(pos: Vector2) -> void:
	var barrel: StaticBody3D = StaticBody3D.new()
	var barrel_mesh: MeshInstance3D = MeshInstance3D.new()
	var cylinder_mesh: CylinderMesh = CylinderMesh.new()
	cylinder_mesh.top_radius = 0.4
	cylinder_mesh.bottom_radius = 0.4
	cylinder_mesh.height = 1.2
	var barrel_mat: StandardMaterial3D = StandardMaterial3D.new()
	barrel_mat.albedo_color = Color(0.7, 0.3, 0.15)
	barrel_mat.roughness = 0.5
	barrel_mat.metallic = 0.6
	cylinder_mesh.material = barrel_mat
	barrel_mesh.mesh = cylinder_mesh
	barrel_mesh.position.y = 0.6
	barrel.add_child(barrel_mesh)
	var barrel_col: CollisionShape3D = CollisionShape3D.new()
	var cylinder_shape: CylinderShape3D = CylinderShape3D.new()
	cylinder_shape.radius = 0.4
	cylinder_shape.height = 1.2
	barrel_col.shape = cylinder_shape
	barrel_col.position.y = 0.6
	barrel.add_child(barrel_col)
	barrel.position = Vector3(pos.x, 0, pos.y)
	add_child(barrel)

func _spawn_small_crate(pos: Vector2) -> void:
	var crate: MeshInstance3D = MeshInstance3D.new()
	var box_mesh: BoxMesh = BoxMesh.new()
	var size: float = rng.randf_range(0.4, 0.8)
	box_mesh.size = Vector3(size, size, size)
	var crate_mat: StandardMaterial3D = StandardMaterial3D.new()
	crate_mat.albedo_color = Color(0.5, 0.35, 0.2)
	crate_mat.roughness = 0.85
	box_mesh.material = crate_mat
	crate.mesh = box_mesh
	crate.position = Vector3(pos.x, size/2, pos.y)
	crate.rotation.y = rng.randf_range(0, PI)
	add_child(crate)

func _spawn_pipe(pos: Vector2) -> void:
	var pipe: MeshInstance3D = MeshInstance3D.new()
	var cylinder_mesh: CylinderMesh = CylinderMesh.new()
	cylinder_mesh.top_radius = 0.15
	cylinder_mesh.bottom_radius = 0.15
	cylinder_mesh.height = rng.randf_range(1.5, 3.0)
	var pipe_mat: StandardMaterial3D = StandardMaterial3D.new()
	pipe_mat.albedo_color = Color(0.35, 0.35, 0.4)
	pipe_mat.roughness = 0.4
	pipe_mat.metallic = 0.7
	cylinder_mesh.material = pipe_mat
	pipe.mesh = cylinder_mesh
	pipe.position = Vector3(pos.x, cylinder_mesh.height/2, pos.y)
	pipe.rotation.z = rng.randf_range(-0.2, 0.2)
	add_child(pipe)

func _spawn_debris(pos: Vector2) -> void:
	for i in range(rng.randi_range(2, 5)):
		var debris: MeshInstance3D = MeshInstance3D.new()
		var box_mesh: BoxMesh = BoxMesh.new()
		var size: float = rng.randf_range(0.15, 0.4)
		box_mesh.size = Vector3(size, size*0.5, size)
		var debris_mat: StandardMaterial3D = StandardMaterial3D.new()
		debris_mat.albedo_color = Color(0.3, 0.3, 0.32)
		debris_mat.roughness = 0.9
		box_mesh.material = debris_mat
		debris.mesh = box_mesh
		var offset: Vector2 = Vector2(rng.randf_range(-0.5, 0.5), rng.randf_range(-0.5, 0.5))
		debris.position = Vector3(pos.x + offset.x, size*0.25, pos.y + offset.y)
		debris.rotation = Vector3(rng.randf_range(0, PI), rng.randf_range(0, PI), rng.randf_range(0, PI))
		add_child(debris)

func _spawn_cone(pos: Vector2) -> void:
	var cone: MeshInstance3D = MeshInstance3D.new()
	var cone_mesh: CylinderMesh = CylinderMesh.new()
	cone_mesh.top_radius = 0.05
	cone_mesh.bottom_radius = 0.25
	cone_mesh.height = 0.7
	var cone_mat: StandardMaterial3D = StandardMaterial3D.new()
	cone_mat.albedo_color = Color(0.9, 0.6, 0.1)
	cone_mat.roughness = 0.6
	cone_mesh.material = cone_mat
	cone.mesh = cone_mesh
	cone.position = Vector3(pos.x, 0.35, pos.y)
	add_child(cone)

func _spawn_ceiling_light(pos: Vector2) -> void:
	var light_stand: MeshInstance3D = MeshInstance3D.new()
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = Vector3(1.5, 0.1, 0.3)
	var light_mat: StandardMaterial3D = StandardMaterial3D.new()
	light_mat.albedo_color = Color(0.8, 0.8, 0.9)
	light_mat.emission_enabled = true
	light_mat.emission = Color(0.8, 0.9, 1.0)
	light_mat.emission_energy_multiplier = 2.0
	box_mesh.material = light_mat
	light_stand.mesh = box_mesh
	light_stand.position = Vector3(pos.x, 3.8, pos.y)
	add_child(light_stand)
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = Color(0.9, 0.95, 1.0)
	light.light_energy = rng.randf_range(1.5, 3.0)
	light.omni_range = rng.randf_range(8.0, 15.0)
	light.position = Vector3(pos.x, 3.5, pos.y)
	add_child(light)

func _get_random_position(min_distance: float) -> Vector2:
	for attempt in range(20):
		var x: float = rng.randf_range(-area_size.x/2 + 3, area_size.x/2 - 3)
		var y: float = rng.randf_range(-area_size.y/2 + 3, area_size.y/2 - 3)
		var pos: Vector2 = Vector2(x, y)
		var valid: bool = true
		for occupied in occupied_positions:
			if pos.distance_to(occupied) < min_distance:
				valid = false
				break
		if valid:
			occupied_positions.append(pos)
			return pos
	return Vector2.ZERO

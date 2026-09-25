extends Node3D
class_name SceneDecorator

# ============================================================
# Scene Decorator - Procedural scene beautification
# Adds atmospheric lighting, decorative props, and effects
# ============================================================

@export var decorate_on_ready: bool = true

func _ready() -> void:
	if decorate_on_ready:
		decorate()

func decorate() -> void:
	_add_atmospheric_lights()
	_add_decorative_props()
	_add_fog_effect()
	_add_ground_details()

func _add_atmospheric_lights() -> void:
	# Add colored accent lights for atmosphere
	var light_positions: Array[Vector3] = [
		Vector3(-20, 4, 15),
		Vector3(20, 4, 15),
		Vector3(-20, 4, -10),
		Vector3(20, 4, -10),
		Vector3(-15, 4, -28),
		Vector3(15, 4, -28),
	]
	var light_colors: Array[Color] = [
		Color(0.3, 0.5, 1.0),
		Color(1.0, 0.4, 0.2),
		Color(0.3, 0.5, 1.0),
		Color(1.0, 0.4, 0.2),
		Color(0.2, 1.0, 0.5),
		Color(0.2, 1.0, 0.5),
	]
	for i in range(light_positions.size()):
		var light: OmniLight3D = OmniLight3D.new()
		light.light_color = light_colors[i]
		light.light_energy = 1.5
		light.omni_range = 10.0
		light.position = light_positions[i]
		add_child(light)
		# Add light fixture mesh
		var fixture: MeshInstance3D = MeshInstance3D.new()
		var fixture_mesh: CylinderMesh = CylinderMesh.new()
		fixture_mesh.top_radius = 0.1
		fixture_mesh.bottom_radius = 0.15
		fixture_mesh.height = 0.3
		var fixture_mat: StandardMaterial3D = StandardMaterial3D.new()
		fixture_mat.albedo_color = Color(0.2, 0.2, 0.25)
		fixture_mat.metallic = 0.8
		fixture_mat.roughness = 0.3
		fixture_mesh.material = fixture_mat
		fixture.mesh = fixture_mesh
		fixture.position = light_positions[i] + Vector3(0, 1.5, 0)
		add_child(fixture)

func _add_decorative_props() -> void:
	# Add wall panels with glowing edges
	var panel_positions: Array[Vector3] = [
		Vector3(-29.5, 2, 10),
		Vector3(-29.5, 2, 0),
		Vector3(-29.5, 2, -10),
		Vector3(-29.5, 2, -20),
		Vector3(29.5, 2, 10),
		Vector3(29.5, 2, 0),
		Vector3(29.5, 2, -10),
		Vector3(29.5, 2, -20),
	]
	for pos in panel_positions:
		var panel: MeshInstance3D = MeshInstance3D.new()
		var panel_mesh: BoxMesh = BoxMesh.new()
		panel_mesh.size = Vector3(0.1, 2.5, 3)
		var panel_mat: StandardMaterial3D = StandardMaterial3D.new()
		panel_mat.albedo_color = Color(0.15, 0.15, 0.2)
		panel_mat.emission_enabled = true
		panel_mat.emission = Color(0.2, 0.4, 0.8)
		panel_mat.emission_energy_multiplier = 0.8
		panel_mesh.material = panel_mat
		panel.mesh = panel_mesh
		panel.position = pos
		add_child(panel)
		# Add glowing edge strip
		var strip: MeshInstance3D = MeshInstance3D.new()
		var strip_mesh: BoxMesh = BoxMesh.new()
		strip_mesh.size = Vector3(0.15, 0.05, 3.1)
		var strip_mat: StandardMaterial3D = StandardMaterial3D.new()
		strip_mat.albedo_color = Color(0.3, 0.6, 1.0)
		strip_mat.emission_enabled = true
		strip_mat.emission = Color(0.3, 0.6, 1.0)
		strip_mat.emission_energy_multiplier = 3.0
		strip_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		strip_mesh.material = strip_mat
		strip.mesh = strip_mesh
		strip.position = pos + Vector3(0, 1.2, 0)
		add_child(strip)

	# Add floor markings
	var marking_positions: Array[Vector3] = [
		Vector3(0, 0.02, 15),
		Vector3(0, 0.02, 5),
		Vector3(0, 0.02, -5),
		Vector3(0, 0.02, -15),
		Vector3(0, 0.02, -25),
	]
	for pos in marking_positions:
		var marking: MeshInstance3D = MeshInstance3D.new()
		var marking_mesh: PlaneMesh = PlaneMesh.new()
		marking_mesh.size = Vector2(4, 0.3)
		var marking_mat: StandardMaterial3D = StandardMaterial3D.new()
		marking_mat.albedo_color = Color(1.0, 0.8, 0.2)
		marking_mat.emission_enabled = true
		marking_mat.emission = Color(1.0, 0.8, 0.2)
		marking_mat.emission_energy_multiplier = 1.5
		marking_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		marking_mat.albedo_color.a = 0.7
		marking_mesh.material = marking_mat
		marking.mesh = marking_mesh
		marking.position = pos
		marking.rotation.x = deg_to_rad(-90)
		add_child(marking)

func _add_fog_effect() -> void:
	# Add atmospheric fog via WorldEnvironment
	var world_env: WorldEnvironment = get_parent().get_node("WorldEnv") as WorldEnvironment
	if world_env != null:
		world_env.environment.volumetric_fog_enabled = true
		world_env.environment.volumetric_fog_density = 0.05
		world_env.environment.volumetric_fog_albedo = Color(0.7, 0.8, 1.0)
		world_env.environment.volumetric_fog_emission = Color(0.1, 0.15, 0.2)
		world_env.environment.glow_enabled = true
		world_env.environment.glow_intensity = 0.8
		world_env.environment.glow_bloom = 0.5
		world_env.environment.ssao_enabled = true
		world_env.environment.ssao_intensity = 1.5

func _add_ground_details() -> void:
	# Add scattered debris and details
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 12345
	for i in range(30):
		var debris: MeshInstance3D = MeshInstance3D.new()
		var debris_mesh: BoxMesh = BoxMesh.new()
		var size: float = rng.randf_range(0.1, 0.35)
		debris_mesh.size = Vector3(size, size * 0.4, size * rng.randf_range(0.8, 1.5))
		var debris_mat: StandardMaterial3D = StandardMaterial3D.new()
		debris_mat.albedo_color = Color(rng.randf_range(0.2, 0.4), rng.randf_range(0.2, 0.4), rng.randf_range(0.22, 0.42))
		debris_mat.roughness = 0.9
		debris_mesh.material = debris_mat
		debris.mesh = debris_mesh
		var x: float = rng.randf_range(-25, 25)
		var z: float = rng.randf_range(-40, 25)
		# Avoid spawning in key areas
		if abs(z - 10) < 5 and abs(x) < 6:
			continue
		if abs(z + 8) < 5 and abs(x) < 8:
			continue
		if abs(z + 25) < 6 and abs(x) < 6:
			continue
		debris.position = Vector3(x, size * 0.2, z)
		debris.rotation = Vector3(rng.randf_range(0, PI), rng.randf_range(0, PI), rng.randf_range(0, PI))
		add_child(debris)

	# Add cable lines on ceiling
	for i in range(5):
		var cable: MeshInstance3D = MeshInstance3D.new()
		var cable_mesh: CylinderMesh = CylinderMesh.new()
		cable_mesh.top_radius = 0.03
		cable_mesh.bottom_radius = 0.03
		cable_mesh.height = 55.0
		var cable_mat: StandardMaterial3D = StandardMaterial3D.new()
		cable_mat.albedo_color = Color(0.1, 0.1, 0.12)
		cable_mesh.material = cable_mat
		cable.mesh = cable_mesh
		cable.position = Vector3(-20 + i * 10, 5.8, -10)
		cable.rotation.x = deg_to_rad(90)
		add_child(cable)

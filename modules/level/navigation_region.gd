extends NavigationRegion3D

## 导航区域管理器
## 异步烘焙导航网格，烘焙前怪物用fallback移动，烘焙后自动寻路

func _ready() -> void:
	var nav_mesh: NavigationMesh = NavigationMesh.new()
	nav_mesh.agent_radius = 0.5
	nav_mesh.agent_height = 1.8
	nav_mesh.agent_max_climb = 0.5
	nav_mesh.agent_max_slope = 45.0
	nav_mesh.cell_size = 0.3
	nav_mesh.cell_height = 0.2
	nav_mesh.region_min_size = 8
	navigation_mesh = nav_mesh
	# 异步后台烘焙，不阻塞游戏
	bake_navigation_mesh(true)
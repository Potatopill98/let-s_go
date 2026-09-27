extends NavigationRegion3D

## 导航区域管理器
## 在_ready中烘焙导航网格，供怪物寻路使用

func _ready() -> void:
	var nav_mesh: NavigationMesh = NavigationMesh.new()
	nav_mesh.agent_radius = 0.5
	nav_mesh.agent_height = 1.8
	nav_mesh.agent_max_climb = 0.5
	nav_mesh.agent_max_slope = 45.0
	nav_mesh.cell_size = 0.3
	nav_mesh.cell_height = 0.2
	navigation_mesh = nav_mesh
	# 后台线程烘焙，不阻塞游戏
	bake_navigation_mesh(true)
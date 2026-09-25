extends Area3D

@export var respawn_health: float = 100.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		var p: Player = body as Player
		if p.current_health <= 0.0:
			p.current_health = respawn_health
			UIManager.show_message("✅ 已复活！")

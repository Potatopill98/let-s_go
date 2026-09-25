extends Area3D

signal game_won()

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		UIManager.show_message("🎉 恭喜通关！你们成功逃出来了！")
		game_won.emit()

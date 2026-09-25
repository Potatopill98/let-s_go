extends CanvasLayer

var interaction_prompt: Label = null
var progress_bar: ProgressBar = null
var message_container: VBoxContainer = null
var controls_hint: Label = null
var countdown_label: Label = null
var health_bar: ProgressBar = null
var health_label: Label = null
var weapon_panel: Panel = null
var weapon_name_label: Label = null
var ammo_label: Label = null
var weapon_anim_timer: float = 0.0

@export var message_duration: float = 3.0

func _ready() -> void:
	# 动态创建所有UI节点
	# 操作提示
	controls_hint = Label.new()
	controls_hint.position = Vector2(10, 10)
	controls_hint.text = "WASD移动 | Shift奔跑 | 空格跳跃 | Q闪避 | 左键攻击 | E交互 | 1/2切换武器 | R换弹 | ESC释放鼠标"
	controls_hint.add_theme_font_size_override("font_size", 14)
	controls_hint.modulate = Color(0.9, 0.9, 0.9, 0.8)
	add_child(controls_hint)
	# 交互提示
	interaction_prompt = Label.new()
	interaction_prompt.anchor_right = 1.0
	interaction_prompt.anchor_bottom = 1.0
	interaction_prompt.offset_bottom = -100.0
	interaction_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	interaction_prompt.add_theme_font_size_override("font_size", 24)
	interaction_prompt.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	interaction_prompt.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	interaction_prompt.visible = false
	add_child(interaction_prompt)
	# 进度条
	progress_bar = ProgressBar.new()
	progress_bar.anchor_right = 1.0
	progress_bar.anchor_bottom = 1.0
	progress_bar.offset_left = -150.0
	progress_bar.offset_top = -130.0
	progress_bar.offset_right = 150.0
	progress_bar.offset_bottom = -110.0
	progress_bar.visible = false
	add_child(progress_bar)
	# 消息容器
	message_container = VBoxContainer.new()
	message_container.anchor_left = 1.0
	message_container.anchor_right = 1.0
	message_container.anchor_bottom = 1.0
	message_container.offset_left = -290.0
	message_container.offset_top = 10.0
	message_container.offset_right = -10.0
	message_container.alignment = VBoxContainer.ALIGNMENT_END
	add_child(message_container)
	# 撤离倒计时标签
	countdown_label = Label.new()
	countdown_label.anchor_right = 1.0
	countdown_label.anchor_bottom = 1.0
	countdown_label.offset_bottom = -200.0
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", 48)
	countdown_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2, 1))
	countdown_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	countdown_label.visible = false
	add_child(countdown_label)
	# 玩家血量条（左下角）
	health_bar = ProgressBar.new()
	health_bar.offset_left = 20.0
	health_bar.offset_top = 60.0
	health_bar.offset_right = 220.0
	health_bar.offset_bottom = 90.0
	health_bar.max_value = 100.0
	health_bar.value = 100.0
	add_child(health_bar)
	health_label = Label.new()
	health_label.text = "血量: 100/100"
	health_label.offset_left = 20.0
	health_label.offset_top = 95.0
	health_label.add_theme_font_size_override("font_size", 16)
	health_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	add_child(health_label)
	# 武器显示面板（右下角）
	weapon_panel = Panel.new()
	weapon_panel.offset_left = 20.0
	weapon_panel.offset_top = -90.0
	weapon_panel.offset_right = 220.0
	weapon_panel.offset_bottom = -20.0
	weapon_panel.anchor_left = 1.0
	weapon_panel.anchor_top = 1.0
	weapon_panel.anchor_right = 1.0
	weapon_panel.anchor_bottom = 1.0
	weapon_panel.modulate = Color(0, 0, 0, 0.6)
	add_child(weapon_panel)
	weapon_name_label = Label.new()
	weapon_name_label.text = "武器: 无"
	weapon_name_label.offset_left = 10.0
	weapon_name_label.offset_top = 10.0
	weapon_name_label.add_theme_font_size_override("font_size", 18)
	weapon_name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	weapon_panel.add_child(weapon_name_label)
	ammo_label = Label.new()
	ammo_label.text = ""
	ammo_label.offset_left = 10.0
	ammo_label.offset_top = 40.0
	ammo_label.add_theme_font_size_override("font_size", 24)
	ammo_label.add_theme_color_override("font_color", Color(1, 0.9, 0.2, 1))
	weapon_panel.add_child(ammo_label)

# 显示交互提示
func show_interaction_prompt(text: String) -> void:
	interaction_prompt.text = text
	interaction_prompt.visible = true

# 隐藏交互提示
func hide_interaction_prompt() -> void:
	interaction_prompt.visible = false

# 显示进度条
func show_progress(current: float, max: float, title: String = "") -> void:
	progress_bar.visible = true
	progress_bar.max_value = max
	progress_bar.value = current

# 更新进度条
func update_progress(current: float, max: float) -> void:
	progress_bar.max_value = max
	progress_bar.value = current

# 隐藏进度条
func hide_progress() -> void:
	progress_bar.visible = false

# 显示临时消息
func show_message(text: String) -> void:
	var msg_label: Label = Label.new()
	msg_label.text = text
	msg_label.add_theme_font_size_override("font_size", 18)
	msg_label.modulate = Color(1, 1, 1, 1)
	message_container.add_child(msg_label)
	var timer: Timer = Timer.new()
	timer.wait_time = message_duration
	timer.one_shot = true
	timer.timeout.connect(func():
		msg_label.queue_free()
	)
	msg_label.add_child(timer)
	timer.start()

# 显示撤离倒计时
func show_countdown(time_left: float) -> void:
	countdown_label.visible = true
	countdown_label.text = "撤离倒计时：%d秒" % ceil(time_left)

# 隐藏倒计时
func hide_countdown() -> void:
	countdown_label.visible = false

# 更新玩家血量显示
func update_health(current: float, max: float) -> void:
	health_bar.max_value = max
	health_bar.value = current
	health_label.text = "血量: %d/%d" % [ceil(current), ceil(max)]

# 更新武器显示
func update_weapon_ui(weapon_name: String, ammo: int = -1, max_ammo: int = -1) -> void:
	weapon_name_label.text = "武器: " + weapon_name
	if ammo >= 0 and max_ammo >= 0:
		ammo_label.text = "%d / %d" % [ammo, max_ammo]
	else:
		ammo_label.text = "近战"
	# 切换动画：面板闪一下
	weapon_anim_timer = 0.2

func _process(delta: float) -> void:
	if weapon_anim_timer > 0:
		weapon_anim_timer -= delta
		var scale_val: float = 1.0 + weapon_anim_timer * 2.0
		weapon_panel.scale = Vector2(scale_val, scale_val)
	else:
		weapon_panel.scale = Vector2(1, 1)

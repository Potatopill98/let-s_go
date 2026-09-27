extends CanvasLayer

# ============================================================
# UI Manager - HUD for co-op survival game
# Style: clean, functional, Lethal Company inspired
# ============================================================

var interaction_prompt: Label = null
var progress_bar: ProgressBar = null
var progress_label: Label = null
var message_container: VBoxContainer = null
var controls_hint: Label = null
var countdown_label: Label = null

# Health UI
var health_panel: Panel = null
var health_bar: ProgressBar = null
var health_label: Label = null
var damage_overlay: ColorRect = null
var damage_flash_timer: float = 0.0

# Weapon/Item UI
var item_panel: Panel = null
var item_name_label: Label = null
var item_icon: ColorRect = null
var ammo_label: Label = null
var item_anim_timer: float = 0.0

# Crosshair
var crosshair: Control = null
var crosshair_visible: bool = false

# Inventory UI
var inventory_panel: Panel = null
var task_slots: Array = []
var consumable_slots: Array = []
var inventory_labels: Array = []

# Toast
var toast_label: Label = null
var toast_timer: float = 0.0

# Equipment UI
var equipment_panel: Panel = null
var equipment_labels: Array = []

@export var message_duration: float = 3.0

func _ready() -> void:
	_create_damage_overlay()
	_create_health_ui()
	_create_item_ui()
	_create_crosshair()
	_create_interaction_ui()
	_create_progress_ui()
	_create_message_ui()
	_create_countdown_ui()
	_create_controls_hint()
	_create_inventory_ui()
	_create_toast_ui()
	_create_equipment_ui()

# ============================================================
# Damage overlay (red vignette when hurt)
# ============================================================
func _create_damage_overlay() -> void:
	damage_overlay = ColorRect.new()
	damage_overlay.color = Color(1, 0, 0, 0)
	damage_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(damage_overlay)

func flash_damage() -> void:
	damage_flash_timer = 0.3
	damage_overlay.color = Color(1, 0, 0, 0.35)

# ============================================================
# Health UI (bottom-left)
# ============================================================
func _create_health_ui() -> void:
	# Background panel
	health_panel = Panel.new()
	health_panel.offset_left = 20.0
	health_panel.offset_top = -110.0
	health_panel.offset_right = 240.0
	health_panel.offset_bottom = -30.0
	health_panel.anchor_left = 0.0
	health_panel.anchor_top = 1.0
	health_panel.anchor_right = 0.0
	health_panel.anchor_bottom = 1.0
	health_panel.modulate = Color(0, 0, 0, 0.7)
	add_child(health_panel)
	# Health bar
	health_bar = ProgressBar.new()
	health_bar.offset_left = 10.0
	health_bar.offset_top = 35.0
	health_bar.offset_right = 210.0
	health_bar.offset_bottom = 60.0
	health_bar.max_value = 100.0
	health_bar.value = 100.0
	health_bar.show_percentage = false
	health_panel.add_child(health_bar)
	# Health label
	health_label = Label.new()
	health_label.text = "HP 100/100"
	health_label.offset_left = 10.0
	health_label.offset_top = 8.0
	health_label.add_theme_font_size_override("font_size", 18)
	health_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	health_panel.add_child(health_label)

# ============================================================
# Item/Weapon UI (bottom-right)
# ============================================================
func _create_item_ui() -> void:
	item_panel = Panel.new()
	item_panel.offset_left = -230.0
	item_panel.offset_top = -110.0
	item_panel.offset_right = -20.0
	item_panel.offset_bottom = -30.0
	item_panel.anchor_left = 1.0
	item_panel.anchor_top = 1.0
	item_panel.anchor_right = 1.0
	item_panel.anchor_bottom = 1.0
	item_panel.modulate = Color(0, 0, 0, 0.7)
	add_child(item_panel)
	# Item name
	item_name_label = Label.new()
	item_name_label.text = "空手"
	item_name_label.offset_left = 10.0
	item_name_label.offset_top = 8.0
	item_name_label.add_theme_font_size_override("font_size", 18)
	item_name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	item_panel.add_child(item_name_label)
	# Ammo label
	ammo_label = Label.new()
	ammo_label.text = ""
	ammo_label.offset_left = 10.0
	ammo_label.offset_top = 38.0
	ammo_label.add_theme_font_size_override("font_size", 24)
	ammo_label.add_theme_color_override("font_color", Color(1, 0.9, 0.2, 1))
	item_panel.add_child(ammo_label)

# ============================================================
# Crosshair (center)
# ============================================================
func _create_crosshair() -> void:
	crosshair = Control.new()
	crosshair.anchor_left = 0.5
	crosshair.anchor_top = 0.5
	crosshair.anchor_right = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.offset_left = -12.0
	crosshair.offset_top = -12.0
	crosshair.offset_right = 12.0
	crosshair.offset_bottom = 12.0
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(crosshair)
	# Horizontal line
	var h_line: ColorRect = ColorRect.new()
	h_line.color = Color(1, 1, 1, 0.9)
	h_line.offset_left = -10.0
	h_line.offset_top = -1.0
	h_line.offset_right = 10.0
	h_line.offset_bottom = 1.0
	crosshair.add_child(h_line)
	# Vertical line
	var v_line: ColorRect = ColorRect.new()
	v_line.color = Color(1, 1, 1, 0.9)
	v_line.offset_left = -1.0
	v_line.offset_top = -10.0
	v_line.offset_right = 1.0
	v_line.offset_bottom = 10.0
	crosshair.add_child(v_line)
	# Center dot
	var dot: ColorRect = ColorRect.new()
	dot.color = Color(1, 0.3, 0.3, 1)
	dot.offset_left = -1.5
	dot.offset_top = -1.5
	dot.offset_right = 1.5
	dot.offset_bottom = 1.5
	crosshair.add_child(dot)
	crosshair.visible = false

# ============================================================
# Interaction prompt
# ============================================================
func _create_interaction_ui() -> void:
	interaction_prompt = Label.new()
	interaction_prompt.anchor_right = 1.0
	interaction_prompt.anchor_bottom = 1.0
	interaction_prompt.offset_bottom = -120.0
	interaction_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	interaction_prompt.add_theme_font_size_override("font_size", 40)
	interaction_prompt.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	interaction_prompt.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	interaction_prompt.add_theme_constant_override("shadow_offset_x", 2)
	interaction_prompt.add_theme_constant_override("shadow_offset_y", 2)
	interaction_prompt.visible = false
	add_child(interaction_prompt)

# ============================================================
# Progress bar (repair etc.)
# ============================================================
func _create_progress_ui() -> void:
	# Background panel - 屏幕中间偏下，固定大小400x70
	var prog_panel: Panel = Panel.new()
	prog_panel.set_anchors_preset(Control.PRESET_CENTER)
	prog_panel.offset_left = -200.0
	prog_panel.offset_top = 200.0
	prog_panel.offset_right = 200.0
	prog_panel.offset_bottom = 270.0
	prog_panel.modulate = Color(0, 0, 0, 0.8)
	prog_panel.visible = false
	prog_panel.name = "ProgressPanel"
	add_child(prog_panel)
	# Progress label - 居中显示
	progress_label = Label.new()
	progress_label.text = "修理中..."
	progress_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	progress_label.offset_top = 6.0
	progress_label.offset_bottom = 30.0
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 20)
	progress_label.add_theme_color_override("font_color", Color(0.7, 1, 0.7, 1))
	prog_panel.add_child(progress_label)
	# Progress bar
	progress_bar = ProgressBar.new()
	progress_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	progress_bar.offset_left = 20.0
	progress_bar.offset_top = 34.0
	progress_bar.offset_right = -20.0
	progress_bar.offset_bottom = 60.0
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0
	progress_bar.show_percentage = true
	prog_panel.add_child(progress_bar)
	# Store reference to panel for visibility control
	progress_bar.set_meta("panel", prog_panel)

# ============================================================
# Message container (top-right notifications)
# ============================================================
func _create_message_ui() -> void:
	message_container = VBoxContainer.new()
	message_container.anchor_left = 1.0
	message_container.anchor_right = 1.0
	message_container.anchor_bottom = 1.0
	message_container.offset_left = -300.0
	message_container.offset_top = 50.0
	message_container.offset_right = -10.0
	message_container.alignment = VBoxContainer.ALIGNMENT_END
	add_child(message_container)

# ============================================================
# Countdown label
# ============================================================
func _create_countdown_ui() -> void:
	countdown_label = Label.new()
	countdown_label.anchor_right = 1.0
	countdown_label.anchor_bottom = 1.0
	countdown_label.offset_bottom = -220.0
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", 52)
	countdown_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2, 1))
	countdown_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	countdown_label.add_theme_constant_override("shadow_offset_x", 3)
	countdown_label.add_theme_constant_override("shadow_offset_y", 3)
	countdown_label.visible = false
	add_child(countdown_label)

# ============================================================
# Controls hint (top-left)
# ============================================================
func _create_controls_hint() -> void:
	controls_hint = Label.new()
	controls_hint.position = Vector2(10, 10)
	controls_hint.text = "WASD移动 | Shift奔跑 | 空格跳跃 | Q闪避 | 左键攻击 | E交互 | G丢弃 | R换弹 | ESC释放鼠标"
	controls_hint.add_theme_font_size_override("font_size", 13)
	controls_hint.modulate = Color(0.85, 0.85, 0.85, 0.7)
	add_child(controls_hint)

# ============================================================
# Public API
# ============================================================
func show_interaction_prompt(text: String) -> void:
	interaction_prompt.text = text
	interaction_prompt.visible = true

func hide_interaction_prompt() -> void:
	interaction_prompt.visible = false

func show_progress(current: float, max: float, title: String = "修理中...") -> void:
	var panel: Panel = progress_bar.get_meta("panel") as Panel
	panel.visible = true
	progress_label.text = title
	progress_bar.max_value = max
	progress_bar.value = current

func update_progress(current: float, max: float) -> void:
	progress_bar.max_value = max
	progress_bar.value = current

func hide_progress() -> void:
	var panel: Panel = progress_bar.get_meta("panel") as Panel
	panel.visible = false

func show_message(text: String) -> void:
	var msg_label: Label = Label.new()
	msg_label.text = text
	msg_label.add_theme_font_size_override("font_size", 17)
	msg_label.modulate = Color(1, 1, 1, 1)
	msg_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	message_container.add_child(msg_label)
	var timer: Timer = Timer.new()
	timer.wait_time = message_duration
	timer.one_shot = true
	timer.timeout.connect(func():
		msg_label.queue_free()
	)
	msg_label.add_child(timer)
	timer.start()

func show_countdown(time_left: float) -> void:
	countdown_label.visible = true
	countdown_label.text = "撤离倒计时：%d秒" % ceil(time_left)

func hide_countdown() -> void:
	countdown_label.visible = false

func update_health(current: float, max: float) -> void:
	health_bar.max_value = max
	health_bar.value = current
	health_label.text = "HP %d/%d" % [ceil(current), ceil(max)]
	# Change health bar color based on ratio
	var ratio: float = current / max
	var style: StyleBoxFlat = health_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if style == null:
		style = StyleBoxFlat.new()
	if ratio <= 0.25:
		style.bg_color = Color(0.9, 0.15, 0.15, 1)
	elif ratio <= 0.5:
		style.bg_color = Color(0.95, 0.75, 0.15, 1)
	else:
		style.bg_color = Color(0.2, 0.8, 0.3, 1)
	health_bar.add_theme_stylebox_override("fill", style)

func update_item_ui(item_name: String, ammo: int = -1, max_ammo: int = -1) -> void:
	item_name_label.text = item_name
	if ammo >= 0 and max_ammo >= 0:
		ammo_label.text = "%d / %d" % [ammo, max_ammo]
	else:
		ammo_label.text = ""
	# Switch animation: panel pop
	item_anim_timer = 0.15

func set_crosshair_visible(visible: bool) -> void:
	crosshair_visible = visible
	crosshair.visible = visible

func _process(delta: float) -> void:
	# Damage flash fade
	if damage_flash_timer > 0:
		damage_flash_timer -= delta
		var alpha: float = damage_flash_timer / 0.3 * 0.35
		damage_overlay.color = Color(1, 0, 0, alpha)
	else:
		damage_overlay.color = Color(1, 0, 0, 0)
	# Item panel pop animation
	if item_anim_timer > 0:
		item_anim_timer -= delta
		var scale_val: float = 1.0 + item_anim_timer * 3.0
		item_panel.scale = Vector2(scale_val, scale_val)
	else:
		item_panel.scale = Vector2(1, 1)
	# Toast fade
	if toast_timer > 0:
		toast_timer -= delta
		if toast_timer < 0.5:
			toast_label.modulate.a = toast_timer / 0.5
	else:
		toast_label.modulate.a = 0

# ============================================================
# Inventory UI
# ============================================================
func _create_inventory_ui() -> void:
	inventory_panel = Panel.new()
	inventory_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	inventory_panel.offset_left = -250
	inventory_panel.offset_top = 20
	inventory_panel.offset_right = -20
	inventory_panel.offset_bottom = 200
	inventory_panel.modulate.a = 0.85
	add_child(inventory_panel)

	var vb: VBoxContainer = VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 8
	vb.offset_top = 8
	vb.offset_right = -8
	vb.offset_bottom = -8
	inventory_panel.add_child(vb)

	var title: Label = Label.new()
	title.text = "背包"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vb.add_child(title)

	# Task slots (2)
	var task_label: Label = Label.new()
	task_label.text = "任务道具:"
	task_label.add_theme_font_size_override("font_size", 10)
	task_label.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
	vb.add_child(task_label)

	var task_hb: HBoxContainer = HBoxContainer.new()
	vb.add_child(task_hb)
	for i in range(2):
		var slot: Panel = Panel.new()
		slot.custom_minimum_size = Vector2(40, 40)
		slot.modulate.a = 0.6
		task_hb.add_child(slot)
		var slot_label: Label = Label.new()
		slot_label.text = ""
		slot_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot_label.add_theme_font_size_override("font_size", 8)
		slot.add_child(slot_label)
		task_slots.append(slot)
		inventory_labels.append(slot_label)

	# Consumable slots (4)
	var con_label: Label = Label.new()
	con_label.text = "消耗品 (1-4):"
	con_label.add_theme_font_size_override("font_size", 10)
	con_label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	vb.add_child(con_label)

	var con_hb: HBoxContainer = HBoxContainer.new()
	vb.add_child(con_hb)
	for i in range(4):
		var slot: Panel = Panel.new()
		slot.custom_minimum_size = Vector2(40, 40)
		slot.modulate.a = 0.6
		con_hb.add_child(slot)
		var slot_label: Label = Label.new()
		slot_label.text = str(i + 1)
		slot_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot_label.add_theme_font_size_override("font_size", 8)
		slot.add_child(slot_label)
		consumable_slots.append(slot)
		inventory_labels.append(slot_label)

func update_inventory(task_items: Array, consumable_data: Array) -> void:
	# Update task slots
	for i in range(2):
		if i < task_items.size() and not task_items[i].is_empty():
			var item_id: String = task_items[i].get("item_id", "")
			var color: Color = ItemManager.get_item_color(item_id)
			task_slots[i].modulate = Color(color.r, color.g, color.b, 0.9)
			inventory_labels[i].text = ItemManager.get_item_name(item_id)
		else:
			task_slots[i].modulate.a = 0.3
			inventory_labels[i].text = ""
	# Update consumable slots
	for i in range(4):
		if i < consumable_data.size() and not consumable_data[i].is_empty():
			var item_id: String = consumable_data[i].get("item_id", "")
			var count: int = consumable_data[i].get("count", 0)
			var color: Color = ItemManager.get_item_color(item_id)
			consumable_slots[i].modulate = Color(color.r, color.g, color.b, 0.9)
			inventory_labels[i + 2].text = str(count)
		else:
			consumable_slots[i].modulate.a = 0.3
			inventory_labels[i + 2].text = str(i + 1)

# ============================================================
# Toast notification
# ============================================================
func _create_toast_ui() -> void:
	toast_label = Label.new()
	toast_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_label.offset_top = 80
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 16)
	toast_label.add_theme_color_override("font_color", Color(1, 1, 1))
	toast_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	toast_label.add_theme_constant_override("outline_size", 4)
	toast_label.modulate.a = 0
	add_child(toast_label)

func show_toast(message: String) -> void:
	toast_label.text = message
	toast_timer = 2.5
	toast_label.modulate.a = 1.0

# Update _process to handle toast

# ============================================================
# Equipment UI
# ============================================================
func _create_equipment_ui() -> void:
	equipment_panel = Panel.new()
	equipment_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	equipment_panel.offset_left = 20
	equipment_panel.offset_top = 20
	equipment_panel.offset_right = 180
	equipment_panel.offset_bottom = 100
	equipment_panel.modulate.a = 0.85
	add_child(equipment_panel)

	var vb: VBoxContainer = VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 8
	vb.offset_top = 8
	vb.offset_right = -8
	vb.offset_bottom = -8
	equipment_panel.add_child(vb)

	var title: Label = Label.new()
	title.text = "装备"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vb.add_child(title)

	var slot_names: Array = ["头部", "身体", "脚部"]
	for i in range(3):
		var hb: HBoxContainer = HBoxContainer.new()
		vb.add_child(hb)
		var name_label: Label = Label.new()
		name_label.text = slot_names[i] + ":"
		name_label.custom_minimum_size = Vector2(40, 0)
		name_label.add_theme_font_size_override("font_size", 10)
		hb.add_child(name_label)
		var value_label: Label = Label.new()
		value_label.text = "无"
		value_label.add_theme_font_size_override("font_size", 10)
		value_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		hb.add_child(value_label)
		equipment_labels.append(value_label)

func update_equipment(equip_list: Array) -> void:
	var slot_names: Array = ["头部", "身体", "脚部"]
	var equipped: Array = ["", "", ""]
	for item in equip_list:
		var slot: int = item.get("slot", 0)
		var name: String = item.get("name", "")
		equipped[slot] = name
	for i in range(3):
		if equipped[i] != "":
			equipment_labels[i].text = equipped[i]
			equipment_labels[i].add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
		else:
			equipment_labels[i].text = "无"
			equipment_labels[i].add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
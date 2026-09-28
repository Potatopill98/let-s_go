extends Control
## Main Menu + Multiplayer Lobby
## Dynamically builds all UI panels in code.

const NETWORK_PORT: int = 5678

var current_panel: String = "main"

# Panels
var main_panel: Panel = null
var mode_panel: Panel = null
var create_panel: Panel = null
var join_panel: Panel = null
var lobby_panel: Panel = null

# Lobby widgets
var player_list_vbox: VBoxContainer = null
var chat_box: RichTextLabel = null
var chat_input: LineEdit = null
var ready_button: Button = null
var start_button: Button = null
var lobby_title: Label = null
var ip_port_label: Label = null

# Input fields
var create_port_edit: LineEdit = null
var join_ip_edit: LineEdit = null
var join_port_edit: LineEdit = null
var join_nick_edit: LineEdit = null
var status_label: Label = null


func _ready() -> void:
	_build_main_panel()
	_build_mode_panel()
	_build_create_panel()
	_build_join_panel()
	_build_lobby_panel()
	_show_panel("main")

	# Connect network signals
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	NetworkManager.player_ready_changed.connect(_on_player_ready_changed)
	NetworkManager.chat_received.connect(_on_chat_received)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.server_disconnected.connect(_on_server_disconnected)
	NetworkManager.game_started.connect(_on_game_started)


func _build_main_panel() -> void:
	main_panel = Panel.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.modulate = Color(0.08, 0.08, 0.12, 1.0)
	add_child(main_panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(400, 0)
	vbox.add_theme_constant_override("separation", 16)
	main_panel.add_child(vbox)

	var title: Label = Label.new()
	title.text = "let's go"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	vbox.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "实验室逃出 - 多人合作"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(subtitle)

	vbox.add_child(_make_spacer(20))

	var start_btn: Button = _make_button("开始游戏", vbox)
	start_btn.pressed.connect(func(): _show_panel("mode"))

	var settings_btn: Button = _make_button("设置", vbox)
	settings_btn.pressed.connect(func(): UIManager.show_settings())

	var quit_btn: Button = _make_button("退出游戏", vbox)
	quit_btn.pressed.connect(func(): get_tree().quit())

	var version: Label = Label.new()
	version.text = "v0.10 - 联机测试版"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.add_theme_font_size_override("font_size", 10)
	version.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	vbox.add_child(version)


func _build_mode_panel() -> void:
	mode_panel = Panel.new()
	mode_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	mode_panel.modulate = Color(0.08, 0.08, 0.12, 1.0)
	add_child(mode_panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(400, 0)
	vbox.add_theme_constant_override("separation", 12)
	mode_panel.add_child(vbox)

	var title: Label = Label.new()
	title.text = "选择联机模式"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	vbox.add_child(title)

	vbox.add_child(_make_spacer(10))

	var create_btn: Button = _make_button("创建房间（作为主机）", vbox)
	create_btn.pressed.connect(func(): _show_panel("create"))

	var join_btn: Button = _make_button("加入房间", vbox)
	join_btn.pressed.connect(func(): _show_panel("join"))

	var dedi_btn: Button = _make_button("连接专用服务器", vbox)
	dedi_btn.pressed.connect(_connect_dedicated_server)

	var back_btn: Button = _make_button("返回", vbox)
	back_btn.pressed.connect(func(): _show_panel("main"))


func _build_create_panel() -> void:
	create_panel = Panel.new()
	create_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	create_panel.modulate = Color(0.08, 0.08, 0.12, 1.0)
	add_child(create_panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(400, 0)
	vbox.add_theme_constant_override("separation", 10)
	create_panel.add_child(vbox)

	var title: Label = Label.new()
	title.text = "创建房间"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	vbox.add_child(title)

	vbox.add_child(_make_spacer(10))

	_make_label("端口：", vbox)
	create_port_edit = LineEdit.new()
	create_port_edit.text = str(NETWORK_PORT)
	create_port_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(create_port_edit)

	vbox.add_child(_make_spacer(10))

	var create_btn: Button = _make_button("创建并进入大厅", vbox)
	create_btn.pressed.connect(_on_create_room)

	var back_btn: Button = _make_button("返回", vbox)
	back_btn.pressed.connect(func(): _show_panel("mode"))

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	vbox.add_child(status_label)


func _build_join_panel() -> void:
	join_panel = Panel.new()
	join_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	join_panel.modulate = Color(0.08, 0.08, 0.12, 1.0)
	add_child(join_panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(400, 0)
	vbox.add_theme_constant_override("separation", 10)
	join_panel.add_child(vbox)

	var title: Label = Label.new()
	title.text = "加入房间"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	vbox.add_child(title)

	vbox.add_child(_make_spacer(10))

	_make_label("主机IP：", vbox)
	join_ip_edit = LineEdit.new()
	join_ip_edit.text = "127.0.0.1"
	join_ip_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(join_ip_edit)

	_make_label("端口：", vbox)
	join_port_edit = LineEdit.new()
	join_port_edit.text = str(NETWORK_PORT)
	join_port_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(join_port_edit)

	_make_label("昵称：", vbox)
	join_nick_edit = LineEdit.new()
	join_nick_edit.text = "玩家" + str(randi() % 1000)
	join_nick_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(join_nick_edit)

	vbox.add_child(_make_spacer(10))

	var connect_btn: Button = _make_button("连接", vbox)
	connect_btn.pressed.connect(_on_join_room)

	var back_btn: Button = _make_button("返回", vbox)
	back_btn.pressed.connect(func(): _show_panel("mode"))


func _build_lobby_panel() -> void:
	lobby_panel = Panel.new()
	lobby_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	lobby_panel.modulate = Color(0.06, 0.06, 0.10, 1.0)
	add_child(lobby_panel)

	# Top bar
	var top_bar: HBoxContainer = HBoxContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_left = 20
	top_bar.offset_right = -20
	top_bar.offset_top = 15
	top_bar.add_theme_constant_override("separation", 20)
	lobby_panel.add_child(top_bar)

	lobby_title = Label.new()
	lobby_title.text = "等待大厅"
	lobby_title.add_theme_font_size_override("font_size", 22)
	lobby_title.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	top_bar.add_child(lobby_title)

	ip_port_label = Label.new()
	ip_port_label.add_theme_font_size_override("font_size", 14)
	ip_port_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	top_bar.add_child(ip_port_label)

	# Center: player list + chat
	var center: HBoxContainer = HBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.custom_minimum_size = Vector2(700, 400)
	center.add_theme_constant_override("separation", 20)
	lobby_panel.add_child(center)

	# Left: player list
	var left: VBoxContainer = VBoxContainer.new()
	left.custom_minimum_size = Vector2(300, 0)
	left.add_theme_constant_override("separation", 8)
	center.add_child(left)

	var list_title: Label = Label.new()
	list_title.text = "玩家列表"
	list_title.add_theme_font_size_override("font_size", 18)
	list_title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	left.add_child(list_title)

	player_list_vbox = VBoxContainer.new()
	player_list_vbox.add_theme_constant_override("separation", 6)
	left.add_child(player_list_vbox)

	# Right: chat
	var right: VBoxContainer = VBoxContainer.new()
	right.custom_minimum_size = Vector2(360, 0)
	right.add_theme_constant_override("separation", 8)
	center.add_child(right)

	var chat_title: Label = Label.new()
	chat_title.text = "聊天"
	chat_title.add_theme_font_size_override("font_size", 18)
	chat_title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	right.add_child(chat_title)

	chat_box = RichTextLabel.new()
	chat_box.custom_minimum_size = Vector2(360, 280)
	chat_box.bbcode_enabled = true
	chat_box.scroll_following = true
	right.add_child(chat_box)

	chat_input = LineEdit.new()
	chat_input.placeholder_text = "输入消息，回车发送..."
	chat_input.text_submitted.connect(_on_chat_submitted)
	right.add_child(chat_input)

	# Bottom bar
	var bottom: HBoxContainer = HBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 20
	bottom.offset_right = -20
	bottom.offset_bottom = -20
	bottom.add_theme_constant_override("separation", 12)
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	lobby_panel.add_child(bottom)

	ready_button = _make_button("准备", bottom)
	ready_button.pressed.connect(_on_ready_toggled)

	start_button = _make_button("开始游戏", bottom)
	start_button.pressed.connect(_on_start_game)
	start_button.visible = false  # Only host sees this

	var leave_btn: Button = _make_button("离开房间", bottom)
	leave_btn.pressed.connect(_on_leave_room)


# --- Panel switching ---

func _show_panel(panel_name: String) -> void:
	current_panel = panel_name
	main_panel.visible = (panel_name == "main")
	mode_panel.visible = (panel_name == "mode")
	create_panel.visible = (panel_name == "create")
	join_panel.visible = (panel_name == "join")
	lobby_panel.visible = (panel_name == "lobby")
	if panel_name == "lobby":
		_refresh_player_list()
		_update_lobby_header()


# --- Button handlers ---

func _on_create_room() -> void:
	var port: int = create_port_edit.text.to_int()
	if port < 1024 or port > 65535:
		status_label.text = "端口范围：1024-65535"
		return
	var err: Error = NetworkManager.create_server(port)
	if err == OK:
		_show_panel("lobby")
		_add_chat_message("系统", "房间已创建，等待玩家加入...", Color(0.5, 0.9, 0.5))
	else:
		status_label.text = "创建失败：端口可能被占用"


func _on_join_room() -> void:
	var ip: String = join_ip_edit.text.strip_edges()
	var port: int = join_port_edit.text.to_int()
	var nick: String = join_nick_edit.text.strip_edges()
	if nick.is_empty():
		nick = "玩家" + str(randi() % 1000)
	var err: Error = NetworkManager.join_server(ip, port, nick)
	if err != OK:
		status_label.text = "连接失败，请检查IP和端口"
		return
	# Wait for connected_to_server signal; on success _on_connected_to_server shows lobby


func _connect_dedicated_server() -> void:
	# Connect to Shanghai dedicated server (IP to be filled by user)
	var ip: String = "127.0.0.1"  # Will be replaced with server IP
	var nick: String = "玩家" + str(randi() % 1000)
	NetworkManager.join_server(ip, NETWORK_PORT, nick)


func _on_ready_toggled() -> void:
	var is_ready: bool = ready_button.text == "准备"
	NetworkManager.set_ready.rpc(is_ready)
	ready_button.text = "取消准备" if is_ready else "准备"


func _on_start_game() -> void:
	if not NetworkManager.all_ready():
		_add_chat_message("系统", "还有玩家未准备！", Color(1.0, 0.5, 0.5))
		return
	NetworkManager.start_game.rpc()


func _on_leave_room() -> void:
	NetworkManager.leave_server()
	_show_panel("main")


func _on_chat_submitted(text: String) -> void:
	if text.strip_edges().is_empty():
		return
	NetworkManager.send_chat.rpc(text)
	chat_input.clear()


# --- Network signal handlers ---

func _on_player_connected(peer_id: int) -> void:
	_refresh_player_list()
	_add_chat_message("系统", "玩家 " + str(peer_id) + " 加入了房间", Color(0.5, 0.9, 0.5))


func _on_player_disconnected(peer_id: int) -> void:
	_refresh_player_list()
	_add_chat_message("系统", "玩家 " + str(peer_id) + " 离开了房间", Color(1.0, 0.5, 0.5))


func _on_player_ready_changed(peer_id: int, ready: bool) -> void:
	_refresh_player_list()


func _on_chat_received(peer_id: int, text: String) -> void:
	var info: Dictionary = NetworkManager.get_player_info(peer_id)
	var name: String = info.get("name", "玩家" + str(peer_id))
	_add_chat_message(name, text, Color(0.9, 0.9, 0.9))


func _on_connection_failed() -> void:
	status_label.text = "连接失败，请检查IP和端口"
	_show_panel("join")


func _on_server_disconnected() -> void:
	_add_chat_message("系统", "与主机断开连接", Color(1.0, 0.4, 0.4))
	await get_tree().create_timer(2.0).timeout
	NetworkManager.leave_server()
	_show_panel("main")


func _on_game_started() -> void:
	# Scene change is handled by NetworkManager.start_game RPC
	pass


func _on_connected_to_server() -> void:
	_show_panel("lobby")
	_add_chat_message("系统", "已连接到主机", Color(0.5, 0.9, 0.5))


# --- UI helpers ---

func _refresh_player_list() -> void:
	if player_list_vbox == null:
		return
	for child in player_list_vbox.get_children():
		child.queue_free()

	for i in range(NetworkManager.MAX_PLAYERS):
		var peer_id: int = i + 1
		var info: Dictionary = NetworkManager.get_player_info(peer_id)
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var color_box: ColorRect = ColorRect.new()
		color_box.custom_minimum_size = Vector2(16, 16)
		if not info.is_empty():
			var colors: Array = [Color(0.9, 0.3, 0.3), Color(0.3, 0.9, 0.3), Color(0.3, 0.5, 0.9), Color(0.9, 0.9, 0.3)]
			color_box.color = colors[i % 4]
		else:
			color_box.color = Color(0.3, 0.3, 0.3)
		row.add_child(color_box)

		var name_label: Label = Label.new()
		if not info.is_empty():
			name_label.text = info.get("name", "玩家" + str(peer_id))
			if peer_id == 1:
				name_label.text += " (主机)"
		else:
			name_label.text = "（空）"
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.custom_minimum_size = Vector2(150, 0)
		row.add_child(name_label)

		var status_label_row: Label = Label.new()
		if not info.is_empty():
			if info.get("ready", false):
				status_label_row.text = "已准备"
				status_label_row.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
			else:
				status_label_row.text = "未准备"
				status_label_row.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
		else:
			status_label_row.text = ""
		status_label_row.add_theme_font_size_override("font_size", 14)
		row.add_child(status_label_row)

		player_list_vbox.add_child(row)

	# Update start button visibility
	start_button.visible = NetworkManager.is_host()
	if NetworkManager.is_host():
		start_button.disabled = not NetworkManager.all_ready()


func _update_lobby_header() -> void:
	if NetworkManager.is_host():
		lobby_title.text = "等待大厅（主机）"
		ip_port_label.text = "端口: " + str(NetworkManager.server_port)
	else:
		lobby_title.text = "等待大厅"
		ip_port_label.text = NetworkManager.server_address + ":" + str(NetworkManager.server_port)


func _add_chat_message(sender: String, text: String, color: Color) -> void:
	if chat_box == null:
		return
	chat_box.append_text("[color=#%s]%s:[/color] %s\n" % [color.to_html(), sender, text])


func _make_button(text: String, parent: Node) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 44)
	btn.add_theme_font_size_override("font_size", 16)
	parent.add_child(btn)
	return btn


func _make_label(text: String, parent: Node) -> Label:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	parent.add_child(lbl)
	return lbl


func _make_spacer(height: int) -> Control:
	var sp: Control = Control.new()
	sp.custom_minimum_size = Vector2(0, height)
	return sp

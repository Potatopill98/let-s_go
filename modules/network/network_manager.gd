extends Node
## NetworkManager - Autoload singleton
## Supports both P2P host mode and dedicated server mode.
## Dedicated server: launch with --server argument (usually with --headless).

const DEFAULT_PORT: int = 5678
const MAX_PLAYERS: int = 4
const LEVEL1_SCENE: String = "res://scenes/level1_lab.tscn"

var peer: ENetMultiplayerPeer = null
var players: Dictionary = {}
var local_nickname: String = "Player"
var server_address: String = "127.0.0.1"
var server_port: int = DEFAULT_PORT
var is_dedicated_server: bool = false

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal connection_failed()
signal server_disconnected()
signal player_ready_changed(peer_id: int, ready: bool)
signal chat_received(peer_id: int, text: String)
signal all_players_loaded()
signal game_started()


func _ready() -> void:
	# Detect dedicated server mode from command line arguments
	var args: PackedStringArray = OS.get_cmdline_args()
	for arg in args:
		if arg == "--server":
			is_dedicated_server = true
		if arg.begins_with("--port="):
			server_port = arg.substr(7).to_int()
		if arg.begins_with("--nick="):
			local_nickname = arg.substr(7)

	if is_dedicated_server:
		# Dedicated server: auto-start and enter game
		var err: Error = create_server(server_port)
		if err == OK:
			print("[Network] Dedicated server started on port ", server_port)
			# Delay scene change to next frame to let signals settle
			call_deferred("_enter_game_scene")
		else:
			push_error("[Network] Failed to start dedicated server: " + str(err))


func _enter_game_scene() -> void:
	get_tree().change_scene_to_file(LEVEL1_SCENE)


func create_server(port: int = DEFAULT_PORT) -> Error:
	peer = ENetMultiplayerPeer.new()
	var err: Error = peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		peer = null
		return err
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	players[1] = {"id": 1, "name": local_nickname, "ready": true, "loaded": false}
	return OK


func join_server(address: String, port: int = DEFAULT_PORT, nickname: String = "Player") -> Error:
	local_nickname = nickname
	server_address = address
	server_port = port
	peer = ENetMultiplayerPeer.new()
	var err: Error = peer.create_client(address, port)
	if err != OK:
		peer = null
		return err
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	return OK


func leave_server() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer = null
	if peer != null:
		peer.close()
		peer = null
	players.clear()


func is_host() -> bool:
	return multiplayer.is_server()


func get_player_count() -> int:
	return players.size()


func get_ready_count() -> int:
	var count: int = 0
	for key in players:
		if players[key].get("ready", false):
			count += 1
	return count


func all_ready() -> bool:
	if players.is_empty():
		return false
	for key in players:
		if not players[key].get("ready", false):
			return false
	return true


func get_player_info(peer_id: int) -> Dictionary:
	if players.has(peer_id):
		return players[peer_id]
	return {}


# --- Server-side event handlers ---

func _on_peer_connected(id: int) -> void:
	print("[Network] Player connected: ", id)
	# Player will register via _register_player RPC
	player_connected.emit(id)


func _on_peer_disconnected(id: int) -> void:
	print("[Network] Player disconnected: ", id)
	if players.has(id):
		players.erase(id)
	player_disconnected.emit(id)


# --- Client-side event handlers ---

func _on_connected_to_server() -> void:
	print("[Network] Connected to server")
	_register_player.rpc(local_nickname)


func _on_connection_failed() -> void:
	print("[Network] Connection failed")
	connection_failed.emit()


func _on_server_disconnected() -> void:
	print("[Network] Server disconnected")
	server_disconnected.emit()


# --- RPC: Player registration ---

@rpc("any_peer", "call_local")
func _register_player(nickname: String) -> void:
	if not is_host():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if players.has(sender_id):
		players[sender_id]["name"] = nickname
	else:
		players[sender_id] = {"id": sender_id, "name": nickname, "ready": false, "loaded": false}
	print("[Network] Registered player ", sender_id, " as ", nickname)
	_broadcast_player_list.rpc()


@rpc("authority", "call_local")
func _broadcast_player_list() -> void:
	# Clients update their local player list from this broadcast
	pass


# --- RPC: Ready state ---

@rpc("any_peer")
func set_ready(ready: bool) -> void:
	if not is_host():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if players.has(sender_id):
		players[sender_id]["ready"] = ready
		player_ready_changed.emit(sender_id, ready)
		_broadcast_ready.rpc(sender_id, ready)


@rpc("authority", "call_local")
func _broadcast_ready(peer_id: int, ready: bool) -> void:
	player_ready_changed.emit(peer_id, ready)


# --- RPC: Chat ---

@rpc("any_peer")
func send_chat(text: String) -> void:
	if not is_host():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	var name: String = "Unknown"
	if players.has(sender_id):
		name = players[sender_id].get("name", "Unknown")
	_broadcast_chat.rpc(sender_id, name, text)


@rpc("authority", "call_local")
func _broadcast_chat(peer_id: int, name: String, text: String) -> void:
	chat_received.emit(peer_id, text)


# --- RPC: Game start and loading ---

@rpc("authority", "call_local")
func start_game() -> void:
	game_started.emit()
	get_tree().change_scene_to_file(LEVEL1_SCENE)


@rpc("any_peer")
func report_loaded() -> void:
	if not is_host():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if players.has(sender_id):
		players[sender_id]["loaded"] = true
	# Check if all players loaded
	var all_loaded: bool = true
	for key in players:
		if not players[key].get("loaded", false):
			all_loaded = false
			break
	if all_loaded:
		all_players_loaded.emit()
		print("[Network] All players loaded, game can begin")

extends Node
## 音频管理器 - 统一管理所有音效、音乐、音量

# 音量通道
var master_volume: float = 0.8
var sfx_volume: float = 0.7
var music_volume: float = 0.3
var voice_volume: float = 0.8
var ambient_volume: float = 0.5

# 音效缓存
var _sfx_cache: Dictionary = {}
var _music_cache: Dictionary = {}

# 当前播放的音乐
var _current_music: AudioStreamPlayer = null
var _current_music_name: String = ""

# 循环音效实例（警报、脚步等）
var _looping_sfx: Dictionary = {}

# AudioBus名称
const BUS_MASTER: String = "Master"
const BUS_SFX: String = "SFX"
const BUS_MUSIC: String = "Music"
const BUS_VOICE: String = "Voice"
const BUS_AMBIENT: String = "Ambient"

func _ready() -> void:
	_ensure_buses()
	_load_settings()
	apply_volumes()

func _ensure_buses() -> void:
	# 确保AudioBus存在
	var buses: Array = ["SFX", "Music", "Voice", "Ambient"]
	for bus_name in buses:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx: int = AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")

func _load_settings() -> void:
	var path: String = "user://audio_settings.json"
	if not FileAccess.file_exists(path):
		return
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	f.close()
	if data.has("master_volume"):
		master_volume = data["master_volume"]
	if data.has("sfx_volume"):
		sfx_volume = data["sfx_volume"]
	if data.has("music_volume"):
		music_volume = data["music_volume"]
	if data.has("voice_volume"):
		voice_volume = data["voice_volume"]
	if data.has("ambient_volume"):
		ambient_volume = data["ambient_volume"]

func _save_settings() -> void:
	var path: String = "user://audio_settings.json"
	var data: Dictionary = {
		"master_volume": master_volume,
		"sfx_volume": sfx_volume,
		"music_volume": music_volume,
		"voice_volume": voice_volume,
		"ambient_volume": ambient_volume
	}
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data))
		f.close()

func apply_volumes() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_MASTER), _linear_to_db(master_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_SFX), _linear_to_db(sfx_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_MUSIC), _linear_to_db(music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_VOICE), _linear_to_db(voice_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_AMBIENT), _linear_to_db(ambient_volume))

func _linear_to_db(linear: float) -> float:
	if linear <= 0.0:
		return -80.0
	return 20.0 * log(linear) / log(10.0)

func _get_sfx_stream(name: String) -> AudioStream:
	if _sfx_cache.has(name):
		return _sfx_cache[name]
	var path: String = "res://assets/audio/sfx/" + name + ".mp3"
	var stream: AudioStream = load(path)
	if stream == null:
		push_warning("AudioManager: 音效未找到 " + path)
		return null
	_sfx_cache[name] = stream
	return stream

## 播放一次音效（2D）
func play_sfx(name: String, volume: float = 1.0, pitch: float = 1.0) -> void:
	var stream: AudioStream = _get_sfx_stream(name)
	if stream == null:
		return
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = _linear_to_db(volume)
	player.pitch_scale = pitch
	player.bus = BUS_SFX
	player.finished.connect(func(): player.queue_free())
	add_child(player)
	player.play()

## 播放3D音效（随距离衰减）
func play_sfx_3d(name: String, position: Vector3, volume: float = 1.0, pitch: float = 1.0, max_distance: float = 20.0) -> AudioStreamPlayer3D:
	var stream: AudioStream = _get_sfx_stream(name)
	if stream == null:
		return null
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = _linear_to_db(volume)
	player.pitch_scale = pitch
	player.bus = BUS_SFX
	player.position = position
	player.max_distance = max_distance
	player.unit_size = 1.0
	player.autoplay = true
	player.finished.connect(func(): player.queue_free())
	get_tree().current_scene.add_child(player)
	return player

## 播放循环音效（可停止）
func play_loop(name: String, volume: float = 1.0) -> String:
	var loop_id: String = name + "_" + str(Time.get_ticks_msec())
	var stream: AudioStream = _get_sfx_stream(name)
	if stream == null:
		return ""
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = _linear_to_db(volume)
	player.bus = BUS_SFX
	if stream is AudioStreamMP3:
		stream.loop = true
	add_child(player)
	player.play()
	_looping_sfx[loop_id] = player
	return loop_id

func stop_loop(loop_id: String) -> void:
	if _looping_sfx.has(loop_id):
		var player: AudioStreamPlayer = _looping_sfx[loop_id]
		player.stop()
		player.queue_free()
		_looping_sfx.erase(loop_id)

## 播放背景音乐（循环，切换时淡出）
func play_music(name: String, volume: float = 1.0, fade_time: float = 1.0) -> void:
	if _current_music_name == name and _current_music != null and _current_music.playing:
		return
	# 淡出旧音乐
	if _current_music != null:
		var old_music: AudioStreamPlayer = _current_music
		var tween: Tween = create_tween()
		tween.tween_property(old_music, "volume_db", -40.0, fade_time)
		tween.tween_callback(func(): old_music.stop(); old_music.queue_free())
	# 淡入新音乐
	var path: String = "res://assets/audio/music/" + name + ".mp3"
	var stream: AudioStream = load(path)
	if stream == null:
		# 尝试从sfx目录加载氛围音
		path = "res://assets/audio/sfx/" + name + ".mp3"
		stream = load(path)
	if stream == null:
		push_warning("AudioManager: 音乐未找到 " + name)
		return
	if stream is AudioStreamMP3:
		stream.loop = true
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = -40.0
	player.bus = BUS_MUSIC
	add_child(player)
	player.play()
	var tween2: Tween = create_tween()
	tween2.tween_property(player, "volume_db", _linear_to_db(volume), fade_time)
	_current_music = player
	_current_music_name = name

func stop_music(fade_time: float = 1.0) -> void:
	if _current_music != null:
		var old_music: AudioStreamPlayer = _current_music
		var tween: Tween = create_tween()
		tween.tween_property(old_music, "volume_db", -40.0, fade_time)
		tween.tween_callback(func(): old_music.stop(); old_music.queue_free())
		_current_music = null
		_current_music_name = ""

## 设置音量（0-1）
func set_master_volume(v: float) -> void:
	master_volume = clampf(v, 0.0, 1.0)
	apply_volumes()
	_save_settings()

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	apply_volumes()
	_save_settings()

func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	apply_volumes()
	_save_settings()

func set_voice_volume(v: float) -> void:
	voice_volume = clampf(v, 0.0, 1.0)
	apply_volumes()
	_save_settings()

func set_ambient_volume(v: float) -> void:
	ambient_volume = clampf(v, 0.0, 1.0)
	apply_volumes()
	_save_settings()

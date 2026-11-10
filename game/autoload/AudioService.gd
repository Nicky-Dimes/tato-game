extends Node
## Sound effects, Tato's voice and music. Sounds are looked up by name in
## res://assets/audio/{sfx,voice,music}/<name>.ogg and a missing file is
## simply silent, so content can be authored before its audio exists.
## Voice count is capped to stay friendly to phones and tablets.

const SFX_DIR := "res://assets/audio/sfx/"
const VOICE_DIR := "res://assets/audio/voice/"
const MUSIC_DIR := "res://assets/audio/music/"
const SFX_VOICES := 10
const VOICE_VOICES := 3

var _cache: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _voice_players: Array[AudioStreamPlayer] = []
var _ui_player: AudioStreamPlayer
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_current := ""
var _music_tween: Tween
var _last_played: Dictionary = {}   # name -> msec, to stop stacking the same sound
var _next_sfx := 0
var _next_voice := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in SFX_VOICES:
		_sfx_players.append(_make_player("SFX"))
	for i in VOICE_VOICES:
		_voice_players.append(_make_player("Voice"))
	_ui_player = _make_player("UI")
	_music_a = _make_player("Music")
	_music_b = _make_player("Music")


func _make_player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus if AudioServer.get_bus_index(bus) >= 0 else "Master"
	add_child(p)
	return p


func _stream(dir: String, sound: String) -> AudioStream:
	var key := dir + sound
	if _cache.has(key):
		return _cache[key]
	var stream: AudioStream = null
	for ext in [".ogg", ".wav"]:
		var path: String = key + ext
		if ResourceLoader.exists(path):
			stream = load(path) as AudioStream
			break
	_cache[key] = stream
	return stream


func has_sound(sound: String) -> bool:
	return _stream(SFX_DIR, sound) != null or _stream(VOICE_DIR, sound) != null


## Plays a sound effect. `gap` (seconds) stops the same sound re-triggering in
## a burst (twenty crumbs at once should not be twenty voices).
func play(sound: String, volume_db: float = 0.0, pitch: float = 1.0, gap: float = 0.04) -> void:
	var stream := _stream(SFX_DIR, sound)
	if stream == null:
		return
	var now := Time.get_ticks_msec()
	if _last_played.has(sound) and now - int(_last_played[sound]) < int(gap * 1000.0):
		return
	_last_played[sound] = now
	var p := _sfx_players[_next_sfx]
	_next_sfx = (_next_sfx + 1) % _sfx_players.size()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = clampf(pitch, 0.4, 2.5)
	p.play()


## Random small pitch change keeps repeated sounds from feeling mechanical.
func play_varied(sound: String, volume_db: float = 0.0, spread: float = 0.08) -> void:
	play(sound, volume_db, 1.0 + randf_range(-spread, spread))


func voice(sound: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var stream := _stream(VOICE_DIR, sound)
	if stream == null:
		stream = _stream(VOICE_DIR, "honk")
	if stream == null:
		return
	var p := _voice_players[_next_voice]
	_next_voice = (_next_voice + 1) % _voice_players.size()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = clampf(pitch, 0.4, 2.5)
	p.play()


func ui(sound: String, volume_db: float = -4.0) -> void:
	var stream := _stream(SFX_DIR, sound)
	if stream == null:
		return
	_ui_player.stream = stream
	_ui_player.volume_db = volume_db
	_ui_player.pitch_scale = 1.0
	_ui_player.play()


func music(track: String, fade: float = 0.8) -> void:
	if track == _music_current:
		return
	_music_current = track
	var stream: AudioStream = null
	if track != "":
		stream = _stream(MUSIC_DIR, track)
		if stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		elif stream is AudioStreamWAV:
			(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
	var old := _music_a
	var fresh := _music_b
	_music_a = fresh
	_music_b = old
	if not old.playing and stream == null:
		return
	_music_tween = create_tween().set_parallel(true)
	if old.playing:
		_music_tween.tween_property(old, "volume_db", -40.0, fade)
		_music_tween.tween_callback(old.stop).set_delay(fade)
	if stream != null:
		fresh.stream = stream
		fresh.volume_db = -40.0
		fresh.play()
		_music_tween.tween_property(fresh, "volume_db", 0.0, fade)


func music_name() -> String:
	return _music_current


## Briefly lowers the music under an important sound (recipe found, page get).
func duck_music(seconds: float = 1.2) -> void:
	if not _music_a.playing:
		return
	var t := create_tween()
	t.tween_property(_music_a, "volume_db", -12.0, 0.15)
	t.tween_interval(seconds)
	t.tween_property(_music_a, "volume_db", 0.0, 0.4)

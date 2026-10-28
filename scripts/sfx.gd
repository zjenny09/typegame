class_name Sfx
extends RefCounted
## 程序化合成音效（运行时生成 16-bit PCM，无外部素材，无版权负担）。
## 全部静态接口：Sfx.play("type")。音效名见 _synth 的 match 表。

const MIX_RATE := 44100
const FW_LIFE := 0.0  # 占位避免误用（本类无烟花逻辑）

static var _cache: Dictionary = {}


static func play(sfx_name: String) -> void:
	var s := stream(sfx_name)
	if s == null:
		return
	var ml := Engine.get_main_loop()
	if ml == null or not (ml is SceneTree):
		return
	var p := AudioStreamPlayer.new()
	p.stream = s
	p.volume_db = -8.0
	p.max_polyphony = 3
	p.finished.connect(p.queue_free)
	(ml as SceneTree).root.add_child(p)
	p.play()


static func stream(sfx_name: String) -> AudioStreamWAV:
	if not _cache.has(sfx_name):
		_cache[sfx_name] = _synth(sfx_name)
	return _cache[sfx_name]


static func _synth(sfx_name: String) -> AudioStreamWAV:
	match sfx_name:
		"type":
			return _to_wav(_samples_tone(0.045, 1150.0, 1150.0, 0.32))
		"click":
			return _to_wav(_samples_tone(0.05, 700.0, 520.0, 0.38))
		"move":
			return _to_wav(_samples_tone(0.09, 500.0, 260.0, 0.32))
		"confirm":
			return _to_wav(_samples_arp([660.0, 990.0], 0.07, 0.4))
		"wrong":
			return _to_wav(_samples_square(0.18, 170.0, 0.38))
		"jump":
			return _to_wav(_samples_tone(0.16, 300.0, 730.0, 0.5))
		"splash":
			return _to_wav(_samples_noise(0.22, 0.42, 2.2))
		"step":
			return _to_wav(_samples_tone(0.09, 135.0, 88.0, 0.62))
		"pop":
			return _to_wav(_mix_samples(
				_samples_noise(0.12, 0.5, 3.0),
				_samples_tone(0.1, 520.0, 200.0, 0.35)))
		"firework":
			return _to_wav(_mix_samples(
				_samples_noise(0.55, 0.4, 1.6),
				_samples_tone(0.18, 760.0, 1420.0, 0.3)))
		"win":
			return _to_wav(_samples_arp([523.25, 659.25, 783.99, 1046.5], 0.11, 0.45))
		"lose":
			return _to_wav(_samples_arp([330.0, 262.0, 196.0], 0.16, 0.42))
		"thud":
			return _to_wav(_samples_tone(0.25, 95.0, 58.0, 0.6))
	return _to_wav(_samples_tone(0.05, 800.0, 800.0, 0.3))


static func _samples_tone(dur: float, f0: float, f1: float, vol: float) -> PackedFloat32Array:
	var n := int(dur * MIX_RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / float(n)
		phase += TAU * lerpf(f0, f1, t) / MIX_RATE
		var env := minf(1.0, float(i) / (0.006 * MIX_RATE)) * pow(1.0 - t, 1.6)
		s[i] = sin(phase) * vol * env
	if n > 0:
		s[n - 1] = 0.0
	return s


static func _samples_square(dur: float, freq: float, vol: float) -> PackedFloat32Array:
	var n := int(dur * MIX_RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / float(n)
		phase += TAU * freq / MIX_RATE
		var env := minf(1.0, float(i) / (0.008 * MIX_RATE)) * pow(1.0 - t, 1.2)
		s[i] = (1.0 if sin(phase) > 0.0 else -1.0) * vol * env * 0.7
	if n > 0:
		s[n - 1] = 0.0
	return s


static func _samples_noise(dur: float, vol: float, decay_pow: float) -> PackedFloat32Array:
	var n := int(dur * MIX_RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / float(n)
		s[i] = randf_range(-1.0, 1.0) * vol * pow(1.0 - t, decay_pow)
	if n > 0:
		s[n - 1] = 0.0
	return s


static func _samples_arp(freqs: Array, note_dur: float, vol: float) -> PackedFloat32Array:
	var s := PackedFloat32Array()
	for freq in freqs:
		s.append_array(_samples_tone(note_dur, freq, freq, vol))
	return s


static func _mix_samples(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var n := maxi(a.size(), b.size())
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var va := a[i] if i < a.size() else 0.0
		var vb := b[i] if i < b.size() else 0.0
		s[i] = clampf(va + vb, -1.0, 1.0)
	return s


static func _to_wav(s: PackedFloat32Array) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	var bytes := PackedByteArray()
	bytes.resize(s.size() * 2)
	for i in s.size():
		bytes.encode_s16(i * 2, int(clampf(s[i], -1.0, 1.0) * 32767.0))
	wav.data = bytes
	return wav

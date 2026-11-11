extends Node
## Sound (autoload "Sfx"). Every sound is synthesised at startup, so the
## game ships no audio files: punchy gunshots with a papery snap, paper
## footsteps, crumples, cotton-thump explosions and UI ticks.

const RATE := 22050

var _bank := {}
var _pool3d: Array[AudioStreamPlayer3D] = []
var _pool_ui: Array[AudioStreamPlayer] = []
var _next3d := 0
var _next_ui := 0
var _seed := 1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_bank()
	for i in 28:
		var p := AudioStreamPlayer3D.new()
		p.unit_size = 7.0
		p.max_distance = 140.0
		p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		p.panning_strength = 1.0
		add_child(p)
		_pool3d.append(p)
	for i in 10:
		var u := AudioStreamPlayer.new()
		add_child(u)
		_pool_ui.append(u)


func play_3d(name: String, pos: Vector3, volume_db := 0.0) -> void:
	if not _bank.has(name):
		return
	var p := _pool3d[_next3d]
	_next3d = (_next3d + 1) % _pool3d.size()
	p.stream = _bank[name]
	p.global_position = pos
	p.volume_db = volume_db
	p.pitch_scale = randf_range(0.94, 1.06)
	p.play()


func play_ui(name: String, volume_db := 0.0) -> void:
	if not _bank.has(name):
		return
	var p := _pool_ui[_next_ui]
	_next_ui = (_next_ui + 1) % _pool_ui.size()
	p.stream = _bank[name]
	p.volume_db = volume_db
	p.pitch_scale = 1.0
	p.play()


# --------------------------------------------------------------- synthesis

func _rand() -> float:
	_seed = (_seed * 1103515245 + 12345) & 0x7fffffff
	return float(_seed) / float(0x7fffffff) * 2.0 - 1.0


func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	var peak := 0.0001
	for s in samples:
		peak = maxf(peak, absf(s))
	var norm := 0.95 / peak if peak > 0.95 else 1.0
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i] * norm, -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w


## A looping helicopter rotor: thudding blade slaps over a turbine whine.
func _rotor() -> AudioStreamWAV:
	var n := int(RATE * 1.0)
	var s := PackedFloat32Array()
	s.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		var ph := fmod(t * 14.0, 1.0)
		var slap := exp(-ph * 18.0)
		lp += (_rand() - lp) * 0.08
		var whine := sin(TAU * 620.0 * t) * 0.04 + sin(TAU * 1240.0 * t) * 0.015
		s[i] = (lp * 2.2 * (0.35 + slap) + sin(TAU * 56.0 * t) * slap * 0.6) * 0.7 + whine
	var w := _wav(s)
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = n
	return w


## A short dog bark: a pitched growl with a noisy edge.
func _bark() -> AudioStreamWAV:
	var n := int(RATE * 0.32)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / RATE
		var env := minf(t * 60.0, 1.0) * exp(-t * 9.0)
		var f := 420.0 - t * 500.0
		var v := sin(TAU * f * t) * 0.6 + sin(TAU * f * 2.02 * t) * 0.3 + _rand() * 0.35
		s[i] = v * env
	return _wav(s)


## Gunshot: a noise crack, a low body thump, and a papery snap on top.
func _shot(len: float, body_hz: float, crack: float, tail: float, lp: float, snap := 0.35) -> AudioStreamWAV:
	var n := int(len * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var low := 0.0
	var low2 := 0.0
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var noise := _rand()
		low += (noise - low) * lp
		low2 += (low - low2) * lp
		var env_crack := exp(-t * crack)
		var env_tail := exp(-t * tail)
		var f := body_hz * (1.0 + 2.0 * exp(-t * 40.0))
		phase += f / RATE * TAU
		var body := sin(phase) * exp(-t * 18.0)
		var snap_v := noise * exp(-t * 300.0) * snap
		out[i] = low2 * env_crack * 1.2 + low * env_tail * 0.35 + body * 0.9 + snap_v
	return _wav(out)


## A soft, muffled footfall: a low felt thump with a faint cardboard
## creak. Four slightly different variants so steps never sound looped.
func _footstep(variant: int) -> AudioStreamWAV:
	var len := 0.16
	var n := int(len * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var low := 0.0
	var low2 := 0.0
	var phase := 0.0
	var f0 := 70.0 + variant * 9.0
	for i in n:
		var t := float(i) / RATE
		var noise := _rand()
		low += (noise - low) * 0.06
		low2 += (low - low2) * 0.06
		phase += f0 * (1.0 + exp(-t * 30.0)) / RATE * TAU
		var thump := sin(phase) * exp(-t * 32.0)
		var scuff := low2 * exp(-t * 22.0) * 3.0
		var attack := minf(1.0, t * 250.0)
		out[i] = (thump * 0.7 + scuff * 0.5) * attack
	return _wav(out)


func _noise_burst(len: float, lp: float, decay: float, hp := 0.0, crackle := 0.0) -> AudioStreamWAV:
	var n := int(len * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var low := 0.0
	var prev := 0.0
	for i in n:
		var t := float(i) / RATE
		var noise := _rand()
		low += (noise - low) * lp
		var v := low - prev * hp
		prev = low
		var env := exp(-t * decay) * minf(1.0, t * 400.0)
		var c := 0.0
		if crackle > 0.0 and absf(_rand()) > 1.0 - crackle:
			c = _rand() * 0.8
		out[i] = (v + c) * env
	return _wav(out)


func _tone(freqs: Array, note_len: float, wave := 0, decay := 8.0, vol := 0.6) -> AudioStreamWAV:
	var n := int(note_len * freqs.size() * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var per := int(note_len * RATE)
	for i in n:
		var k := i / per
		var t := float(i % per) / RATE
		var f: float = freqs[mini(k, freqs.size() - 1)]
		var ph := t * f * TAU
		var v := sin(ph) if wave == 0 else (1.0 if sin(ph) > 0.0 else -1.0) * 0.5
		v += sin(ph * 2.0) * 0.25
		out[i] = v * exp(-t * decay) * minf(1.0, t * 300.0) * vol
	return _wav(out)


func _clicks(times: Array, len: float, tone_hz := 1800.0) -> AudioStreamWAV:
	var n := int(len * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var low := 0.0
	for i in n:
		var t := float(i) / RATE
		var v := 0.0
		for c in times:
			var dt: float = t - float(c)
			if dt >= 0.0 and dt < 0.05:
				v += (sin(dt * tone_hz * TAU) * 0.6 + _rand() * 0.5) * exp(-dt * 120.0)
		var noise := _rand()
		low += (noise - low) * 0.08
		out[i] = v + low * 0.15 * exp(-t * 6.0)
	return _wav(out)


func _sweep(len: float, f0: float, f1: float, noise_amt: float) -> AudioStreamWAV:
	var n := int(len * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	var low := 0.0
	for i in n:
		var t := float(i) / RATE
		var u := t / len
		var f := lerpf(f0, f1, u)
		phase += f / RATE * TAU
		var noise := _rand()
		low += (noise - low) * 0.2
		var env := sin(u * PI)
		out[i] = (sin(phase) * (1.0 - noise_amt) + low * noise_amt * 2.0) * env
	return _wav(out)


func _build_bank() -> void:
	_bank["rifle"] = _shot(0.42, 85.0, 30.0, 7.0, 0.35)
	_bank["rifle_heavy"] = _shot(0.5, 65.0, 24.0, 6.0, 0.28)
	_bank["smg"] = _shot(0.3, 110.0, 42.0, 10.0, 0.45, 0.45)
	_bank["pistol"] = _shot(0.32, 120.0, 40.0, 9.0, 0.5, 0.5)
	_bank["sniper"] = _shot(1.1, 55.0, 14.0, 3.0, 0.22, 0.3)
	_bank["shotgun"] = _shot(0.75, 60.0, 16.0, 4.5, 0.25, 0.4)
	_bank["explosion"] = _noise_burst(1.6, 0.05, 2.4, 0.0, 0.03)
	for i in 4:
		_bank["step%d" % i] = _footstep(i)
	_bank["step"] = _bank["step0"]
	_bank["jump"] = _noise_burst(0.12, 0.4, 30.0, 0.5, 0.04)
	_bank["land"] = _noise_burst(0.16, 0.18, 30.0, 0.0, 0.05)
	_bank["mantle"] = _noise_burst(0.3, 0.35, 10.0, 0.5, 0.08)
	_bank["reload"] = _clicks([0.05, 0.38, 0.62], 0.75, 1500.0)
	_bank["pump"] = _clicks([0.08, 0.22], 0.35, 900.0)
	_bank["dry"] = _clicks([0.0], 0.08, 2600.0)
	_bank["swap"] = _noise_burst(0.2, 0.4, 14.0, 0.6, 0.06)
	_bank["knife"] = _sweep(0.22, 1400.0, 300.0, 0.85)
	_bank["knife_hit"] = _noise_burst(0.25, 0.12, 18.0, 0.0, 0.15)
	_bank["throw"] = _sweep(0.3, 600.0, 200.0, 0.9)
	_bank["pin"] = _tone([2600.0], 0.18, 0, 25.0, 0.5)
	_bank["bounce"] = _tone([380.0], 0.08, 0, 50.0, 0.6)
	_bank["death"] = _noise_burst(0.55, 0.45, 6.0, 0.5, 0.25)
	_bank["hitmarker"] = _tone([1900.0], 0.045, 0, 60.0, 0.55)
	_bank["hit_kill"] = _tone([1900.0, 2500.0], 0.05, 0, 50.0, 0.6)
	_bank["rotor"] = _rotor()
	_bank["bark"] = _bark()
	_bank["heli_gun"] = _shot(0.22, 95.0, 46.0, 14.0, 0.5, 0.4)
	_bank["ui_click"] = _tone([880.0], 0.06, 0, 40.0, 0.45)
	_bank["ui_move"] = _tone([620.0], 0.04, 0, 60.0, 0.3)
	_bank["streak_ready"] = _tone([523.25, 659.25, 783.99, 1046.5], 0.09, 0, 10.0, 0.45)
	_bank["streak_use"] = _tone([392.0, 523.25, 659.25], 0.12, 1, 8.0, 0.35)
	_bank["rank_up"] = _tone([523.25, 659.25, 783.99, 1046.5, 1318.5], 0.11, 0, 6.0, 0.5)
	_bank["match_start"] = _tone([392.0, 392.0, 523.25], 0.16, 1, 6.0, 0.35)
	_bank["victory"] = _tone([523.25, 659.25, 783.99, 1046.5, 783.99, 1046.5], 0.16, 0, 4.0, 0.5)
	_bank["defeat"] = _tone([392.0, 349.23, 311.13, 261.63], 0.25, 0, 3.0, 0.45)
	_bank["plane"] = _sweep(2.5, 140.0, 120.0, 0.6)

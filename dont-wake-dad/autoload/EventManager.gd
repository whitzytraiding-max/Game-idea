extends Node

signal event_fired(event_name: String, data: Dictionary)

const EVENTS := [
	{"name": "dog_bark",        "weight": 30, "noise": 60.0,  "cooldown": 15.0},
	{"name": "sibling_door",    "weight": 20, "noise": 20.0,  "cooldown": 20.0},
	{"name": "microwave_beep",  "weight": 25, "noise": 45.0,  "cooldown": 12.0},
	{"name": "lego_spawn",      "weight": 15, "noise": 0.0,   "cooldown": 25.0},
	{"name": "fart",            "weight": 45, "noise": 15.0,  "cooldown": 8.0},
	{"name": "phone_buzz",      "weight": 35, "noise": 30.0,  "cooldown": 10.0},
	{"name": "dad_fake_stir",   "weight": 10, "noise": 0.0,   "cooldown": 30.0},
	{"name": "flicker",         "weight": 50, "noise": 0.0,   "cooldown": 6.0},
]

var _cooldowns: Dictionary = {}
var _timer: Timer
var _running: bool = false

func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_timer)
	add_child(_timer)
	for e in EVENTS:
		_cooldowns[e["name"]] = 0.0

func _process(delta: float) -> void:
	if not _running:
		return
	for key in _cooldowns.keys():
		if _cooldowns[key] > 0.0:
			_cooldowns[key] = max(_cooldowns[key] - delta, 0.0)

func start_events() -> void:
	_running = true
	_schedule_next()

func stop_events() -> void:
	_running = false
	_timer.stop()

func _schedule_next() -> void:
	if not _running:
		return
	var interval: float = randf_range(
		DifficultyManager.config["event_interval_min"],
		DifficultyManager.config["event_interval_max"]
	)
	_timer.start(interval)

func _on_timer() -> void:
	if not _running:
		return
	var available := []
	for e in EVENTS:
		if _cooldowns[e["name"]] <= 0.0:
			available.append(e)
	if available.size() > 0:
		var chosen := _weighted_pick(available)
		_fire_event(chosen)
	_schedule_next()

func _weighted_pick(pool: Array) -> Dictionary:
	var total := 0
	for e in pool:
		total += e["weight"]
	var roll: int = randi() % total
	var acc := 0
	for e in pool:
		acc += e["weight"]
		if roll < acc:
			return e
	return pool[0]

func _fire_event(e: Dictionary) -> void:
	_cooldowns[e["name"]] = e["cooldown"]
	if e["noise"] > 0.0:
		NoiseMeter.add_noise(e["noise"])
	event_fired.emit(e["name"], e)

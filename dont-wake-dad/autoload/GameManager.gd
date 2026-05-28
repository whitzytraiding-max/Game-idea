extends Node

signal run_started(objective: String)
signal run_completed(stars: int, peak_noise: float)
signal run_failed(completion_pct: float)
signal revive_available

const SCENE_MAIN_MENU := "res://scenes/main_menu.tscn"
const SCENE_GAME      := "res://scenes/game.tscn"
const SCENE_WIN       := "res://scenes/win_screen.tscn"
const SCENE_LOSE      := "res://scenes/lose_screen.tscn"

const OBJECTIVES := [
	"Get a snack from the kitchen",
	"Charge your phone",
	"Steal the TV remote",
	"Get a glass of water",
	"Rescue your Nintendo Switch",
	"Use the bathroom",
	"Get your shoes for school",
	"Check the fridge at midnight",
	"Silence your alarm clock",
	"Return the dog to his bed",
]

const LEVEL_SCENES := [
	"res://levels/level_1.tscn",
	"res://levels/level_2.tscn",
]

var current_run: int = 0
var total_stars: int = 0
var current_objective: String = ""
var current_level_index: int = 0
var revives_used_this_run: int = 0
var last_completion_pct: float = 0.0
var last_stars: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_run() -> void:
	current_run += 1
	revives_used_this_run = 0
	current_objective = OBJECTIVES[randi() % OBJECTIVES.size()]
	DifficultyManager.update_for_run(current_run)
	NoiseMeter.decay_rate = DifficultyManager.config.noise_decay_rate
	NoiseMeter.activate()
	NoiseMeter.reset(0.0)
	EventManager.start_events()
	run_started.emit(current_objective)

func complete_run() -> void:
	NoiseMeter.deactivate()
	EventManager.stop_events()
	var peak := NoiseMeter.get_peak()
	var stars := _calculate_stars(peak)
	last_stars = stars
	last_completion_pct = 100.0
	total_stars += stars
	run_completed.emit(stars, peak)
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file(SCENE_WIN)

func fail_run(completion_pct: float) -> void:
	NoiseMeter.deactivate()
	EventManager.stop_events()
	last_completion_pct = completion_pct
	run_failed.emit(completion_pct)
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file(SCENE_LOSE)

func use_revive() -> bool:
	if revives_used_this_run >= 2:
		return false
	revives_used_this_run += 1
	NoiseMeter.reset(70.0)
	NoiseMeter.activate()
	EventManager.start_events()
	return true

func go_to_main_menu() -> void:
	NoiseMeter.deactivate()
	EventManager.stop_events()
	get_tree().change_scene_to_file(SCENE_MAIN_MENU)

func go_to_game() -> void:
	get_tree().change_scene_to_file(SCENE_GAME)

func get_current_level_scene() -> String:
	return LEVEL_SCENES[current_level_index % LEVEL_SCENES.size()]

func advance_level() -> void:
	current_level_index = (current_level_index + 1) % LEVEL_SCENES.size()

func _calculate_stars(peak_noise: float) -> int:
	if peak_noise < 30.0:
		return 3
	elif peak_noise < 65.0:
		return 2
	else:
		return 1

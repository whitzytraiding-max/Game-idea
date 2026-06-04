extends Node

const SAVE_PATH := "user://save.cfg"

var total_stars: int = 0
var best_run: int = 0
var ads_removed: bool = false

func _ready() -> void:
	load_data()

func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	total_stars  = cfg.get_value("progress", "total_stars",  0)
	best_run     = cfg.get_value("progress", "best_run",     0)
	ads_removed  = cfg.get_value("purchases", "ads_removed", false)

func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress",  "total_stars",  total_stars)
	cfg.set_value("progress",  "best_run",     best_run)
	cfg.set_value("purchases", "ads_removed",  ads_removed)
	cfg.save(SAVE_PATH)

func add_stars(amount: int) -> void:
	total_stars += amount
	save_data()

func update_best_run(run_num: int) -> void:
	if run_num > best_run:
		best_run = run_num
		save_data()

func set_ads_removed() -> void:
	ads_removed = true
	save_data()

extends Node

var config := {
	"dad_base_speed": 80.0,
	"dad_chase_multiplier": 1.5,
	"noise_decay_rate": 10.0,
	"event_interval_min": 10.0,
	"event_interval_max": 18.0,
	"lego_density": 1,
	"dog_reactivity": 0.3,
	"stir_window": 3.0,
	"search_duration": 4.0,
}

func update_for_run(run_index: int) -> void:
	var r := float(run_index)
	config["dad_base_speed"]        = 80.0 + r * 2.0
	config["dad_chase_multiplier"]  = min(1.5 + r * 0.05, 2.5)
	config["noise_decay_rate"]      = max(10.0 - r * 0.3, 4.0)
	config["event_interval_min"]    = max(10.0 - r * 0.4, 5.0)
	config["event_interval_max"]    = max(18.0 - r * 0.5, 8.0)
	config["lego_density"]          = 1 + int(r / 4)
	config["dog_reactivity"]        = min(0.3 + r * 0.05, 0.9)
	config["stir_window"]           = max(3.0 - r * 0.05, 1.5)
	config["search_duration"]       = max(4.0 - r * 0.1, 2.0)

extends Node

var config := {
	"dad_base_speed": 78.0,
	"dad_chase_multiplier": 1.30,
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
	# Player walks 90px/s, creeps 40px/s.
	# Run 1: 80 * 1.32 = ~106px/s — faster than player walk, must hide not run.
	# Run 8: 96 * 1.56 = ~150px/s — unavoidable without hiding.
	config["dad_base_speed"]        = 78.0 + r * 2.2
	config["dad_chase_multiplier"]  = minf(1.30 + r * 0.04, 2.2)
	config["noise_decay_rate"]      = maxf(10.0 - r * 0.3, 4.0)
	config["event_interval_min"]    = maxf(10.0 - r * 0.4, 5.0)
	config["event_interval_max"]    = maxf(18.0 - r * 0.5, 8.0)
	config["lego_density"]          = 1 + int(r / 4)
	config["dog_reactivity"]        = minf(0.3 + r * 0.05, 0.9)
	config["stir_window"]           = maxf(3.0 - r * 0.05, 1.5)
	config["search_duration"]       = maxf(4.0 - r * 0.1, 2.0)

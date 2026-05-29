extends Node
# Randomizes obstacle and object positions each run.
# Called from game.gd after the level loads.

func randomize_level(level: Node) -> void:
	if not level:
		return
	_randomize_legos(level)
	_randomize_dad_bed_position(level)

func _randomize_legos(level: Node) -> void:
	# Move Lego piles to random positions within the living room area
	# Living room: y 620-940, x 60-330 (avoiding walls and edges)
	var lego_y_min := 660.0
	var lego_y_max := 900.0
	var lego_x_positions := [80.0, 150.0, 195.0, 240.0, 300.0]

	for child in level.get_children():
		var name_lower := child.name.to_lower()
		if "lego" in name_lower and child is Area2D:
			# Random position in living room, keep separated
			var rand_x: float = lego_x_positions[randi() % lego_x_positions.size()]
			var rand_y: float = randf_range(lego_y_min, lego_y_max)
			child.position = Vector2(rand_x, rand_y)

func _randomize_dad_bed_position(level: Node) -> void:
	# Slightly vary Dad's start position within his room area
	var dad_start := level.get_node_or_null("DadStart")
	if dad_start:
		var base: Vector2 = dad_start.position
		dad_start.position = Vector2(
			base.x + randf_range(-8, 8),
			base.y + randf_range(-10, 10)
		)

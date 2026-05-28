extends Control

# Semi-transparent virtual joystick — fixed bottom-left position
# Exposes `direction` (Vector2) and `magnitude` (0.0–1.0) for player.gd

const OUTER_RADIUS  := 65.0
const KNOB_RADIUS   := 26.0
const MAX_KNOB_DIST := 52.0
const CENTER        := Vector2(110.0, 710.0)  # fixed screen position

var direction:  Vector2 = Vector2.ZERO
var magnitude:  float   = 0.0

var _touch_index:  int     = -1
var _knob_offset:  Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("joystick")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS

func _draw() -> void:
	# Outer ring fill
	draw_circle(CENTER, OUTER_RADIUS, Color(1, 1, 1, 0.10))
	# Outer ring border
	draw_arc(CENTER, OUTER_RADIUS, 0.0, TAU, 64, Color(1, 1, 1, 0.45), 2.5, true)
	# Inner direction indicator lines (cardinal cross)
	for angle_deg in [0, 90, 180, 270]:
		var rad := deg_to_rad(float(angle_deg))
		var dir_v := Vector2(cos(rad), sin(rad))
		draw_line(CENTER + dir_v * (OUTER_RADIUS * 0.45),
				  CENTER + dir_v * (OUTER_RADIUS * 0.75),
				  Color(1, 1, 1, 0.2), 1.5, true)
	# Knob
	var knob_pos := CENTER + _knob_offset
	draw_circle(knob_pos, KNOB_RADIUS, Color(1, 1, 1, 0.35))
	draw_arc(knob_pos, KNOB_RADIUS, 0.0, TAU, 48, Color(1, 1, 1, 0.75), 2.0, true)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			# Capture only touches near the joystick
			if event.position.distance_to(CENTER) < OUTER_RADIUS * 1.6:
				_touch_index = event.index
				_update_knob(event.position)
				get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_knob_offset = Vector2.ZERO
			direction     = Vector2.ZERO
			magnitude     = 0.0
			queue_redraw()
			get_viewport().set_input_as_handled()

	elif event is InputEventScreenDrag:
		if event.index == _touch_index:
			_update_knob(event.position)
			get_viewport().set_input_as_handled()

func _update_knob(screen_pos: Vector2) -> void:
	var offset := screen_pos - CENTER
	var dist   := offset.length()
	if dist > MAX_KNOB_DIST:
		offset = offset.normalized() * MAX_KNOB_DIST
	_knob_offset = offset
	if dist > 8.0:
		direction = (screen_pos - CENTER).normalized()
		magnitude = minf(dist / MAX_KNOB_DIST, 1.0)
	else:
		direction = Vector2.ZERO
		magnitude = 0.0
	queue_redraw()

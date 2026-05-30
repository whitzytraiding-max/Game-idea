extends RefCounted

const ROOM_W: float = 390.0
const ROOM_H: float = 350.0
const WALL_T: float = 14.0
const DOOR_W: float = 90.0
const DOOR_X: float = (ROOM_W - DOOR_W) * 0.5  # 150.0

const WALL_COLOR  := Color(0.10, 0.08, 0.13, 1.0)
const DOOR_COLOR  := Color(0.16, 0.10, 0.06, 1.0)
const DOOR_TRIM   := Color(0.24, 0.16, 0.09, 1.0)

const ALL_MIDDLE: Array = ["kitchen", "living_room", "bathroom"]

# ── Entry point ──────────────────────────────────────────────────────────────

func generate(required_room: String, num_middle: int) -> Node2D:
	num_middle = clampi(num_middle, 2, 5)

	var middle: Array = [required_room]
	var pool: Array = []
	for r in ALL_MIDDLE:
		if r != required_room:
			pool.append(r)
	pool.shuffle()
	for i in range(min(num_middle - 1, pool.size())):
		middle.append(pool[i])
	middle.shuffle()

	# Objective rooms at TOP, Dad's Room just above Kid's Room at BOTTOM.
	# This puts Dad close to the player (matching original level feel) and
	# forces the player to sneak PAST Dad to reach the objective.
	var rooms: Array = middle + ["dads_room", "kids_room"]
	var n: int = rooms.size()
	var total_h: float = float(n) * ROOM_H

	var root := Node2D.new()
	root.name = "GeneratedHouse"

	var bg := ColorRect.new()
	bg.name = "Background"
	bg.size = Vector2(ROOM_W, total_h)
	bg.color = Color(0.06, 0.06, 0.10, 1.0)
	root.add_child(bg)

	for i in range(n):
		var rtype: String = rooms[i]
		var y_off: float = float(i) * ROOM_H
		var north_door: bool = (i > 0)
		var south_door: bool = (i < n - 1)
		var is_obj: bool = (rtype == required_room)
		_build_room(root, rtype, y_off, north_door, south_door, is_obj)

	# PlayerStart — near bed at bottom of Kid's Room
	var ps := Node2D.new()
	ps.name = "PlayerStart"
	ps.position = Vector2(ROOM_W * 0.5, float(n - 1) * ROOM_H + ROOM_H * 0.75)
	root.add_child(ps)

	# DadStart — near south door of Dad's Room so he's close to the player
	var dad_y: float = float(n - 2) * ROOM_H
	var ds := Node2D.new()
	ds.name = "DadStart"
	ds.position = Vector2(ROOM_W * 0.35, dad_y + ROOM_H * 0.38)
	root.add_child(ds)

	return root

# ── Room builder ─────────────────────────────────────────────────────────────

func _build_room(root: Node2D, rtype: String, y_off: float, north_door: bool, south_door: bool, is_obj: bool) -> void:
	var c := Node2D.new()
	c.name = rtype
	c.position = Vector2(0.0, y_off)
	root.add_child(c)

	# Floor base
	var room_floor := ColorRect.new()
	room_floor.size = Vector2(ROOM_W, ROOM_H)
	room_floor.color = _floor_color(rtype)
	c.add_child(room_floor)

	# Floor texture overlay
	_draw_floor_texture(c, rtype)

	# Walls (collision + visual)
	_north_wall(c, north_door)
	_south_wall(c, south_door)
	_wall_rect(c, 0.0, WALL_T, WALL_T, ROOM_H - WALL_T * 2.0)
	_wall_rect(c, ROOM_W - WALL_T, WALL_T, WALL_T, ROOM_H - WALL_T * 2.0)

	# Wall details (baseboard, chair rail)
	_draw_wall_details(c, rtype)

	# Room label plate on wall
	_draw_room_sign(c, rtype)

	# Furniture and entities
	_room_content(c, rtype, is_obj)

# ── Wall collision + visuals ─────────────────────────────────────────────────

func _north_wall(c: Node2D, has_door: bool) -> void:
	if has_door:
		_wall_rect(c, 0.0, 0.0, DOOR_X, WALL_T)
		_wall_rect(c, DOOR_X + DOOR_W, 0.0, ROOM_W - DOOR_X - DOOR_W, WALL_T)
		# Door opening fill
		_color_rect(c, DOOR_X, 0.0, DOOR_W, WALL_T, DOOR_COLOR)
		# Door frame trim strips
		_color_rect(c, DOOR_X - 3.0, 0.0, 3.0, WALL_T + 4.0, DOOR_TRIM)
		_color_rect(c, DOOR_X + DOOR_W, 0.0, 3.0, WALL_T + 4.0, DOOR_TRIM)
	else:
		_wall_rect(c, 0.0, 0.0, ROOM_W, WALL_T)

func _south_wall(c: Node2D, has_door: bool) -> void:
	var y: float = ROOM_H - WALL_T
	if has_door:
		_wall_rect(c, 0.0, y, DOOR_X, WALL_T)
		_wall_rect(c, DOOR_X + DOOR_W, y, ROOM_W - DOOR_X - DOOR_W, WALL_T)
		_color_rect(c, DOOR_X, y, DOOR_W, WALL_T, DOOR_COLOR)
		_color_rect(c, DOOR_X - 3.0, y - 4.0, 3.0, WALL_T + 4.0, DOOR_TRIM)
		_color_rect(c, DOOR_X + DOOR_W, y - 4.0, 3.0, WALL_T + 4.0, DOOR_TRIM)
	else:
		_wall_rect(c, 0.0, y, ROOM_W, WALL_T)

func _wall_rect(parent: Node2D, x: float, y: float, w: float, h: float) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	body.position = Vector2(x, y)

	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(w, h)
	cs.shape = rs
	cs.position = Vector2(w * 0.5, h * 0.5)
	body.add_child(cs)

	# Wall face
	var vis := ColorRect.new()
	vis.size = Vector2(w, h)
	vis.color = WALL_COLOR
	body.add_child(vis)

	# Inner edge highlight (gives the wall depth)
	var highlight := ColorRect.new()
	highlight.size = Vector2(w, 2.0)
	highlight.position = Vector2(0.0, h - 2.0)
	highlight.color = Color(0.22, 0.18, 0.28, 0.6)
	body.add_child(highlight)

	parent.add_child(body)

# ── Visual helpers ────────────────────────────────────────────────────────────

func _color_rect(parent: Node2D, x: float, y: float, w: float, h: float, col: Color) -> void:
	var cr := ColorRect.new()
	cr.position = Vector2(x, y)
	cr.size = Vector2(w, h)
	cr.color = col
	parent.add_child(cr)

# Outlined rect — draws shadow behind, then fill on top
func _outlined_rect(parent: Node2D, x: float, y: float, w: float, h: float, fill: Color, outline: Color, t: float = 2.5) -> void:
	_color_rect(parent, x - t, y - t, w + t * 2.0, h + t * 2.0, outline)
	_color_rect(parent, x, y, w, h, fill)

# Horizontal highlight strip on top of a rect (makes surfaces look lit)
func _surface_highlight(parent: Node2D, x: float, y: float, w: float, brightness: float = 0.12) -> void:
	_color_rect(parent, x, y, w, 3.0, Color(1.0, 1.0, 1.0, brightness))

# Thin dark shadow line below an object
func _shadow_line(parent: Node2D, x: float, y: float, w: float) -> void:
	_color_rect(parent, x, y, w, 2.5, Color(0.0, 0.0, 0.0, 0.28))

# ── Floor textures ────────────────────────────────────────────────────────────

func _draw_floor_texture(c: Node2D, rtype: String) -> void:
	var fx: float = WALL_T
	var fy: float = WALL_T
	var fw: float = ROOM_W - WALL_T * 2.0
	var fh: float = ROOM_H - WALL_T * 2.0

	match rtype:
		"bathroom":
			# Grid tile pattern
			var tile: float = 22.0
			var x: float = fx
			while x < fx + fw:
				_color_rect(c, x, fy, 1.0, fh, Color(0.0, 0.0, 0.0, 0.12))
				x += tile
			var y: float = fy + tile
			while y < fy + fh:
				_color_rect(c, fx, y, fw, 1.0, Color(0.0, 0.0, 0.0, 0.12))
				y += tile
		_:
			# Wood plank lines
			var spacing: float = 20.0
			var y: float = fy + spacing
			while y < fy + fh:
				_color_rect(c, fx, y, fw, 1.5, Color(0.0, 0.0, 0.0, 0.10))
				y += spacing

# ── Wall details ─────────────────────────────────────────────────────────────

func _draw_wall_details(c: Node2D, rtype: String) -> void:
	var wall_col := _wall_shade(rtype)

	# Left + right wall faces (visual overlay on top of StaticBody visuals)
	_color_rect(c, 0.0, WALL_T, WALL_T, ROOM_H - WALL_T * 2.0, wall_col)
	_color_rect(c, ROOM_W - WALL_T, WALL_T, WALL_T, ROOM_H - WALL_T * 2.0, wall_col)

	# Chair rail (horizontal stripe across walls at 1/3 height)
	var rail_y: float = WALL_T + (ROOM_H - WALL_T * 2.0) * 0.32
	_color_rect(c, 0.0, rail_y, WALL_T, 4.0, Color(0.28, 0.22, 0.18, 0.7))
	_color_rect(c, ROOM_W - WALL_T, rail_y, WALL_T, 4.0, Color(0.28, 0.22, 0.18, 0.7))

	# Baseboard (strip along bottom of side walls)
	var base_y: float = ROOM_H - WALL_T - 7.0
	_color_rect(c, 0.0, base_y, WALL_T, 7.0, Color(0.20, 0.16, 0.14, 0.8))
	_color_rect(c, ROOM_W - WALL_T, base_y, WALL_T, 7.0, Color(0.20, 0.16, 0.14, 0.8))

func _wall_shade(rtype: String) -> Color:
	match rtype:
		"kitchen":      return Color(0.13, 0.12, 0.10, 1.0)
		"living_room":  return Color(0.11, 0.10, 0.14, 1.0)
		"bathroom":     return Color(0.10, 0.12, 0.14, 1.0)
		"dads_room":    return Color(0.12, 0.09, 0.10, 1.0)
		"kids_room":    return Color(0.09, 0.10, 0.14, 1.0)
	return Color(0.10, 0.10, 0.12, 1.0)

# ── Room sign ────────────────────────────────────────────────────────────────

func _draw_room_sign(c: Node2D, rtype: String) -> void:
	# Small door-plate style sign in top-left corner
	_outlined_rect(c, WALL_T + 6.0, WALL_T + 6.0, 78.0, 14.0,
		Color(0.18, 0.14, 0.10, 1.0), Color(0.30, 0.22, 0.14, 1.0), 1.5)
	var lbl := Label.new()
	lbl.text = _room_label(rtype)
	lbl.position = Vector2(WALL_T + 8.0, WALL_T + 5.0)
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.modulate = Color(0.70, 0.62, 0.48, 0.9)
	c.add_child(lbl)

# ── Room content ─────────────────────────────────────────────────────────────

func _room_content(c: Node2D, rtype: String, is_obj: bool) -> void:
	match rtype:
		"dads_room":    _build_dads_room(c)
		"kids_room":    _build_kids_room(c)
		"kitchen":      _build_kitchen(c, is_obj)
		"living_room":  _build_living_room(c, is_obj)
		"bathroom":     _build_bathroom(c, is_obj)

# ── KITCHEN ──────────────────────────────────────────────────────────────────

func _build_kitchen(c: Node2D, is_obj: bool) -> void:
	# Counter base (dark wood)
	var counter_x: float = WALL_T
	var counter_y: float = WALL_T
	var counter_w: float = 252.0
	var counter_h: float = 48.0
	_outlined_rect(c, counter_x, counter_y, counter_w, counter_h,
		Color(0.20, 0.16, 0.10, 1.0), Color(0.10, 0.08, 0.05, 1.0))
	# Counter stone top surface
	_color_rect(c, counter_x, counter_y, counter_w, 10.0, Color(0.42, 0.40, 0.38, 1.0))
	_surface_highlight(c, counter_x + 2.0, counter_y, counter_w - 4.0, 0.14)
	# Sink basin
	_outlined_rect(c, counter_x + 80.0, counter_y + 3.0, 55.0, 28.0,
		Color(0.28, 0.32, 0.34, 1.0), Color(0.12, 0.14, 0.15, 1.0))
	_color_rect(c, counter_x + 82.0, counter_y + 5.0, 51.0, 18.0, Color(0.15, 0.20, 0.22, 1.0))
	# Faucet
	_color_rect(c, counter_x + 103.0, counter_y - 8.0, 5.0, 11.0, Color(0.55, 0.55, 0.58, 1.0))
	_color_rect(c, counter_x + 98.0, counter_y - 8.0, 14.0, 3.0, Color(0.55, 0.55, 0.58, 1.0))

	# Fridge (right side)
	var fridge_x: float = 298.0
	var fridge_y: float = WALL_T
	_outlined_rect(c, fridge_x, fridge_y, 76.0, 118.0,
		Color(0.38, 0.40, 0.42, 1.0), Color(0.12, 0.12, 0.14, 1.0), 3.0)
	# Freezer top section
	_color_rect(c, fridge_x + 2.5, fridge_y + 2.5, 71.0, 34.0, Color(0.44, 0.46, 0.48, 1.0))
	_surface_highlight(c, fridge_x + 4.0, fridge_y + 4.0, 67.0, 0.16)
	# Fridge door seam
	_color_rect(c, fridge_x + 2.5, fridge_y + 36.5, 71.0, 2.0, Color(0.10, 0.10, 0.12, 1.0))
	# Handles
	_color_rect(c, fridge_x + 9.0, fridge_y + 10.0, 4.0, 18.0, Color(0.20, 0.20, 0.22, 1.0))
	_color_rect(c, fridge_x + 9.0, fridge_y + 52.0, 4.0, 30.0, Color(0.20, 0.20, 0.22, 1.0))
	_shadow_line(c, fridge_x, fridge_y + 118.0, 76.0)

	# Kitchen table
	var table_x: float = 100.0
	var table_y: float = 170.0
	_shadow_line(c, table_x + 4.0, table_y + 64.0, 140.0)
	_outlined_rect(c, table_x, table_y, 148.0, 12.0,
		Color(0.30, 0.22, 0.13, 1.0), Color(0.12, 0.08, 0.04, 1.0))
	_surface_highlight(c, table_x + 2.0, table_y, 144.0, 0.12)
	# Table legs
	_color_rect(c, table_x + 4.0, table_y + 12.0, 8.0, 50.0, Color(0.22, 0.16, 0.10, 1.0))
	_color_rect(c, table_x + 136.0, table_y + 12.0, 8.0, 50.0, Color(0.22, 0.16, 0.10, 1.0))
	# Chairs (simple rects)
	_outlined_rect(c, table_x - 26.0, table_y + 6.0, 22.0, 32.0,
		Color(0.25, 0.18, 0.10, 1.0), Color(0.12, 0.08, 0.04, 1.0))
	_outlined_rect(c, table_x + 152.0, table_y + 6.0, 22.0, 32.0,
		Color(0.25, 0.18, 0.10, 1.0), Color(0.12, 0.08, 0.04, 1.0))

	_add_hide_spot(c, Vector2(counter_x + 126.0, counter_y + 24.0), "under counter", 248.0, 44.0)
	_add_hide_spot(c, Vector2(table_x + 74.0, table_y + 31.0), "under table", 148.0, 62.0)

	if is_obj:
		_add_objective(c, Vector2(fridge_x + 38.0, fridge_y + 70.0))

# ── LIVING ROOM ───────────────────────────────────────────────────────────────

func _build_living_room(c: Node2D, is_obj: bool) -> void:
	# TV stand + TV against top wall
	var tv_x: float = 100.0
	var tv_y: float = WALL_T + 6.0
	# Stand
	_outlined_rect(c, tv_x - 10.0, tv_y + 28.0, 190.0, 18.0,
		Color(0.22, 0.18, 0.12, 1.0), Color(0.10, 0.08, 0.05, 1.0))
	_surface_highlight(c, tv_x - 8.0, tv_y + 28.0, 186.0, 0.10)
	_color_rect(c, tv_x + 20.0, tv_y + 46.0, 12.0, 12.0, Color(0.16, 0.12, 0.08, 1.0))
	_color_rect(c, tv_x + 138.0, tv_y + 46.0, 12.0, 12.0, Color(0.16, 0.12, 0.08, 1.0))
	# TV bezel
	_outlined_rect(c, tv_x, tv_y, 170.0, 28.0,
		Color(0.06, 0.06, 0.08, 1.0), Color(0.04, 0.04, 0.06, 1.0), 3.0)
	# Screen (blue-grey static)
	_color_rect(c, tv_x + 4.0, tv_y + 3.0, 162.0, 19.0, Color(0.08, 0.12, 0.22, 1.0))
	_surface_highlight(c, tv_x + 6.0, tv_y + 4.0, 60.0, 0.08)
	# Power LED
	_color_rect(c, tv_x + 160.0, tv_y + 22.0, 4.0, 4.0, Color(0.1, 0.8, 0.1, 0.7))
	_shadow_line(c, tv_x - 10.0, tv_y + 46.0, 190.0)

	# Rug under coffee table area
	var rug_y: float = ROOM_H - 200.0
	_color_rect(c, 55.0, rug_y, 280.0, 115.0, Color(0.20, 0.13, 0.28, 0.45))
	# Rug border
	_color_rect(c, 55.0, rug_y, 280.0, 4.0, Color(0.35, 0.22, 0.45, 0.5))
	_color_rect(c, 55.0, rug_y + 111.0, 280.0, 4.0, Color(0.35, 0.22, 0.45, 0.5))
	_color_rect(c, 55.0, rug_y, 4.0, 115.0, Color(0.35, 0.22, 0.45, 0.5))
	_color_rect(c, 331.0, rug_y, 4.0, 115.0, Color(0.35, 0.22, 0.45, 0.5))

	# Coffee table
	var ct_x: float = 120.0
	var ct_y: float = ROOM_H - 178.0
	_shadow_line(c, ct_x + 4.0, ct_y + 36.0, 148.0)
	_outlined_rect(c, ct_x, ct_y, 150.0, 10.0,
		Color(0.28, 0.20, 0.12, 1.0), Color(0.12, 0.08, 0.04, 1.0))
	_surface_highlight(c, ct_x + 2.0, ct_y, 146.0, 0.10)
	_color_rect(c, ct_x + 6.0, ct_y + 10.0, 8.0, 26.0, Color(0.20, 0.14, 0.08, 1.0))
	_color_rect(c, ct_x + 136.0, ct_y + 10.0, 8.0, 26.0, Color(0.20, 0.14, 0.08, 1.0))

	# Couch — back rest + seat + arms
	var couch_x: float = 55.0
	var couch_y: float = ROOM_H - 125.0
	_shadow_line(c, couch_x, couch_y + 78.0, 280.0)
	# Back
	_outlined_rect(c, couch_x, couch_y, 280.0, 30.0,
		Color(0.28, 0.16, 0.38, 1.0), Color(0.12, 0.06, 0.18, 1.0), 2.5)
	_surface_highlight(c, couch_x + 3.0, couch_y + 2.0, 274.0, 0.08)
	# Seat
	_outlined_rect(c, couch_x, couch_y + 30.0, 280.0, 38.0,
		Color(0.32, 0.18, 0.44, 1.0), Color(0.12, 0.06, 0.18, 1.0), 2.5)
	# Armrests
	_color_rect(c, couch_x, couch_y, 22.0, 68.0, Color(0.22, 0.12, 0.30, 1.0))
	_color_rect(c, couch_x + 258.0, couch_y, 22.0, 68.0, Color(0.22, 0.12, 0.30, 1.0))
	# Couch cushion lines
	_color_rect(c, couch_x + 107.0, couch_y + 32.0, 3.0, 34.0, Color(0.12, 0.06, 0.18, 0.6))
	_color_rect(c, couch_x + 170.0, couch_y + 32.0, 3.0, 34.0, Color(0.12, 0.06, 0.18, 0.6))

	_add_hide_spot(c, Vector2(couch_x + 140.0, couch_y + 34.0), "behind couch", 280.0, 68.0)
	_add_hide_spot(c, Vector2(280.0, tv_y + 22.0), "behind curtain", 90.0, 42.0)

	if is_obj:
		_add_objective(c, Vector2(tv_x + 85.0, tv_y + 10.0))

# ── BATHROOM ──────────────────────────────────────────────────────────────────

func _build_bathroom(c: Node2D, is_obj: bool) -> void:
	# Bathtub
	var tub_x: float = 190.0
	var tub_y: float = WALL_T + 8.0
	_outlined_rect(c, tub_x, tub_y, 172.0, 95.0,
		Color(0.48, 0.52, 0.56, 1.0), Color(0.14, 0.16, 0.18, 1.0), 3.0)
	# Inside (water)
	_color_rect(c, tub_x + 8.0, tub_y + 8.0, 156.0, 70.0, Color(0.20, 0.35, 0.48, 0.7))
	_surface_highlight(c, tub_x + 10.0, tub_y + 10.0, 80.0, 0.14)
	# Faucet
	_color_rect(c, tub_x + 70.0, tub_y - 8.0, 8.0, 16.0, Color(0.55, 0.56, 0.60, 1.0))
	_color_rect(c, tub_x + 60.0, tub_y - 8.0, 26.0, 4.0, Color(0.55, 0.56, 0.60, 1.0))
	_shadow_line(c, tub_x, tub_y + 95.0, 172.0)

	# Toilet — tank + bowl
	var tlt_x: float = WALL_T + 6.0
	var tlt_y: float = WALL_T + 8.0
	# Tank
	_outlined_rect(c, tlt_x, tlt_y, 46.0, 30.0,
		Color(0.75, 0.76, 0.78, 1.0), Color(0.14, 0.16, 0.18, 1.0))
	_surface_highlight(c, tlt_x + 2.0, tlt_y + 2.0, 42.0, 0.12)
	_color_rect(c, tlt_x + 15.0, tlt_y + 4.0, 16.0, 8.0, Color(0.60, 0.62, 0.64, 1.0))
	# Bowl
	_outlined_rect(c, tlt_x - 4.0, tlt_y + 30.0, 54.0, 48.0,
		Color(0.70, 0.72, 0.74, 1.0), Color(0.14, 0.16, 0.18, 1.0))
	_color_rect(c, tlt_x - 2.0, tlt_y + 34.0, 50.0, 32.0, Color(0.55, 0.60, 0.65, 0.6))
	_shadow_line(c, tlt_x - 4.0, tlt_y + 78.0, 54.0)

	# Sink + pedestal
	var sink_x: float = WALL_T + 6.0
	var sink_y: float = WALL_T + 110.0
	_outlined_rect(c, sink_x - 2.0, sink_y, 50.0, 40.0,
		Color(0.70, 0.72, 0.74, 1.0), Color(0.14, 0.16, 0.18, 1.0))
	_color_rect(c, sink_x + 2.0, sink_y + 6.0, 42.0, 22.0, Color(0.50, 0.58, 0.65, 0.7))
	_surface_highlight(c, sink_x, sink_y, 46.0, 0.12)
	# Faucet
	_color_rect(c, sink_x + 21.0, sink_y - 10.0, 4.0, 14.0, Color(0.55, 0.56, 0.60, 1.0))
	_color_rect(c, sink_x + 14.0, sink_y - 10.0, 18.0, 3.0, Color(0.55, 0.56, 0.60, 1.0))
	# Mirror
	_outlined_rect(c, sink_x - 2.0, WALL_T + 4.0, 50.0, 40.0,
		Color(0.22, 0.28, 0.34, 1.0), Color(0.14, 0.16, 0.18, 1.0))
	_surface_highlight(c, sink_x, WALL_T + 6.0, 26.0, 0.18)
	_shadow_line(c, sink_x - 2.0, WALL_T + 112.0, 50.0)

	_add_hide_spot(c, Vector2(tub_x + 86.0, tub_y + 48.0), "in bathtub", 168.0, 90.0)
	_add_hide_spot(c, Vector2(WALL_T + 30.0, ROOM_H - 80.0), "behind door", 56.0, 80.0)

	if is_obj:
		_add_objective(c, Vector2(tlt_x + 4.0, tlt_y + 40.0))

# ── KID'S ROOM ────────────────────────────────────────────────────────────────

func _build_kids_room(c: Node2D) -> void:
	# Desk
	var desk_x: float = WALL_T + 4.0
	var desk_y: float = 50.0
	_shadow_line(c, desk_x, desk_y + 54.0, 96.0)
	_outlined_rect(c, desk_x, desk_y, 96.0, 10.0,
		Color(0.28, 0.20, 0.12, 1.0), Color(0.12, 0.08, 0.04, 1.0))
	_surface_highlight(c, desk_x + 2.0, desk_y, 92.0, 0.10)
	_color_rect(c, desk_x + 4.0, desk_y + 10.0, 10.0, 44.0, Color(0.22, 0.16, 0.10, 1.0))
	_color_rect(c, desk_x + 82.0, desk_y + 10.0, 10.0, 44.0, Color(0.22, 0.16, 0.10, 1.0))
	# Drawer front
	_outlined_rect(c, desk_x + 16.0, desk_y + 16.0, 60.0, 28.0,
		Color(0.24, 0.17, 0.10, 1.0), Color(0.12, 0.08, 0.04, 1.0))
	# Drawer handle
	_color_rect(c, desk_x + 41.0, desk_y + 26.0, 14.0, 5.0, Color(0.40, 0.32, 0.22, 1.0))

	# Poster on wall (above desk)
	_outlined_rect(c, desk_x + 4.0, WALL_T + 4.0, 78.0, 34.0,
		Color(0.12, 0.18, 0.28, 1.0), Color(0.08, 0.08, 0.10, 1.0))
	# Poster content (simple pixel art style stars)
	_color_rect(c, desk_x + 14.0, WALL_T + 10.0, 8.0, 8.0, Color(0.9, 0.85, 0.2, 0.8))
	_color_rect(c, desk_x + 30.0, WALL_T + 14.0, 5.0, 5.0, Color(0.9, 0.85, 0.2, 0.6))
	_color_rect(c, desk_x + 48.0, WALL_T + 8.0, 7.0, 7.0, Color(0.9, 0.85, 0.2, 0.7))
	_color_rect(c, desk_x + 62.0, WALL_T + 16.0, 5.0, 5.0, Color(0.9, 0.85, 0.2, 0.5))

	# Bed frame + mattress + pillow
	var bed_x: float = 100.0
	var bed_y: float = ROOM_H - 120.0
	_shadow_line(c, bed_x, bed_y + 98.0, 178.0)
	# Frame
	_outlined_rect(c, bed_x, bed_y, 178.0, 98.0,
		Color(0.16, 0.22, 0.42, 1.0), Color(0.06, 0.08, 0.18, 1.0), 3.0)
	# Mattress
	_color_rect(c, bed_x + 4.0, bed_y + 4.0, 170.0, 82.0, Color(0.24, 0.32, 0.52, 1.0))
	# Blanket (rumpled, covers most of bed)
	_color_rect(c, bed_x + 4.0, bed_y + 24.0, 170.0, 62.0, Color(0.18, 0.28, 0.55, 1.0))
	_color_rect(c, bed_x + 4.0, bed_y + 24.0, 170.0, 8.0, Color(0.28, 0.40, 0.65, 1.0))
	_surface_highlight(c, bed_x + 6.0, bed_y + 26.0, 80.0, 0.08)
	# Pillow
	_outlined_rect(c, bed_x + 10.0, bed_y + 5.0, 60.0, 22.0,
		Color(0.82, 0.82, 0.86, 1.0), Color(0.40, 0.42, 0.50, 1.0))
	_surface_highlight(c, bed_x + 12.0, bed_y + 7.0, 40.0, 0.14)
	# Headboard
	_color_rect(c, bed_x - 4.0, bed_y - 8.0, 186.0, 12.0, Color(0.10, 0.15, 0.30, 1.0))

	# Nightstand
	var ns_x: float = bed_x + 182.0
	var ns_y: float = bed_y + 10.0
	_outlined_rect(c, ns_x, ns_y, 40.0, 52.0,
		Color(0.22, 0.16, 0.10, 1.0), Color(0.10, 0.07, 0.04, 1.0))
	# Lamp on nightstand
	_color_rect(c, ns_x + 12.0, ns_y - 24.0, 3.0, 24.0, Color(0.30, 0.24, 0.18, 1.0))
	_outlined_rect(c, ns_x + 4.0, ns_y - 34.0, 24.0, 14.0,
		Color(0.70, 0.60, 0.30, 0.9), Color(0.30, 0.24, 0.16, 1.0))
	_surface_highlight(c, ns_x + 6.0, ns_y - 32.0, 14.0, 0.20)

	_add_hide_spot(c, Vector2(bed_x + 89.0, bed_y + 49.0), "under bed", 178.0, 98.0)
	_add_hide_spot(c, Vector2(desk_x + 48.0, desk_y + 25.0), "under desk", 96.0, 50.0)
	_add_bed_return(c)

# ── DAD'S ROOM ────────────────────────────────────────────────────────────────

func _build_dads_room(c: Node2D) -> void:
	# Large imposing bed
	var bed_x: float = 80.0
	var bed_y: float = 55.0
	_shadow_line(c, bed_x, bed_y + 108.0, 200.0)
	# Frame
	_outlined_rect(c, bed_x, bed_y, 200.0, 108.0,
		Color(0.22, 0.10, 0.10, 1.0), Color(0.08, 0.04, 0.04, 1.0), 3.0)
	# Mattress
	_color_rect(c, bed_x + 4.0, bed_y + 4.0, 192.0, 92.0, Color(0.30, 0.14, 0.14, 1.0))
	# Dark blanket
	_color_rect(c, bed_x + 4.0, bed_y + 24.0, 192.0, 72.0, Color(0.18, 0.08, 0.08, 1.0))
	_color_rect(c, bed_x + 4.0, bed_y + 24.0, 192.0, 8.0, Color(0.28, 0.12, 0.12, 1.0))
	# Pillow
	_outlined_rect(c, bed_x + 10.0, bed_y + 5.0, 70.0, 22.0,
		Color(0.65, 0.62, 0.60, 1.0), Color(0.35, 0.28, 0.28, 1.0))
	_surface_highlight(c, bed_x + 12.0, bed_y + 7.0, 40.0, 0.10)
	# Headboard
	_color_rect(c, bed_x - 4.0, bed_y - 10.0, 208.0, 14.0, Color(0.14, 0.06, 0.06, 1.0))

	# Nightstand
	var ns_x: float = bed_x + 204.0
	var ns_y: float = bed_y + 12.0
	_outlined_rect(c, ns_x, ns_y, 44.0, 58.0,
		Color(0.20, 0.10, 0.08, 1.0), Color(0.08, 0.04, 0.04, 1.0))
	# Alarm clock on nightstand
	_outlined_rect(c, ns_x + 8.0, ns_y - 18.0, 26.0, 18.0,
		Color(0.15, 0.15, 0.18, 1.0), Color(0.06, 0.06, 0.08, 1.0))
	_color_rect(c, ns_x + 11.0, ns_y - 15.0, 20.0, 12.0, Color(0.05, 0.60, 0.10, 0.8))
	# Clock feet
	_color_rect(c, ns_x + 9.0, ns_y, 5.0, 3.0, Color(0.15, 0.15, 0.18, 1.0))
	_color_rect(c, ns_x + 24.0, ns_y, 5.0, 3.0, Color(0.15, 0.15, 0.18, 1.0))

	# Wardrobe against left wall
	var ward_x: float = WALL_T + 2.0
	var ward_y: float = 55.0
	_shadow_line(c, ward_x, ward_y + 192.0, 72.0)
	_outlined_rect(c, ward_x, ward_y, 72.0, 192.0,
		Color(0.18, 0.10, 0.08, 1.0), Color(0.06, 0.04, 0.03, 1.0), 3.0)
	# Door panels
	_color_rect(c, ward_x + 4.0, ward_y + 6.0, 30.0, 80.0, Color(0.14, 0.08, 0.06, 1.0))
	_color_rect(c, ward_x + 38.0, ward_y + 6.0, 30.0, 80.0, Color(0.14, 0.08, 0.06, 1.0))
	_color_rect(c, ward_x + 4.0, ward_y + 96.0, 30.0, 90.0, Color(0.14, 0.08, 0.06, 1.0))
	_color_rect(c, ward_x + 38.0, ward_y + 96.0, 30.0, 90.0, Color(0.14, 0.08, 0.06, 1.0))
	# Door handles
	_color_rect(c, ward_x + 30.0, ward_y + 42.0, 8.0, 4.0, Color(0.38, 0.30, 0.22, 1.0))
	_color_rect(c, ward_x + 30.0, ward_y + 138.0, 8.0, 4.0, Color(0.38, 0.30, 0.22, 1.0))

	_add_hide_spot(c, Vector2(ward_x + 36.0, ward_y + 96.0), "in wardrobe", 72.0, 192.0)

# ── Entity spawners ──────────────────────────────────────────────────────────

func _add_hide_spot(parent: Node2D, pos: Vector2, spot_name: String, w: float = 80.0, h: float = 50.0) -> void:
	var scene: PackedScene = load("res://entities/hide_spot.tscn")
	if not scene:
		return
	var hs: Area2D = scene.instantiate()
	hs.position = pos
	if hs.get("spot_name") != null:
		hs.spot_name = spot_name
	# Resize collision shape to match the actual furniture piece
	var col: Node = hs.get_node_or_null("CollisionShape2D")
	if col and col.shape is RectangleShape2D:
		var new_shape := RectangleShape2D.new()
		new_shape.size = Vector2(w, h)
		col.shape = new_shape
	# Resize visual polygon to same footprint (invisible by default, outline when nearby)
	var vis: Node = hs.get_node_or_null("Visual")
	if vis:
		var hw: float = w * 0.5
		var hh: float = h * 0.5
		vis.polygon = PackedVector2Array([
			Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)
		])
	parent.add_child(hs)

func _add_objective(parent: Node2D, pos: Vector2) -> void:
	var scene: PackedScene = load("res://entities/objective.tscn")
	if not scene:
		return
	var obj: Area2D = scene.instantiate()
	obj.position = pos
	parent.add_child(obj)

func _add_bed_return(parent: Node2D) -> void:
	var bed_script: Script = load("res://scripts/bed_return.gd")
	if not bed_script:
		return
	var area := Area2D.new()
	area.name = "BedReturn"
	area.set_script(bed_script)
	area.position = Vector2(180.0, ROOM_H - 62.0)
	area.collision_layer = 0
	area.collision_mask = 1

	var vis := Polygon2D.new()
	vis.name = "Visual"
	vis.polygon = PackedVector2Array([
		Vector2(-75, -36), Vector2(75, -36), Vector2(75, 36), Vector2(-75, 36)
	])
	vis.color = Color(0.18, 0.26, 0.50, 0.85)
	area.add_child(vis)

	var cs := CollisionShape2D.new()
	cs.name = "CollisionShape2D"
	var rs := RectangleShape2D.new()
	rs.size = Vector2(150, 72)
	cs.shape = rs
	area.add_child(cs)

	var lbl := Label.new()
	lbl.name = "PromptLabel"
	lbl.text = "TAP TO SLEEP 🛏️"
	lbl.position = Vector2(-52, -60)
	lbl.visible = false
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.modulate = Color(1.0, 0.9, 0.2, 1.0)
	area.add_child(lbl)

	parent.add_child(area)

# ── Room data ────────────────────────────────────────────────────────────────

func _floor_color(rtype: String) -> Color:
	match rtype:
		"dads_room":    return Color(0.10, 0.07, 0.08, 1.0)
		"kids_room":    return Color(0.08, 0.09, 0.13, 1.0)
		"kitchen":      return Color(0.10, 0.11, 0.08, 1.0)
		"living_room":  return Color(0.10, 0.08, 0.11, 1.0)
		"bathroom":     return Color(0.08, 0.10, 0.12, 1.0)
	return Color(0.09, 0.09, 0.11, 1.0)

func _room_label(rtype: String) -> String:
	match rtype:
		"dads_room":    return "DAD'S ROOM"
		"kids_room":    return "YOUR ROOM"
		"kitchen":      return "KITCHEN"
		"living_room":  return "LIVING ROOM"
		"bathroom":     return "BATHROOM"
	return rtype.to_upper()

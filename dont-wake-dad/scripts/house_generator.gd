extends RefCounted

# ── Dimensions ───────────────────────────────────────────────────────────────
const ROOM_W:    float = 390.0
const ROOM_H:    float = 310.0
const HALL_H:    float = 110.0
const WALL_T:    float = 14.0
const SPLIT_X:   float = 195.0   # centre split for side-by-side rooms

# Hallway corridor (left wall block | gap | right wall block = 390)
const HALL_WALL: float = 115.0
const HALL_GAP:  float = 160.0
const HALL_X:    float = 115.0   # corridor start x

# Doors in room top/bottom walls match hallway gap exactly
const DOOR_W: float = HALL_GAP   # 160
const DOOR_X: float = HALL_X     # 115

# Centre wall between Dad's and Kid's rooms
const CENTRE_W:  float = 14.0
const CENTRE_X:  float = SPLIT_X - CENTRE_W * 0.5   # ~188

# ── Colours ───────────────────────────────────────────────────────────────────
const WALL_COLOR  := Color(0.10, 0.08, 0.13, 1.0)
const WALL_LIGHT  := Color(0.14, 0.11, 0.18, 1.0)
const DOOR_COLOR  := Color(0.16, 0.10, 0.06, 1.0)
const DOOR_TRIM   := Color(0.26, 0.17, 0.09, 1.0)
const HALL_FLOOR  := Color(0.08, 0.07, 0.09, 1.0)

const ALL_MIDDLE: Array = ["kitchen", "living_room", "bathroom"]

# ── Entry point ──────────────────────────────────────────────────────────────

func generate(required_room: String, num_middle: int) -> Node2D:
	num_middle = clampi(num_middle, 2, 4)

	var middle: Array = [required_room]
	var pool: Array = []
	for r in ALL_MIDDLE:
		if r != required_room:
			pool.append(r)
	pool.shuffle()
	for i in range(min(num_middle - 1, pool.size())):
		middle.append(pool[i])
	middle.shuffle()

	# Layout top → bottom:
	#   Dad's Room  ←  far end of the house
	#   hallway
	#   common room(s) with hallways between them  ←  objective is here
	#   hallway
	#   Kid's Room  ←  player starts here
	#
	# Player must sneak UP through the whole house past the common rooms,
	# grab the item, and race back before Dad charges down from the top.

	var sections: Array = []
	sections.append({"kind": "room", "rtype": "dads_room", "is_obj": false})
	sections.append({"kind": "hall"})
	for i in range(middle.size()):
		sections.append({"kind": "room", "rtype": middle[i], "is_obj": middle[i] == required_room})
		sections.append({"kind": "hall"})
	sections.append({"kind": "room", "rtype": "kids_room", "is_obj": false})

	var total_h: float = 0.0
	for s in sections:
		total_h += ROOM_H if s["kind"] == "room" else HALL_H

	var root := Node2D.new()
	root.name = "GeneratedHouse"

	var bg := ColorRect.new()
	bg.name = "Background"
	bg.size = Vector2(ROOM_W, total_h)
	bg.color = Color(0.05, 0.05, 0.09, 1.0)
	root.add_child(bg)

	var y: float = 0.0
	var kids_room_y: float = total_h - ROOM_H  # always the last section
	var dads_room_y: float = 0.0               # always the first section

	for i in range(sections.size()):
		var s: Dictionary = sections[i]
		if s["kind"] == "room":
			var north_door := (i > 0)
			var south_door := (i < sections.size() - 1)
			_build_room(root, s["rtype"], y, north_door, south_door, s.get("is_obj", false))
			y += ROOM_H
		else:
			_build_hallway(root, y)
			y += HALL_H

	# PlayerStart — near the kid's bed at the very bottom
	var ps := Node2D.new()
	ps.name = "PlayerStart"
	ps.position = Vector2(ROOM_W * 0.5, kids_room_y + ROOM_H * 0.74)
	root.add_child(ps)

	# DadStart — in his room at the very top
	var ds := Node2D.new()
	ds.name = "DadStart"
	ds.position = Vector2(ROOM_W * 0.38, dads_room_y + ROOM_H * 0.40)
	root.add_child(ds)

	return root

# ── Hallway ───────────────────────────────────────────────────────────────────

func _build_hallway(root: Node2D, y_off: float) -> void:
	var c := Node2D.new()
	c.name = "hallway"
	c.position = Vector2(0.0, y_off)
	root.add_child(c)

	var room_floor := ColorRect.new()
	room_floor.size = Vector2(ROOM_W, HALL_H)
	room_floor.color = HALL_FLOOR
	c.add_child(room_floor)

	_floor_planks(c, HALL_X, 0.0, HALL_GAP, HALL_H)

	_hall_wall_block(c, 0.0, 0.0, HALL_WALL, HALL_H)
	_hall_wall_block(c, HALL_X + HALL_GAP, 0.0, HALL_WALL, HALL_H)

	# Door-frame trim
	_color_rect(c, HALL_X - 4.0, 0.0, 4.0, HALL_H, DOOR_TRIM)
	_color_rect(c, HALL_X + HALL_GAP, 0.0, 4.0, HALL_H, DOOR_TRIM)

	_color_rect(c, HALL_X, HALL_H - 6.0, HALL_GAP, 6.0, Color(0.18, 0.14, 0.11, 0.9))

	# Picture frame on left block
	_outlined_rect(c, 14.0, HALL_H * 0.12, 58.0, 72.0,
		Color(0.12, 0.10, 0.15, 1.0), Color(0.28, 0.22, 0.14, 1.0))
	_color_rect(c, 16.0, HALL_H * 0.12 + 2.0, 54.0, 54.0, Color(0.20, 0.18, 0.22, 1.0))
	_color_rect(c, 28.0, HALL_H * 0.12 + 8.0, 30.0, 24.0, Color(0.25, 0.22, 0.28, 1.0))

	# Light switch on right block
	_outlined_rect(c, HALL_X + HALL_GAP + 26.0, HALL_H * 0.28, 18.0, 28.0,
		Color(0.70, 0.70, 0.72, 1.0), Color(0.20, 0.18, 0.22, 1.0))
	_color_rect(c, HALL_X + HALL_GAP + 33.0, HALL_H * 0.28 + 8.0, 4.0, 12.0,
		Color(0.35, 0.35, 0.38, 1.0))

func _hall_wall_block(parent: Node2D, x: float, y: float, w: float, h: float) -> void:
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
	var vis := ColorRect.new()
	vis.size = Vector2(w, h)
	vis.color = WALL_COLOR
	body.add_child(vis)
	var face_w: float = 5.0
	var face_x: float = (w - face_w) if x < ROOM_W * 0.5 else 0.0
	var face := ColorRect.new()
	face.size = Vector2(face_w, h)
	face.position = Vector2(face_x, 0.0)
	face.color = WALL_LIGHT
	body.add_child(face)
	parent.add_child(body)

# ── Full-width room ───────────────────────────────────────────────────────────

func _build_room(root: Node2D, rtype: String, y_off: float, north_door: bool, south_door: bool, is_obj: bool) -> void:
	var c := Node2D.new()
	c.name = rtype
	c.position = Vector2(0.0, y_off)
	root.add_child(c)

	var room_floor := ColorRect.new()
	room_floor.size = Vector2(ROOM_W, ROOM_H)
	room_floor.color = _floor_color(rtype)
	c.add_child(room_floor)

	_draw_floor_texture(c, rtype, WALL_T, WALL_T, ROOM_W - WALL_T * 2.0, ROOM_H - WALL_T * 2.0)

	_north_wall(c, north_door)
	_south_wall(c, south_door)
	_wall_rect(c, 0.0, WALL_T, WALL_T, ROOM_H - WALL_T * 2.0)
	_wall_rect(c, ROOM_W - WALL_T, WALL_T, WALL_T, ROOM_H - WALL_T * 2.0)

	_draw_wall_details(c, rtype)
	_draw_room_sign(c, rtype, WALL_T + 6.0)

	_room_content(c, rtype, is_obj)

# ── Wall builders ─────────────────────────────────────────────────────────────

func _north_wall(c: Node2D, has_door: bool) -> void:
	if has_door:
		_wall_rect(c, 0.0, 0.0, DOOR_X, WALL_T)
		_wall_rect(c, DOOR_X + DOOR_W, 0.0, ROOM_W - DOOR_X - DOOR_W, WALL_T)
		_color_rect(c, DOOR_X, 0.0, DOOR_W, WALL_T, DOOR_COLOR)
		_color_rect(c, DOOR_X - 3.0, 0.0, 3.0, WALL_T + 5.0, DOOR_TRIM)
		_color_rect(c, DOOR_X + DOOR_W, 0.0, 3.0, WALL_T + 5.0, DOOR_TRIM)
	else:
		_wall_rect(c, 0.0, 0.0, ROOM_W, WALL_T)

func _south_wall(c: Node2D, has_door: bool) -> void:
	var y: float = ROOM_H - WALL_T
	if has_door:
		_wall_rect(c, 0.0, y, DOOR_X, WALL_T)
		_wall_rect(c, DOOR_X + DOOR_W, y, ROOM_W - DOOR_X - DOOR_W, WALL_T)
		_color_rect(c, DOOR_X, y, DOOR_W, WALL_T, DOOR_COLOR)
		_color_rect(c, DOOR_X - 3.0, y - 5.0, 3.0, WALL_T + 5.0, DOOR_TRIM)
		_color_rect(c, DOOR_X + DOOR_W, y - 5.0, 3.0, WALL_T + 5.0, DOOR_TRIM)
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
	var vis := ColorRect.new()
	vis.size = Vector2(w, h)
	vis.color = WALL_COLOR
	body.add_child(vis)
	var hi := ColorRect.new()
	hi.size = Vector2(w, 2.0)
	hi.position = Vector2(0.0, h - 2.0)
	hi.color = Color(0.22, 0.18, 0.28, 0.5)
	body.add_child(hi)
	parent.add_child(body)

# ── Visual helpers ────────────────────────────────────────────────────────────

func _color_rect(parent: Node2D, x: float, y: float, w: float, h: float, col: Color) -> void:
	var cr := ColorRect.new()
	cr.position = Vector2(x, y)
	cr.size = Vector2(w, h)
	cr.color = col
	parent.add_child(cr)

func _outlined_rect(parent: Node2D, x: float, y: float, w: float, h: float, fill: Color, outline: Color, t: float = 2.5) -> void:
	_color_rect(parent, x - t, y - t, w + t * 2.0, h + t * 2.0, outline)
	_color_rect(parent, x, y, w, h, fill)

func _surface_highlight(parent: Node2D, x: float, y: float, w: float, a: float = 0.12) -> void:
	_color_rect(parent, x, y, w, 3.0, Color(1.0, 1.0, 1.0, a))

func _shadow_line(parent: Node2D, x: float, y: float, w: float) -> void:
	_color_rect(parent, x, y, w, 2.5, Color(0.0, 0.0, 0.0, 0.28))

func _floor_planks(parent: Node2D, fx: float, fy: float, fw: float, fh: float) -> void:
	var spacing: float = 20.0
	var y: float = fy + spacing
	while y < fy + fh:
		_color_rect(parent, fx, y, fw, 1.5, Color(0.0, 0.0, 0.0, 0.10))
		y += spacing

# ── Floor / wall decorations ──────────────────────────────────────────────────

func _draw_floor_texture(c: Node2D, rtype: String, fx: float, fy: float, fw: float, fh: float) -> void:
	if rtype == "bathroom":
		var tile: float = 22.0
		var x: float = fx
		while x < fx + fw:
			_color_rect(c, x, fy, 1.0, fh, Color(0.0, 0.0, 0.0, 0.12))
			x += tile
		var y: float = fy + tile
		while y < fy + fh:
			_color_rect(c, fx, y, fw, 1.0, Color(0.0, 0.0, 0.0, 0.12))
			y += tile
	else:
		_floor_planks(c, fx, fy, fw, fh)

func _draw_wall_details(c: Node2D, rtype: String) -> void:
	var wc := _wall_shade(rtype)
	_color_rect(c, 0.0, WALL_T, WALL_T, ROOM_H - WALL_T * 2.0, wc)
	_color_rect(c, ROOM_W - WALL_T, WALL_T, WALL_T, ROOM_H - WALL_T * 2.0, wc)
	var rail_y: float = WALL_T + (ROOM_H - WALL_T * 2.0) * 0.30
	_color_rect(c, 0.0, rail_y, WALL_T, 4.0, Color(0.28, 0.22, 0.16, 0.7))
	_color_rect(c, ROOM_W - WALL_T, rail_y, WALL_T, 4.0, Color(0.28, 0.22, 0.16, 0.7))
	var base_y: float = ROOM_H - WALL_T - 7.0
	_color_rect(c, 0.0, base_y, WALL_T, 7.0, Color(0.20, 0.16, 0.14, 0.8))
	_color_rect(c, ROOM_W - WALL_T, base_y, WALL_T, 7.0, Color(0.20, 0.16, 0.14, 0.8))

func _draw_room_sign(c: Node2D, rtype: String, x: float) -> void:
	_outlined_rect(c, x, WALL_T + 6.0, 82.0, 14.0,
		Color(0.18, 0.14, 0.10, 1.0), Color(0.30, 0.22, 0.14, 1.0), 1.5)
	var lbl := Label.new()
	lbl.text = _room_label(rtype)
	lbl.position = Vector2(x + 2.0, WALL_T + 5.0)
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.modulate = Color(0.70, 0.62, 0.48, 0.9)
	c.add_child(lbl)

# ── Full-width room content ───────────────────────────────────────────────────

func _room_content(c: Node2D, rtype: String, is_obj: bool) -> void:
	match rtype:
		"dads_room":    _build_dads_room(c)
		"kids_room":    _build_kids_room(c)
		"kitchen":      _build_kitchen(c, is_obj)
		"living_room":  _build_living_room(c, is_obj)
		"bathroom":     _build_bathroom(c, is_obj)

func _build_kitchen(c: Node2D, is_obj: bool) -> void:
	var cx: float = WALL_T
	var cy: float = WALL_T
	var cw: float = 240.0
	_outlined_rect(c, cx, cy, cw, 48.0, Color(0.20, 0.16, 0.10, 1.0), Color(0.10, 0.08, 0.05, 1.0))
	_color_rect(c, cx, cy, cw, 10.0, Color(0.42, 0.40, 0.38, 1.0))
	_surface_highlight(c, cx + 2.0, cy, cw - 4.0, 0.14)
	_outlined_rect(c, cx + 75.0, cy + 3.0, 55.0, 28.0, Color(0.28, 0.32, 0.34, 1.0), Color(0.12, 0.14, 0.15, 1.0))
	_color_rect(c, cx + 77.0, cy + 5.0, 51.0, 18.0, Color(0.15, 0.20, 0.22, 1.0))
	_color_rect(c, cx + 99.0, cy - 9.0, 5.0, 12.0, Color(0.55, 0.55, 0.58, 1.0))
	_color_rect(c, cx + 93.0, cy - 9.0, 16.0, 3.0, Color(0.55, 0.55, 0.58, 1.0))
	var fx: float = ROOM_W - WALL_T - 80.0
	_outlined_rect(c, fx, cy, 78.0, 118.0, Color(0.38, 0.40, 0.42, 1.0), Color(0.12, 0.12, 0.14, 1.0), 3.0)
	_color_rect(c, fx + 2.5, cy + 2.5, 73.0, 34.0, Color(0.44, 0.46, 0.48, 1.0))
	_surface_highlight(c, fx + 4.0, cy + 4.0, 69.0, 0.16)
	_color_rect(c, fx + 2.5, cy + 36.5, 73.0, 2.0, Color(0.10, 0.10, 0.12, 1.0))
	_color_rect(c, fx + 9.0, cy + 10.0, 5.0, 18.0, Color(0.20, 0.20, 0.22, 1.0))
	_color_rect(c, fx + 9.0, cy + 52.0, 5.0, 30.0, Color(0.20, 0.20, 0.22, 1.0))
	_shadow_line(c, fx, cy + 118.0, 78.0)
	var tx: float = 90.0; var ty: float = 165.0
	_shadow_line(c, tx + 4.0, ty + 58.0, 140.0)
	_outlined_rect(c, tx, ty, 148.0, 12.0, Color(0.30, 0.22, 0.13, 1.0), Color(0.12, 0.08, 0.04, 1.0))
	_surface_highlight(c, tx + 2.0, ty, 144.0, 0.12)
	_color_rect(c, tx + 4.0, ty + 12.0, 8.0, 46.0, Color(0.22, 0.16, 0.10, 1.0))
	_color_rect(c, tx + 136.0, ty + 12.0, 8.0, 46.0, Color(0.22, 0.16, 0.10, 1.0))
	_outlined_rect(c, tx - 26.0, ty + 6.0, 22.0, 32.0, Color(0.25, 0.18, 0.10, 1.0), Color(0.12, 0.08, 0.04, 1.0))
	_outlined_rect(c, tx + 152.0, ty + 6.0, 22.0, 32.0, Color(0.25, 0.18, 0.10, 1.0), Color(0.12, 0.08, 0.04, 1.0))
	_add_hide_spot(c, Vector2(cx + 120.0, cy + 24.0), "under counter", cw - 4.0, 44.0)
	_add_hide_spot(c, Vector2(tx + 74.0, ty + 29.0), "under table", 148.0, 58.0)
	if is_obj:
		_add_objective(c, Vector2(fx + 39.0, cy + 70.0))

func _build_living_room(c: Node2D, is_obj: bool) -> void:
	var tv_x: float = 95.0; var tv_y: float = WALL_T + 6.0
	_outlined_rect(c, tv_x - 10.0, tv_y + 28.0, 200.0, 18.0, Color(0.22, 0.18, 0.12, 1.0), Color(0.10, 0.08, 0.05, 1.0))
	_surface_highlight(c, tv_x - 8.0, tv_y + 28.0, 196.0, 0.10)
	_color_rect(c, tv_x + 20.0, tv_y + 46.0, 14.0, 12.0, Color(0.16, 0.12, 0.08, 1.0))
	_color_rect(c, tv_x + 146.0, tv_y + 46.0, 14.0, 12.0, Color(0.16, 0.12, 0.08, 1.0))
	_outlined_rect(c, tv_x, tv_y, 180.0, 28.0, Color(0.06, 0.06, 0.08, 1.0), Color(0.04, 0.04, 0.06, 1.0), 3.0)
	_color_rect(c, tv_x + 4.0, tv_y + 3.0, 172.0, 19.0, Color(0.08, 0.12, 0.22, 1.0))
	_surface_highlight(c, tv_x + 6.0, tv_y + 4.0, 60.0, 0.08)
	_color_rect(c, tv_x + 170.0, tv_y + 22.0, 4.0, 4.0, Color(0.1, 0.8, 0.1, 0.7))
	_shadow_line(c, tv_x - 10.0, tv_y + 46.0, 200.0)
	var rug_y: float = ROOM_H - 205.0
	_color_rect(c, 50.0, rug_y, 290.0, 120.0, Color(0.20, 0.13, 0.28, 0.40))
	_color_rect(c, 50.0, rug_y, 290.0, 4.0, Color(0.35, 0.22, 0.45, 0.5))
	_color_rect(c, 50.0, rug_y + 116.0, 290.0, 4.0, Color(0.35, 0.22, 0.45, 0.5))
	_color_rect(c, 50.0, rug_y, 4.0, 120.0, Color(0.35, 0.22, 0.45, 0.5))
	_color_rect(c, 336.0, rug_y, 4.0, 120.0, Color(0.35, 0.22, 0.45, 0.5))
	var ct_x: float = 120.0; var ct_y: float = ROOM_H - 182.0
	_shadow_line(c, ct_x + 4.0, ct_y + 36.0, 148.0)
	_outlined_rect(c, ct_x, ct_y, 150.0, 10.0, Color(0.28, 0.20, 0.12, 1.0), Color(0.12, 0.08, 0.04, 1.0))
	_surface_highlight(c, ct_x + 2.0, ct_y, 146.0, 0.10)
	_color_rect(c, ct_x + 6.0, ct_y + 10.0, 8.0, 26.0, Color(0.20, 0.14, 0.08, 1.0))
	_color_rect(c, ct_x + 136.0, ct_y + 10.0, 8.0, 26.0, Color(0.20, 0.14, 0.08, 1.0))
	var couch_x: float = 50.0; var couch_y: float = ROOM_H - 120.0
	_shadow_line(c, couch_x, couch_y + 78.0, 290.0)
	_outlined_rect(c, couch_x, couch_y, 290.0, 30.0, Color(0.28, 0.16, 0.38, 1.0), Color(0.12, 0.06, 0.18, 1.0), 2.5)
	_surface_highlight(c, couch_x + 3.0, couch_y + 2.0, 284.0, 0.08)
	_outlined_rect(c, couch_x, couch_y + 30.0, 290.0, 38.0, Color(0.32, 0.18, 0.44, 1.0), Color(0.12, 0.06, 0.18, 1.0), 2.5)
	_color_rect(c, couch_x, couch_y, 22.0, 68.0, Color(0.22, 0.12, 0.30, 1.0))
	_color_rect(c, couch_x + 268.0, couch_y, 22.0, 68.0, Color(0.22, 0.12, 0.30, 1.0))
	_color_rect(c, couch_x + 112.0, couch_y + 32.0, 3.0, 34.0, Color(0.12, 0.06, 0.18, 0.6))
	_color_rect(c, couch_x + 175.0, couch_y + 32.0, 3.0, 34.0, Color(0.12, 0.06, 0.18, 0.6))
	_add_hide_spot(c, Vector2(couch_x + 145.0, couch_y + 34.0), "behind couch", 290.0, 68.0)
	_add_hide_spot(c, Vector2(tv_x + 90.0, tv_y + 20.0), "behind curtain", 140.0, 38.0)
	if is_obj:
		_add_objective(c, Vector2(tv_x + 90.0, tv_y + 10.0))

func _build_bathroom(c: Node2D, is_obj: bool) -> void:
	var tub_x: float = 185.0; var tub_y: float = WALL_T + 8.0
	_outlined_rect(c, tub_x, tub_y, 175.0, 95.0, Color(0.48, 0.52, 0.56, 1.0), Color(0.14, 0.16, 0.18, 1.0), 3.0)
	_color_rect(c, tub_x + 8.0, tub_y + 8.0, 159.0, 70.0, Color(0.20, 0.35, 0.48, 0.7))
	_surface_highlight(c, tub_x + 10.0, tub_y + 10.0, 80.0, 0.14)
	_color_rect(c, tub_x + 72.0, tub_y - 9.0, 8.0, 17.0, Color(0.55, 0.56, 0.60, 1.0))
	_color_rect(c, tub_x + 62.0, tub_y - 9.0, 26.0, 4.0, Color(0.55, 0.56, 0.60, 1.0))
	_shadow_line(c, tub_x, tub_y + 95.0, 175.0)
	var tlt_x: float = WALL_T + 6.0; var tlt_y: float = WALL_T + 8.0
	_outlined_rect(c, tlt_x, tlt_y, 46.0, 30.0, Color(0.75, 0.76, 0.78, 1.0), Color(0.14, 0.16, 0.18, 1.0))
	_surface_highlight(c, tlt_x + 2.0, tlt_y + 2.0, 42.0, 0.12)
	_color_rect(c, tlt_x + 15.0, tlt_y + 4.0, 16.0, 8.0, Color(0.60, 0.62, 0.64, 1.0))
	_outlined_rect(c, tlt_x - 4.0, tlt_y + 30.0, 54.0, 48.0, Color(0.70, 0.72, 0.74, 1.0), Color(0.14, 0.16, 0.18, 1.0))
	_color_rect(c, tlt_x - 2.0, tlt_y + 34.0, 50.0, 32.0, Color(0.55, 0.60, 0.65, 0.6))
	_shadow_line(c, tlt_x - 4.0, tlt_y + 78.0, 54.0)
	var sink_x: float = WALL_T + 6.0; var sink_y: float = WALL_T + 112.0
	_outlined_rect(c, sink_x - 2.0, sink_y, 50.0, 40.0, Color(0.70, 0.72, 0.74, 1.0), Color(0.14, 0.16, 0.18, 1.0))
	_color_rect(c, sink_x + 2.0, sink_y + 6.0, 42.0, 22.0, Color(0.50, 0.58, 0.65, 0.7))
	_surface_highlight(c, sink_x, sink_y, 46.0, 0.12)
	_color_rect(c, sink_x + 21.0, sink_y - 10.0, 4.0, 14.0, Color(0.55, 0.56, 0.60, 1.0))
	_color_rect(c, sink_x + 14.0, sink_y - 10.0, 18.0, 3.0, Color(0.55, 0.56, 0.60, 1.0))
	_outlined_rect(c, sink_x - 2.0, WALL_T + 4.0, 50.0, 40.0, Color(0.22, 0.28, 0.34, 1.0), Color(0.14, 0.16, 0.18, 1.0))
	_surface_highlight(c, sink_x, WALL_T + 6.0, 26.0, 0.18)
	_add_hide_spot(c, Vector2(tub_x + 88.0, tub_y + 48.0), "in bathtub", 170.0, 90.0)
	_add_hide_spot(c, Vector2(WALL_T + 30.0, ROOM_H - 75.0), "behind door", 56.0, 80.0)
	if is_obj:
		_add_objective(c, Vector2(tlt_x + 4.0, tlt_y + 38.0))

# ── DAD'S ROOM (full width) ───────────────────────────────────────────────────

func _build_dads_room(c: Node2D) -> void:
	# Wardrobe — left wall
	var wx: float = WALL_T + 4.0
	var wy: float = WALL_T + 14.0
	_shadow_line(c, wx, wy + 192.0, 76.0)
	_outlined_rect(c, wx, wy, 76.0, 192.0,
		Color(0.18, 0.10, 0.08, 1.0), Color(0.06, 0.04, 0.03, 1.0), 3.0)
	_color_rect(c, wx + 4.0, wy + 6.0, 30.0, 80.0, Color(0.14, 0.08, 0.06, 1.0))
	_color_rect(c, wx + 40.0, wy + 6.0, 30.0, 80.0, Color(0.14, 0.08, 0.06, 1.0))
	_color_rect(c, wx + 4.0, wy + 94.0, 30.0, 90.0, Color(0.14, 0.08, 0.06, 1.0))
	_color_rect(c, wx + 40.0, wy + 94.0, 30.0, 90.0, Color(0.14, 0.08, 0.06, 1.0))
	_color_rect(c, wx + 32.0, wy + 42.0, 10.0, 4.0, Color(0.38, 0.30, 0.22, 1.0))
	_color_rect(c, wx + 32.0, wy + 136.0, 10.0, 4.0, Color(0.38, 0.30, 0.22, 1.0))

	# Bed — centred
	var bx: float = 118.0
	var by: float = ROOM_H - 140.0
	_shadow_line(c, bx, by + 118.0, 210.0)
	_outlined_rect(c, bx, by, 210.0, 118.0,
		Color(0.22, 0.10, 0.10, 1.0), Color(0.08, 0.04, 0.04, 1.0), 3.0)
	_color_rect(c, bx + 4.0, by + 4.0, 202.0, 102.0, Color(0.30, 0.14, 0.14, 1.0))
	_color_rect(c, bx + 4.0, by + 24.0, 202.0, 78.0, Color(0.18, 0.08, 0.08, 1.0))
	_color_rect(c, bx + 4.0, by + 24.0, 202.0, 9.0, Color(0.28, 0.12, 0.12, 1.0))
	_surface_highlight(c, bx + 6.0, by + 26.0, 90.0, 0.07)
	_outlined_rect(c, bx + 8.0, by + 5.0, 70.0, 22.0,
		Color(0.65, 0.62, 0.60, 1.0), Color(0.35, 0.28, 0.28, 1.0))
	_surface_highlight(c, bx + 10.0, by + 7.0, 38.0, 0.10)
	_color_rect(c, bx - 5.0, by - 10.0, 220.0, 14.0, Color(0.14, 0.06, 0.06, 1.0))

	# Nightstand + alarm clock — right of bed
	var nx: float = bx + 214.0
	var ny: float = by + 10.0
	_outlined_rect(c, nx, ny, 44.0, 58.0,
		Color(0.20, 0.10, 0.08, 1.0), Color(0.08, 0.04, 0.04, 1.0))
	_outlined_rect(c, nx + 8.0, ny - 20.0, 28.0, 18.0,
		Color(0.15, 0.15, 0.18, 1.0), Color(0.06, 0.06, 0.08, 1.0))
	_color_rect(c, nx + 11.0, ny - 17.0, 22.0, 12.0, Color(0.05, 0.60, 0.10, 0.8))
	_color_rect(c, nx + 10.0, ny, 5.0, 3.0, Color(0.15, 0.15, 0.18, 1.0))
	_color_rect(c, nx + 27.0, ny, 5.0, 3.0, Color(0.15, 0.15, 0.18, 1.0))

	_add_hide_spot(c, Vector2(wx + 38.0, wy + 96.0), "in wardrobe", 76.0, 192.0)

# ── KID'S ROOM (full width) ───────────────────────────────────────────────────

func _build_kids_room(c: Node2D) -> void:
	# Desk — left side against wall
	var dx: float = WALL_T + 4.0
	var dy: float = WALL_T + 14.0
	_shadow_line(c, dx, dy + 54.0, 100.0)
	_outlined_rect(c, dx, dy, 100.0, 10.0,
		Color(0.28, 0.20, 0.12, 1.0), Color(0.12, 0.08, 0.04, 1.0))
	_surface_highlight(c, dx + 2.0, dy, 96.0, 0.10)
	_color_rect(c, dx + 4.0, dy + 10.0, 10.0, 44.0, Color(0.22, 0.16, 0.10, 1.0))
	_color_rect(c, dx + 86.0, dy + 10.0, 10.0, 44.0, Color(0.22, 0.16, 0.10, 1.0))
	_outlined_rect(c, dx + 14.0, dy + 14.0, 64.0, 26.0,
		Color(0.24, 0.17, 0.10, 1.0), Color(0.12, 0.08, 0.04, 1.0))
	_color_rect(c, dx + 39.0, dy + 22.0, 14.0, 5.0, Color(0.40, 0.32, 0.22, 1.0))

	# Star poster above desk
	_outlined_rect(c, dx + 4.0, WALL_T + 4.0, 82.0, 34.0,
		Color(0.12, 0.18, 0.28, 1.0), Color(0.08, 0.08, 0.10, 1.0))
	_color_rect(c, dx + 12.0, WALL_T + 8.0, 8.0, 8.0, Color(0.9, 0.85, 0.2, 0.8))
	_color_rect(c, dx + 28.0, WALL_T + 13.0, 5.0, 5.0, Color(0.9, 0.85, 0.2, 0.6))
	_color_rect(c, dx + 46.0, WALL_T + 7.0, 7.0, 7.0, Color(0.9, 0.85, 0.2, 0.7))
	_color_rect(c, dx + 62.0, WALL_T + 15.0, 5.0, 5.0, Color(0.9, 0.85, 0.2, 0.5))

	# Bed — centred
	var bx: float = 100.0
	var by: float = ROOM_H - 128.0
	_shadow_line(c, bx, by + 108.0, 210.0)
	_outlined_rect(c, bx, by, 210.0, 108.0,
		Color(0.16, 0.22, 0.42, 1.0), Color(0.06, 0.08, 0.18, 1.0), 3.0)
	_color_rect(c, bx + 4.0, by + 4.0, 202.0, 92.0, Color(0.24, 0.32, 0.52, 1.0))
	_color_rect(c, bx + 4.0, by + 24.0, 202.0, 72.0, Color(0.18, 0.28, 0.55, 1.0))
	_color_rect(c, bx + 4.0, by + 24.0, 202.0, 9.0, Color(0.28, 0.40, 0.65, 1.0))
	_surface_highlight(c, bx + 6.0, by + 26.0, 90.0, 0.08)
	_outlined_rect(c, bx + 8.0, by + 5.0, 64.0, 22.0,
		Color(0.82, 0.82, 0.86, 1.0), Color(0.40, 0.42, 0.50, 1.0))
	_surface_highlight(c, bx + 10.0, by + 7.0, 36.0, 0.14)
	_color_rect(c, bx - 5.0, by - 9.0, 220.0, 12.0, Color(0.10, 0.15, 0.30, 1.0))

	# Nightstand + lamp — right of bed
	var nx: float = bx + 214.0
	var ny: float = by + 10.0
	_outlined_rect(c, nx, ny, 42.0, 52.0,
		Color(0.22, 0.16, 0.10, 1.0), Color(0.10, 0.07, 0.04, 1.0))
	_color_rect(c, nx + 14.0, ny - 24.0, 3.0, 24.0, Color(0.30, 0.24, 0.18, 1.0))
	_outlined_rect(c, nx + 4.0, ny - 36.0, 26.0, 14.0,
		Color(0.70, 0.60, 0.30, 0.9), Color(0.30, 0.24, 0.16, 1.0))
	_surface_highlight(c, nx + 6.0, ny - 34.0, 16.0, 0.20)

	_add_hide_spot(c, Vector2(bx + 105.0, by + 54.0), "under bed", 210.0, 108.0)
	_add_hide_spot(c, Vector2(dx + 50.0, dy + 27.0), "under desk", 100.0, 54.0)
	# Full-width bed return — covers the bed
	var area := Area2D.new()
	area.name = "BedReturn"
	area.set_script(load("res://scripts/bed_return.gd"))
	area.position = Vector2(bx + 105.0, by + 54.0)
	area.collision_layer = 0
	area.collision_mask = 1
	var vis := Polygon2D.new()
	vis.name = "Visual"
	vis.polygon = PackedVector2Array([
		Vector2(-101, -50), Vector2(101, -50), Vector2(101, 50), Vector2(-101, 50)
	])
	vis.color = Color(0.18, 0.26, 0.50, 0.0)
	area.add_child(vis)
	var cs := CollisionShape2D.new()
	cs.name = "CollisionShape2D"
	var rs := RectangleShape2D.new()
	rs.size = Vector2(202.0, 100.0)
	cs.shape = rs
	area.add_child(cs)
	var lbl := Label.new()
	lbl.name = "PromptLabel"
	lbl.text = "TAP TO SLEEP 🛏️"
	lbl.position = Vector2(-80.0, -68.0)
	lbl.visible = false
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.modulate = Color(1.0, 0.9, 0.2, 1.0)
	area.add_child(lbl)
	c.add_child(area)

# ── Entity spawners ───────────────────────────────────────────────────────────

func _add_hide_spot(parent: Node2D, pos: Vector2, spot_name: String, w: float = 80.0, h: float = 50.0) -> void:
	var scene: PackedScene = load("res://entities/hide_spot.tscn")
	if not scene:
		return
	var hs: Area2D = scene.instantiate()
	hs.position = pos
	if hs.get("spot_name") != null:
		hs.spot_name = spot_name
	var col: Node = hs.get_node_or_null("CollisionShape2D")
	if col and col.shape is RectangleShape2D:
		var ns := RectangleShape2D.new()
		ns.size = Vector2(w, h)
		col.shape = ns
	var vis: Node = hs.get_node_or_null("Visual")
	if vis:
		vis.polygon = PackedVector2Array([
			Vector2(-w * 0.5, -h * 0.5), Vector2(w * 0.5, -h * 0.5),
			Vector2(w * 0.5, h * 0.5), Vector2(-w * 0.5, h * 0.5)
		])
	parent.add_child(hs)

func _add_objective(parent: Node2D, pos: Vector2) -> void:
	var scene: PackedScene = load("res://entities/objective.tscn")
	if not scene:
		return
	var obj: Area2D = scene.instantiate()
	obj.position = pos
	parent.add_child(obj)


# ── Room data ─────────────────────────────────────────────────────────────────

func _floor_color(rtype: String) -> Color:
	match rtype:
		"kitchen":      return Color(0.10, 0.11, 0.08, 1.0)
		"living_room":  return Color(0.10, 0.08, 0.11, 1.0)
		"bathroom":     return Color(0.08, 0.10, 0.12, 1.0)
	return Color(0.09, 0.09, 0.11, 1.0)

func _wall_shade(rtype: String) -> Color:
	match rtype:
		"kitchen":      return Color(0.13, 0.12, 0.10, 1.0)
		"living_room":  return Color(0.11, 0.10, 0.14, 1.0)
		"bathroom":     return Color(0.10, 0.12, 0.14, 1.0)
	return Color(0.10, 0.10, 0.12, 1.0)

func _room_label(rtype: String) -> String:
	match rtype:
		"kitchen":      return "KITCHEN"
		"living_room":  return "LIVING ROOM"
		"bathroom":     return "BATHROOM"
	return rtype.to_upper()

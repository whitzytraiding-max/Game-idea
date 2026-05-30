extends RefCounted

const ROOM_W: float = 390.0
const ROOM_H: float = 350.0
const WALL_T: float = 14.0
const DOOR_W: float = 90.0
const DOOR_X: float = (ROOM_W - DOOR_W) * 0.5   # 150.0

const WALL_COLOR  := Color(0.14, 0.11, 0.18, 1.0)
const DOOR_COLOR  := Color(0.20, 0.14, 0.08, 1.0)

const ALL_MIDDLE: Array = ["kitchen", "living_room", "bathroom"]

# ── Entry point ─────────────────────────────────────────────────────────────

func generate(required_room: String, num_middle: int) -> Node2D:
	num_middle = clampi(num_middle, 2, 5)

	# Build middle room list — required room always present
	var middle: Array = [required_room]
	var pool: Array = []
	for r in ALL_MIDDLE:
		if r != required_room:
			pool.append(r)
	pool.shuffle()
	for i in range(min(num_middle - 1, pool.size())):
		middle.append(pool[i])
	middle.shuffle()

	# Layout: dad at top (y=0), kid at bottom
	var rooms: Array = ["dads_room"] + middle + ["kids_room"]
	var total_h: float = rooms.size() * ROOM_H

	var root := Node2D.new()
	root.name = "GeneratedHouse"

	# Full dark background (required by game.gd camera clamp via .size.y)
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.size = Vector2(ROOM_W, total_h)
	bg.color = Color(0.06, 0.06, 0.12, 1.0)
	root.add_child(bg)

	for i in range(rooms.size()):
		var rtype: String = rooms[i]
		var y_off: float = float(i) * ROOM_H
		var north_door: bool = (i > 0)
		var south_door: bool = (i < rooms.size() - 1)
		var is_obj: bool = (rtype == required_room)
		_build_room(root, rtype, y_off, north_door, south_door, is_obj)

	# PlayerStart — lower portion of kid's room
	var ps := Node2D.new()
	ps.name = "PlayerStart"
	ps.position = Vector2(ROOM_W * 0.5, float(rooms.size() - 1) * ROOM_H + ROOM_H * 0.78)
	root.add_child(ps)

	# DadStart — upper portion of dad's room
	var ds := Node2D.new()
	ds.name = "DadStart"
	ds.position = Vector2(ROOM_W * 0.3, ROOM_H * 0.32)
	root.add_child(ds)

	return root

# ── Room builder ─────────────────────────────────────────────────────────────

func _build_room(root: Node2D, rtype: String, y_off: float, north_door: bool, south_door: bool, is_obj: bool) -> void:
	var c := Node2D.new()
	c.name = rtype
	c.position = Vector2(0.0, y_off)
	root.add_child(c)

	# Floor
	var floor := ColorRect.new()
	floor.size = Vector2(ROOM_W, ROOM_H)
	floor.color = _floor_color(rtype)
	c.add_child(floor)

	# Room name label
	var lbl := Label.new()
	lbl.text = _room_label(rtype)
	lbl.position = Vector2(WALL_T + 4.0, WALL_T + 4.0)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.modulate = Color(0.55, 0.55, 0.6, 0.75)
	c.add_child(lbl)

	# Walls
	_north_wall(c, north_door)
	_south_wall(c, south_door)
	# Side walls (avoid corner overlap)
	_wall_rect(c, 0.0, WALL_T, WALL_T, ROOM_H - WALL_T * 2.0)
	_wall_rect(c, ROOM_W - WALL_T, WALL_T, WALL_T, ROOM_H - WALL_T * 2.0)

	# Furniture + entities
	_room_content(c, rtype, is_obj)

# ── Wall helpers ─────────────────────────────────────────────────────────────

func _north_wall(c: Node2D, has_door: bool) -> void:
	if has_door:
		_wall_rect(c, 0.0, 0.0, DOOR_X, WALL_T)
		_wall_rect(c, DOOR_X + DOOR_W, 0.0, ROOM_W - DOOR_X - DOOR_W, WALL_T)
		_color_rect(c, DOOR_X, 0.0, DOOR_W, WALL_T, DOOR_COLOR)
	else:
		_wall_rect(c, 0.0, 0.0, ROOM_W, WALL_T)

func _south_wall(c: Node2D, has_door: bool) -> void:
	var y: float = ROOM_H - WALL_T
	if has_door:
		_wall_rect(c, 0.0, y, DOOR_X, WALL_T)
		_wall_rect(c, DOOR_X + DOOR_W, y, ROOM_W - DOOR_X - DOOR_W, WALL_T)
		_color_rect(c, DOOR_X, y, DOOR_W, WALL_T, DOOR_COLOR)
	else:
		_wall_rect(c, 0.0, y, ROOM_W, WALL_T)

func _wall_rect(parent: Node2D, x: float, y: float, w: float, h: float) -> void:
	var body := StaticBody2D.new()
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

	parent.add_child(body)

# Visual-only colored rect (no collision)
func _color_rect(parent: Node2D, x: float, y: float, w: float, h: float, col: Color) -> void:
	var cr := ColorRect.new()
	cr.position = Vector2(x, y)
	cr.size = Vector2(w, h)
	cr.color = col
	parent.add_child(cr)

# ── Room content ─────────────────────────────────────────────────────────────

func _room_content(c: Node2D, rtype: String, is_obj: bool) -> void:
	match rtype:
		"dads_room":
			_color_rect(c, 120.0, 55.0, 150.0, 80.0, Color(0.28, 0.10, 0.10, 1.0))   # bed
			_color_rect(c, 280.0, 55.0, 50.0, 40.0, Color(0.18, 0.12, 0.10, 1.0))    # nightstand
			_add_hide_spot(c, Vector2(280.0, 160.0), "wardrobe")
			# No objective here

		"kids_room":
			_color_rect(c, 110.0, ROOM_H - 105.0, 160.0, 75.0, Color(0.10, 0.18, 0.38, 1.0))  # bed
			_color_rect(c, 290.0, ROOM_H - 105.0, 70.0, 40.0, Color(0.18, 0.12, 0.10, 1.0))   # nightstand
			_color_rect(c, 18.0, 65.0, 85.0, 50.0, Color(0.20, 0.14, 0.08, 1.0))               # desk
			_add_hide_spot(c, Vector2(110.0, ROOM_H - 85.0), "under bed")
			_add_hide_spot(c, Vector2(18.0, 65.0), "under desk")
			_add_bed_return(c)
			# No item objective here

		"kitchen":
			# Counter along top
			_color_rect(c, WALL_T, WALL_T, 260.0, 50.0, Color(0.22, 0.20, 0.16, 1.0))
			# Fridge (mission target area)
			_color_rect(c, 300.0, WALL_T, 76.0, 110.0, Color(0.42, 0.44, 0.46, 1.0))
			# Table
			_color_rect(c, 130.0, 170.0, 130.0, 70.0, Color(0.20, 0.16, 0.10, 1.0))
			_add_hide_spot(c, Vector2(WALL_T + 4.0, 80.0), "under counter")
			_add_hide_spot(c, Vector2(130.0, 175.0), "under table")
			if is_obj:
				_add_objective(c, Vector2(338.0, WALL_T + 60.0))

		"living_room":
			# Couch at bottom
			_color_rect(c, 60.0, ROOM_H - 115.0, 270.0, 55.0, Color(0.22, 0.13, 0.30, 1.0))
			# TV at top
			_color_rect(c, 125.0, WALL_T + 10.0, 140.0, 22.0, Color(0.05, 0.04, 0.08, 1.0))
			_color_rect(c, 115.0, WALL_T + 32.0, 160.0, 18.0, Color(0.18, 0.14, 0.10, 1.0))  # TV stand
			# Coffee table
			_color_rect(c, 130.0, ROOM_H - 165.0, 130.0, 40.0, Color(0.18, 0.13, 0.08, 1.0))
			_add_hide_spot(c, Vector2(60.0, ROOM_H - 110.0), "behind couch")
			_add_hide_spot(c, Vector2(280.0, 100.0), "behind curtain")
			if is_obj:
				_add_objective(c, Vector2(195.0, WALL_T + 18.0))

		"bathroom":
			# Bathtub along top
			_color_rect(c, 200.0, WALL_T + 6.0, 165.0, 85.0, Color(0.55, 0.60, 0.65, 1.0))
			# Toilet
			_color_rect(c, WALL_T + 4.0, WALL_T + 6.0, 45.0, 60.0, Color(0.78, 0.78, 0.80, 1.0))
			# Sink
			_color_rect(c, WALL_T + 4.0, WALL_T + 80.0, 40.0, 35.0, Color(0.68, 0.68, 0.72, 1.0))
			_add_hide_spot(c, Vector2(200.0, WALL_T + 10.0), "in bathtub")
			_add_hide_spot(c, Vector2(WALL_T + 4.0, 170.0), "behind door")
			if is_obj:
				_add_objective(c, Vector2(WALL_T + 26.0, WALL_T + 36.0))

# ── Entity spawners ──────────────────────────────────────────────────────────

func _add_hide_spot(parent: Node2D, pos: Vector2, spot_name: String) -> void:
	var scene: PackedScene = load("res://entities/hide_spot.tscn")
	if not scene:
		return
	var hs: Area2D = scene.instantiate()
	hs.position = pos
	if hs.get("spot_name") != null:
		hs.spot_name = spot_name
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
	area.position = Vector2(ROOM_W * 0.5, ROOM_H - 68.0)
	area.collision_layer = 0
	area.collision_mask = 1

	# Visual polygon matching original level
	var vis := Polygon2D.new()
	vis.name = "Visual"
	vis.polygon = PackedVector2Array([
		Vector2(-48, -28), Vector2(48, -28), Vector2(48, 28), Vector2(-48, 28)
	])
	vis.color = Color(0.3, 0.38, 0.6, 0.9)
	area.add_child(vis)

	var cs := CollisionShape2D.new()
	cs.name = "CollisionShape2D"
	var rs := RectangleShape2D.new()
	rs.size = Vector2(96, 56)
	cs.shape = rs
	area.add_child(cs)

	var lbl := Label.new()
	lbl.name = "PromptLabel"
	lbl.text = "TAP TO SLEEP 🛏️"
	lbl.position = Vector2(-48, -52)
	lbl.visible = false
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.modulate = Color(1.0, 0.9, 0.2, 1.0)
	area.add_child(lbl)

	parent.add_child(area)

# ── Room data helpers ────────────────────────────────────────────────────────

func _floor_color(rtype: String) -> Color:
	match rtype:
		"dads_room":    return Color(0.11, 0.08, 0.10, 1.0)
		"kids_room":    return Color(0.09, 0.10, 0.15, 1.0)
		"kitchen":      return Color(0.10, 0.12, 0.09, 1.0)
		"living_room":  return Color(0.11, 0.09, 0.13, 1.0)
		"bathroom":     return Color(0.08, 0.11, 0.13, 1.0)
	return Color(0.10, 0.10, 0.12, 1.0)

func _room_label(rtype: String) -> String:
	match rtype:
		"dads_room":    return "DAD'S ROOM"
		"kids_room":    return "YOUR ROOM"
		"kitchen":      return "KITCHEN"
		"living_room":  return "LIVING ROOM"
		"bathroom":     return "BATHROOM"
	return rtype.to_upper()

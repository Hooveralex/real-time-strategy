extends Node2D

var bar_width: float = 30.0
var bar_height: float = 4.0
var bar_offset: Vector2 = Vector2(0, -30)

var _background: Polygon2D
var _fill: Polygon2D

func _ready():
	position = bar_offset
	visible = false  # Only show when damaged
	
	# Background (dark)
	_background = Polygon2D.new()
	_background.polygon = _make_rect(bar_width, bar_height)
	_background.color = Color(0.2, 0.2, 0.2, 0.8)
	add_child(_background)
	
	# Fill (green)
	_fill = Polygon2D.new()
	_fill.polygon = _make_rect(bar_width, bar_height)
	_fill.color = Color(0.2, 0.9, 0.2)
	add_child(_fill)

func update_health(current: float, max_health: float):
	if max_health <= 0:
		return
	
	var ratio = clampf(current / max_health, 0.0, 1.0)
	
	# Only show when damaged
	visible = ratio < 1.0
	
	if not _fill:
		return
	
	# Update fill width
	var fill_width = bar_width * ratio
	_fill.polygon = _make_rect_offset(fill_width, bar_height)
	
	# Color: green -> yellow -> red
	if ratio > 0.6:
		_fill.color = Color(0.2, 0.9, 0.2)
	elif ratio > 0.3:
		_fill.color = Color(0.9, 0.9, 0.2)
	else:
		_fill.color = Color(0.9, 0.2, 0.2)

func _make_rect(w: float, h: float) -> PackedVector2Array:
	var hw = w / 2.0
	var hh = h / 2.0
	return PackedVector2Array([
		Vector2(-hw, -hh),
		Vector2(hw, -hh),
		Vector2(hw, hh),
		Vector2(-hw, hh)
	])

func _make_rect_offset(w: float, h: float) -> PackedVector2Array:
	# Fill bar anchored to left side of background
	var bg_hw = bar_width / 2.0
	var hh = h / 2.0
	return PackedVector2Array([
		Vector2(-bg_hw, -hh),
		Vector2(-bg_hw + w, -hh),
		Vector2(-bg_hw + w, hh),
		Vector2(-bg_hw, hh)
	])

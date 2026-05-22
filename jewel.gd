class_name Jewel
extends Control

signal jewel_clicked(jewel)
signal jewel_dragged(jewel, direction)
signal jewel_double_clicked(jewel)

enum JewelType { RED, BLUE, GREEN, YELLOW, PURPLE, ORANGE }

@export var type: JewelType = JewelType.RED:
	set(value):
		type = value
		queue_redraw()

@export var is_selected: bool = false:
	set(value):
		is_selected = value
		queue_redraw()

@export var is_matched: bool = false:
	set(value):
		is_matched = value
		queue_redraw()

# Grid coordinates
var grid_x: int = 0
var grid_y: int = 0

# Swiping detection variables
var is_mouse_down: bool = false
var mouse_down_pos: Vector2 = Vector2.ZERO
const DRAG_THRESHOLD: float = 20.0
var drag_reported: bool = false

# Pulse/animation timers
var glow_time: float = 0.0

# Double click variables
var last_click_time: int = 0
const DOUBLE_CLICK_DELAY_MS: int = 350

func _ready() -> void:
	# Ensure the Control node catches mouse events
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(64, 64)
	pivot_offset = custom_minimum_size / 2.0

func _process(delta: float) -> void:
	if is_selected or is_matched:
		glow_time += delta * 6.0
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if is_matched:
		return # Don't accept inputs if already matched

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_mouse_down = true
				mouse_down_pos = event.position
				drag_reported = false
			else:
				if is_mouse_down:
					is_mouse_down = false
					if not drag_reported:
						var current_time = Time.get_ticks_msec()
						if current_time - last_click_time < DOUBLE_CLICK_DELAY_MS:
							jewel_double_clicked.emit(self)
							last_click_time = 0
						else:
							last_click_time = current_time
							jewel_clicked.emit(self)
	
	elif event is InputEventMouseMotion:
		if is_mouse_down and not drag_reported:
			var diff = event.position - mouse_down_pos
			if diff.length() > DRAG_THRESHOLD:
				drag_reported = true
				is_mouse_down = false
				
				# Determine major direction
				var direction = Vector2.ZERO
				if abs(diff.x) > abs(diff.y):
					direction = Vector2.LEFT if diff.x < 0 else Vector2.RIGHT
				else:
					direction = Vector2.UP if diff.y < 0 else Vector2.DOWN
				
				jewel_dragged.emit(self, direction)

func _draw() -> void:
	var center = size / 2.0
	var r = size.x * 0.38
	
	# Fetch shape points and colors
	var color = get_jewel_color()
	var points = get_shape_points(center, r)
	
	# 1. Draw Drop Shadow
	var shadow_offset = Vector2(3, 5)
	if points.size() > 0:
		var shadow_points = PackedVector2Array()
		for p in points:
			shadow_points.append(p + shadow_offset)
		draw_polygon(shadow_points, PackedColorArray([Color(0, 0, 0, 0.22)]))
	else:
		# Circle shadow
		draw_circle(center + shadow_offset, r, Color(0, 0, 0, 0.22))
		
	# 2. Draw Selection Glow (Behind Shape)
	if is_selected:
		var pulse = abs(sin(glow_time)) * 0.4 + 0.6
		var glow_color = Color(1.0, 0.85, 0.3, 0.7 * pulse)
		var glow_width = 8.0 + pulse * 4.0
		if points.size() > 0:
			var glow_points = Array(points)
			glow_points.append(points[0]) # Close polyline
			draw_polyline(PackedVector2Array(glow_points), glow_color, glow_width, true)
		else:
			# Draw circle outline glow
			draw_arc(center, r + 2.0, 0.0, TAU, 32, glow_color, glow_width, true)

	# 3. Draw Thick Dark Border (Background of fill)
	var border_color = Color(0.12, 0.12, 0.14)
	var border_width = 4.0
	if points.size() > 0:
		var border_points = Array(points)
		border_points.append(points[0])
		draw_polyline(PackedVector2Array(border_points), border_color, border_width, true)
	else:
		draw_circle(center, r + 1.0, border_color)

	# 4. Draw Main Solid Filled Shape
	if points.size() > 0:
		draw_polygon(points, PackedColorArray([color]))
	else:
		draw_circle(center, r, color)
		
	# 5. Draw Glossy Highlight (Glass Reflection)
	draw_gloss_highlight(center, r)

	# 6. Draw Match Flash Overlay
	if is_matched:
		var flash_alpha = abs(sin(glow_time * 2.0)) * 0.7 + 0.3
		var flash_color = Color(1.0, 1.0, 1.0, flash_alpha)
		if points.size() > 0:
			draw_polygon(points, PackedColorArray([flash_color]))
		else:
			draw_circle(center, r, flash_color)

func get_jewel_color() -> Color:
	match type:
		JewelType.RED:
			return Color("#ff3b30") # Ruby Red
		JewelType.BLUE:
			return Color("#007aff") # Sapphire Blue
		JewelType.GREEN:
			return Color("#34c759") # Emerald Green
		JewelType.YELLOW:
			return Color("#ffcc00") # Topaz Yellow
		JewelType.PURPLE:
			return Color("#af52de") # Amethyst Purple
		JewelType.ORANGE:
			return Color("#ff9500") # Amber Orange
	return Color.WHITE

func get_shape_points(center: Vector2, r: float) -> PackedVector2Array:
	var points = PackedVector2Array()
	match type:
		JewelType.RED: # Diamond / Rhombus
			points.append(center + Vector2(0, -r))
			points.append(center + Vector2(r * 0.9, 0))
			points.append(center + Vector2(0, r))
			points.append(center + Vector2(-r * 0.9, 0))
			
		JewelType.BLUE: # Square
			points.append(center + Vector2(-r * 0.8, -r * 0.8))
			points.append(center + Vector2(r * 0.8, -r * 0.8))
			points.append(center + Vector2(r * 0.8, r * 0.8))
			points.append(center + Vector2(-r * 0.8, r * 0.8))
			
		JewelType.GREEN: # Pentagon
			for i in range(5):
				var angle = deg_to_rad(-90 + i * 72)
				points.append(center + Vector2(cos(angle), sin(angle)) * r)
				
		JewelType.YELLOW: # Triangle
			points.append(center + Vector2(0, -r))
			points.append(center + Vector2(r * 0.9, r * 0.75))
			points.append(center + Vector2(-r * 0.9, r * 0.75))
			
		JewelType.PURPLE: # Hexagon
			for i in range(6):
				var angle = deg_to_rad(i * 60)
				points.append(center + Vector2(cos(angle), sin(angle)) * r)
				
		JewelType.ORANGE: # Circle (draw_circle handles it)
			pass
			
	return points

func draw_gloss_highlight(center: Vector2, r: float) -> void:
	var highlight_color = Color(1.0, 1.0, 1.0, 0.35)
	
	match type:
		JewelType.RED: # Top-left facet highlight
			var h_points = PackedVector2Array([
				center + Vector2(0, -r * 0.85),
				center + Vector2(-r * 0.75, 0),
				center + Vector2(-r * 0.4, 0),
				center + Vector2(0, -r * 0.45)
			])
			draw_polygon(h_points, PackedColorArray([highlight_color]))
			
		JewelType.BLUE: # Top-left edge glow
			var h_points = PackedVector2Array([
				center + Vector2(-r * 0.7, -r * 0.7),
				center + Vector2(r * 0.5, -r * 0.7),
				center + Vector2(r * 0.5, -r * 0.5),
				center + Vector2(-r * 0.5, -r * 0.5),
				center + Vector2(-r * 0.5, r * 0.5),
				center + Vector2(-r * 0.7, r * 0.5)
			])
			draw_polygon(h_points, PackedColorArray([highlight_color]))
			
		JewelType.GREEN: # Pentagon corner highlight
			var h_points = PackedVector2Array([
				center + Vector2(0, -r * 0.85),
				center + Vector2(cos(deg_to_rad(-18)) * r * 0.85, sin(deg_to_rad(-18)) * r * 0.85),
				center + Vector2(cos(deg_to_rad(-18)) * r * 0.55, sin(deg_to_rad(-18)) * r * 0.55),
				center + Vector2(0, -r * 0.5)
			])
			draw_polygon(h_points, PackedColorArray([highlight_color]))
			
		JewelType.YELLOW: # Left-side slope highlight
			var h_points = PackedVector2Array([
				center + Vector2(0, -r * 0.85),
				center + Vector2(-r * 0.75, r * 0.65),
				center + Vector2(-r * 0.45, r * 0.65),
				center + Vector2(0, -r * 0.4)
			])
			draw_polygon(h_points, PackedColorArray([highlight_color]))
			
		JewelType.PURPLE: # Hexagon top-left facet
			var h_points = PackedVector2Array([
				center + Vector2(cos(deg_to_rad(180)) * r * 0.85, sin(deg_to_rad(180)) * r * 0.85),
				center + Vector2(cos(deg_to_rad(240)) * r * 0.85, sin(deg_to_rad(240)) * r * 0.85),
				center + Vector2(cos(deg_to_rad(300)) * r * 0.85, sin(deg_to_rad(300)) * r * 0.85),
				center + Vector2(cos(deg_to_rad(300)) * r * 0.55, sin(deg_to_rad(300)) * r * 0.55),
				center + Vector2(cos(deg_to_rad(240)) * r * 0.55, sin(deg_to_rad(240)) * r * 0.55),
				center + Vector2(cos(deg_to_rad(180)) * r * 0.55, sin(deg_to_rad(180)) * r * 0.55)
			])
			draw_polygon(h_points, PackedColorArray([highlight_color]))
			
		JewelType.ORANGE: # Rounded glassy circle crescent
			draw_circle(center - Vector2(r * 0.28, r * 0.28), r * 0.25, highlight_color)

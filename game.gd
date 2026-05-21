extends Control

const GRID_WIDTH = 8
const GRID_HEIGHT = 8
const CELL_SIZE = 64.0
const GRID_MARGIN = 4.0

const jewel_scene = preload("res://jewel.tscn")

# Grid reference: 2D array [x][y]
var grid: Array = []

# Selected jewel tracker
var selected_jewel: Control = null

# State locker
var is_board_locked: bool = false

# Player stats
var score: int = 0
var moves_remaining: int = 30
var is_game_over: bool = false

# UI Nodes (automatically bound to scene structure)
@onready var grid_container: Control = $Board/GridContainer
@onready var score_label: Label = $HUD/Margin/VBox/StatsRow/ScoreLabel
@onready var moves_label: Label = $HUD/Margin/VBox/StatsRow/MovesLabel
@onready var combo_label: Label = $Board/ComboLabel
@onready var info_overlay: Label = $Board/InfoOverlay
@onready var game_over_panel: Panel = $GameOverPanel
@onready var final_score_label: Label = $GameOverPanel/VBox/FinalScoreLabel
@onready var restart_button: Button = $GameOverPanel/VBox/RestartButton
@onready var hud_restart_button: Button = $HUD/Margin/VBox/StatsRow/RestartButton

func _ready() -> void:
	# Setup random seed
	randomize()
	
	# Connect buttons
	restart_button.pressed.connect(_on_restart_pressed)
	hud_restart_button.pressed.connect(_on_restart_pressed)
	
	# Initialize game
	start_new_game()

func start_new_game() -> void:
	# Reset states
	score = 0
	moves_remaining = 30
	is_game_over = false
	is_board_locked = false
	selected_jewel = null
	
	game_over_panel.visible = false
	info_overlay.visible = false
	combo_label.text = ""
	score_label.text = "Score: 0"
	moves_label.text = "Moves: 30"
	
	# Clear old children from grid container
	for child in grid_container.get_children():
		child.queue_free()
		
	# Initialize grid array
	grid = []
	for x in range(GRID_WIDTH):
		var col = []
		for y in range(GRID_HEIGHT):
			col.append(null)
		grid.append(col)
		
	# Populate board with no initial matches
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			var jewel = jewel_scene.instantiate()
			grid_container.add_child(jewel)
			
			# Choose a type that doesn't create a match
			var jewel_type = get_non_matching_type(x, y)
			jewel.type = jewel_type
			jewel.grid_x = x
			jewel.grid_y = y
			jewel.position = get_cell_position(x, y)
			
			# Signals
			jewel.jewel_clicked.connect(_on_jewel_clicked)
			jewel.jewel_dragged.connect(_on_jewel_dragged)
			
			grid[x][y] = jewel
			
	# Ensure the board has at least one valid starting move
	if not has_valid_moves():
		shuffle_board_with_guarantee(false)

func get_cell_position(x: int, y: int) -> Vector2:
	return Vector2(
		x * (CELL_SIZE + GRID_MARGIN) + GRID_MARGIN,
		y * (CELL_SIZE + GRID_MARGIN) + GRID_MARGIN
	)

func get_non_matching_type(x: int, y: int) -> int:
	var available_types = [0, 1, 2, 3, 4, 5]
	available_types.shuffle()
	
	for t in available_types:
		if not creates_match_at(x, y, t):
			return t
			
	return available_types[0] # Fallback

func creates_match_at(x: int, y: int, type: int) -> bool:
	# Horizontal check (2 cells to the left)
	if x >= 2:
		if grid[x-1][y] != null and grid[x-1][y].type == type:
			if grid[x-2][y] != null and grid[x-2][y].type == type:
				return true
	# Vertical check (2 cells above)
	if y >= 2:
		if grid[x][y-1] != null and grid[x][y-1].type == type:
			if grid[x][y-2] != null and grid[x][y-2].type == type:
				return true
	return false

# ----------------- GAME PLAY INTERACTION -----------------

func _on_jewel_clicked(jewel: Control) -> void:
	if is_board_locked or is_game_over:
		return
		
	if selected_jewel == null:
		# Select
		selected_jewel = jewel
		jewel.is_selected = true
	elif selected_jewel == jewel:
		# Deselect
		jewel.is_selected = false
		selected_jewel = null
	else:
		# Check adjacency
		if is_adjacent(selected_jewel, jewel):
			var a = selected_jewel
			var b = jewel
			
			# Deselect
			a.is_selected = false
			selected_jewel = null
			
			# Swap!
			swap_jewels(a, b)
		else:
			# Switch selection
			selected_jewel.is_selected = false
			selected_jewel = jewel
			jewel.is_selected = true

func _on_jewel_dragged(jewel: Control, direction: Vector2) -> void:
	if is_board_locked or is_game_over:
		return
		
	# Find adjacent coordinates
	var target_x = jewel.grid_x + int(direction.x)
	var target_y = jewel.grid_y + int(direction.y)
	
	if target_x >= 0 and target_x < GRID_WIDTH and target_y >= 0 and target_y < GRID_HEIGHT:
		var target_jewel = grid[target_x][target_y]
		if target_jewel != null:
			# Clean selection
			if selected_jewel != null:
				selected_jewel.is_selected = false
				selected_jewel = null
				
			swap_jewels(jewel, target_jewel)

func is_adjacent(a: Control, b: Control) -> bool:
	var diff_x = abs(a.grid_x - b.grid_x)
	var diff_y = abs(a.grid_y - b.grid_y)
	return (diff_x + diff_y) == 1

# ----------------- SWAP AND ANIMATION ENGINE -----------------

func swap_jewels(a: Control, b: Control) -> void:
	is_board_locked = true
	moves_remaining -= 1
	moves_label.text = "Moves: " + str(moves_remaining)
	
	# Grid Coordinates cache
	var ax = a.grid_x
	var ay = a.grid_y
	var bx = b.grid_x
	var by = b.grid_y
	
	# Logic Swap
	a.grid_x = bx
	a.grid_y = by
	b.grid_x = ax
	b.grid_y = ay
	
	grid[ax][ay] = b
	grid[bx][by] = a
	
	# Play Swap Tween
	var tween = create_tween().set_parallel(true)
	tween.tween_property(a, "position", get_cell_position(bx, by), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(b, "position", get_cell_position(ax, ay), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	# Evaluate matches
	var matched_grid = find_matches()
	var has_matches = false
	
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			if matched_grid[x][y]:
				has_matches = true
				break
		if has_matches:
			break
			
	if has_matches:
		# Process cascades
		await process_matches_and_cascade()
	else:
		# Undo Logical Swap
		a.grid_x = ax
		a.grid_y = ay
		b.grid_x = bx
		b.grid_y = by
		
		grid[ax][ay] = a
		grid[bx][by] = b
		
		# Animate back swap
		var back_tween = create_tween().set_parallel(true)
		back_tween.tween_property(a, "position", get_cell_position(ax, ay), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		back_tween.tween_property(b, "position", get_cell_position(bx, by), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await back_tween.finished
		
		# Release locking
		if moves_remaining <= 0:
			show_game_over()
		else:
			is_board_locked = false

# ----------------- MATCH-3 & CASCADE CORE ALGORITHMS -----------------

func find_matches() -> Array:
	# Create match-tracker grid
	var matched_grid = []
	for x in range(GRID_WIDTH):
		var col = []
		for y in range(GRID_HEIGHT):
			col.append(false)
		matched_grid.append(col)
		
	# 1. Horizontal scans (Lines of 3 or more)
	for y in range(GRID_HEIGHT):
		var x = 0
		while x < GRID_WIDTH:
			if grid[x][y] != null:
				var target_type = grid[x][y].type
				var count = 1
				while x + count < GRID_WIDTH and grid[x + count][y] != null and grid[x + count][y].type == target_type:
					count += 1
				
				if count >= 3:
					for i in range(count):
						matched_grid[x + i][y] = true
				x += count
			else:
				x += 1
				
	# 2. Vertical scans (Lines of 3 or more)
	for x in range(GRID_WIDTH):
		var y = 0
		while y < GRID_HEIGHT:
			if grid[x][y] != null:
				var target_type = grid[x][y].type
				var count = 1
				while y + count < GRID_HEIGHT and grid[x][y + count] != null and grid[x][y + count].type == target_type:
					count += 1
				
				if count >= 3:
					for i in range(count):
						matched_grid[x][y + i] = true
				y += count
			else:
				y += 1
				
	return matched_grid

func process_matches_and_cascade() -> void:
	var matches_found = true
	var combo = 0
	
	while matches_found:
		var matched_grid = find_matches()
		var match_count = 0
		
		for x in range(GRID_WIDTH):
			for y in range(GRID_HEIGHT):
				if matched_grid[x][y]:
					match_count += 1
					
		if match_count == 0:
			matches_found = false
			break
			
		combo += 1
		var pts = match_count * 100 * combo
		score += pts
		
		# Show HUD updates
		score_label.text = "Score: " + str(score)
		
		if combo > 1:
			combo_label.text = "Combo x" + str(combo) + "!"
			combo_label.scale = Vector2(0.5, 0.5)
			var combo_tween = create_tween()
			combo_tween.tween_property(combo_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			combo_label.text = ""
			
		# Match sound mockup effect / visual dissolve
		var clear_tween = create_tween().set_parallel(true)
		for x in range(GRID_WIDTH):
			for y in range(GRID_HEIGHT):
				if matched_grid[x][y]:
					var jewel = grid[x][y]
					if jewel != null:
						jewel.is_matched = true
						clear_tween.tween_property(jewel, "scale", Vector2.ZERO, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
						clear_tween.tween_property(jewel, "modulate:a", 0.0, 0.24)
		await clear_tween.finished
		
		# Remove cleared node structures
		for x in range(GRID_WIDTH):
			for y in range(GRID_HEIGHT):
				if matched_grid[x][y]:
					if grid[x][y] != null:
						grid[x][y].queue_free()
						grid[x][y] = null
						
		# Wait a tiny moment
		await get_tree().create_timer(0.05).timeout
		
		# Apply gravity to pull down elements & refill board
		await apply_gravity_and_refill()
		
	combo_label.text = ""
	
	# Verify that moves remain possible
	if not has_valid_moves():
		await shuffle_board_with_guarantee(true)
		
	# Game Over checklist
	if moves_remaining <= 0:
		show_game_over()
	else:
		is_board_locked = false

func apply_gravity_and_refill() -> void:
	var fall_tween = create_tween().set_parallel(true)
	var max_duration = 0.0
	
	for x in range(GRID_WIDTH):
		var empty_slots = 0
		# Evaluate column from bottom to top
		for y in range(GRID_HEIGHT - 1, -1, -1):
			if grid[x][y] == null:
				empty_slots += 1
			elif empty_slots > 0:
				var target_y = y + empty_slots
				var jewel = grid[x][y]
				
				grid[x][target_y] = jewel
				grid[x][y] = null
				jewel.grid_y = target_y
				
				# Bounce Fall Animation
				var duration = 0.14 + (empty_slots * 0.04)
				max_duration = max(max_duration, duration)
				var final_pos = get_cell_position(x, target_y)
				
				fall_tween.tween_property(jewel, "position", final_pos, duration).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
				
		# Spawn elements at top columns
		for k in range(empty_slots):
			var target_y = empty_slots - 1 - k
			var jewel = jewel_scene.instantiate()
			grid_container.add_child(jewel)
			
			jewel.type = randi() % Jewel.JewelType.size()
			jewel.grid_x = x
			jewel.grid_y = target_y
			
			# Spawning point is off-screen
			var start_y = -1 - k
			jewel.position = get_cell_position(x, start_y)
			grid[x][target_y] = jewel
			
			jewel.jewel_clicked.connect(_on_jewel_clicked)
			jewel.jewel_dragged.connect(_on_jewel_dragged)
			
			# Spawn pop scale and fall bounce
			jewel.scale = Vector2.ZERO
			var final_pos = get_cell_position(x, target_y)
			var fall_dist = target_y - start_y
			var duration = 0.18 + (fall_dist * 0.04)
			max_duration = max(max_duration, duration)
			
			fall_tween.tween_property(jewel, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			fall_tween.tween_property(jewel, "position", final_pos, duration).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			
	if max_duration > 0.0:
		await fall_tween.finished

# ----------------- SHUFFLE & VALID PLAY SEARCHERS -----------------

func has_valid_moves() -> bool:
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			# Sim right swap
			if x < GRID_WIDTH - 1:
				if test_swap_creates_match(x, y, x + 1, y):
					return true
			# Sim bottom swap
			if y < GRID_HEIGHT - 1:
				if test_swap_creates_match(x, y, x, y + 1):
					return true
	return false

func test_swap_creates_match(x1: int, y1: int, x2: int, y2: int) -> bool:
	var j1 = grid[x1][y1]
	var j2 = grid[x2][y2]
	if j1 == null or j2 == null:
		return false
		
	# Logic simulation swap
	grid[x1][y1] = j2
	grid[x2][y2] = j1
	
	var is_match = check_cell_has_match(x1, y1) or check_cell_has_match(x2, y2)
	
	# Swap back simulation
	grid[x1][y1] = j1
	grid[x2][y2] = j2
	
	return is_match

func check_cell_has_match(cx: int, cy: int) -> bool:
	var target_type = grid[cx][cy].type
	
	# Horizontal check
	var h_count = 1
	var x = cx - 1
	while x >= 0 and grid[x][cy] != null and grid[x][cy].type == target_type:
		h_count += 1
		x -= 1
	x = cx + 1
	while x < GRID_WIDTH and grid[x][cy] != null and grid[x][cy].type == target_type:
		h_count += 1
		x += 1
	if h_count >= 3:
		return true
		
	# Vertical check
	var v_count = 1
	var y = cy - 1
	while y >= 0 and grid[cx][y] != null and grid[cx][y].type == target_type:
		v_count += 1
		y -= 1
	y = cy + 1
	while y < GRID_HEIGHT and grid[cx][y] != null and grid[cx][y].type == target_type:
		v_count += 1
		y += 1
	if v_count >= 3:
		return true
		
	return false

func shuffle_board_with_guarantee(animate_shuffle: bool = true) -> void:
	is_board_locked = true
	
	if animate_shuffle:
		info_overlay.text = "No Moves! Shuffling..."
		info_overlay.visible = true
		await get_tree().create_timer(1.2).timeout
		
	var attempts = 0
	while attempts < 100:
		var active_types = []
		for x in range(GRID_WIDTH):
			for y in range(GRID_HEIGHT):
				if grid[x][y] != null:
					active_types.append(grid[x][y].type)
					grid[x][y].queue_free()
					grid[x][y] = null
					
		while active_types.size() < GRID_WIDTH * GRID_HEIGHT:
			active_types.append(randi() % Jewel.JewelType.size())
			
		active_types.shuffle()
		
		# Build back elements one by one safely without immediate matches
		var idx = 0
		var builder_success = true
		for x in range(GRID_WIDTH):
			for y in range(GRID_HEIGHT):
				var found_type = false
				for i in range(idx, active_types.size()):
					var test_t = active_types[i]
					if not creates_match_at(x, y, test_t):
						# Swap types index
						var tmp = active_types[idx]
						active_types[idx] = active_types[i]
						active_types[i] = tmp
						found_type = true
						break
						
				if not found_type:
					builder_success = false
					break
					
				# Build jewel
				var jewel = jewel_scene.instantiate()
				grid_container.add_child(jewel)
				jewel.type = active_types[idx]
				jewel.grid_x = x
				jewel.grid_y = y
				jewel.position = get_cell_position(x, y)
				jewel.jewel_clicked.connect(_on_jewel_clicked)
				jewel.jewel_dragged.connect(_on_jewel_dragged)
				grid[x][y] = jewel
				
				idx += 1
			if not builder_success:
				break
				
		if builder_success and has_valid_moves():
			break
		attempts += 1
		
	info_overlay.visible = false
	is_board_locked = false

# ----------------- UI SCREEN BINDINGS -----------------

func show_game_over() -> void:
	is_game_over = true
	is_board_locked = true
	final_score_label.text = "Final Score: " + str(score)
	game_over_panel.visible = true

func _on_restart_pressed() -> void:
	start_new_game()

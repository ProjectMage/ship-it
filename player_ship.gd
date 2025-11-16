# PlayerShip - Controllable ship with water interaction
#
# This ship can be controlled with arrow keys and physically interacts
# with the water. The ship's movement creates waves that spread across
# the water surface.

extends CharacterBody2D

# Movement speed of the ship in pixels per second
@export var speed = 150.0

# Base strength of generated water waves (higher = larger waves)
@export var water_splash_force = 2.0

# Maximum distance to water surface for interaction (currently unused)
@export var water_check_distance = 50.0

# Multiplier for horizontal movement (lateral movement creates additional waves)
@export var horizontal_splash_multiplier = 0.5

# Auto-Pilot settings
@export var auto_pilot_idle_time = 3.0  # Seconds without input until auto-pilot starts
@export var auto_pilot_speed_multiplier = 0.6  # Speed in auto-pilot mode

# Reference to WaterBody in the scene
var water_body = null

# Last position of the ship (for future use)
var previous_position = Vector2.ZERO

# Auto-Pilot variables
var idle_timer = 0.0
var auto_pilot_active = false
var auto_pilot_target = Vector2.ZERO
var island_positions = []
var current_target_index = 0

# Gold collection tracking
var last_island_index = -1  # Track which island was last visited
signal gold_collected  # Signal to notify when gold is collected

func _ready() -> void:
	# Wait one frame so all nodes are loaded
	await get_tree().process_frame
	
	# Find the WaterBody in the scene
	water_body = get_tree().get_first_node_in_group("water")
	
	# Find all islands for auto-pilot
	setup_island_positions()
	
	previous_position = global_position

# Find and store island positions for auto-pilot navigation
func setup_island_positions() -> void:
	# Search for nodes with "island" in name (case-insensitive)
	var nodes = get_tree().get_nodes_in_group("islands")
	
	# If no group exists, manually search for known positions
	if nodes.is_empty():
		# Define default positions based on typical island locations
		island_positions = [
			Vector2(100, 320),   # Left (Home Island - no gold)
			Vector2(608, 322)    # Right (Treasure Island - gives gold)
		]
	else:
		for node in nodes:
			island_positions.append(node.global_position)
		print("Auto-Pilot: Found ", island_positions.size(), " islands")
	
	if island_positions.size() > 0:
		auto_pilot_target = island_positions[0]

func _physics_process(_delta: float) -> void:
	# Movement
	var direction = Vector2.ZERO
	var player_input = false
	
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
		player_input = true
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
		player_input = true
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
		player_input = true
	
	# Auto-Pilot System
	if player_input:
		# Player controls: Reset idle timer and deactivate auto-pilot
		idle_timer = 0.0
		if auto_pilot_active:
			auto_pilot_active = false
			print("Auto-Pilot deactivated - player took control")
	else:
		# No player input: Increase idle timer
		idle_timer += _delta
		
		# Activate auto-pilot after idle_time
		if idle_timer >= auto_pilot_idle_time and not auto_pilot_active:
			auto_pilot_active = true
			print("Auto-Pilot activated - navigating to islands")
		
		# Auto-Pilot control
		if auto_pilot_active and island_positions.size() > 0:
			direction = get_auto_pilot_direction()
	
	if direction != Vector2.ZERO:
		direction = direction.normalized()
	
	# Adjust speed (auto-pilot is slower)
	var current_speed = speed
	if auto_pilot_active:
		current_speed *= auto_pilot_speed_multiplier
	
	velocity = direction * current_speed
	move_and_slide()
	
	# Flip sprite based on movement direction
	update_sprite_direction()
	
	# Water interaction
	if water_body:
		affect_water()
	
	previous_position = global_position

# Update sprite direction based on movement
func update_sprite_direction() -> void:
	# Only flip when ship is moving horizontally
	if abs(velocity.x) > 0.1:
		# Sprite is facing left by default
		# flip_h = true means facing right
		if velocity.x > 0:  # Moving right
			$Sprite2D.flip_h = true
		else:  # Moving left
			$Sprite2D.flip_h = false

# Calculate direction to current auto-pilot target
func get_auto_pilot_direction() -> Vector2:
	var to_target = auto_pilot_target - global_position
	
	# When close to target, switch to next
	if to_target.length() < 50:
		# Check if we reached the Treasure Island (index 1 = right island at position 608,322)
		# Only collect gold when visiting Treasure Island, not Home Island
		if current_target_index == 1 and current_target_index != last_island_index:
			collect_gold()
			last_island_index = current_target_index
		elif current_target_index != last_island_index:
			# Reached home island - just update last visited without collecting gold
			last_island_index = current_target_index
		
		current_target_index = (current_target_index + 1) % island_positions.size()
		auto_pilot_target = island_positions[current_target_index]
		print("Auto-Pilot: Reached target, heading to next island")
		to_target = auto_pilot_target - global_position
	
	return to_target.normalized()

# Collect gold when reaching an island
func collect_gold() -> void:
	print("Gold collected at island!")
	gold_collected.emit()  # Emit signal for game manager to handle

# Main function for water interaction
# Called every frame when the ship is moving
func affect_water() -> void:
	# Safety check: No interaction possible without WaterBody
	if not water_body:
		print("Water body not found!")
		return
	
	# Only moving ships create waves (threshold: 0.1 pixels/frame)
	if velocity.length() < 0.1:
		return
	
	
	# Find the water spring index directly under the ship
	var spring_index = get_nearest_spring_index()
	
	
	if spring_index >= 0:
		# Calculate horizontal speed for enhanced lateral waves
		var horizontal_speed = abs(velocity.x)
		
		# Base splash: Proportional to total ship speed
		# (normalized to 0-1 by dividing by max speed)
		var base_splash = velocity.length() / speed * water_splash_force
		
		# Horizontal bonus: Lateral movement in water creates additional waves
		# Simulates water displacement when plowing sideways
		var horizontal_bonus = (horizontal_speed / speed) * water_splash_force * horizontal_splash_multiplier
		
		# Total strength = base + horizontal bonus
		var splash_strength = base_splash + horizontal_bonus
		
		
		# Main impulse: Apply full force directly under the ship
		water_body.splash(spring_index, splash_strength)
		
		# Wave distribution: Distribute force to neighboring springs
		# This creates a more realistic, wider wave effect
		var spread_range = 2  # 2 springs on each side = 5 springs total
		for i in range(1, spread_range + 1):
			# Falloff: Further away = weaker (linear decrease)
			var falloff = 1.0 - (float(i) / float(spread_range + 1))
			
			# Left neighboring springs
			if spring_index - i >= 0:
				water_body.splash(spring_index - i, splash_strength * falloff * 0.4)
			# Right neighboring springs
			if spring_index + i < water_body.springs.size():
				water_body.splash(spring_index + i, splash_strength * falloff * 0.4)
		
		# Bow wave: During fast horizontal movement a wave forms in front of the ship
		# Simulates water displacement at the bow
		if horizontal_speed > speed * 0.5:  # Only above 50% of max speed
			var direction_sign = sign(velocity.x)  # Movement direction: -1 (left) or 1 (right)
			var bow_index = spring_index + int(direction_sign * 2)  # 2 springs ahead
			
			if bow_index >= 0 and bow_index < water_body.springs.size():
				water_body.splash(bow_index, splash_strength * 0.5)

# Find the water spring closest to the ship's current X position
# 
# The water consists of many individual "springs" at regular intervals.
# This function calculates which spring is directly under the ship.
func get_nearest_spring_index() -> int:
	if not water_body or water_body.springs.size() == 0:
		return -1
	
	# Calculate relative X position to water origin
	var relative_x = global_position.x - water_body.global_position.x
	
	# Divide by spring distance to get the index
	# Example: With 32px spacing, position 64 = index 2
	var spring_index = int(relative_x / water_body.distance_between_springs)
	
	# Clamp to valid range [0, number of springs - 1]
	spring_index = clamp(spring_index, 0, water_body.springs.size() - 1)
	
	return spring_index

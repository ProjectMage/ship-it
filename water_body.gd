# WaterBody - 2D water simulation with spring-mass system
# see https://pixelipy.itch.io/water-2d-simulation
#
# This water surface consists of many individual "springs" that are
# connected to each other. Each spring behaves like an oscillator and
# influences its neighbors, creating realistic waves.
#
# PHYSICS MODEL:
# - Each spring has a rest position (target_height) and a current position
# - Hooke's Law: F = -k * x (restoring force proportional to displacement)
# - Damping: Velocity is reduced so waves decay
# - Spread: Height differences between neighboring springs equalize

extends Node2D

# Spring constant (k): How strongly the spring returns to rest position
# Higher = stiffer water, faster oscillations
@export var k = 0.015

# Damping (d): How quickly waves decay
# Higher = waves die faster, Lower = waves oscillate longer
@export var d = 0.04

# Spread: How strongly neighboring springs influence each other
# Higher = waves propagate faster
@export var spread = 0.125

# Array of all water spring instances
var springs = []

# Number of iterations for wave propagation per frame
# Higher = smoother propagation, but more computational cost
var passes = 8

# Horizontal distance between springs in pixels
@export var distance_between_springs = 32

# Total number of springs (determines water surface width)
@export var number_of_springs = 20

# Automatically calculate number of springs based on viewport width
@export var auto_fit_to_viewport = true

# Template for individual water spring nodes
@onready var water_spring = preload("res://water_alt.tscn")

# Water depth below the surface (for polygon rendering)
@export var depth = 50

# Y-position of the resting water surface
var target_height = global_position.y;

# Y-position of the water bottom (surface + depth)
var bottom = target_height + depth

func _ready() -> void:
	add_to_group("water")
	
	# If enabled, adjust number of springs to viewport width
	if auto_fit_to_viewport:
		var viewport_width = get_viewport_rect().size.x
		number_of_springs = int(viewport_width / distance_between_springs) + 1
		print("Auto-fitting water to viewport: ", viewport_width, "px wide with ", number_of_springs, " springs")
	
	for i in range(number_of_springs):
		var x_pos = distance_between_springs * i
		var water_spring_instance = water_spring.instantiate()

		add_child(water_spring_instance)
		springs.append(water_spring_instance)
		water_spring_instance.initialize(x_pos)
		splash(2,5)


# Physics update every frame
# 1. Calculate wave propagation (spread between neighbors)
# 2. Update each spring (spring force + damping)
# 3. Redraw water polygon
func _process(_delta: float) -> void:
	# Arrays for velocity changes from neighboring springs
	var left_deltas = []
	var right_deltas = []

	# Initialize delta arrays with zeros
	for i in range(springs.size()):
		left_deltas.append(0)
		right_deltas.append(0)

	# WAVE PROPAGATION: Multiple passes for smoother distribution
	# In each pass, springs transfer their movement to neighbors
	for j in range(passes):
		for i in range(springs.size()):
			# Left neighbor: If current spring is higher, push left spring up
			if i > 0:
				left_deltas[i] = spread * (springs[i].position.y - springs[i - 1].position.y)
				springs[i - 1].velocity += left_deltas[i]
			
			# Right neighbor: If current spring is higher, push right spring up
			if i < springs.size() - 1:
				right_deltas[i] = spread * (springs[i].position.y - springs[i + 1].position.y)
				springs[i + 1].velocity += right_deltas[i]
	
	# SPRING PHYSICS: Update each spring with Hooke's Law and damping
	for spring in springs:
		spring.water_update(k, d)

	# Draw the visible water surface
	draw_water_body()




# Create a splash at a specific spring
# index: Which spring should be affected (0 to springs.size()-1)
# speed: Velocity/force of the splash (positive = downward, negative = upward)
func splash(index: int, speed: float) -> void:
	if index >= 0 and index < springs.size():
		# Add velocity to spring - this starts the wave movement
		springs[index].velocity += speed

# Draw the visible water polygon
# Creates a 2D polygon from all spring positions plus bottom points
func draw_water_body() -> void:
	# Collect all surface points (X/Y position of each spring)
	var surface_points = []

	for i in range(springs.size()):
		surface_points.append(springs[i].position)

	var first_index = 0
	var last_index = surface_points.size() - 1

	# Copy surface points for polygon
	var water_polygon_points = surface_points

	# Add bottom points to form a closed polygon:
	# Bottom right: (last X position, bottom height)
	water_polygon_points.append(Vector2(surface_points[last_index].x, bottom))
	# Bottom left: (first X position, bottom height)
	water_polygon_points.append(Vector2(surface_points[first_index].x, bottom))

	# Convert to PackedVector2Array and set polygon
	water_polygon_points = PackedVector2Array(water_polygon_points)

	# Update the visible Polygon2D node
	$waterPoly.polygon = water_polygon_points

# Water Spring - Individual water spring in the surface simulation
#
# Represents a single point on the water surface.
# Behaves like a damped harmonic oscillator (spring-mass system).
#
# PHYSICS:
# - Hooke's Law: F = -k * x (restoring force)
# - Damping: F_damping = -d * v (friction force)
# - Euler integration: v += F, y += v

extends Node2D

# Current velocity of the spring (pixels per frame)
# Positive = movement downward, Negative = movement upward
var velocity = 0

# Current acting force (recalculated every frame)
var force = 0

# Rest position (Y-coordinate of the flat water surface)
var target_height = 0

# Physics update for this spring
# spring_constant (k): Spring constant - how strong the restoring force is
# damping (d): Damping - how quickly the oscillation decays
func water_update(spring_constant, damping):
	# Current height of the spring
	var height = position.y
	
	# Displacement from rest position (x in Hooke's Law)
	# Positive = below rest position, Negative = above rest position
	var x = height - target_height
	
	# Damping force: Slows movement proportional to velocity
	var loss = -damping * velocity
	
	# Total force = restoring force (Hooke) + damping
	# F = -k*x - d*v
	force = -spring_constant * x + loss
	
	# Update velocity: v = v + F (simplified Euler integration)
	velocity += force
	
	# Update position: y = y + v
	position.y += velocity

# Spring initialization
# x_pos: Horizontal position on the water surface
func initialize(x_pos: int) -> void:
	# Set X position (never changes)
	position.x = x_pos
	
	# Store current Y position as rest position
	target_height = position.y
	
	# Start with velocity 0 (still water)
	velocity = 0
extends Node2D

var window: Window
var gold: int = 0
var click_pos := Vector2i.ZERO
@onready var shipPath: PathFollow2D = $PathToGold/PathFollow2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	window = get_window()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	shipPath.progress_ratio += delta * 0.1
	if Input.is_action_just_pressed("click"):
		click_pos = Vector2i(get_global_mouse_position())
	if Input.is_action_pressed("click"):
		$ViewPortFrame.visible = true
		window.position = window.position + Vector2i(get_global_mouse_position()) - click_pos
	else:
		$ViewPortFrame.visible = false
		


func _on_transparent_button_toggled(toggled_on: bool) -> void:
	window.transparent = toggled_on
	window.transparent_bg = toggled_on

func _on_border_button_toggled(toggled_on: bool) -> void:
	window.borderless = toggled_on


func _on_always_on_top_button_toggled(toggled_on: bool) -> void:
	var borderless = window.borderless
	window.borderless = true
	window.always_on_top = toggled_on
	window.borderless = borderless

func _on_no_focus_button_toggled(toggled_on: bool) -> void:
	var borderless = window.borderless
	window.borderless = true
	window.unfocusable = toggled_on
	window.borderless = borderless


func _on_island_area_entered(_area: Area2D) -> void:
	$Island/Label.text = str(gold) + " Gold"
	gold += 1
	

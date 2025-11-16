extends Node2D

var window: Window
var gold: int = 0
var click_pos := Vector2i.ZERO
@onready var trayMenu : PopupMenu = $StatusIndicator/PopupMenu
@onready var gold_indicator: Label = $TreasureIsland/GoldIndicator

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	window = get_window()
	
	# Connect to player ship's gold collection signal
	var player_ship = $PlayerShip
	if player_ship:
		player_ship.gold_collected.connect(_on_gold_collected)

# Handle gold collection from player ship
func _on_gold_collected() -> void:
	gold += 1
	print("Gold collected! Total gold: ", gold)
	update_gold_display()

# Update the gold indicator label
func update_gold_display() -> void:
	if gold_indicator:
		gold_indicator.text = str(gold) + " Gold"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
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
	window.visible = !toggled_on


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
	gold += 1
	update_gold_display()
	


func _on_popup_menu_id_pressed(id: int) -> void:
	#id - Function
	# 0 - Borderless
	# 1 - Transparent
	# 2 - Focus
	# 3 - Always on Top
	# 4 - Line Seperator (no function)
	# 5 - Quit
	if id < 4:
		trayMenu.set_item_checked(id, !trayMenu.is_item_checked(id))
	match id:
		0: _on_border_button_toggled(trayMenu.is_item_checked(id))
		1: _on_transparent_button_toggled(trayMenu.is_item_checked(id))
		2: _on_no_focus_button_toggled(trayMenu.is_item_checked(id))
		3: _on_always_on_top_button_toggled(trayMenu.is_item_checked(id))
		5: get_tree().quit()

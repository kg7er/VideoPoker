extends CanvasLayer
signal deal_signal
signal bet_one_signal
signal bet_max_signal
signal info_signal

# Called when the node enters the scene tree for the first time.
func _ready():
	# 1. Load the Impact font file directly from your assets folder
	var local_font = load("res://assets/Impact.ttf") 
	
	# 2. Grab the grid container node
	var grid = $Control/PayTableGrid
	
	# 3. Loop through every single label from TableLabel0 to TableLabel53 automatically
	for cell in grid.get_children():
		if cell is Label:
			cell.add_theme_font_override("font", local_font)
			cell.add_theme_font_size_override("font_size", 30)
			#cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			cell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			cell.custom_minimum_size.y = 0
			#cell.autowrap_mode = TextServer.AUTOWRAP_OFF
			#cell.clip_text = false
func _on_deal_draw_button_pressed():
	deal_signal.emit() # Replace with function body.


func _on_bet_one_button_pressed():
	bet_one_signal.emit()


func _on_bet_max_button_pressed():
	bet_max_signal.emit()


func _on_info_button_pressed():
	info_signal.emit()

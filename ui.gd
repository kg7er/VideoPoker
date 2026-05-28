extends CanvasLayer
signal deal_signal
signal bet_one_signal
signal bet_max_signal
signal info_signal

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_deal_draw_button_pressed():
	deal_signal.emit() # Replace with function body.


func _on_bet_one_button_pressed():
	bet_one_signal.emit()


func _on_bet_max_button_pressed():
	bet_max_signal.emit()


func _on_info_button_pressed():
	info_signal.emit()

extends Sprite2D

signal hold_signal(n)
# ============== Card0 =======
func _ready():
	position = Vector2i(160,600)
	#scale = Vector2(0.45, 0.38)
	texture = load("res://assets/cards/x_cardback.png")

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if get_rect().has_point(to_local(event.position)):
			hold_signal.emit(0)

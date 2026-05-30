extends Node

class_name Card        # Calling it "class_name" makes it a GLOBAL class
var value: int
var suit: String
	
func _init(v:int, s:String):
	value = v
	suit = s
	
func get_card_name():
	return str(value)+suit
	
func get_card_image():
	return "x_" + get_card_name()+".png"
	
func get_card_id() -> int:
	var suit_index = 0
	match suit.to_upper():
		"C": suit_index = 0
		"D": suit_index = 1
		"H": suit_index = 2
		"S": suit_index = 3

	var value_index = value - 2
			
	return (value_index * 4) + suit_index

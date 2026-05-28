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
	

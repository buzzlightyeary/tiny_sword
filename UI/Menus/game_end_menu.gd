extends Control

signal main_menu_button_pressed(origin:String)
signal replay_pressed(origin:String)



func _on_main_menu_pressed() -> void:
	main_menu_button_pressed.emit("game_over")
	pass # Replace with function body.


func _on_replay_pressed() -> void:
	replay_pressed.emit("game_over")
	pass # Replace with function body.



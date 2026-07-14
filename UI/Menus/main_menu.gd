extends Control

signal exit_pressed(origin:String)
signal about_pressed(origin:String)
signal new_game_pressed(origin:String)
signal setting_pressed(origin:String)	



func _on_exit_pressed() -> void:
	exit_pressed.emit("main_menu")
	pass # Replace with function body.


func _on_about_pressed() -> void:
	about_pressed.emit("main_menu")
	pass # Replace with function body.


func _on_new_game_pressed() -> void:
	new_game_pressed.emit("main_menu")
	pass # Replace with function body.


func _on_setting_pressed() -> void:
	setting_pressed.emit("main_menu")
	pass # Replace with function body.



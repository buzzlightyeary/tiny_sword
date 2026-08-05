# SelectionManager.gd — 项目设置中注册为 Autoload
extends Node

var selected_unit: Node2D = null

func select_unit(unit)->void:
	print("select")
	if(unit==null):
		deselect()
	else:
		select(unit)

func select(unit: Node2D) -> void:
	deselect()
	selected_unit = unit
	print("select",unit)
	if unit:
		unit.set_selected(true)

func deselect() -> void:
	if selected_unit:
		selected_unit.set_selected(false)
		selected_unit = null

func command_move(target_pos: Vector2) -> void:
	if selected_unit:
		selected_unit.move_to(target_pos)
		print("command_move",target_pos)

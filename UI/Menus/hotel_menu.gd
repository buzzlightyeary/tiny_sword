extends Control

const KNIGHT_SCENE: PackedScene = preload("res://Entities/Player/player.tscn")
# Spawn a bit below the house so the knight doesn't overlap the building sprite.
const SPAWN_OFFSET: Vector2 = Vector2(0, 100)

# Set by the Home that opened this menu (home.gd).
var home: Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_texture_button_button_up() -> void:
	queue_free()
	pass # Replace with function body.


func _on_knight_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed == false:
			spawn_knight()


func spawn_knight() -> void:
	if not is_instance_valid(home):
		return
	var knight: Node2D = KNIGHT_SCENE.instantiate()
	# Knights join the same container as the existing player units.
	var container: Node = get_tree().get_first_node_in_group("playerContainer")
	if container == null:
		container = home.get_parent()
	container.add_child(knight)
	knight.global_position = home.global_position + SPAWN_OFFSET

extends Control

@export var KNIGHT_SCENE: PackedScene = preload("res://Entities/Player/player.tscn")
@export var ANCHOR_SCENE: PackedScene = preload("res://Entities/Player/anchor1.tscn")
# Spawn a bit below the house so the knight doesn't overlap the building sprite.
const SPAWN_OFFSET: Vector2 = Vector2(0, 80)
# Horizontal spacing between consecutively spawned units so they don't stack.
const SPAWN_SPACING: float = 64.0

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
	knight.global_position = _next_spawn_position(container)


# Spread consecutive spawns horizontally: 1st at center, then alternating
# right/left of the base point based on how many units the container holds.
func _next_spawn_position(container: Node) -> Vector2:
	var index: int = container.get_child_count()
	var side: float = 1.0 if index % 2 == 0 else -1.0
	var step: int = (index + 1) / 2
	return home.global_position + SPAWN_OFFSET + Vector2(side * step * SPAWN_SPACING, 0)


func _on_anchor_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed == false:
			spawn_anchor()

func spawn_anchor() -> void:
	if not is_instance_valid(home):
		return
	var anchor: Node2D = ANCHOR_SCENE.instantiate()
	# Anchors join the same container as the existing player units.
	var container: Node = get_tree().get_first_node_in_group("playerContainer")
	if container == null:
		container = home.get_parent()
	container.add_child(anchor)
	anchor.global_position = _next_spawn_position(container)

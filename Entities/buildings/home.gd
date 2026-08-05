extends Node2D
@export var hotel_menu: PackedScene

@onready var sprite: Sprite2D = $Sprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed==false:
			var hotel_menu_instance = hotel_menu.instantiate()
			hotel_menu_instance.position = Vector2(0, 0)
			hotel_menu_instance.home = self
			get_tree().get_first_node_in_group("UI").add_child(hotel_menu_instance)
		
	pass # Replace with function body.



func _on_area_2d_mouse_entered() -> void:
	sprite.material.set_shader_parameter("enable_outline", true)
	pass # Replace with function body.


func _on_area_2d_mouse_exited() -> void:
	sprite.material.set_shader_parameter("enable_outline", false)
	pass # Replace with function body.

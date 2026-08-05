extends PanelContainer

const HOVER_SCALE: Vector2 = Vector2(1.2, 1.2)
const NORMAL_SCALE: Vector2 = Vector2.ONE
const TWEEN_DURATION: float = 0.1


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	resized.connect(_update_pivot)
	_update_pivot()


# Scale from the center of the control instead of the top-left corner.
func _update_pivot() -> void:
	pivot_offset = size / 2.0


func _on_mouse_entered() -> void:
	_tween_scale(HOVER_SCALE)


func _on_mouse_exited() -> void:
	_tween_scale(NORMAL_SCALE)


func _tween_scale(target_scale: Vector2) -> void:
	create_tween().tween_property(self, "scale", target_scale, TWEEN_DURATION)

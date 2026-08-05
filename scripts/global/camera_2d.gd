extends Camera2D


signal unit_clicked(unit)
signal ground_clicked(position)

@export var bounds := Rect2(-1700, -1000, 3400, 2000)  # 可拖拽的世界范围

var dragging := false
var drag_start_mouse := Vector2.ZERO
var drag_start_pos := Vector2.ZERO

func _unhandled_input(event):
    if event is InputEventMouseButton :
        var mouse_position = get_global_mouse_position()
        if event.button_index == MOUSE_BUTTON_MIDDLE:
            if event.pressed:
                dragging = true
                drag_start_mouse = event.position
                drag_start_pos = position
            else:
                dragging = false
        elif event.button_index==MOUSE_BUTTON_LEFT:
            if (event.pressed==false):
                var unit = _pick_unit(mouse_position)
                print("pick",unit)
                unit_clicked.emit(unit)
        elif event.button_index==MOUSE_BUTTON_RIGHT:
            if event.pressed:
                ground_clicked.emit(mouse_position)
    pass        

func _pick_unit(point: Vector2):
    var params := PhysicsPointQueryParameters2D.new()
    params.position = point
    params.collision_mask = 8            # 只查单位所在的层
    params.collide_with_areas = true     # 如果单位用 Area2D 也能查到
    params.collide_with_bodies = true

    var results = get_world_2d().direct_space_state.intersect_point(params, 1)
    print(results)
    for hit in results:
        
        var node = hit.collider
        if node.is_in_group("player"):
            return node
    return null
			

func _input(event):
    if dragging and event is InputEventMouseMotion:
        var delta = (drag_start_mouse - event.position) / zoom.x
        var target = drag_start_pos + delta

        # 限制在矩形范围内
        var half_view = get_viewport_rect().size / zoom / 2
        target.x = clampf(target.x, bounds.position.x + half_view.x, bounds.end.x - half_view.x)
        target.y = clampf(target.y, bounds.position.y + half_view.y, bounds.end.y - half_view.y)

        position = target

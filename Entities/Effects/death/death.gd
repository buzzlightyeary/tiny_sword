extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
    animation_player.animation_finished.connect(
        _on_animation_finished
    )

    animation_player.play(&"die")



func _on_animation_finished(_animation_name: StringName) -> void:
    queue_free()
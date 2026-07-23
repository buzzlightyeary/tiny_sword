extends Control

@onready var levelLable :Label = $Level/Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_level_label()
	pass # Replace with function body.


func set_level_label()->void:
	levelLable.set_text(str(player_data.level))

func set_hp_bar_value(val:int)->void:
	var hit_bar :TextureProgressBar = $Hitpoints/TextureProgressBar
	hit_bar.set_value(val)

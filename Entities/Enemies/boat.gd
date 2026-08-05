extends Node2D

signal arrived

@export var speed: int = 100
@export var landing_place: Vector2 = Vector2.ZERO
@export var arrive_distance: float = 10.0
@export var goblin_scene: PackedScene = preload("res://Entities/Enemies/goblin.tscn")

var goblin: CharacterBody2D
var sailing: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	
	animation_player.play("idle")
	goblin = goblin_scene.instantiate()
	# Keep the goblin's own chase/attack logic off while it rides the boat.
	goblin.set_physics_process(false)
	add_child(goblin)


func _physics_process(delta: float) -> void:
	if not sailing:
		return
	var to_target: Vector2 = landing_place - global_position
	if to_target.length() <= arrive_distance:
		dock()
		return
	var direction: Vector2 = to_target.normalized()
	global_position += direction * speed * delta
	if direction.x != 0.0:
		sprite.flip_h = direction.x < 0.0


func dock() -> void:
	sailing = false
	var drop_position: Vector2 = goblin.global_position
	# The boat's parent is the level root; enemyContainer keeps y-sorting
	# consistent with the other units.
	goblin.reparent(get_parent().get_node("enemyContainer"))
	goblin.global_position = drop_position
	goblin.set_physics_process(true)
	arrived.emit()

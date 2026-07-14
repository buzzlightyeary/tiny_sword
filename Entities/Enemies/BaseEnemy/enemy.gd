extends CharacterBody2D

signal die(experience: int)

enum EnemyState {
	IDLE,
	CHASE,
	ATTACK
}
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@onready var player: CharacterBody2D = %player
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D


@export_category("Stats")
@export var speed: int = 100
@export var max_health: int = 100
@export var hit_value: int = 10
@export var attack_duration: float = 0.4
@export var chase_distance: float = 500
@export var experience_value: int = 200

var enemyState: EnemyState = EnemyState.IDLE


func _ready() -> void:
	print("Enemy ready")
	animation_tree.active = true


func _physics_process(delta: float) -> void:
	if enemyState == EnemyState.ATTACK:
		return
	if get_player_distance() < 100:
		enemyState = EnemyState.ATTACK
		attack()
	elif get_player_distance() < chase_distance:
		enemyState = EnemyState.CHASE
		chase()
	else:
		enemyState = EnemyState.IDLE
		idle()
	return 

func enemy_die() -> void:
	print("Enemy died")
	die.emit(experience_value, global_position)
	queue_free()


func take_damage(damage: int) -> void:
	max_health -= damage
	if max_health <= 0:
		enemy_die()


func updateFacing(dir_x:float ) -> void:
	if dir_x != 0.0:
		sprite.flip_h = dir_x < 0.0


func get_player_distance() -> float:
	return global_position.distance_to(player.global_position)

func attack() -> void:
	print("Enemy attack")
	var vector_to_player: Vector2 = (player.global_position - global_position).normalized()
	updateFacing(vector_to_player.x)
	animation_tree.set("parameters/attack/BlendSpace1D/blend_position",vector_to_player.x)
	animation_playback.travel("attack")
	await get_tree().create_timer(attack_duration).timeout
	animation_playback.start("idle")
	enemyState = EnemyState.IDLE


func chase() -> void:
	navigation_agent.target_position = player.global_position
	var safe_velocity: Vector2 = navigation_agent.get_next_path_position()
	
	velocity = global_position.direction_to(safe_velocity)*speed
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(velocity)
	else:	
		_on_navigation_agent_2d_velocity_computed(velocity)
	
	updateFacing(velocity.x)
	move_and_slide()

func idle() -> void:
	animation_playback.travel("idle")


#func _on_hit_area_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
#	print('area ',area,player.get_node("guardArea").get("monitorable"))
#	pass # Replace with function body.


func _on_hit_area_body_entered(body: Node2D) -> void:
	body.take_damage(hit_value,global_position)  # Replace with the actual damage value for attack1
	pass # Replace with function body.


func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	navigation_agent.set_velocity(safe_velocity)
	pass # Replace with function body.

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
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D


@export_category("Stats")
@export var speed: int = 100
@export var max_health: int = 100
@export var hit_value: int = 10
@export var attack_duration: float = 0.4
@export var chase_distance: float = 500
@export var experience_value: int = 200
@export var attack_distance : int = 70
@export var knockback_decay: float = 1200.0

var enemyState: EnemyState = EnemyState.IDLE
var knockback_velocity: Vector2 = Vector2.ZERO
var player: CharacterBody2D

func _ready() -> void:
	print("Enemy ready")
	add_to_group("enemy")
	animation_tree.active = true
	player = get_tree().get_nodes_in_group("player")[0]


func _physics_process(delta: float) -> void:
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	if enemyState == EnemyState.ATTACK:
		return
	if get_player_distance() < attack_distance:
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
	die.emit(experience_value, global_position)
	queue_free()


func take_damage(damage: int) -> void:
	max_health -= damage
	if max_health <= 0:
		enemy_die()


func apply_knockback(impulse: Vector2) -> void:
	knockback_velocity = impulse


func updateFacing(dir_x:float ) -> void:
	if dir_x != 0.0:
		sprite.flip_h = dir_x < 0.0


func get_player_distance() -> float:
	return global_position.distance_to(player.global_position)

func attack() -> void:
	# Standing still while attacking: report zero velocity to the avoidance sim
	navigation_agent.set_velocity(Vector2.ZERO)
	var vector_to_player: Vector2 = (player.global_position - global_position).normalized()
	updateFacing(vector_to_player.x)
	animation_tree.set("parameters/attack/BlendSpace1D/blend_position",vector_to_player.x)
	animation_playback.travel("attack")
	await get_tree().create_timer(attack_duration).timeout
	animation_playback.start("idle")
	enemyState = EnemyState.IDLE


func chase() -> void:
	navigation_agent.target_position = player.global_position
	var next_position: Vector2 = navigation_agent.get_next_path_position()

	velocity = global_position.direction_to(next_position)*speed + knockback_velocity
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(velocity)
	else:
		updateFacing(velocity.x)
		animation_playback.travel("run")
		move_and_slide()

func idle() -> void:
	# Standing still: report zero velocity so the avoidance sim doesn't keep a stale velocity
	navigation_agent.set_velocity(Vector2.ZERO)
	animation_playback.travel("idle")
	if knockback_velocity != Vector2.ZERO:
		velocity = knockback_velocity
		move_and_slide()


#func _on_hit_area_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
#	print('area ',area,player.get_node("guardArea").get("monitorable"))
#	pass # Replace with function body.


func _on_hit_area_body_entered(body: Node2D) -> void:
	body.take_damage(hit_value,global_position)  # Replace with the actual damage value for attack1
	pass # Replace with function body.


func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	if(enemyState!=EnemyState.CHASE):
		return 
	velocity=safe_velocity
	updateFacing(velocity.x)
	animation_playback.travel("run")
	move_and_slide()
	pass # Replace with function body.


#func _on_hit_area_area_entered(area: Area2D) -> void:
#	print(area)
#	pass # Replace with function body.

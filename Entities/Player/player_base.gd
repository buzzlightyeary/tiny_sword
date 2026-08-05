class_name PlayerBase
extends CharacterBody2D

signal hp_changed(val:int)

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D


@export_category("Stats")
@export var speed: int = 120
@export var maxHealth: int = 100
@export_category("Attack")
@export var attack_damage: int = 60
@export var attack_distance: int = 70
@export var warning_distance: int = 300
#@export var attack_speed: float = 0.4

var currentHealth:int

enum PlayerState {
	IDLE,
	RUN,
	GUARD,
	ATTACK
}

var attack_speed: float = 0.4
var playerState: PlayerState = PlayerState.IDLE
var moveDirection: Vector2 = Vector2.ZERO
var isAttack: bool = false
var is_arrived : bool=true
var target: Node2D
var is_select:bool=false
var detect_range_list: Array[Node2D]=[]
#var attack_range_list: Array[Node2D]=[]
#var isGuard: bool = false


func _ready() -> void:
	print("player")
	add_to_group("player")
	animation_tree.active = true
	currentHealth = maxHealth
	set_selected(false)
	calculate_stats()
	# Initialize the nav target to our own position so "no move command" counts as arrived
	#nav_agent.target_position = global_position

func find_target() -> Node2D:
	# 先清理野指针（防御层：任何漏网之鱼在这里被兜住）
	detect_range_list = detect_range_list.filter(func(e): return is_instance_valid(e))

	var nearest: Node2D = null
	var nearest_dist := INF
	for e in detect_range_list:
		var d := global_position.distance_squared_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e
	return nearest

func acquire_target() -> void:
	target = find_target()
	

func calculate_stats() -> void:
	attack_speed = Equations.calculate_attack_speed(attack_speed)
	animation_tree.set("parameters/attack/TimeScale/scale", Equations.BASE_ATTACK_SPEED / attack_speed)
	print("Player attack speed: ", attack_speed)

func move_to(target:Vector2)->void:
	is_arrived = false
	nav_agent.target_position=target

func _physics_process(delta: float) -> void:
	if(playerState == PlayerState.ATTACK):
		return
	updateAction()
	return

# rts logic
func updateAction()->void:
	velocity= Vector2.ZERO
	# Attack takes priority: stop navigating as soon as an enemy is in attack range
	var nearest_position = null
	if target!=null:
		nearest_position = target.global_position

	if nearest_position != null and global_position.distance_to(nearest_position) < attack_distance:
		is_arrived = true
		updateFacing((nearest_position - global_position).x)
		# Standing still: report zero velocity so the avoidance sim doesn't keep a stale velocity
		nav_agent.set_velocity(Vector2.ZERO)
		attack()
		return
	if(nav_agent.is_navigation_finished()==false):
		playerState = PlayerState.RUN
		var next_position :Vector2 = nav_agent.get_next_path_position()
		var delta_vec = global_position.direction_to(next_position)*speed
		if nav_agent.avoidance_enabled:
			nav_agent.set_velocity(delta_vec)
	else:
		if(is_arrived==false):
			is_arrived=true
		if(nearest_position!=null):
			is_arrived = false
			nav_agent.target_position=nearest_position
		else:
			acquire_target()
			nav_agent.set_velocity(Vector2.ZERO)
			idle()


func run_rts(dir: Vector2) -> void:
	updateFacing(dir.x)
	velocity = dir
	playback.travel("run")
	move_and_slide()
	



func updateFacing(dir_x:float ) -> void:
	if dir_x != 0.0:
		sprite.flip_h = dir_x < 0.0

func getFacing() -> float:
	return -1.0 if sprite.flip_h else 1.0

func attack() -> void:
	playerState = PlayerState.ATTACK
	var facedir:float = getFacing()
	animation_tree.set("parameters/attack/BlendSpace1D/blend_position",facedir)
	playback.travel("attack")
	await get_tree().create_timer(attack_speed).timeout
	playback.travel("idle")
	playerState = PlayerState.IDLE

func idle() -> void:
	playerState = PlayerState.IDLE
	playback.travel("idle")




func take_damage(damage: int, attack_position: Vector2) -> void:
	if playerState == PlayerState.GUARD:
		var attack_direction: Vector2 = (attack_position - global_position).normalized()
		var facing_direction: Vector2 = Vector2(getFacing(), 0)
		if attack_direction.dot(facing_direction) > 0:
			print("Attack blocked!")
			return
	currentHealth -= damage
	var percentage : int = currentHealth*100/maxHealth 
	hp_changed.emit(percentage)


	if currentHealth <= 0:
		print("Player has died.")
		death()

func death() -> void:
	print('death')
	get_parent().get_parent().game_over.emit(false)
	pass


func set_selected(flag) -> void:
	is_select=flag
	if(is_select):
		sprite.material.set_shader_parameter("enable_outline", true)
	else:
		sprite.material.set_shader_parameter("enable_outline", false)

# 鼠标进入 Area2D 时触发
func _on_cursor_area_mouse_entered() -> void:
	if sprite.material:
		# 打开 Shader 中的描边开关
		sprite.material.set_shader_parameter("enable_outline", true)


func _on_cursor_area_mouse_exited() -> void:
	if sprite.material:
		# 关闭 Shader 中的描边开关
		if(is_select==false):
			sprite.material.set_shader_parameter("enable_outline", false)
	pass # Replace with function body.

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	if playerState!=PlayerState.RUN:
		return
	velocity = safe_velocity                # 用避让后的安全速度移动
	run_rts(velocity)


func _on_detection_area_body_entered(body: Node2D) -> void:
	print("_on_detection_area_body_entered",body)
	detect_range_list.append(body)
	acquire_target()
	pass # Replace with function body.

func _on_detection_area_body_exited(body: Node2D) -> void:
	print("_on_detection_area_body_exited",body)
	detect_range_list.erase(body)
	pass # Replace with function body.
func _on_hit_area_body_entered(body: Node2D) -> void:
	print("Hit area body entered: ", body)
	body.take_damage(attack_damage)  # Replace with the actual damage value for attack1
	pass # Replace with function body.


#func _on_attack_area_body_exited(body: Node2D) -> void:
#	attack_range_list.append(body)
#	pass # Replace with function body.

#func _on_attack_area_body_entered(body: Node2D) -> void:
#	detect_range_list.erase(body)
#	pass # Replace with function body.

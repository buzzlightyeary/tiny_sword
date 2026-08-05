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
@export var attack1_damage: int = 60
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
var SCAN_INTERVAL = 0.15
var playerState: PlayerState = PlayerState.IDLE
var moveDirection: Vector2 = Vector2.ZERO
var isAttack: bool = false
var scan_timer
var is_arrived : bool=true
var nearest_position
var is_select:bool=false
#var isGuard: bool = false


func _ready() -> void:
	print("player")
	add_to_group("player")
	animation_tree.active = true
	currentHealth = maxHealth
	scan_timer = randf()*SCAN_INTERVAL
	set_selected(false)
	calculate_stats()
	# Initialize the nav target to our own position so "no move command" counts as arrived
	#nav_agent.target_position = global_position


func calculate_stats() -> void:
	attack_speed = Equations.calculate_attack_speed()
	animation_tree.set("parameters/attack/TimeScale/scale", Equations.BASE_ATTACK_SPEED / attack_speed)
	print("Player attack speed: ", attack_speed)

func move_to(target:Vector2)->void:
	is_arrived = false
	nav_agent.target_position=target

func _physics_process(delta: float) -> void:
	scan_timer-=delta
	if(playerState == PlayerState.ATTACK):
		return
	if scan_timer<=0:
		nearest_position = _find_nearest_enemy()
		scan_timer=SCAN_INTERVAL
	updateAction()
	#updateState()
	return

# rts logic
func updateAction()->void:
	velocity= Vector2.ZERO
	# Attack takes priority: stop navigating as soon as an enemy is in attack range
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
			#print("here")
			nav_agent.set_velocity(Vector2.ZERO)
			idle()


func run_rts(dir: Vector2) -> void:
	updateFacing(dir.x)
	velocity = dir
	playback.travel("run")
	move_and_slide()
	

## 找 attack_range 内最近的敌人（距离平方比较，省去开方）
func _find_nearest_enemy():
	var enemy_group := "enemies"
	var best: Vector2
	var best_d2 :float= warning_distance * warning_distance
	#print("get_tree().get_nodes_in_group(enemy_group)",get_tree().get_nodes_in_group(enemy_group))
	for e in get_tree().get_nodes_in_group(enemy_group):
		var d2 := global_position.distance_squared_to(e.global_position)
		if d2 < best_d2:
			best_d2 = d2
			best = e.global_position
	if(best_d2<warning_distance*warning_distance):
		return best
	return null

# rpg logic
func updateState() -> void:
	velocity= Vector2.ZERO
	moveDirection = Input.get_vector("left", "right", "up", "down")
	if Input.is_action_just_pressed("click_left"):
		if(playerState != PlayerState.ATTACK):
			attack()
	elif Input.is_action_pressed("click_right"):
		guard()
	elif moveDirection != Vector2.ZERO:
		run(moveDirection)
	else:
		idle()

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


func guard() -> void:
	playerState = PlayerState.GUARD
	var facedir:float = getFacing()
	animation_tree.set("parameters/guard/BlendSpace1D/blend_position",facedir)
	playback.travel("guard")


func run(dir: Vector2) -> void:
	playerState = PlayerState.RUN
	updateFacing(dir.x)
	velocity = dir * speed
	playback.travel("run")
	move_and_slide()

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


func _on_hit_area_body_entered(body: Node2D) -> void:
	print("Hit area body entered: ", body)
	body.take_damage(attack1_damage)  # Replace with the actual damage value for attack1
	pass # Replace with function body.


func _on_detection_area_body_entered(body: Node2D) -> void:
	pass # Replace with function body.

func _on_detection_area_body_exited(body: Node2D) -> void:
	pass # Replace with function body.



func _on_attack_area_body_exited(body: Node2D) -> void:
	pass # Replace with function body.

func _on_attack_area_body_entered(body: Node2D) -> void:
	pass # Replace with function body.

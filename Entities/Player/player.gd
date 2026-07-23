extends CharacterBody2D

signal hp_changed(val:int)

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")

@export_category("Stats")
@export var speed: int = 400
@export var maxHealth: int = 100
@export_category("Attack")
@export var attack1_damage: int = 60
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
#var isGuard: bool = false


func _ready() -> void:
	print("player parent",get_parent())
	animation_tree.active = true
	currentHealth = maxHealth
	calculate_stats()


func calculate_stats() -> void:
	attack_speed = Equations.calculate_attack_speed()
	animation_tree.set("parameters/attack/TimeScale/scale", Equations.BASE_ATTACK_SPEED / attack_speed)
	print("Player attack speed: ", attack_speed)

func _physics_process(delta: float) -> void:
	if(playerState == PlayerState.ATTACK):
		return
	updateState()
	move_and_slide()

	return


func updateState() -> void:
	velocity= Vector2.ZERO
	moveDirection = Input.get_vector("left", "right", "up", "down")
	if Input.is_action_just_pressed("click_left"):
		if(playerState != PlayerState.ATTACK):
			playerState = PlayerState.ATTACK
			attack()
	elif Input.is_action_pressed("click_right"):
		playerState = PlayerState.GUARD
		#isGuard = true
		guard()
	elif moveDirection != Vector2.ZERO:
		playerState = PlayerState.RUN
		run(moveDirection)
	else:
		playerState = PlayerState.IDLE
		idle()

func updateFacing(dir_x:float ) -> void:
	if dir_x != 0.0:
		sprite.flip_h = dir_x < 0.0

func getFacing() -> float:
	return -1.0 if sprite.flip_h else 1.0

func attack() -> void:
	var facedir:float = getFacing()
	animation_tree.set("parameters/attack/BlendSpace1D/blend_position",facedir)
	playback.travel("attack")
	await get_tree().create_timer(attack_speed).timeout
	playback.travel("idle")
	playerState = PlayerState.IDLE


func guard() -> void:
	var facedir:float = getFacing()
	animation_tree.set("parameters/guard/BlendSpace1D/blend_position",facedir)
	playback.travel("guard")


func run(dir: Vector2) -> void:
	updateFacing(dir.x)
	velocity = dir * speed
	playback.travel("run")

func idle() -> void:
	playback.travel("idle")


func _on_hit_area_body_entered(body: Node2D) -> void:
	print("Hit area body entered: ", body)
	body.take_damage(attack1_damage)  # Replace with the actual damage value for attack1
	pass # Replace with function body.

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

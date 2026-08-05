class_name ArcProjectile
extends Area2D

signal hit(position: Vector2)          # 命中敌人,上报特效位置
signal finished(arrow: ArcProjectile)  # 生命周期结束(命中/落地/保险丝),请求回收

@onready var hitArea:CollisionShape2D=$CollisionShape2D
@onready var sprite:Sprite2D=$Sprite2D

@export var gravityVal: float = 1200.0
@export var arc_visual_height: float = 30.0   # 影子偏移用的峰值高度
@export var knockback_force: float = 300.0    # 命中敌人时的击退冲量 (px/s)


var velocity: Vector2
var damage: int
var flight_timer: float = 0.0
var _life_timer: float = 0.0        # 保险丝
var landed := false

## 发射（管理器 acquire 后调用）
func launch(from: Vector2, to: Vector2, flight_time: float) -> void:
	to.y = to.y -10
	global_position = from
	landed = false
	flight_timer = flight_time
	_life_timer = flight_time + 2.0                    # 保险丝 = 预期飞行 + 余量
	#velocity = (to - from - 0.5 * Vector2(0, gravityVal) * flight_time * flight_time) / flight_time
	velocity = (to - from ) / flight_time
	rotation = velocity.angle()
	#hitArea.set_deferred("disabled", true)           # 途中不判定

func _physics_process(delta: float) -> void:
	if landed: return
	_life_timer -= delta
	if _life_timer <= 0.0:
		finished.emit(self)                            # 保险丝熔断
		return

	#velocity.y += gravityVal * delta
	#position += velocity * delta
	position += velocity * delta
	#sprite.rotation = velocity.angle()              # 箭头跟切线

	flight_timer -= delta
	if flight_timer <= 0.0:
		_land()

func _land() -> void:
	finished.emit(self)

## 回收时清状态（池化契约）
func reset() -> void:
	velocity = Vector2.ZERO
	damage = 0
	flight_timer = 0.0
	landed = false
	rotation = 0.0
	sprite.rotation = 0.0
	sprite.position = Vector2.ZERO


func _on_body_entered(body: Node2D) -> void:
	print("Hit area body entered: ", body)
	body.take_damage(damage)
	if body.has_method("apply_knockback"):
		body.apply_knockback(velocity.normalized() * knockback_force)
	hit.emit(body.global_position)
	finished.emit(self)

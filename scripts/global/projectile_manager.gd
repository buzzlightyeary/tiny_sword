# projectile_manager.gd（挂在主场景，或做成 Autoload）
extends Node2D
signal arrow_hited(position: Vector2)
const POOL_PREWARM := 50        # 预热数量，避免首次齐射卡顿

var arrow_scene: PackedScene = preload("res://Entities/projectile/arrow.tscn")
var _pool: Array[ArcProjectile] = []
var _active: Array[ArcProjectile] = []

func _ready() -> void:
    for i in POOL_PREWARM:
        var a: ArcProjectile = arrow_scene.instantiate()
        _connect_arrow(a)
        a.visible = false
        a.set_physics_process(false)
        add_child(a)
        _pool.append(a)

## 创建时连接一次:命中事件转发,结束事件回收(池化复用不失效)
func _connect_arrow(arrow: ArcProjectile) -> void:
    arrow.hit.connect(func(pos): arrow_hited.emit(pos))
    arrow.finished.connect(release)      # release(arrow) 签名正好匹配

## 攻击组件唯一要调用的接口
func fire_arrow(from: Vector2, to: Vector2, flight_time: float, damage: int) -> void:
    var arrow := _acquire()
    arrow.launch(from, to, flight_time)
    arrow.damage = damage
    _active.append(arrow)

func _acquire() -> ArcProjectile:
    var arrow: ArcProjectile
    if _pool.is_empty():
        arrow = arrow_scene.instantiate()
        _connect_arrow(arrow)
        add_child(arrow)
    else:
        arrow = _pool.pop_back()
    arrow.visible = true
    arrow.set_physics_process(true)
    return arrow

## 箭落地后自己上报，管理器回收
func release(arrow: ArcProjectile) -> void:
    _active.erase(arrow)
    arrow.reset()                       # 清空速度、目标、计时器
    arrow.visible = false
    arrow.set_physics_process(false)
    _pool.append(arrow)
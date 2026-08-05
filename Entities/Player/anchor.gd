extends PlayerBase

@onready var marker2d: Marker2D= $Marker2D

@export var flight_time: =1

func _ready() -> void:
	attack_speed = 0.8
	super()
	
	print("anchor",nav_agent.avoidance_enabled)

func attack() -> void:
	playerState = PlayerState.ATTACK
	#var facedir:float = getFacing()
	#animation_tree.set("parameters/attack/BlendSpace1D/blend_position",facedir)
	if(target!=null):
		var target_position = target.global_position
		var dirVec:Vector2 = global_position-target_position 
		dirVec.y = dirVec.y
		dirVec = dirVec.normalized()
		animation_tree.set("parameters/attack/BlendSpace2D/blend_position",dirVec)
		playback.travel("attack")
		await get_tree().create_timer(attack_speed).timeout	 
	playback.travel("idle")
	playerState = PlayerState.IDLE

func spawn_arrow() -> void:
	print("spawn")
	if(target==null):
		return 
	var target_position = target.global_position
	print("marker2d.global_position",marker2d.global_position)
	print("gloal_position",global_position)
	projectile_manager.fire_arrow(marker2d.global_position,target_position,attack_speed,attack_damage)
	#var arrow := ProjectilePool.acquire(projectile_scene)
	#arrow.global_position = marker.global_position
	#arrow.target = unit.targeting.target
	#get_tree().current_scene.add_child(arrow)

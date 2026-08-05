extends Node

signal game_over(victory:bool)

# The level to load. scene_handler can swap this before add_child() to load a
# different level; the level root node name no longer matters.
@export var level_scene: PackedScene

@onready var death_effect: Node2D = $effects
@onready var hud:Control=$UI/HUD

var level: Node2D
var effect_container: Node2D

var total_enemies_cnt: int = 0
var kill_enemies_cnt: int = 0



var player
var enemys


signal levelUp

func _ready() -> void:
	level = level_scene.instantiate()
	add_child(level)
	# Keep the same child order as before: effects, level, UI.
	move_child(level, 1)
	effect_container = get_tree().get_first_node_in_group("effectContainer")
	enemys = get_tree().get_nodes_in_group("enemy")
	player = get_tree().get_nodes_in_group("player")[0]
	total_enemies_cnt = enemys.size()
	print("GAME READY",total_enemies_cnt)
	var camera = get_tree().get_nodes_in_group("camera")[0]
	camera.unit_clicked.connect(selection_manager.select_unit)
	camera.ground_clicked.connect(selection_manager.command_move)
	kill_enemies_cnt = 0
	for enemy in enemys:
		print(enemy.name)
		enemy.die.connect(_on_enemy_die)
	get_node("UI").add_to_group("UI")
	levelUp.connect(player.calculate_stats)
	player.hp_changed.connect(hud.set_hp_bar_value)
	projectile_manager.arrow_hited.connect(func(pos): spawn_effect("dust", pos))

func _on_enemy_die(experience: int, death_position: Vector2) -> void:
	get_experience(experience)
	spawn_effect("die", death_position)
	kill_enemies_cnt+=1
	if(kill_enemies_cnt >= total_enemies_cnt):
		game_over.emit(true)
		print("All enemies killed")


func get_experience(experience: int) -> void:
	print("Player gained experience: ", experience)
	if player_data.level < level_data.max_level:
		player_data.experience += experience
		if(player_data.experience >= level_data.level_experience_list[player_data.level]):
			level_up()
		player_data.save_data()
	

func level_up() -> void:
	print("Player leveled up! New level: ", player_data.level + 1)
	player_data.experience -= level_data.level_experience_list[player_data.level]
	player_data.level += 1
	player_data.save_data()
	hud.set_level_label()
	levelUp.emit()
	
func spawn_effect(effect_name: String, position: Vector2) -> void:
	if effect_container == null:
		return
	if(effect_name =="die"):
		var effect_instance = death_effect.death.instantiate()
		effect_instance.global_position = position
		effect_container.add_child(effect_instance)
	elif(effect_name =="dust"):
		var effect_instance = death_effect.dust.instantiate()
		effect_instance.global_position = position
		effect_container.add_child(effect_instance)

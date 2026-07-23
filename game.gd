extends Node

signal game_over(victory:bool)

@onready var death_effect: Node2D = $effects
@onready var hud:Control=$UI/HUD

var total_enemies_cnt: int = 0
var kill_enemies_cnt: int = 0

var player
var enemys

signal levelUp

func _ready() -> void:
	enemys = get_tree().get_nodes_in_group("enemies")
	player = get_tree().get_nodes_in_group("player")[0]
	total_enemies_cnt = enemys.size()
	print("GAME READY",total_enemies_cnt)

	kill_enemies_cnt = 0
	for enemy in enemys:
		print(enemy.name)
		enemy.die.connect(_on_enemy_die)
	
	levelUp.connect(player.calculate_stats)
	player.hp_changed.connect(hud.set_hp_bar_value)

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
	if(effect_name =="die"):
		var effect_instance = death_effect.death.instantiate()
		position.y = position.y-20
		effect_instance.global_position = position
		get_node("test_scene").get_node("effectContainer").add_child(effect_instance)

extends Control

@export var main_menu_scene: PackedScene
@export var game_scene: PackedScene
@export var game_end_scene: PackedScene



# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	load_main_menu("game_start")
	pass # Replace with function body.

func load_main_menu(origin:String) -> void:
	if origin=="game_over":
		get_node("Game").queue_free()
		#await get_tree().process_frame
	var main_menu_instance: Control = main_menu_scene.instantiate()
	main_menu_instance.new_game_pressed.connect(new_game)
	main_menu_instance.about_pressed.connect(about)
	main_menu_instance.setting_pressed.connect(setting)
	main_menu_instance.exit_pressed.connect(exit)
	add_child(main_menu_instance)

func new_game(origin:String)->void:
	print("New Game pressed from: ", origin)
	if(origin == "main_menu"):
		get_node("MainMenu").queue_free()
	if origin=="game_over":
		get_node("Game").queue_free()
		await get_tree().create_timer(0.4).timeout
	var game_instance = game_scene.instantiate()
	game_instance.game_over.connect(load_game_end_menu)
	add_child(game_instance)

func load_game_end_menu(victory:bool)->void:
	await get_tree().create_timer(0.4).timeout
	var enemys = get_tree().get_nodes_in_group("enemies")
	var player = get_tree().get_nodes_in_group("player")[0]
	player.set_process_mode(PROCESS_MODE_DISABLED)
	for enemy in enemys:
		enemy.set_process_mode(PROCESS_MODE_DISABLED)
	var game_end_scene_instance : Control = game_end_scene.instantiate()
	print("game victory",victory)
	if victory:
		game_end_scene_instance.get_node("VBoxContainer/label").set_text("Victorious")
	else:
		game_end_scene_instance.get_node("VBoxContainer/label").set_text("You died.")
	game_end_scene_instance.main_menu_button_pressed.connect(load_main_menu)
	game_end_scene_instance.replay_pressed.connect(new_game)
	get_node("Game/UI").add_child(game_end_scene_instance)


func about(origin:String)->void:
	pass

func setting(origin:String)->void:
	
	pass

func exit(origin:String)->void:
	queue_free()
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

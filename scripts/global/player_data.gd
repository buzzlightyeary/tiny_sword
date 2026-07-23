extends Node

const SAVE_PATH: String = "user://save_game.json"

var level: int = 0
var experience: int = 0


func _ready() -> void:
	load_data()


func save_data() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file for writing: ", error_string(FileAccess.get_open_error()))
		print("Failed to open save file for writing: ", error_string(FileAccess.get_open_error()))
		return
	var data: Dictionary = {
		"level": level,
		"experience": experience,
	}
	file.store_string(JSON.stringify(data))
	file.close()
	print("Game saved: ", data)


func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found, starting fresh")
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open save file for reading: ", error_string(FileAccess.get_open_error()))
		print("Failed to open save file for reading: ", error_string(FileAccess.get_open_error()))
		return
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Save file is corrupted, ignoring it")
		print("Save file is corrupted, ignoring it")
		return
	var data: Dictionary = parsed
	# Note: do not reference level_data here — autoload init order means it may not be ready yet.
	# game.gd's get_experience() guards against level >= max_level.
	if data.has("level") and (typeof(data["level"]) == TYPE_FLOAT or typeof(data["level"]) == TYPE_INT):
		level = maxi(0, int(data["level"]))
	if data.has("experience") and (typeof(data["experience"]) == TYPE_FLOAT or typeof(data["experience"]) == TYPE_INT):
		experience = maxi(0, int(data["experience"]))
	print("Save loaded: level=", level, " experience=", experience)

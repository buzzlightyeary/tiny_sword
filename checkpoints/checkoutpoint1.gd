extends Node2D

const BoatScene: PackedScene = preload("res://Entities/Enemies/boat.tscn")


func _ready() -> void:
	# Deferred so game.gd finishes counting the "enemy" group before the
	# goblin joins it — the boat goblin must not affect the victory count.
	_spawn_boat.call_deferred()


func _spawn_boat() -> void:
	var boat = BoatScene.instantiate()
	boat.global_position = $boatPlace.global_position
	boat.landing_place = $landingPlace.global_position
	add_child(boat)

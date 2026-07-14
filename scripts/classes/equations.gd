class_name  Equations
extends Node


const BASE_ATTACK_SPEED: float = 0.6

static func calculate_attack_speed() -> float:
	return BASE_ATTACK_SPEED * (1.0 - (player_data.level * 0.3))
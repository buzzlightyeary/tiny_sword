class_name  Equations
extends Node


const BASE_ATTACK_SPEED: float = 0.6

static func calculate_attack_speed(attack_speed: float) -> float:
	return attack_speed * (1.0 - (player_data.level * 0.05))
extends Area2D

var target = null


func respawnPlayer(player):
	player.global_position = Vector2(0, 0)

func _on_FallRespawn_body_entered(body):
	if(!is_instance_valid(target)):
		target = body
	respawnPlayer(target)

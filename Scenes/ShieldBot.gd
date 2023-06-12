extends KinematicBody2D

enum State {IDLE, SHIELD, ATTACK, DEATH}



func set_true(visableItem):
	visableItem.visable = true

func set_false(visableItem):
	visableItem.visable = false



func process_idle():
	print("entered fucker")
	$SpriteHolder/Idle.hide()
	$SpriteHolder/ShieldReady.show()
	$AnimationPlayer.play("ShieldReady")

func shieldReady():
	$SpriteHolder/ShieldReady.hide()
	$SpriteHolder/ShieldUp.show()
	$AnimationPlayer.play("ShieldUp")


func _on_AlertRange_body_entered(body):
	process_idle()

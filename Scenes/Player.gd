extends KinematicBody2D

enum State {NORMAL, DASHING, ATTACKING, DASH_ATTACK, WALL_SLIDE}
#sprite info for effects
var ghost_scene = preload ("res://Scenes/player/ghosteffect.tscn")
var dust_scene = preload ("res://Scenes/player/WallSlideEffect.tscn")
var dust = dust_scene.instance()

#General player stats and information
var gravity = 1000

var velocity = Vector2.ZERO
var maxHorizontalSpeed = 200
var maxDashSpeed = 350
var minDashSpeed = 300
var horizontalAcceleration = 1500
var jumpSpeed = 320
var dashJumpSpeed = 420
var jumpTerminationMultiplier = 5
var hasDash = false
var currentState = State.NORMAL
var isStateNew = true

#Wall info
var wallJumpHoriSpeed = 340
var wallSlideGrav = 500
var wallSlideMaxGrav = 200

func _process(delta):
	match currentState:
		State.NORMAL:
			process_normal(delta)
		State.DASHING:
			process_dashing(delta)
		State.ATTACKING:
			process_attack(delta)
		State.DASH_ATTACK:
			process_dash_attack(delta)
		State.WALL_SLIDE:
			process_wallSlide(delta)
	isStateNew = false
	print($Timers/FlickTimer.time_left)

func process_normal(delta):
	var sprite = $Inner/Sprite
	var moveVector = get_movement_vector()
	movement_controller(delta, maxHorizontalSpeed, jumpSpeed, moveVector)
	
	update_animation()
	
	if(Input.is_action_just_pressed("attack")):
		change_state(State.ATTACKING)
	if(InputBuffer.is_action_press_buffered("dash") && moveVector.x != 0 && is_on_floor()):
		$Timers/DashTimer.start()
		$Timers/GhostTimer.start()
		instance_ghost(sprite)
		change_state(State.DASHING)
	if(moveVector.x != 0 && is_on_wall() && !is_on_floor()):
		change_state(State.WALL_SLIDE)

func process_attack(delta):
	$AnimationPlayer.play("Attack01")
	
	if(!is_on_floor()):
		var moveVector = get_movement_vector()
		movement_controller(delta, maxHorizontalSpeed, jumpSpeed, moveVector)

func process_dashing(delta):
	var sprite = $Inner/Sprite
	$AnimationPlayer.play("Dash")
	var moveVector = get_movement_vector()
	movement_controller(delta, maxDashSpeed, dashJumpSpeed, moveVector)
	
	if($Timers/GhostTimer.is_stopped()):
		instance_ghost(sprite)
		$Timers/GhostTimer.start()
	
	if(!is_on_floor()):
		update_animation()
	
	if(moveVector.x != 0):
		if(moveVector.x < 0):
			$Inner.scale.x = -1
		else:
			$Inner.scale.x = 1
	
	if(Input.is_action_just_pressed("attack")):
		change_state(State.DASH_ATTACK)
	
	if(Input.is_action_just_pressed("dash") && is_on_floor()):
		return_to_normal()
	
	if($Timers/DashTimer.is_stopped() && is_on_floor()):
		change_state(State.NORMAL)
	if(is_on_floor() && moveVector.x == 0 && $Timers/FlickTimer.is_stopped()):
		$Timers/FlickTimer.start()
		velocity.x = 0
	if($Timers/FlickTimer.is_stopped() && is_on_floor() && moveVector.x == 0):
		change_state(State.NORMAL)
	if(moveVector.x != 0 && is_on_wall() && !is_on_floor()):
		change_state(State.WALL_SLIDE)

func process_dash_attack(delta):
	var sprite = $Inner/Sprite
	$AnimationPlayer.play("DashAttack")
	var moveVector = get_movement_vector()
	
	if($Timers/GhostTimer.is_stopped()):
		instance_ghost(sprite)
		$Timers/GhostTimer.start()
	movement_controller(delta, maxDashSpeed, dashJumpSpeed, moveVector)
	
	var wasOnFloor = is_on_floor()
	
	if(!wasOnFloor && is_on_floor()):
			return_to_normal()
	
	if($Timers/DashTimer.is_stopped() && is_on_floor()):
		change_state(State.NORMAL)
	elif(is_on_floor() && moveVector.x == 0):
		change_state(State.NORMAL)

func process_wallSlide(delta):
	$AnimationPlayer.play("WallSlide")
	if(get_wall_direction() == "left"):
		$Inner.scale.x = -1
	var moveVector = get_movement_vector()

	var sprite = $Inner/Sprite
	if($Timers/WallJumpTimer.is_stopped()):
		velocity.x += moveVector.x * horizontalAcceleration * delta
		if(moveVector.x == 0):
			velocity.x = lerp(0, velocity.x, pow(2, -50 * delta))
	
	velocity.x = clamp(velocity.x, -maxHorizontalSpeed, maxHorizontalSpeed)
	velocity.y = clamp(velocity.y, -wallSlideMaxGrav, wallSlideMaxGrav)
	
	if(moveVector.y < 0):
		$Timers/WallJumpTimer.start()
		velocity.y = moveVector.y * jumpSpeed
		if(get_wall_direction() == "left"):
			velocity.x = wallJumpHoriSpeed
		else:
			velocity.x = -wallJumpHoriSpeed
	
	if(moveVector.y < 0 && Input.is_action_pressed("dash")):
		$Timers/WallJumpTimer.start()
		velocity.y = moveVector.y * dashJumpSpeed
		change_state(State.DASHING)
	
	$Timers/CoyoteTimer.stop()
	
	velocity.y += wallSlideGrav * delta
	
	var wasOnFloor = is_on_floor()
	velocity = move_and_slide(velocity, Vector2.UP);
	
	if(wasOnFloor && !is_on_floor()):
		$Timers/CoyoteTimer.start()
	
	if(!is_on_wall() && Input.is_action_pressed("dash") && moveVector.y < 0):
		$Timers/DashTimer.start()
		$Timers/GhostTimer.start()
		instance_ghost(sprite)
		change_state(State.DASHING)
	if(!is_on_wall()):
		change_state(State.NORMAL)
	if(is_on_floor()):
		change_state(State.NORMAL)

func return_to_normal():
	if($Inner/Sprite/AttackArea/CollisionPolygon2D.disabled == true):
		$Inner/Sprite/AttackArea/CollisionPolygon2D.disabled = false
	currentState = State.NORMAL

func return_to_dash():
	if($Inner/Sprite/AttackArea/CollisionPolygon2D.disabled == true):
		$Inner/Sprite/AttackArea/CollisionPolygon2D.disabled = false
	currentState = State.DASHING

func get_movement_vector():
	var moveVector = Vector2.ZERO
	moveVector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	moveVector.y = -1 if Input.is_action_just_pressed("jump") else 0
	return moveVector

func get_wall_direction():
	var wallChecker = $WallCheck
	if(is_on_wall() && wallChecker.is_colliding() == true):
		return "left"
	elif(is_on_wall() && wallChecker.is_colliding() == false):
		return "right"

func change_state(newState):
	currentState = newState
	isStateNew = true

func instance_ghost(sprite):
	var ghost: Sprite = ghost_scene.instance()
	get_parent().add_child(ghost)
	
	ghost.global_position = $Inner/Sprite.global_position
	ghost.texture = sprite.texture
	ghost.vframes = sprite.vframes
	ghost.hframes = sprite.hframes
	ghost.frame = sprite.frame
	
	if($Inner.scale.x == -1):
		ghost.scale.x = -1
	else:
		ghost.scale.x = 1

func instance_dust():
	get_parent().add_child(dust)
	
	if($Inner.scale.x == -1):
		dust.scale.x = -1
	else:
		dust.scale.x = 1

func update_animation():
	var moveVec = get_movement_vector()
	if(velocity.y < 0):
		$AnimationPlayer.stop()
		$AnimationPlayer.play("Jump")
	elif(velocity.y > 0):
		$AnimationPlayer.play("Fall")
	elif(moveVec.x != 0):
		$AnimationPlayer.play("Run")
	else:
		$AnimationPlayer.play("Idle")
	
	if(moveVec.x != 0):
		if(moveVec.x < 0):
			$Inner.scale.x = -1
		else:
			$Inner.scale.x = 1

func movement_controller(delta, horzontalController, jumpController, moveVector):
	var sprite = $Inner/Sprite
	velocity.x += moveVector.x * horizontalAcceleration * delta
	if(moveVector.x == 0):
		velocity.x = lerp(0, velocity.x, pow(2, -50 * delta))
	
	velocity.x = clamp(velocity.x, -horzontalController, horzontalController)
	
	if(moveVector.y < 0 && (is_on_floor() || !$Timers/CoyoteTimer.is_stopped())):
		velocity.y = moveVector.y * jumpController
	if(Input.is_action_pressed("jump")):
		$Timers/CoyoteTimer.stop()
	
	if(velocity.y < 0 && !Input.is_action_pressed("jump")):
		velocity.y += gravity * jumpTerminationMultiplier * delta
	else:
		velocity.y += gravity * delta
		
	var wasOnFloor = is_on_floor()
	velocity = move_and_slide(velocity, Vector2.UP);
	
	if(wasOnFloor && !is_on_floor()):
		$Timers/CoyoteTimer.start()
		
	if(State.ATTACKING):
		if(!wasOnFloor && is_on_floor()):
			return_to_normal()


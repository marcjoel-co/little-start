extends CharacterBody2D

const speed = 30
var dir:Vector2
var is_fly_noticed: bool
var player: RigidBody2D

func _ready():
	is_fly_noticed = true
	
func _process(delta):
		move(delta)

func move(delta):
	if is_fly_noticed:
		player = Global.playerBody
		velocity = position.direction_to(player.position) * speed
		
		print(abs(velocity))
		
		
	if !is_fly_noticed:
		velocity += dir * speed * delta
	move_and_slide()

func _on_timer_timeout():
	$Timer.wait_time = choose([1.0, 1.5, 2.0])
	if !is_fly_noticed:
			dir = choose([Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP])
			print(dir)
			
func choose(array):
	array.shuffle()
	return array.front()

class_name Player
extends RigidBody2D

# --- Movement Constants ---
const WALK_ACCEL = 1000.0
const WALK_DEACCEL = 1000.0
const WALK_MAX_VELOCITY = 200.0
const AIR_ACCEL = 250.0
const AIR_DEACCEL = 250.0
const JUMP_VELOCITY = 380.0
const STOP_JUMP_FORCE = 450.0
const MAX_FLOOR_AIRBORNE_TIME = 0.15

# --- Combat Constants (Can be removed for an unarmed hero) ---
const MAX_SHOOT_POSE_TIME = 0.3
const BULLET_SCENE = preload("res://player/bullet.tscn")
const ENEMY_SCENE = preload("res://enemy/enemy.tscn")

# --- Win Condition Variables ---
var is_in_win_zone := false

# --- State Variables ---
var siding_left := false
var jumping := false
var stopping_jump := false
var shooting := false
var floor_h_velocity := 0.0
var airborne_time := 1e20
var shoot_time := 1e20

# --- Node References ---
@onready var win_timer := $WinTimer as Timer
@onready var sound_jump := $SoundJump as AudioStreamPlayer2D
@onready var sound_shoot := $SoundShoot as AudioStreamPlayer2D
@onready var sprite := $Sprite2D as Sprite2D
@onready var sprite_smoke := sprite.get_node(^"Smoke") as CPUParticles2D
@onready var animation_player := $AnimationPlayer as AnimationPlayer
@onready var bullet_shoot := $BulletShoot as Marker2D

func _ready() -> void:
	# Make sure the RigidBody2D is set up correctly
	gravity_scale = 1.0
	lock_rotation = true
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC

func _physics_process(delta: float) -> void:
	# Handle input
	var move_left := Input.is_action_pressed(&"move_left")
	var move_right := Input.is_action_pressed(&"move_right")
	var jump := Input.is_action_pressed(&"jump")
	var shoot := Input.is_action_pressed(&"shoot")
	var spawn := Input.is_action_just_pressed(&"spawn")
	
	if spawn:
		_spawn_enemy_above()
	
	# Get current velocity
	var velocity := linear_velocity
	
	# Check if on floor
	var on_floor := _is_on_floor()
	
	# Handle jumping
	if on_floor and jump and not jumping:
		velocity.y = -JUMP_VELOCITY
		jumping = true
		stopping_jump = false
		sound_jump.play()
	
	if jumping:
		if velocity.y > 0:
			jumping = false
		elif not jump:
			stopping_jump = true
		
		if stopping_jump:
			velocity.y += STOP_JUMP_FORCE * delta
	
	# Handle horizontal movement
	var accel := WALK_ACCEL if on_floor else AIR_ACCEL
	var deaccel := WALK_DEACCEL if on_floor else AIR_DEACCEL
	
	if move_left:
		velocity.x -= accel * delta
		siding_left = true
	elif move_right:
		velocity.x += accel * delta
		siding_left = false
	else:
		# Apply friction
		velocity.x = move_toward(velocity.x, 0, deaccel * delta)
	
	# Clamp horizontal velocity
	velocity.x = clamp(velocity.x, -WALK_MAX_VELOCITY, WALK_MAX_VELOCITY)
	
	# Apply velocity
	linear_velocity = velocity
	
	# Handle shooting
	if shoot and not shooting:
		_shot_bullet()
	else:
		shoot_time += delta
	
	# Handle win condition
	_check_win_condition()

func _is_on_floor() -> bool:
	# Simple raycast to check if on floor
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		global_position, 
		global_position + Vector2(0, 50)
	)
	var result := space_state.intersect_ray(query)
	return result.size() > 0

func _check_win_condition() -> void:
	# Check if player is standing still in win zone
	if is_in_win_zone and linear_velocity.is_zero_approx():
		if win_timer.is_stopped():
			win_timer.start()
	else:
		if not win_timer.is_stopped():
			win_timer.stop()

func _shot_bullet() -> void:
	shooting = true
	shoot_time = 0.0
	sound_shoot.play()
	
	# Create bullet instance
	var bullet: Node = BULLET_SCENE.instantiate()
	var bullet_dir: int = -1 if siding_left else 1
	
	# Set bullet position and direction
	bullet.global_position = bullet_shoot.global_position
	bullet.set_direction(bullet_dir)
	
	# Add bullet to scene
	get_tree().current_scene.add_child(bullet)
	
	# Start smoke effect
	sprite_smoke.emitting = true

func _spawn_enemy_above() -> void:
	var enemy: Node = ENEMY_SCENE.instantiate()
	enemy.global_position = global_position + Vector2(0, -100)
	get_tree().current_scene.add_child(enemy)

# --- Signal Callbacks for Win Condition ---
func _on_win_zone_body_entered(body: Node2D) -> void:
	if body == self:
		is_in_win_zone = true
		print("Player has entered the light.")

func _on_win_zone_body_exited(body: Node2D) -> void:
	if body == self:
		is_in_win_zone = false
		print("Player has left the light.")

func _on_win_timer_timeout() -> void:
	print("YOU WIN! CONGRATULATIONS!")
	get_tree().create_timer(1.0).timeout.connect(
		func() -> void: get_tree().change_scene_to_file("res://lol.tscn"))

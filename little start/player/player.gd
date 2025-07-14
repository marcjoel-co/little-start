class_name Player
extends RigidBody2D

# --- Movement Constants ---
const WALK_ACCEL = 1000.0
const WALK_DEACCEL = 1000.0
const WALK_MAX_VELOCITY = 200.0
const AIR_ACCEL = 250.0
const AIR_DEACCEL = 250.0
const JUMP_VELOCITY = 780.0
const STOP_JUMP_FORCE = 450.0
const MAX_FLOOR_AIRBORNE_TIME = 0.15

# --- Combat Constants (Can be removed for an unarmed hero) ---
#const MAX_SHOOT_POSE_TIME = 0.3
#const BULLET_SCENE = preload("res://player/bullet.tscn")
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
var jump_cooldown := 0.0  # Prevent multiple jumps

# --- Node References ---
@onready var win_timer := $WinTimer as Timer
@onready var sound_jump := $SoundJump as AudioStreamPlayer2D
#@onready var sound_shoot := $SoundShoot as AudioStreamPlayer2D
@onready var sprite := $Sprite2D as Sprite2D
@onready var sprite_smoke := sprite.get_node(^"Smoke") as CPUParticles2D
@onready var animation_player := $AnimationPlayer as AnimationPlayer
#@onready var bullet_shoot := $BulletShoot as Marker2D

func _ready() -> void:
	gravity_scale = 3.0  # Increased gravity for faster falling
	lock_rotation = true
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC

func _physics_process(delta: float) -> void:
	# Handle input
	var move_left := Input.is_action_pressed(&"move_left")
	var move_right := Input.is_action_pressed(&"move_right")
	var jump := Input.is_action_pressed(&"jump")
	var spawn := Input.is_action_just_pressed(&"spawn")
	
	if spawn:
		_spawn_enemy_above()
	
	# Get current velocity
	var velocity := linear_velocity
	
	# Update jump cooldown
	if jump_cooldown > 0:
		jump_cooldown -= delta
	
	# Check if on floor
	var on_floor := _is_on_floor()
	
	# Handle jumping - only allow if truly on floor and cooldown expired
	if on_floor and jump and not jumping and jump_cooldown <= 0:
		velocity.y = -JUMP_VELOCITY
		jumping = true
		stopping_jump = false
		jump_cooldown = 0.15  # 150ms cooldown before next jump
		sound_jump.play()
	
	# Reset jumping state when landing
	if on_floor and velocity.y >= 0:
		jumping = false
		stopping_jump = false
	
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
	
	# Handle win condition

func _is_on_floor() -> bool:
	# Get the collision shape from the player
	var collision_shape := $CollisionShape2D as CollisionShape2D
	if not collision_shape or not collision_shape.shape:
		return false
	
	var shape := collision_shape.shape
	var space_state := get_world_2d().direct_space_state
	
	# Create a small rectangle for floor detection
	var floor_check_shape := RectangleShape2D.new()
	
	# Adjust size based on the player's collision shape
	var shape_size: Vector2
	if shape is RectangleShape2D:
		shape_size = shape.size
	elif shape is CapsuleShape2D:
		shape_size = Vector2(shape.radius * 2, shape.height)
	elif shape is CircleShape2D:
		shape_size = Vector2(shape.radius * 2, shape.radius * 2)
	else:
		shape_size = Vector2(32, 32)  # Default size
	
	# Make the floor check shape slightly smaller width-wise and very thin
	floor_check_shape.size = Vector2(shape_size.x * 0.8, 4)
	
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = floor_check_shape
	
	# Position the check shape just below the player's collision shape
	var check_position := global_position + Vector2(0, shape_size.y * 0.5 + 2)
	query.transform = Transform2D(0, check_position)
	query.collision_mask = collision_mask
	query.exclude = [self]  # Exclude the player itself
	
	var result := space_state.intersect_shape(query)
	return result.size() > 0

func _spawn_enemy_above() -> void:
	var enemy: Node = ENEMY_SCENE.instantiate()
	enemy.global_position = global_position + Vector2(0, -100)
	get_tree().current_scene.add_child(enemy)

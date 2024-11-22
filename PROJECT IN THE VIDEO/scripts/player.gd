extends CharacterBody3D

@onready var camera_mount = $camera_mount
@onready var animation_player = $visuals/AuxScene/AnimationPlayer
@onready var visuals = $visuals

@export var sens_horizontal = 0.2
@export var sens_vertical = 0.2

var SPEED = 1.75
const JUMP_VELOCITY = 4.5

var walking_speed = 1.75
var running_speed = 2.6

var running = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x) * sens_horizontal)
		visuals.rotate_y(deg_to_rad(event.relative.x) * sens_horizontal)
		camera_mount.rotate_x(deg_to_rad(-event.relative.y) * sens_vertical)
		camera_mount.rotation_degrees.x = clamp(camera_mount.rotation_degrees.x, -75, 85)

func _physics_process(delta):
	
	if Input.is_action_pressed("run"):
		SPEED = running_speed
		running = true
	else:
		SPEED = walking_speed
		running = false
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		if running:
			animation_player.play("JogForward")
		else:
			animation_player.play("Walking")
		
		visuals.look_at(position + direction)
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		animation_player.play("Idle")
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

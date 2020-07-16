extends KinematicBody

###################-VARIABLES-####################

# Camera
export(float) var mouse_sensitivity = 12.0
export(NodePath) var head_path
export(NodePath) var cam_path
export(float) var FOV = 80.0
var mouse_axis := Vector2()
onready var head: Spatial = get_node(head_path)
onready var cam: Camera = get_node(cam_path)
# Move
var velocity := Vector3()
var direction := Vector3()
var move_axis := Vector2()
var can_sprint := true
var sprinting := false
# Walk
const FLOOR_NORMAL := Vector3(0, 1, 0)
export(float) var gravity = 30.0
export(int) var walk_speed = 10
export(int) var sprint_speed = 16
export(int) var acceleration = 8
export(int) var deacceleration = 10
export(float, 0.0, 1.0, 0.05) var air_control = 0.3
export(int) var jump_height = 10
# Slopes
export(float) var floor_max_angle = 45.0
var gravity_velocity := Vector3()
##################################################

# Called when the node enters the scene tree
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	cam.fov = FOV


# Called every frame. 'delta' is the elapsed time since the previous frame
func _process(_delta: float) -> void:
	move_axis.x = Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
	move_axis.y = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	
	camera_rotation()


# Called every physics tick. 'delta' is constant
func _physics_process(delta: float) -> void:
	
	# Input
	direction = Vector3()
	var aim: Basis = get_global_transform().basis
	if move_axis.x >= 0.5:
		direction -= aim.z
	if move_axis.x <= -0.5:
		direction += aim.z
	if move_axis.y <= -0.5:
		direction -= aim.x
	if move_axis.y >= 0.5:
		direction += aim.x
	direction.y = 0
	direction = direction.normalized()
	
	# Jump
	var _snap: Vector3
	#if (moving): #idk how to stop on slopes now
		#gravity_velocity.y = 0
	if is_on_floor():
		gravity_velocity.y = -0.0001
		_snap = Vector3(0, -1, 0)
		if Input.is_action_just_pressed("move_jump"):
			_snap = Vector3(0, 0, 0)
			gravity_velocity.y = jump_height
	else:
		# Apply Gravity
		velocity.y = 0;
		gravity_velocity.y -= gravity * delta
	
	# Sprint
	var _speed: int
	if (Input.is_action_pressed("move_sprint") and can_sprint and move_axis.x >= 0.5):
		_speed = sprint_speed
		cam.set_fov(lerp(cam.fov, FOV * 1.05, delta * 8))
		sprinting = true
	else:
		_speed = walk_speed
		cam.set_fov(lerp(cam.fov, FOV, delta * 8))
		sprinting = false
	
	# Acceleration and Deacceleration
	# where would the player go
	var _temp_vel: Vector3 = velocity
	_temp_vel.y = 0
	var _target: Vector3 = direction * _speed
	var _temp_accel: float
	if direction.dot(_temp_vel) > 0:
		_temp_accel = acceleration
	else:
		_temp_accel = deacceleration
	if not is_on_floor():
		_temp_accel *= air_control
	# interpolation
	_temp_vel = _temp_vel.linear_interpolate(_target, _temp_accel * delta)
	velocity.x = _temp_vel.x
	velocity.z = _temp_vel.z
	# clamping (to stop on slopes)
	if direction.dot(velocity) == 0:
		var _vel_clamp := 0.25
		if velocity.x < _vel_clamp and velocity.x > -_vel_clamp:
			velocity.x = 0
		if velocity.z < _vel_clamp and velocity.z > -_vel_clamp:
			velocity.z = 0
	"""
	var temp_vel = velocity;
	temp_vel.y = 0
	temp_vel = direction * _speed;
	velocity.x = temp_vel.x;
	velocity.z = temp_vel.z;
	"""
	
	# new idea: have a ray pointing in the direction you are moving on your feet. if it finds somethign that is steeper than the 
	
	# Move
	#move_and_slide(gravity_velocity, FLOOR_NORMAL, true, 4, deg2rad(floor_max_angle))
	if (is_on_floor()):
		if  (is_on_wall()):
			velocity = move_and_slide(velocity, FLOOR_NORMAL, true, 4, deg2rad(floor_max_angle))
		else:
			velocity.y = move_and_slide_with_snap(velocity, _snap, FLOOR_NORMAL, true, 4, deg2rad(floor_max_angle)).y
		#velocity = move_and_slide_with_snap(velocity, _snap, FLOOR_NORMAL, true, 4, deg2rad(floor_max_angle))
	else:
		velocity = move_and_slide(velocity, FLOOR_NORMAL, true, 4, deg2rad(floor_max_angle))
	move_and_slide(gravity_velocity, FLOOR_NORMAL, false, 4, deg2rad(floor_max_angle))	
	print(velocity);
	


# Called when there is an input event
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_axis = event.relative


func camera_rotation() -> void:
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return
	if mouse_axis.length() > 0:
		var horizontal: float = -mouse_axis.x * (mouse_sensitivity / 100)
		var vertical: float = -mouse_axis.y * (mouse_sensitivity / 100)
		
		mouse_axis = Vector2()
		
		rotate_y(deg2rad(horizontal))
		head.rotate_x(deg2rad(vertical))
		
		# Clamp mouse rotation
		var temp_rot: Vector3 = head.rotation_degrees
		temp_rot.x = clamp(temp_rot.x, -90, 90)
		head.rotation_degrees = temp_rot

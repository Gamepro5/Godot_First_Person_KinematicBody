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
export(int) var jump_height = 5
# Slopes
export(float) var floor_max_angle = 45.0

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

#TODO: stop deceleration when on a wall, fix not going up and down slopes at the same speed, also see comment on line 133.
var wall_counter = 0
var air_counter = 0
var floor_counter = 0
var curr_gravity = 0
var _temp_vel
var on_floor = false
var floor_normal = Vector3()
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
	if on_floor:
		_snap = Vector3(0, -0.1, 0)
		velocity.y = 0
		#curr_gravity = 0
		if Input.is_action_just_pressed("move_jump"):
			_snap = Vector3(0, 0, 0)
			velocity.y = jump_height
	
	# Apply Gravity
	curr_gravity -= gravity * delta

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
	if not on_floor:
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
	_temp_vel = direction * _speed
	"""
	# Move
	print(velocity)
	if on_floor:
		# set gravity to 0 or jump speed
		curr_gravity = velocity.y
		# slide input vector surface normal
		_temp_vel = _temp_vel.slide(floor_normal)
		# reapply gravity, so jumps go up rather than normal to the floor
		_temp_vel.y += curr_gravity
		if  (is_on_wall()):
			wall_counter += 1
			#print("wall: ", wall_counter)
			#setting velocity to the remainder solves weird behavior on super steep slopes but fucks things up on perfect 90 degree walls when on a slope. idk how to have it both ways.
			velocity = move_and_slide(_temp_vel, FLOOR_NORMAL, true, 4, deg2rad(floor_max_angle))
		else:
			move_and_slide(_temp_vel, FLOOR_NORMAL, true, 4, deg2rad(floor_max_angle), false)

		# manually control this since we don't always have downward pressure above. could use a raycast
		on_floor = false
		floor_normal = null

		# snap if vector exists
		if _snap != Vector3():
			# collision check
			var col = move_and_collide(_snap, false, false, true)
			# if no collision, we're not on the floor
			if col:
				if acos(col.normal.dot(FLOOR_NORMAL)) < deg2rad(floor_max_angle) + 0.01:
					var travel = col.travel.project(FLOOR_NORMAL)
					# move object if it's super far away, otherwise just chill
					if abs(travel.length()) > 0.1:
						global_transform.origin += travel
					# we're now on the floor
					on_floor = true
					floor_normal = col.normal

			# print(col.normal.dot(FLOOR_NORMAL) < deg2rad(floor_max_angle),  col.travel.project(FLOOR_NORMAL))
	else:
		air_counter += 1
		#print("air:  ", air_counter, " ", on_floor)
		_temp_vel.y = velocity.y
		_temp_vel.y += curr_gravity
		if (is_on_ceiling()):
			curr_gravity = 0;
			velocity.y = 0;
		move_and_slide(_temp_vel, FLOOR_NORMAL, true, 4, deg2rad(floor_max_angle))
		on_floor = is_on_floor()
		floor_normal = get_floor_normal()



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

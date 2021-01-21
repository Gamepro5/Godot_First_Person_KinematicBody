extends KinematicBody

###################-VARIABLES-####################

# Camera
var mouse_sensitivity = 12.0
var FOV = 80.0 #default = 80.0
var mouse_axis := Vector2()
onready var head: Spatial = $Head
onready var cam: Camera = $Head/Camera
# Move
var velocity := Vector3()
var direction := Vector3()
var move_axis := Vector2()
var can_sprint := true
var sprinting := false
# Walk
const FLOOR_NORMAL := Vector3(0, 1, 0)
var gravity = 30.0
var walk_speed = 10
var acceleration = 2 #default = 4
var deacceleration = 2 #default = 4
var air_control = 0 #default = 0.3
var jump_height = 5
# Slopes
var floor_max_angle = 45.0
var current_floor_angle = 0.0;

##################################################

# Called when the node enters the scene tree
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	cam.fov = FOV

var curr_gravity = Vector3()
var on_floor = false
var floor_normal = Vector3()
# Called every physics tick. 'delta' is constant
func _physics_process(delta: float) -> void:
	
	# Mouse rotations
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
	
	# Input
	direction = Vector3()
	var basis: Basis = get_global_transform().basis
	if Input.get_action_strength("move_forward"):
		direction -= basis.z
	if Input.get_action_strength("move_backward"):
		direction += basis.z
	if Input.get_action_strength("move_left"):
		direction -= basis.x
	if Input.get_action_strength("move_right"):
		direction += basis.x
	direction.y = 0
	direction = direction.normalized()

	# Jump
	var _snap: Vector3
	var jump: bool
	jump = false
	if on_floor:
		_snap = Vector3(0, -1, 0)
		#velocity.y = 0
		curr_gravity.y = 0
		jump = false
		if Input.is_action_just_pressed("move_jump"):
			_snap = Vector3(0, 0, 0)
			jump = true
	else:
	# Apply Gravity
			curr_gravity.y -= gravity * delta
	
	# Acceleration and Deacceleration
	
	# where would the player go
	var _target: Vector3
	
	if (on_floor):
		if jump:
			curr_gravity.y = 10
		# slide input vector surface normal
		velocity = velocity.slide(floor_normal)
		var input_vec = direction * walk_speed
		var projected_vec = direction * walk_speed
		projected_vec.y = -(input_vec.x * floor_normal.x + input_vec.z * floor_normal.z) / floor_normal.y
		_target = projected_vec
	else:
		_target = direction * walk_speed
	

		
	# interpolation
	velocity = velocity.linear_interpolate(_target, acceleration * delta)
	
	#To keep the visual velocity vector pointing where you would expect it to.
	$vel_raycast.cast_to = velocity.rotated(Vector3.UP, -rotation.y)
	
	# Move
	if on_floor:
		if  (is_on_wall()):
			#setting velocity to the remainder solves weird behavior on super steep slopes but fucks things up on perfect 90 degree walls when on a slope. idk how to have it both ways.
			var temp = move_and_slide(velocity, FLOOR_NORMAL, true, 4, deg2rad(floor_max_angle))
			velocity.x = temp.x
			velocity.z = temp.z
		else:
			move_and_slide(velocity, FLOOR_NORMAL, true, 4, deg2rad(floor_max_angle), false)
		# manually control this since we don't always have downward pressure above. could use a raycast
		on_floor = false
		floor_normal = null
		
		# snap if vector exists
		if _snap != Vector3(0,0,0):
			# collision check
			var col = move_and_collide(_snap, false, false, true)
			# if no collision, we're not on the floor
			if col:
				current_floor_angle = rad2deg(acos(col.get_normal().dot(Vector3.UP)))
				if acos(col.normal.dot(FLOOR_NORMAL)) < deg2rad(floor_max_angle) + 0.01:
					var travel = col.travel.project(FLOOR_NORMAL)
					# move object if it's super far away, otherwise just chill
					if abs(travel.length()) > 0.1:
						global_transform.origin += travel
					# we're now on the floor
					on_floor = true
					floor_normal = col.normal
		

			
	else:
		velocity.y = curr_gravity.y
		if (is_on_ceiling()):
			curr_gravity.y = 0;
			velocity.y = 0;
		velocity = move_and_slide(velocity, FLOOR_NORMAL, true, 4, deg2rad(floor_max_angle))
		on_floor = is_on_floor()
		floor_normal = get_floor_normal()


# Called when there is an input event
func _input(event: InputEvent) -> void:
	#No idea what this does tbh, I ddin't write this part.
	if event is InputEventMouseMotion:
		mouse_axis = event.relative



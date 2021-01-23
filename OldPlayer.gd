extends KinematicBody


var velocity = Vector3.ZERO;
var temp_vel = Vector3.ZERO;
var gravity_dir = Vector3.DOWN;
var gravity_strength = 0.1#1;
var mouse_axis = Vector2.ZERO;
var mouse_sensitivity = 12.0;
var snap = Vector3.ZERO;
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	# Mouse rotations
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return
	if mouse_axis.length() > 0:
		var horizontal: float = -mouse_axis.x * (mouse_sensitivity / 100)
		var vertical: float = -mouse_axis.y * (mouse_sensitivity / 100)
		
		mouse_axis = Vector2()
		
		rotate_y(deg2rad(horizontal))
		$Head.rotate_x(deg2rad(vertical))
		
		# Clamp mouse rotation
		var temp_rot: Vector3 = $Head.rotation_degrees
		temp_rot.x = clamp(temp_rot.x, -90, 90)
		$Head.rotation_degrees = temp_rot
	
	
	var direction = Vector3()
	if Input.is_action_pressed("move_forward"):
		direction += Vector3.FORWARD
	elif Input.is_action_pressed("move_backward"):
		direction += Vector3.BACK
	if Input.is_action_pressed("move_left"):
		direction += Vector3.LEFT
	elif Input.is_action_pressed("move_right"):
		direction += Vector3.RIGHT
	direction = direction.normalized()
	
	var temp_vel = get_global_transform().basis * direction * 3
	velocity.x = temp_vel.x
	velocity.z = temp_vel.z
	if (is_on_floor()):
		if Input.is_action_just_pressed("move_jump"):
			#snap = Vector3.ZERO
			#velocity.y = 20
			pass
	else:
		snap = Vector3.DOWN
	
	velocity += (gravity_dir * gravity_strength)
	#velocity = move_and_slide(velocity, Vector3.UP)
	velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP, true, 4, deg2rad(45));
	#print(is_on_floor(), velocity)


func _input(event: InputEvent) -> void:
	#No idea what this does tbh, I ddin't write this part.
	if event is InputEventMouseMotion:
		mouse_axis = event.relative

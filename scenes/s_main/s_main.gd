extends Spatial

func _ready():
	print("##############################################################################################################")
	print("DON'T FORGET TO RUN WITH VISIBLE COLLISION SHAPES ON TO SEE THE VELOCITY VECTORS (AS RAYCASTS)")
	print("##############################################################################################################")
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		#get_tree().quit() # Quits the game
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event.is_action_pressed("mouse_input"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

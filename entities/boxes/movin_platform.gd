extends Path3D

@onready var path = $PathFollow3D

var speed = 0.5
var direction = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	platform_movement(delta)

func platform_movement(delta):
	print(path.progress_ratio)
	path.progress_ratio += delta * speed

	#path.progress_ratio += delta*speed*direction
	if path.progress_ratio >= 1.0:
		direction = -1
	elif path.progress_ratio <= 0.0:
		direction = 1

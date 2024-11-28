extends CharacterBody3D

signal position_changed(v)
signal position_y_changed(v)
signal dash_count_changed(v)
signal dash_count_max_changed(v)
signal dash_recharge_time_changed(v)
signal glider_active_changed(v)


@onready var neck := $Neck
@onready var camera := $Neck/Camera
@onready var gun := $Gun

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Jump
@export var jump_height = 6
var can_jump_max_air_time = 0.3
var can_jump_curr_air_time = 0.0
var can_jump = true

# Movement
var mov_speed = 12
var mov_smooth_max = 0.300
var mov_smooth_curr = 0.0

# Velocity
var velocity_y_max = 50

# Dash
var dash_count = 3
@export var dash_count_max = 3
var dash_speed_curr = 0
@export var dash_speed = 30
var dash_duration_curr = 0
var dash_duration = 0.1
@export var dash_recharge_time = 2.0
var dash_recharge_time_curr = 0.0
@export var dash_cooldown = 0.4
var dash_cooldown_curr = 0.0
var dash_direction = Vector3 (0,0,0)

# Boost Down
var boost_down = 100
var boost_down_max = 100
var boost_down_curr = 0
@export var can_boost_down_after = 1.0
var can_boost_down_after_curr = 0.0

# Glider
var glider_active = false
@export var can_glide_after = 1.5
var can_glide_after_curr = 0.0
var glider_direction = Vector3(0,0,0)
var glider_velocity = Vector3(0,0,0)
var glider_speed = 100


# Camera Settings
var cam_max_angle = 90
var cam_min_angle = -80
@export var cam_sens = 0.002


func _ready():
	dash_count_changed.emit(dash_count)
	dash_count_max_changed.emit(dash_count_max)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			handle_player_rotation(Vector2(event.relative.x, event.relative.y))



func _physics_process(delta):
	var input_dir = Input.get_vector("left", "right", "front", "back")
	var direction = (neck.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var prev_pos_y = velocity.y

	handle_jump(delta)
	handle_glide(delta, input_dir)
	handle_move(delta, direction)
	handle_boost_down(delta)
	handle_dash(delta, direction)
		
	if is_moving(): 
		position_changed.emit(get_position())
		if prev_pos_y != position.y:
			position_y_changed.emit(get_position().y)
	
	move_and_slide()

func handle_move(delta, direction):
	if glider_active:
		return
	if direction:
		clamp(mov_smooth_curr, 0, mov_smooth_max)
		if mov_smooth_curr < mov_smooth_max:
			if mov_smooth_curr + delta > mov_smooth_max:
				mov_smooth_curr = mov_smooth_max
			else:
				mov_smooth_curr += delta
		
		velocity.x = direction.x * (mov_speed * (mov_smooth_curr / mov_smooth_max))
		velocity.z = direction.z * (mov_speed * (mov_smooth_curr / mov_smooth_max))
			
	else:
		if mov_smooth_curr > 0.0:
			if mov_smooth_curr - delta < 0.0:
				mov_smooth_curr = 0.0
			else:
				mov_smooth_curr -= delta
		velocity.x = move_toward(velocity.x, 0, delta * mov_smooth_max * 1000 )
		velocity.z = move_toward(velocity.z, 0, delta * mov_smooth_max * 1000 )
		
	if not is_on_floor():
		velocity.y = clamp(velocity.y - gravity * delta, -velocity_y_max, velocity_y_max)


func handle_jump(delta):
	if glider_active:
		return
	if is_on_floor():
		if not can_jump: can_jump = true
		if can_jump_curr_air_time > 0: can_jump_curr_air_time = 0
		if Input.is_action_just_pressed("jump"):
				velocity.y = jump_height
				can_jump = false
	elif can_jump:
		if	can_jump_curr_air_time < can_jump_max_air_time:
			if can_jump_curr_air_time + delta >= can_jump_max_air_time:
				can_jump = false
				can_jump_curr_air_time = can_jump_max_air_time
			else:
				can_jump_curr_air_time += delta


func handle_glide(delta, input_dir):
	if is_on_floor():
		if can_glide_after_curr > 0: can_glide_after_curr = 0
		if glider_active: 
			glider_active = false
			glider_active_changed.emit(glider_active)
	else:
		if can_glide_after_curr < can_glide_after:
			can_glide_after_curr = clamp(can_glide_after_curr + delta, 0, can_glide_after)
			if can_glide_after_curr < can_glide_after: pass
	
		if Input.is_action_just_pressed("jump") and not can_jump and can_glide_after_curr == can_glide_after:
			glider_active = !glider_active
			glider_active_changed.emit(glider_active)
			$Paraglider.rotation = Vector3(camera.rotation.x, neck.rotation.y, 0)
			glider_direction = (neck.basis * Vector3(0,camera.rotation.x,-1)).normalized()
			glider_velocity = glider_direction
			
		if glider_active:
			if input_dir:
				#handle_player_rotation(Vector2(rotation.x + input_dir.x * 1000 * delta, rotation.y + input_dir.y * 1000 * delta))
				# Consider creating a "Neck" for Paraglider to seperate x and y rotation. Rotating x might affect the rotation value of y.
				handle_glider_rotation(Vector2((input_dir.x * 1000 * delta), (input_dir.y * 1000 * delta)))
				glider_velocity = ($Paraglider.basis * Vector3(0 ,0,-1)).normalized()
				#glider_velocity += Vector3(input_dir.x * delta, 0, input_dir.y * delta)
				pass
			velocity = glider_velocity * glider_speed


func handle_dash(delta, direction):
	if glider_active:
		return
	if Input.is_action_just_pressed("dash") and direction and dash_count > 0 and dash_duration_curr >= dash_duration and dash_cooldown_curr == 0:
		dash_duration_curr = 0
		dash_direction = direction
		dash_count -= 1
		dash_count_changed.emit(dash_count)
		dash_cooldown_curr = dash_cooldown
	
	if dash_cooldown_curr > 0:
		dash_cooldown_curr = clamp(dash_cooldown_curr - delta, 0, dash_cooldown)
	
	if dash_duration_curr < dash_duration:
		dash_duration_curr = clamp(dash_duration_curr + delta, 0, dash_duration)
		dash_speed_curr = dash_speed * (dash_duration_curr / dash_duration)
	
	if dash_count < dash_count_max:
		if dash_recharge_time_curr == dash_recharge_time:
			dash_recharge_time_curr = 0
			dash_count += 1
			dash_count_changed.emit(dash_count)
		else:
			dash_recharge_time_curr = clamp(dash_recharge_time_curr + delta, 0, dash_recharge_time)
			dash_recharge_time_changed.emit(dash_recharge_time_curr / dash_recharge_time)
	
	if dash_speed_curr > 0:
		if dash_duration_curr == dash_duration:
			dash_speed_curr = clamp(dash_speed_curr - ((delta * (dash_duration * 1000) * dash_speed_curr / dash_speed) + 1), 0, dash_speed)
		velocity.x += dash_direction.x * dash_speed_curr * (delta * 100)
		velocity.z += dash_direction.z * dash_speed_curr * (delta * 100)

func handle_boost_down(delta):
	if glider_active:
		return
	
	if not is_on_floor():
		if Input.is_action_pressed("boost_down") and can_boost_down_after_curr == can_boost_down_after:
			var down_boost = clamp(boost_down_curr + (boost_down * delta), 0, boost_down_max)
			velocity.y -= down_boost
			boost_down_curr = down_boost
		elif can_boost_down_after_curr < can_boost_down_after:
			can_boost_down_after_curr = clamp(can_boost_down_after_curr + delta, 0, can_boost_down_after)
		elif boost_down_curr > 0:
			var down_boost = clamp(boost_down_curr - (boost_down * delta * 4), 0, boost_down_max)
			velocity.y -= down_boost
			boost_down_curr = down_boost
			
	else:
		if can_boost_down_after_curr > 0: can_boost_down_after_curr = 0.0
		if boost_down_curr > 0: boost_down_curr = 0


func is_moving():
	if velocity.x != 0 or velocity.y != 0 or velocity.z != 0:
		return true
	return false


func _on_glider_active_changed(v):
	$Gun.visible = !v
	$Paraglider.visible = v

func handle_player_rotation(direction):
	neck.rotation.y -= direction.x * cam_sens
	camera.rotation.x -= direction.y * cam_sens
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(cam_min_angle), deg_to_rad(cam_max_angle))
	gun.rotation.x = camera.rotation.x
	gun.rotation.y = neck.rotation.y

func handle_glider_rotation(direction):
	$Paraglider.rotation.y -= direction.x * cam_sens
	$Paraglider.rotation.x -= direction.y * cam_sens
	$Paraglider.rotation.x = clamp($Paraglider.rotation.x, deg_to_rad(cam_min_angle), deg_to_rad(cam_max_angle))

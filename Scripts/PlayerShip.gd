extends KinematicBody2D

onready var globals = get_node("/root/Globals")

const PREDICTION_STEPS = 10
enum { ACTIVE, IDLE, SELECTED }
const MAX_ACCEL = 100
const SHIFT_SPEED = 3
const COLLISION_BOUNCE_FACTOR = .8

var velocity = Vector2(0,0)
var acceleration = Vector2(0,0)
var rotation_speed = 60
var desired_angle = 0
var state = IDLE

func _ready():
	add_to_group(globals.SIMULATED)
	add_to_group(globals.PLAYER_GROUP)
	_predict_path()

# recieve group calls
func sim_start():
	$underglow.visible = false
	_clear_accel()
	_clear_path()
	_clear_angle()
	state = ACTIVE
	
func sim_end():
	state = IDLE
	acceleration = Vector2(0,0)
	_predict_path()
	_show_angle()
	
func select(add = false):
	if state == ACTIVE:
		return
	if !add:
		get_tree().call_group(globals.PLAYER_GROUP, 'new_ship_selected', get_instance_id())
	state = SELECTED
	$underglow.visible = true
	_show_accel()

func new_ship_selected(id):
	if state == ACTIVE:
		return
	if get_instance_id() != id:
		_clear_accel()
		state = IDLE
		$underglow.visible = false

func is_selected():
	return state == SELECTED

func get_hit(id, impact_velocity):
	if get_instance_id() == id:
		velocity += impact_velocity * COLLISION_BOUNCE_FACTOR

#processes
func _process(_delta):
	match state:
		IDLE:
			_idle_process()
		SELECTED:
			_selected_process()
		ACTIVE:
			_active_process()
		

func _physics_process(delta):
	if state == ACTIVE:
		# Velocity
		velocity += acceleration * delta
		velocity = move_and_slide(velocity)
		if get_slide_count() > 0:
			var collision = get_slide_collision(0)
			var relative_velocity = velocity - collision.collider_velocity
			var impact_vel = collision.normal * relative_velocity.length() * COLLISION_BOUNCE_FACTOR
			get_tree().call_group(globals.SIMULATED, "get_hit", collision.collider_id, impact_vel * -1)
			velocity += impact_vel * COLLISION_BOUNCE_FACTOR
		
		if abs(velocity.length_squared()) < 1:
			velocity = Vector2(0,0)
		# Angle
		if abs(desired_angle - $Sprite.rotation_degrees) < (rotation_speed * delta):
			$Sprite.rotation_degrees = desired_angle
		elif _right_turn_needed() > _left_turn_needed():
			$Sprite.rotation_degrees += rotation_speed * delta
			if $Sprite.rotation_degrees > 360:
				$Sprite.rotation_degrees -= 360
		elif _left_turn_needed() > _right_turn_needed():
			$Sprite.rotation_degrees -= rotation_speed * delta
			if $Sprite.rotation_degrees < 0:
				$Sprite.rotation_degrees += 360


# State funcs
func _idle_process():
	pass

func _selected_process():
	_selected_input()

func _active_process():
	pass

#Helpers
func _left_turn_needed():
	if desired_angle == $Sprite.rotation_degrees:
		return 0
	elif $Sprite.rotation_degrees > desired_angle:
		return $Sprite.rotation_degrees - desired_angle
	else:
		return 360 - desired_angle + $Sprite.rotation_degrees

func _right_turn_needed():
	if desired_angle == $Sprite.rotation_degrees:
		return 0
	elif desired_angle > $Sprite.rotation_degrees:
		return desired_angle - $Sprite.rotation_degrees
	else:
		return 360 - $Sprite.rotation_degrees + desired_angle

func _predict_path():
	var p_velocity = velocity
	var p_position = Vector2(0,0)
	var delta = float(1) / PREDICTION_STEPS
	
	$PathPredictor.clear_points()
	$PathPredictor.add_point(p_position)

	for i in PREDICTION_STEPS:
		p_velocity += acceleration * delta
		p_position += p_velocity * delta
		$PathPredictor.add_point(p_position)

func _clear_path():
	$PathPredictor.clear_points()

func _show_accel():
	$AccelIndicator.clear_points()
	$AccelIndicator.add_point(Vector2(0,0))
	$AccelIndicator.add_point(acceleration)

func _clear_accel():
	$AccelIndicator.clear_points()
	
func _show_angle():
	if desired_angle - 180 != $Sprite.rotation_degrees:
		print(desired_angle, ": ", $Sprite.rotation_degrees)
		$AngleIndicator.clear_points()
		$AngleIndicator.add_point(Vector2(0, 30).rotated(deg2rad(desired_angle) - rotation))
		$AngleIndicator.add_point(Vector2(0, 35).rotated(deg2rad(desired_angle) - rotation))

func _clear_angle():
	$AngleIndicator.clear_points()

func _selected_input():
	var temp_accel = acceleration
	var temp_angle = desired_angle
	
	if Input.is_action_pressed("ship_up"):
		temp_accel.y -= SHIFT_SPEED
	if Input.is_action_pressed("ship_down"):
		temp_accel.y += SHIFT_SPEED
	if Input.is_action_pressed("ship_left"):
		temp_accel.x -= SHIFT_SPEED
	if Input.is_action_pressed("ship_right"):
		temp_accel.x += SHIFT_SPEED

	if Input.is_action_pressed("ship_rotate_right"):
		temp_angle = (temp_angle + SHIFT_SPEED) % 360
	if Input.is_action_pressed("ship_rotate_left"):
		temp_angle -= SHIFT_SPEED
		if temp_angle < 0:
			temp_angle = 360 + temp_angle

	if acceleration != temp_accel:
		acceleration = temp_accel.clamped(MAX_ACCEL)
		_predict_path()
		_show_accel()
	if desired_angle != temp_angle:
		desired_angle = temp_angle
		_show_angle()

func _on_PlayerShip_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		select(Input.is_action_pressed("ship_add"))

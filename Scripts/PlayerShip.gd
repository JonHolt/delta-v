extends KinematicBody2D

onready var globals = get_node("/root/Globals")

const PREDICTION_STEPS = 10
enum { ACTIVE, IDLE, SELECTED }
const MAX_ACCEL = 100
const SHIFT_SPEED = 5

var velocity = Vector2(0,0)
var acceleration = Vector2(0,0)
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
	state = ACTIVE
	
func sim_end():
	state = IDLE
	acceleration = Vector2(0,0)
	_predict_path()	
	
func select():
	if state == ACTIVE:
		return
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

#processes
func _process(delta):
	match state:
		IDLE:
			_idle_process()
		SELECTED:
			_selected_process()
		ACTIVE:
			_active_process()
		

func _physics_process(delta):
	if state == ACTIVE:
		velocity += acceleration * delta
		velocity = move_and_slide(velocity)
		if abs(velocity.length_squared()) < 1:
			velocity = Vector2(0,0)

# State funcs
func _idle_process():
	pass

func _selected_process():
	_selected_input()

func _active_process():
	pass

#Helpers
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

func _selected_input():
	var temp_accel = acceleration
	if Input.is_action_pressed("ship_up"):
		temp_accel.y -= SHIFT_SPEED
	if Input.is_action_pressed("ship_down"):
		temp_accel.y += SHIFT_SPEED
	if Input.is_action_pressed("ship_left"):
		temp_accel.x -= SHIFT_SPEED
	if Input.is_action_pressed("ship_right"):
		temp_accel.x += SHIFT_SPEED
	if acceleration != temp_accel:
		acceleration = temp_accel.clamped(MAX_ACCEL)
		_predict_path()
		_show_accel()


func _on_PlayerShip_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		select()

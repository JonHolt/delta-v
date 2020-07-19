extends Node

onready var SIM_GROUP = get_node("/root/Globals").SIMULATED
onready var PLAYER_GROUP = get_node("/root/Globals").PLAYER_GROUP
export var step_time = 1

func _ready():
	$Timer.wait_time = step_time

func _process(delta):
	if Input.is_action_just_pressed("commit"):
		get_tree().call_group(SIM_GROUP, "sim_start")
		$Timer.start()
	if Input.is_action_just_pressed("ship_cycle"):
		_cycle_forward()
	if Input.is_action_just_pressed("ship_cycle_back"):
		_cycle_back()


func _on_Timer_timeout():
	 get_tree().call_group(SIM_GROUP, "sim_end")

#Helpers
func _cycle_forward():
	var ships = get_tree().get_nodes_in_group(PLAYER_GROUP)
	var didShift = false
	for i in ships.size():
		if !didShift && ships[i].is_selected():
			var next = ships[(i + 1) % ships.size()]
			next.select()
			get_tree().call_group(PLAYER_GROUP, "new_ship_selected", next.get_instance_id())
			didShift = true
	if !didShift:
		ships[0].select()

func _cycle_back():
	var ships = get_tree().get_nodes_in_group(PLAYER_GROUP)
	var didShift = false
	for i in ships.size():
		if !didShift && ships[i].is_selected():
			var nextidx = i - 1
			if i < 0:
				i = ships.size() - 1
			var next = ships[nextidx]
			next.select()
			get_tree().call_group(PLAYER_GROUP, "new_ship_selected", next.get_instance_id())
			didShift = true
	if !didShift:
		ships[0].select()

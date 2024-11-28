extends CanvasLayer

var player_dash_count = 0
var player_dash_count_max = 0
var player_dash_recharge_percentage = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_player_position_y_changed(newValue):
	$HBoxContainer/DepthMeter/Label.set_text(str(int(round(newValue))) + "M")


func _on_player_dash_count_changed(value):
	var dashes_children = $DashesContainer.get_children()
	
	for i in dashes_children.size():
		if i < value:
			dashes_children[i].set_value(1)
		else:
			dashes_children[i].set_value(0)
	
	player_dash_count = value


func _on_player_dash_recharge_time_changed(value):
	var empty_dash_index = 0;
	if player_dash_count < player_dash_count_max:
		empty_dash_index = player_dash_count
	else:
		empty_dash_index = player_dash_count - 1
		
	var dash = $DashesContainer.get_child(empty_dash_index)
	player_dash_recharge_percentage = value
	dash.set_value(player_dash_recharge_percentage)


func _on_player_dash_count_max_changed(value):
	var difference = abs(player_dash_count_max - value)
	if player_dash_count_max > value:
		var dashes_children = $DashesContainer.get_children()
		for n in difference:
			dashes_children[dashes_children.size() - 1].queue_free()
	if player_dash_count_max < value:
		for n in difference:
			var dashes_children = $DashesContainer.get_children()
			var dash = load("res://ui/player_game_ui/Dash.tscn").instantiate()
			if dashes_children.size():
				dash.position.x = dashes_children[dashes_children.size() - 1].position.x + 100
			else:
				dash.position.x = 100
			dash.set_value(1.0)
			$DashesContainer.add_child(dash)
	
	player_dash_count_max = value


func _on_player_glider_active_changed(v):
	if v:
		$Test/isGliderActive.text = "glider on"
	else:
		$Test/isGliderActive.text = "glider off"

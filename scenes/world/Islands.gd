extends Node3D

@onready var player = $"../Player"

# Scenes
var island_test = preload("res://entities/islands/common_1.tscn")

# Variables
var islands = []
@export var cooldown_time = 0.5
var cooldown_active = false
@export var distance_between = 1000
@export var margin_between = 200

func _on_player_position_changed(player_pos):
	if cooldown_active:
		return
	
	# Activate cooldown to prevent this function from running every render
	cooldown_active = true
	$Cooldown.start(cooldown_time)
		
	var section_x = round(player_pos.x / distance_between)
	var section_z = round(player_pos.z / distance_between)
	var section_y = abs(round(player_pos.y / distance_between)) # Turn positive due to array index
	
	var boxes_to_check = [
		# Check section_y
		{"x": section_x - 1, "y": section_y, "z": section_z - 1},
		{"x": section_x, "y": section_y, "z": section_z - 1},
		{"x": section_x + 1, "y": section_y, "z": section_z - 1},
		
		{"x": section_x - 1, "y": section_y, "z": section_z},
		{"x": section_x, "y": section_y, "z": section_z},
		{"x": section_x + 1, "y": section_y, "z": section_z},
		
		{"x": section_x - 1, "y": section_y, "z": section_z + 1},
		{"x": section_x, "y": section_y, "z": section_z + 1},
		{"x": section_x + 1, "y": section_y, "z": section_z + 1},
			
		# Check section_y + 1
		{"x": section_x - 1, "y": section_y + 1, "z": section_z - 1},
		{"x": section_x, "y": section_y + 1, "z": section_z - 1},
		{"x": section_x + 1, "y": section_y + 1, "z": section_z - 1},
		
		{"x": section_x - 1, "y": section_y + 1, "z": section_z},
		{"x": section_x, "y": section_y + 1, "z": section_z},
		{"x": section_x + 1, "y": section_y + 1, "z": section_z},
		
		{"x": section_x - 1, "y": section_y + 1, "z": section_z + 1},
		{"x": section_x, "y": section_y + 1, "z": section_z + 1},
		{"x": section_x + 1, "y": section_y + 1, "z": section_z + 1},
	]
	
	for box in boxes_to_check:
		# Check if island exist in current box
		var island_exists = false
		if islands.size() <= box.y:
			islands.push_back([])
			# Remove upper islands
			for island in islands[section_y - 1]:
				remove_child(island.ref)
		if islands[box.y].size() > 0:
			for island in islands[box.y]:
				if box.x == island.section_x and box.z == island.section_z:
					island_exists = true
					continue
		# Create island
		if !island_exists:
			var island = island_test.instantiate()
			var island_info = {
				"section_x": box.x,
				"section_y": box.y,
				"section_z": box.z,
				"pos": calculate_island_position(box),
				"ref": island
			}
			
			islands[box.y].push_back(island_info)
			island.position = island_info.pos
			island.scale = Vector3(50,50,50)
			island.rotation.y = randf_range(0, 365)
			add_child(island)

func calculate_island_position(box):
	var pos = Vector3(round(box.x * distance_between), round(-box.y * distance_between), round(box.z * distance_between))
	var margin = (distance_between / 2) - margin_between
	
	pos.x = randf_range((pos.x - margin), (pos.x + margin))
	pos.y = randf_range((pos.y - margin), (pos.y + margin))
	pos.z = randf_range((pos.z + margin), (pos.z - margin))
		
	return pos

func _on_cooldown_timeout():
	cooldown_active = false

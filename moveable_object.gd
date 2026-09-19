extends Node2D

@onready var map: TileMapLayer = get_parent()
@onready var cell_position: Vector2i = map.local_to_map(position)
@onready var button: Button = $"../../Control/Button"

@onready var original_position: Vector2i = cell_position;

var tween: Tween;
var use_tween_animation: bool = true

func _ready() -> void:
	button.pressed.connect(_on_pressed)

# TEMPORARY IMPLEMENTATION OF RESET BUTTON
# REMOVE THIS!!!!!!!!!!!!!!!!!!!!!!
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reset"):
		cell_position = original_position;
		position = map.map_to_local(cell_position);

func move_to(cell: Vector2i):
	# print(cell)
	var distance = (cell - cell_position).length();
	var tween_time = 0.07 * distance;
	
	cell_position = cell
	
	if use_tween_animation:
		if tween:
			tween.kill()
		tween = create_tween()
		tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
		tween.tween_property(self, "position", map.map_to_local(cell_position), tween_time);
	else:
		position = map.map_to_local(cell_position)
	#return true
func switch_animation() -> void:
	if use_tween_animation:
		use_tween_animation = false
	else:
		use_tween_animation = true


func is_wall(cell: Vector2i) -> bool:
	var data := map.get_cell_tile_data(cell)
	
	if not data:
		return false
	return data.get_custom_data("is_wall")
	
func get_projectile(cell: Vector2i) -> Projectile:
	for projectile in get_tree().get_nodes_in_group(&"projectile"):
		if projectile.cell_position == cell:
			return projectile
	return null

func _on_pressed() -> void:
	switch_animation()

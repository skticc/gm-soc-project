extends "res://moveable_object.gd"
class_name Player

signal player_move

const MOVE_DIRECTIONS: Dictionary = {
	"up": Vector2i(0, -1),
	"down": Vector2i(0, 1),
	"left": Vector2i(-1, 0),
	"right": Vector2i(1, 0)
}

var step_len := 1
var has_superpower := false

# Timer that handles automatic movement
@onready var automove_timer: Timer = $AutoMove;

# Timer that allows the player to buffer the last input
@onready var move_buffer: Timer = $MoveBuffer;

# Array of buffered inputs processed in a queue
var buffered_input: Array[Vector2i] = [];

func _ready() -> void:
	super._ready()

	GlobalSignal.on_red_tile.connect(_on_red_tile)
	GlobalSignal.on_green_tile.connect(_on_green_tile)

func _input(event: InputEvent) -> void:
	_receive_move_input(event);
	super._input(event);

func _physics_process(delta: float) -> void:
	if (!tween or !tween.is_running()):
		if (len(buffered_input) > 0):
			automove_timer.start();
			
			_move(buffered_input[0]);
			
			buffered_input.pop_front();
			
		_receive_automove_input();

func _process(delta: float) -> void:
	$Sprite2D.scale = $Sprite2D.scale.lerp(Vector2(1,1), 0.26);

func _move(dir: Vector2i) -> void:
	player_move.emit();
	
	var dest: Vector2i = cell_position + (dir * step_len);
	
	if (is_wall(dest) or !_check_projectile(dir, dest)):
		return;
	
	move_to(dest);
	
	has_superpower = false;
	step_len = 1;
	
	if (abs(dir.x) > 0):
		$Sprite2D.flip_h = (dir.x < 0);
		
		$Sprite2D.scale.x = 2;
		$Sprite2D.scale.y = 0.5;
	else:
		$Sprite2D.scale.y = 2;
		$Sprite2D.scale.x = 0.5;

# Checks if there is a projectile at the player destination and attempts to
# push it if there is.
#
# Return value: True if successful, False if not
func _check_projectile(dir: Vector2i, dest: Vector2i) -> bool:
	var projectile := get_projectile(dest)
	if projectile:
		var projectile_dest
		if has_superpower:
			projectile_dest = _find_superpower_dest(dest, dir);
		else:
			projectile_dest = dest + dir
		if is_wall(projectile_dest) or get_projectile(projectile_dest):
			return false;
		projectile.move_to(projectile_dest)

	return true;

func _receive_move_input(event: InputEvent) -> void:
	var move_direction: Vector2i = Vector2i.ZERO;
	
	for direction in MOVE_DIRECTIONS:
		if event.is_action_pressed(direction):
			buffered_input.append(MOVE_DIRECTIONS[direction]);
			move_buffer.start();

func _receive_automove_input() -> void:
	var move_direction: Vector2i = Vector2i.ZERO;
	
	for direction in MOVE_DIRECTIONS:
		if (Input.is_action_pressed(direction) && automove_timer.is_stopped()):
			buffered_input.append(MOVE_DIRECTIONS[direction]);
			move_buffer.start();

func _on_red_tile() -> void:
	step_len = 2
	
func _on_green_tile() -> void:
	has_superpower = true
	
func get_player_position() -> Vector2:
	return position
	
func _find_superpower_dest(cell_pos: Vector2i, dir: Vector2i) -> Vector2i:
	var dest := cell_pos + dir
	while not is_wall(dest) and not get_projectile(dest):
		dest += dir
	dest -= dir
	return dest

func _on_move_buffer_timeout() -> void:
	buffered_input.clear();

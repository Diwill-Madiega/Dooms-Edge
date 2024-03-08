extends Node3D

var game_paused:bool
var current_time = 0
var points = 0
@onready var pauseUI = $PauseUI

func _ready():
	game_paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true

	$StartUI/Blur/HBoxContainer/MarginContainer/JetpackButton.grab_focus()

func _process(delta):
	
	if Input.is_action_just_pressed("pause") and $StartUI.visible == false:
		if not game_paused:
			pauseUI.visible = true
			game_paused = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().paused = true
			$PauseUI/ResumeButton.grab_focus()
			
		else:
			get_tree().paused = false
			pauseUI.visible = false
			game_paused = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
	if not game_paused:
		$UI/Timer.text = str(round_to_dec(current_time, 3))
		current_time+=delta
	
	$UI/Points.text = str(points)

func _on_resume_button_pressed():
	get_tree().paused = false
	pauseUI.visible = false
	game_paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _on_quit_button_pressed():
	get_tree().quit()
	
func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)


func _on_jetpack_button_pressed():
	$player.jetpack_ability = true
	$StartUI.visible = false
	$UI/JetpackBar.visible = true
	_on_resume_button_pressed()

func _on_updraft_button_pressed():
	$player.updraft_ability = true
	$StartUI.visible = false
	_on_resume_button_pressed()

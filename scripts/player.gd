extends CharacterBody3D

@onready var neck = $neck
@onready var head = $neck/head
@onready var eyes = $neck/head/eyes
@onready var standing_collision = $StandingCollision
@onready var crouching_collision = $CrouchingCollision
@onready var ray_cast_3d = $RayCast3D
@onready var camera_3d = $neck/head/eyes/Camera3D
@onready var gun = $neck/head/eyes/hand/gun
@onready var gun_anim = $neck/head/eyes/hand/gun/AnimationPlayer
@onready var gun_barrel = $neck/head/eyes/hand/gun/RayCast3D
@onready var ammo_label = $"../UI/Ammo"

var current_speed = 5.0

var bullet = load("res://scenes/bullet.tscn")
var instance
var current_ammo
const max_ammo = 15

@export var walking_speed = 6.0
@export var sprinting_speed = 11.0
@export var crouching_speed = 4.0

const jump_velocity = 12.0
var updraft_velocity = 24.0
var has_updraft

@export var updraft_ability:bool
@export var jetpack_ability:bool

var jetpack_power = 10.0
var jetpack_max_energy = 100.0
var jetpack_current_energy
var jetpack_recharge_rate = 90.0
var jetpack_drain_rate = 75.0
var can_jetpack:bool=false

const mouse_sens = 0.2
var lerp_speed = 10.0
var air_lerp_speed = 5.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var direction = Vector3.ZERO

var crouching_height = -0.8
var free_look_tilt = 6


var walking = false
var sprinting = false
var crouching = false
var free_looking = false
var sliding = false

var slide_timer = 0.0
var slide_timer_max = 1.0
var slide_vector = Vector2.ZERO
var slide_speed = 15

const head_bobbing_sprinting_speed = 22
const head_bobbing_walking_speed = 14
const head_bobbing_crouching_speed = 10
const head_bobbing_sprinting_intensity = 0.35
const head_bobbing_walking_intensity = 0.2
const head_bobbing_crouching_intensity = 0.1

var head_bobbing_vector = Vector2.ZERO
var head_bobbing_index = 0.0
var head_bobbing_current_intensity = 0.0

var right_horizontal_motion = 0
var right_vertical_motion = 0


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	current_ammo = max_ammo
	jetpack_current_energy = jetpack_max_energy
	$Footstep.play()
	
func _input(event):
	if event is InputEventMouseMotion:
		if free_looking:
			neck.rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
			neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-120), deg_to_rad(120))
		else:	
			rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _physics_process(delta):
	
	if Input.get_joy_axis(0, JOY_AXIS_RIGHT_X) < -0.2 or Input.get_joy_axis(0, JOY_AXIS_RIGHT_X) > 0.2:
		rotation.y -= deg_to_rad( Input.get_joy_axis(0, 2) * 4.3 )
	if Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y) < -0.2 or Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y) > 0.2:
		head.rotation.x -= deg_to_rad( Input.get_joy_axis(0, 3) * 4.3 )
	head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	
	
	if (is_on_floor()):
		has_updraft = true
		can_jetpack = false
	
	ammo_label.text = str(current_ammo)
	
	if position.y < 1:
		get_tree().reload_current_scene()
	
	if Input.is_action_pressed("shoot") and !gun_anim.is_playing() and current_ammo > 0:
		gun_anim.play("shoot")
		current_ammo -= 1
		instance = bullet.instantiate()
		instance.position = gun_barrel.global_position
		instance.transform.basis = gun_barrel.global_transform.basis
		get_parent().add_child(instance)
	if Input.is_action_pressed("reload") and !gun_anim.is_playing() and current_ammo < max_ammo:
			gun_anim.play("reload")
			await get_tree().create_timer(0.25).timeout
			$neck/head/eyes/hand/gun/AudioStreamPlayer3D.playing = true
			await get_tree().create_timer(1).timeout
			current_ammo = max_ammo
			$"../UI/Ammo/AnimationPlayer".play("reloaded")
			
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	if input_dir != Vector2.ZERO and is_on_floor() and !$Footstep.playing:
		$Footstep.play()
	elif (input_dir == Vector2.ZERO or not is_on_floor()) and $Footstep.playing:
		$Footstep.stop()
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	if is_on_floor() and (Input.is_action_pressed("crouch") or sliding):
		current_speed = lerp(current_speed, crouching_speed, delta * lerp_speed)
		head.position.y = lerp(head.position.y, crouching_height, delta * lerp_speed)
		standing_collision.disabled = true
		crouching_collision.disabled = false
		
		if sprinting and input_dir != Vector2.ZERO:
			sliding = true
			free_looking = true
			slide_timer = slide_timer_max
			slide_vector = input_dir
		
		walking = false
		sprinting = false
		crouching = true
		
	elif !ray_cast_3d.is_colliding():
		head.position.y = lerp(head.position.y, 0.0, delta * lerp_speed)
		standing_collision.disabled = false
		crouching_collision.disabled = true
		if Input.is_action_pressed("sprint"):
			current_speed =  lerp(current_speed, sprinting_speed, delta * lerp_speed)
			walking = false
			sprinting = true
			crouching = false
		else:
			current_speed =  lerp(current_speed, walking_speed, delta * lerp_speed)
			walking = true
			sprinting = false
			crouching = false
			
	if Input.is_action_pressed("free_look") or sliding:
		free_looking = true
		if sliding:
			camera_3d.rotation.z = lerp(camera_3d.rotation.z, -deg_to_rad(7.0), delta * lerp_speed)
		else:
			camera_3d.rotation.z = -deg_to_rad(neck.rotation.y*free_look_tilt)
	else:
		free_looking = false
		camera_3d.rotation.z = lerp(camera_3d.rotation.z, 0.0, delta*lerp_speed)
		neck.rotation.y = lerp(neck.rotation.y, 0.0, delta*lerp_speed)
		
	if sliding:
		slide_timer -= delta
		if slide_timer <=0:
			sliding = false
			free_looking = false
			
			
	if sprinting:
		head_bobbing_current_intensity = head_bobbing_sprinting_intensity
		head_bobbing_index += head_bobbing_sprinting_speed * delta
	elif walking:
			head_bobbing_current_intensity = head_bobbing_walking_intensity
			head_bobbing_index += head_bobbing_walking_speed * delta
	elif crouching:
		head_bobbing_current_intensity = head_bobbing_crouching_intensity
		head_bobbing_index += head_bobbing_crouching_speed * delta
	
	if is_on_floor() and !sliding and input_dir!=Vector2.ZERO:
		head_bobbing_vector.y = sin(head_bobbing_index)
		head_bobbing_vector.x = sin(head_bobbing_index / 2) + 0.5
		
		eyes.position.y = lerp(eyes.position.y, head_bobbing_vector.y*(head_bobbing_current_intensity/2.0),delta * lerp_speed)
		eyes.position.x = lerp(eyes.position.x, head_bobbing_vector.x*head_bobbing_current_intensity,delta * lerp_speed)
		
		gun.position.y = lerp(gun.position.y, head_bobbing_vector.y*(head_bobbing_current_intensity/4.0),delta * lerp_speed)
		gun.position.x = lerp(gun.position.x, head_bobbing_vector.x*(head_bobbing_current_intensity/2.0),delta * lerp_speed)
		
	else:
		eyes.position.y = lerp(eyes.position.y, 0.0,delta * lerp_speed)
		eyes.position.x = lerp(eyes.position.x, 0.0,delta * lerp_speed)
		
		gun.position.y = lerp(eyes.position.y, 0.0,delta * lerp_speed)
		gun.position.x = lerp(eyes.position.x, 0.0,delta * lerp_speed)
	
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept"):
		
		if not is_on_floor():
			can_jetpack = true
		
		if is_on_floor():
			velocity.y = jump_velocity
		elif has_updraft and updraft_ability:
			has_updraft = false
			velocity.y = updraft_velocity		
		sliding = false
		
	$"../UI/JetpackBar".value = (jetpack_current_energy/jetpack_max_energy)*100
	
	if Input.is_action_pressed("ui_accept") and not is_on_floor() and jetpack_current_energy > 0 and can_jetpack and jetpack_ability:
		velocity.y = lerp(velocity.y,jetpack_power, air_lerp_speed*delta)

		jetpack_current_energy -= delta * jetpack_drain_rate
		
	if (is_on_floor() and jetpack_current_energy<jetpack_max_energy):
		jetpack_current_energy += delta * jetpack_recharge_rate

	if is_on_floor():
		direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*lerp_speed)
	else:
		if input_dir != Vector2.ZERO:
			direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*air_lerp_speed)
	if sliding:
		direction = (transform.basis * Vector3(slide_vector.x, 0 , slide_vector.y)).normalized()
		current_speed = (slide_timer+0.1) * slide_speed
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
	

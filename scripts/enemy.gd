extends CharacterBody3D

@onready var particles = $CollisionShape3D/GPUParticles3D

@export var max_health:int
@export var points:int

var current_health
var rng = RandomNumberGenerator.new()

func _ready():
	current_health = max_health
	if ($AnimationPlayer != null):
		$AnimationPlayer.play("idle")
		
func take_damage():
	current_health-=1
	
	if current_health > 0:
		$AudioStreamPlayer3D.pitch_scale = rng.randf_range(0.75, 1.25)
		$AudioStreamPlayer3D.playing = true
		for i in range(3):
			$BotDrone.visible = false
			await get_tree().create_timer(0.02).timeout
			$BotDrone.visible = true
			await get_tree().create_timer(0.02).timeout
	else:
		$DeathSound.pitch_scale = rng.randf_range(0.75, 1.25)
		$DeathSound.playing = true
		get_node("../../").points += points
		particles.emitting = true
		$BotDrone.visible = false
		await get_tree().create_timer(1.0).timeout
		queue_free()
	

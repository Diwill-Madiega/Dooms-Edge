extends Area3D

const speed = 60

@onready var mesh = $MeshInstance3D
@onready var ray_cast_3d = $RayCast3D
@onready var particles = $GPUParticles3D

var rng = RandomNumberGenerator.new()


func _ready():
	$AudioStreamPlayer3D.pitch_scale = rng.randf_range(0.75, 1.25)

func _process(delta):
	position += transform.basis * Vector3(0,0,-speed) * delta
	if ray_cast_3d.is_colliding():
		mesh.visible = false
		particles.emitting = true
		await get_tree().create_timer(1.0).timeout
		queue_free()
		
func _on_body_entered(body):
		if body.is_in_group("Enemy") and body.current_health > 0:
			body.take_damage()

func _on_timer_timeout():
		queue_free()

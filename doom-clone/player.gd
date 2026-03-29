# Player.gd
extends CharacterBody3D

@onready var health_label: RichTextLabel = get_tree().current_scene.get_node("UI/HealthLabel")
@export var max_health: int = 100
var health: int = max_health

# UI elements
@export var hud_height: float = 230.0
@onready var crosshair: ColorRect = $CanvasLayer/Crosshair
@onready var dmg_overlay: ColorRect = $CanvasLayer/DamageOverlay

@onready var input_handler = $InputHandler
@onready var player_movement = $PlayerMovement

# Hand sway variables
var gun_base_pos: Vector2
var sway_time: float = 0.0
@export var sway_speed: float = 15.0
@export var sway_amount: float = 3.0

# Screen shake
var shake_duration: float = 0.0
var shake_intensity: float = 0.0
var shake_time: float = 0.0

const MOUSE_SENSITIVITY = 0.3

# Nodes
@onready var animated_sprite_2d = $CanvasLayer/GunBase/GunAnimations
@onready var kick_animation = $CanvasLayer/KickBase/KickAnimation
@onready var ray_cast_3d = $RayCast3D
@onready var shoot_sound: AudioStreamPlayer3D = $ShootSound
@onready var dmg_sound_1: AudioStreamPlayer3D = $DamageSound1
@onready var dmg_sound_2: AudioStreamPlayer3D = $DamageSound2
@onready var player_death_sound: AudioStreamPlayer3D = $PlayerDeathSound
@onready var camera = $Camera3D

# Gameplay state
var can_shoot = true
var dead = false
@export var shoot_damage = 34

# Called when the game starts
func _ready() -> void:
	gun_base_pos = $CanvasLayer/GunBase.position
	input_handler.look_input.connect(_on_look_input)
	input_handler.action_triggered.connect(_on_action_triggered)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	animated_sprite_2d.animation_finished.connect(shoot_animation_done)
	$CanvasLayer/DeathScreen/Panel/Button.button_up.connect(restart)

	# Ensure overlay doesn't block input
	dmg_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dmg_overlay.visible = false

	# Center the crosshair
	if crosshair:
		var gameplay_center = get_gameplay_center()
		crosshair.position = gameplay_center - (crosshair.size / 2)

func _on_look_input(delta_x: float, delta_y: float) -> void:
	if dead:
		return

	rotation_degrees.y -= delta_x * MOUSE_SENSITIVITY
	var pitch = camera.rotation_degrees.x - delta_y * MOUSE_SENSITIVITY
	camera.rotation_degrees.x = clamp(pitch, -90, 90)

func _on_action_triggered(action: String) -> void:
	# Allow restart and exit even when dead
	if dead and action not in ["restart", "exit"]:
		return

	match action:
		"shoot": shoot()
		"kick": kick()
		"slide": player_movement.try_slide()
		"restart": restart()
		"exit": get_tree().quit()

func _process(_delta: float) -> void:
	if dead:
		return

	# Gun sway
	if velocity.length() > 0.1:
		sway_time += _delta * sway_speed
		var sway_x = sin(sway_time) * sway_amount
		var sway_y = abs(cos(sway_time * 0.5)) * (sway_amount * 8)
		$CanvasLayer/GunBase.position = gun_base_pos + Vector2(sway_x, sway_y)
	else:
		sway_time = 0.0
		$CanvasLayer/GunBase.position = gun_base_pos

	# Screen shake
	if shake_duration > 0:
		shake_duration -= _delta
		shake_time += _delta * 50
		var shake_x = randf_range(-1, 1) * shake_intensity * (shake_duration / 0.15)
		var shake_y = randf_range(-1, 1) * shake_intensity * (shake_duration / 0.15)
		camera.h_offset = shake_x
		camera.v_offset = shake_y
	else:
		camera.h_offset = 0
		camera.v_offset = 0

func _physics_process(_delta: float) -> void:
	if dead:
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	velocity = player_movement.process_movement(_delta, velocity)
	move_and_slide()

func restart():
	dmg_overlay.visible = false
	get_tree().reload_current_scene()

func get_gameplay_center() -> Vector2:
	var viewport_size = get_viewport().get_visible_rect().size
	var gameplay_height = viewport_size.y - hud_height
	var center_x = viewport_size.x / 2.0
	var center_y = gameplay_height / 2.0
	return Vector2(center_x, center_y)

func shoot():
	if !can_shoot or dead:
		return

	can_shoot = false
	animated_sprite_2d.stop()
	animated_sprite_2d.play("shoot")
	shoot_sound.play()

	var gameplay_center = get_gameplay_center()
	var from = camera.project_ray_origin(gameplay_center)
	var to = from + camera.project_ray_normal(gameplay_center) * 1000

	var ray_params = PhysicsRayQueryParameters3D.new()
	ray_params.from = from
	ray_params.to = to

	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(ray_params)

	if result:
		var target = result.collider
		var hit_position = result.position
		if target.has_method("take_damage"):
			target.take_damage(shoot_damage, hit_position)

	await get_tree().create_timer(0.25).timeout
	can_shoot = true

func shoot_animation_done():
	can_shoot = true

func trigger_shake(duration: float, intensity: float):
	shake_duration = duration
	shake_intensity = intensity
	shake_time = 0.0

func kick():
	if !can_shoot:
		return

	velocity = Vector3.ZERO
	can_shoot = false
	$CanvasLayer/KickBase.visible = true
	kick_animation.play("kick")

	$KickArea3D.monitoring = true
	await kick_animation.animation_finished

	$CanvasLayer/KickBase.visible = false
	$KickArea3D.monitoring = false
	can_shoot = true

func _on_kick_area_3d_body_entered(body):
	if body == self:
		return
	if body.has_method("take_damage"):
		var kick_origin = $KickArea3D.global_position
		var direction = (body.global_position - kick_origin).normalized()
		body.take_damage(25, kick_origin, direction)
		trigger_shake(0.15, 0.3)

# --- Damage + Death handling ---
func take_damage(amount: int, hit_position: Vector3 = Vector3.ZERO, knockback_dir: Vector3 = Vector3.ZERO):
	if dead:
		return

	health -= amount
	health = clamp(health, 0, max_health)
	health_label.text = str(health) + "/" + str(max_health)

	# Flash red overlay for nonfatal damage
	if health > 0:
		var damage_sounds = [dmg_sound_1, dmg_sound_2]
		damage_sounds[randi() % 2].play()

		dmg_overlay.visible = true
		await get_tree().create_timer(0.2).timeout
		dmg_overlay.visible = false
	else:
		# Death logic
		player_death_sound.play()
		kill()

	if knockback_dir != Vector3.ZERO:
		velocity += knockback_dir * 5.0

func kill():
	dead = true
	dmg_overlay.visible = true  # Stays on during death
	$CanvasLayer/DeathScreen.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

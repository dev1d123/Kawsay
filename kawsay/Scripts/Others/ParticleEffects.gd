class_name ParticleEffects

## Partículas al recoger un powerup del mapa
static func spawn_powerup_pickup_particles(parent: Node, screen_pos: Vector2) -> void:
	if not is_instance_valid(parent) or not parent.is_inside_tree():
		return
		
	var particles := CPUParticles2D.new()
	particles.amount = 35
	particles.lifetime = 0.75
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.spread = 180.0
	particles.gravity = Vector2(0, 140)
	particles.initial_velocity_min = 120.0
	particles.initial_velocity_max = 220.0
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0
	
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.9, 0.3, 1.0))
	gradient.add_point(0.5, Color(1.0, 0.5, 0.1, 1.0))
	gradient.set_color(1, Color(0.9, 0.2, 0.0, 0.0))
	particles.color_ramp = gradient
	
	particles.z_index = 25
	parent.add_child(particles)
	particles.global_position = screen_pos
	particles.emitting = true
	
	var tree = parent.get_tree()
	if tree:
		var timer = tree.create_timer(1.0)
		timer.timeout.connect(func():
			if is_instance_valid(particles):
				particles.queue_free()
		)

## Partículas de bola de fuego parabólica y su posterior explosión
static func launch_fireball(parent: Node, start_world: Vector2, target_world: Vector2) -> void:
	var fireball_node := Node2D.new()
	fireball_node.position = start_world
	parent.add_child(fireball_node)
	
	# 1. Núcleo denso de partículas (sin sprites estáticos)
	var core_particles := CPUParticles2D.new()
	core_particles.amount = 50
	core_particles.lifetime = 0.25
	core_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	core_particles.emission_sphere_radius = 4.0
	core_particles.spread = 180.0
	core_particles.gravity = Vector2.ZERO
	core_particles.initial_velocity_min = 10.0
	core_particles.initial_velocity_max = 35.0
	core_particles.scale_amount_min = 8.0
	core_particles.scale_amount_max = 16.0
	
	var core_gradient := Gradient.new()
	core_gradient.set_color(0, Color(2.5, 2.5, 2.0, 1.0))
	core_gradient.add_point(0.5, Color(1.0, 0.7, 0.1, 0.9))
	core_gradient.set_color(1, Color(1.0, 0.3, 0.0, 0.0))
	core_particles.color_ramp = core_gradient
	core_particles.z_index = 22
	fireball_node.add_child(core_particles)
	
	# 2. Cola ardiente de fuego y humo
	var trail_particles := CPUParticles2D.new()
	trail_particles.amount = 60
	trail_particles.lifetime = 0.5
	trail_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	trail_particles.emission_sphere_radius = 7.0
	trail_particles.spread = 45.0
	trail_particles.gravity = Vector2(0, -60)
	trail_particles.initial_velocity_min = 30.0
	trail_particles.initial_velocity_max = 80.0
	trail_particles.scale_amount_min = 6.0
	trail_particles.scale_amount_max = 18.0
	
	var trail_gradient := Gradient.new()
	trail_gradient.set_color(0, Color(1.0, 0.9, 0.3, 1.0))
	trail_gradient.add_point(0.3, Color(1.0, 0.4, 0.0, 0.9))
	trail_gradient.add_point(0.7, Color(0.7, 0.1, 0.0, 0.5))
	trail_gradient.set_color(1, Color(0.12, 0.12, 0.12, 0.0))
	trail_particles.color_ramp = trail_gradient
	trail_particles.z_index = 20
	fireball_node.add_child(trail_particles)
	
	# 3. Chispas voladoras al frente
	var spark_particles := CPUParticles2D.new()
	spark_particles.amount = 25
	spark_particles.lifetime = 0.35
	spark_particles.spread = 75.0
	spark_particles.gravity = Vector2(0, 30)
	spark_particles.initial_velocity_min = 60.0
	spark_particles.initial_velocity_max = 140.0
	spark_particles.scale_amount_min = 2.0
	spark_particles.scale_amount_max = 5.0
	
	var spark_gradient := Gradient.new()
	spark_gradient.set_color(0, Color(1.0, 1.0, 0.6, 1.0))
	spark_gradient.set_color(1, Color(1.0, 0.4, 0.0, 0.0))
	spark_particles.color_ramp = spark_gradient
	spark_particles.z_index = 21
	fireball_node.add_child(spark_particles)
	
	# Parámetros del vuelo parabólico
	var distance = start_world.distance_to(target_world)
	var max_arc_height = clamp(distance * 0.45, 100.0, 260.0)
	var flight_duration = clamp(distance / 450.0, 0.6, 1.2)
	
	var tween = parent.create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(t: float):
		if not is_instance_valid(fireball_node):
			return
		var current_pos = start_world.lerp(target_world, t)
		var arc_y = 4.0 * max_arc_height * t * (1.0 - t)
		var pos_now = Vector2(current_pos.x, current_pos.y - arc_y)
		fireball_node.position = pos_now
		
		var next_t = min(t + 0.02, 1.0)
		var next_pos_base = start_world.lerp(target_world, next_t)
		var next_arc_y = 4.0 * max_arc_height * next_t * (1.0 - next_t)
		var next_pos = Vector2(next_pos_base.x, next_pos_base.y - next_arc_y)
		if pos_now.distance_squared_to(next_pos) > 0.1:
			fireball_node.rotation = (next_pos - pos_now).angle()
	, 0.0, 1.0, flight_duration)
	
	tween.chain().tween_callback(func():
		if is_instance_valid(fireball_node):
			fireball_node.queue_free()
		spawn_fireball_explosion_particles(parent, target_world)
	)

## Explosión de impacto multicapa
static func spawn_fireball_explosion_particles(parent: Node, world_pos: Vector2) -> void:
	var container := Node2D.new()
	container.position = world_pos
	parent.add_child(container)
	
	# Capa 1: Ráfaga de Onda Expansiva (Flash & Sparks)
	var burst := CPUParticles2D.new()
	burst.emitting = false
	burst.one_shot = true
	burst.amount = 80
	burst.lifetime = 0.75
	burst.explosiveness = 0.98
	burst.spread = 180.0
	burst.gravity = Vector2(0, 80)
	burst.initial_velocity_min = 200.0
	burst.initial_velocity_max = 420.0
	burst.scale_amount_min = 6.0
	burst.scale_amount_max = 18.0
	
	var burst_grad := Gradient.new()
	burst_grad.set_color(0, Color(2.5, 2.5, 2.0, 1.0))
	burst_grad.add_point(0.25, Color(1.0, 0.8, 0.2, 1.0))
	burst_grad.add_point(0.65, Color(0.9, 0.25, 0.0, 0.8))
	burst_grad.set_color(1, Color(0.2, 0.05, 0.0, 0.0))
	burst.color_ramp = burst_grad
	burst.z_index = 25
	container.add_child(burst)
	
	# Capa 2: Chispas y Ascuas que vuelan hacia arriba (Embers)
	var embers := CPUParticles2D.new()
	embers.emitting = false
	embers.one_shot = true
	embers.amount = 40
	embers.lifetime = 1.1
	embers.explosiveness = 0.8
	embers.spread = 110.0
	embers.direction = Vector2(0, -1)
	embers.gravity = Vector2(0, 160)
	embers.initial_velocity_min = 140.0
	embers.initial_velocity_max = 280.0
	embers.scale_amount_min = 3.0
	embers.scale_amount_max = 6.0
	
	var embers_grad := Gradient.new()
	embers_grad.set_color(0, Color(1.0, 0.9, 0.4, 1.0))
	embers_grad.add_point(0.5, Color(1.0, 0.4, 0.0, 0.9))
	embers_grad.set_color(1, Color(0.6, 0.1, 0.0, 0.0))
	embers.color_ramp = embers_grad
	embers.z_index = 26
	container.add_child(embers)
	
	# Capa 3: Penacho de Humo Oscuro (Smoke Plume)
	var smoke := CPUParticles2D.new()
	smoke.emitting = false
	smoke.one_shot = true
	smoke.amount = 30
	smoke.lifetime = 1.3
	smoke.explosiveness = 0.75
	smoke.spread = 80.0
	smoke.direction = Vector2(0, -1)
	smoke.gravity = Vector2(0, -90)
	smoke.initial_velocity_min = 40.0
	smoke.initial_velocity_max = 110.0
	smoke.scale_amount_min = 12.0
	smoke.scale_amount_max = 24.0
	
	var smoke_grad := Gradient.new()
	smoke_grad.set_color(0, Color(0.3, 0.3, 0.35, 0.7))
	smoke_grad.add_point(0.5, Color(0.18, 0.18, 0.22, 0.5))
	smoke_grad.set_color(1, Color(0.08, 0.08, 0.1, 0.0))
	smoke.color_ramp = smoke_grad
	smoke.z_index = 24
	container.add_child(smoke)
	
	# Disparar emisión
	burst.emitting = true
	embers.emitting = true
	smoke.emitting = true
	
	# Sonido de explosión
	if parent.get_node_or_null("/root/AudioManager"):
		parent.get_node("/root/AudioManager").play_sfx("explosion")
		
	parent.get_tree().create_timer(1.6).timeout.connect(container.queue_free)

## Animación de martillo golpeando una celda con partículas por cada impacto (5 golpes, ~2 seg)
static func play_hammer_strike(parent: Node, cell_local_pos: Vector2) -> void:
	var container := Node2D.new()
	container.position = cell_local_pos
	container.z_index = 30
	parent.add_child(container)
	
	var hammer_sprite := Sprite2D.new()
	var tex = load("res://Sprites/Icons/hammer.png")
	if tex:
		hammer_sprite.texture = tex
		var target_size = 48.0
		var base_scale = target_size / max(tex.get_width(), tex.get_height())
		hammer_sprite.scale = Vector2(base_scale, base_scale)
	
	hammer_sprite.position = Vector2(20, -35)
	hammer_sprite.rotation_degrees = -45.0
	container.add_child(hammer_sprite)
	
	var total_strikes = 5
	var tween = parent.create_tween()
	
	for i in range(total_strikes):
		# 1. Bajada rápida (Impacto)
		tween.tween_property(hammer_sprite, "rotation_degrees", 35.0, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(hammer_sprite, "position", Vector2(5, 5), 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		
		# 2. Callback de impacto: partículas y sonido
		tween.tween_callback(func():
			_spawn_hammer_impact_particles(container, Vector2.ZERO)
		)
		
		# 3. Subida / Recarga suave
		tween.tween_property(hammer_sprite, "rotation_degrees", -45.0, 0.27).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(hammer_sprite, "position", Vector2(20, -35), 0.27).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Desvanecer al completar los 5 golpes
	tween.tween_property(hammer_sprite, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(container.queue_free)

## Partículas de impacto del martillo (polvo, chispas y esquirlas de piedra)
static func _spawn_hammer_impact_particles(parent: Node, local_offset: Vector2) -> void:
	var sparks := CPUParticles2D.new()
	sparks.position = local_offset
	sparks.emitting = false
	sparks.one_shot = true
	sparks.amount = 35
	sparks.lifetime = 0.45
	sparks.explosiveness = 0.95
	sparks.spread = 180.0
	sparks.gravity = Vector2(0, 120)
	sparks.initial_velocity_min = 120.0
	sparks.initial_velocity_max = 240.0
	sparks.scale_amount_min = 4.0
	sparks.scale_amount_max = 10.0
	
	var spark_grad := Gradient.new()
	spark_grad.set_color(0, Color(1.0, 0.9, 0.4, 1.0))
	spark_grad.add_point(0.4, Color(0.9, 0.5, 0.1, 0.9))
	spark_grad.set_color(1, Color(0.4, 0.4, 0.4, 0.0))
	sparks.color_ramp = spark_grad
	sparks.z_index = 32
	parent.add_child(sparks)
	sparks.emitting = true
	
	var dust := CPUParticles2D.new()
	dust.position = local_offset
	dust.emitting = false
	dust.one_shot = true
	dust.amount = 20
	dust.lifetime = 0.55
	dust.explosiveness = 0.9
	dust.spread = 180.0
	dust.gravity = Vector2(0, 20)
	dust.initial_velocity_min = 60.0
	dust.initial_velocity_max = 130.0
	dust.scale_amount_min = 8.0
	dust.scale_amount_max = 16.0
	
	var dust_grad := Gradient.new()
	dust_grad.set_color(0, Color(0.8, 0.75, 0.65, 0.8))
	dust_grad.set_color(1, Color(0.4, 0.38, 0.35, 0.0))
	dust.color_ramp = dust_grad
	dust.z_index = 31
	parent.add_child(dust)
	dust.emitting = true
	
	# Sonido de martillazo
	if parent.get_node_or_null("/root/AudioManager"):
		parent.get_node("/root/AudioManager").play_sfx("hammer")
		
	parent.get_tree().create_timer(0.65).timeout.connect(sparks.queue_free)
	parent.get_tree().create_timer(0.65).timeout.connect(dust.queue_free)

## Animación de lluvia en una celda considerando perspectiva 3D (duración 3 segundos)
static func play_rain_effect(parent: Node, cell_local_pos: Vector2) -> void:
	var container := Node2D.new()
	container.position = cell_local_pos
	container.z_index = 28
	parent.add_child(container)
	
	# 1. Nube/Bruma de lluvia en la parte superior (elevada en perspectiva 3D sobre la celda)
	var cloud := CPUParticles2D.new()
	cloud.position = Vector2(0, -180)
	cloud.amount = 15
	cloud.lifetime = 1.0
	cloud.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	cloud.emission_rect_extents = Vector2(35, 8)
	cloud.gravity = Vector2(0, -10)
	cloud.initial_velocity_min = 5.0
	cloud.initial_velocity_max = 15.0
	cloud.scale_amount_min = 12.0
	cloud.scale_amount_max = 24.0
	
	var cloud_grad := Gradient.new()
	cloud_grad.set_color(0, Color(0.25, 0.35, 0.45, 0.5))
	cloud_grad.set_color(1, Color(0.15, 0.22, 0.3, 0.0))
	cloud.color_ramp = cloud_grad
	cloud.z_index = 29
	container.add_child(cloud)
	
	# 2. Gotas de lluvia cayendo desde el aire hasta la base 3D de la celda
	var rain_drops := CPUParticles2D.new()
	rain_drops.position = Vector2(5, -180)
	rain_drops.amount = 70
	rain_drops.lifetime = 0.45
	rain_drops.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain_drops.emission_rect_extents = Vector2(35, 4)
	rain_drops.gravity = Vector2(-25, 520)
	rain_drops.scale_amount_min = 2.0
	rain_drops.scale_amount_max = 4.5
	
	var rain_grad := Gradient.new()
	rain_grad.set_color(0, Color(0.7, 0.9, 1.0, 0.9))
	rain_grad.add_point(0.7, Color(0.5, 0.75, 0.95, 0.8))
	rain_grad.set_color(1, Color(0.3, 0.6, 0.85, 0.0))
	rain_drops.color_ramp = rain_grad
	rain_drops.z_index = 28
	container.add_child(rain_drops)
	
	# 3. Salpicaduras de agua rebotando en el plano base hexagonal (3D floor)
	var splashes := CPUParticles2D.new()
	splashes.position = Vector2(0, 5)
	splashes.amount = 35
	splashes.lifetime = 0.35
	splashes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	splashes.emission_rect_extents = Vector2(25, 12)
	splashes.spread = 120.0
	splashes.direction = Vector2(0, -1)
	splashes.gravity = Vector2(0, 160)
	splashes.initial_velocity_min = 40.0
	splashes.initial_velocity_max = 90.0
	splashes.scale_amount_min = 2.0
	splashes.scale_amount_max = 4.0
	
	var splash_grad := Gradient.new()
	splash_grad.set_color(0, Color(0.85, 0.95, 1.0, 0.95))
	splash_grad.set_color(1, Color(0.4, 0.7, 0.9, 0.0))
	splashes.color_ramp = splash_grad
	splashes.z_index = 27
	container.add_child(splashes)
	
	cloud.emitting = true
	rain_drops.emitting = true
	splashes.emitting = true
	
	# Sonido de lluvia
	if parent.get_node_or_null("/root/AudioManager"):
		parent.get_node("/root/AudioManager").play_sfx("rain")
		
	parent.get_tree().create_timer(3.0).timeout.connect(func():
		if is_instance_valid(cloud): cloud.emitting = false
		if is_instance_valid(rain_drops): rain_drops.emitting = false
		if is_instance_valid(splashes): splashes.emitting = false
	)
	
	parent.get_tree().create_timer(3.8).timeout.connect(func():
		if is_instance_valid(container):
			container.queue_free()
	)

## Animación de columna de fuego y brasas en una celda (tecla X)
static func play_fire_effect(parent: Node, cell_local_pos: Vector2) -> void:
	var container := Node2D.new()
	container.position = cell_local_pos
	container.z_index = 28
	parent.add_child(container)

	# 1. Llamas de fuego ascendentes
	var flames := CPUParticles2D.new()
	flames.position = Vector2(0, 10)
	flames.amount = 50
	flames.lifetime = 0.75
	flames.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	flames.emission_rect_extents = Vector2(25, 4)
	flames.direction = Vector2(0, -1)
	flames.spread = 12.0
	flames.gravity = Vector2(0, -220)
	flames.initial_velocity_min = 60.0
	flames.initial_velocity_max = 140.0
	flames.scale_amount_min = 6.0
	flames.scale_amount_max = 14.0

	var flame_grad := Gradient.new()
	flame_grad.set_color(0, Color(2.0, 2.0, 1.5)) # Núcleo blanco brillante
	flame_grad.add_point(0.2, Color(1.0, 0.8, 0.1)) # Amarillo
	flame_grad.add_point(0.5, Color(1.0, 0.4, 0.0)) # Naranja
	flame_grad.add_point(0.8, Color(0.9, 0.15, 0.0)) # Rojo ardiente
	flame_grad.set_color(1, Color(0.2, 0.2, 0.2, 0.0)) # Humo disipándose
	flames.color_ramp = flame_grad
	container.add_child(flames)

	# 2. Humo oscuro denso
	var smoke := CPUParticles2D.new()
	smoke.position = Vector2(0, -20)
	smoke.amount = 30
	smoke.lifetime = 1.0
	smoke.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	smoke.emission_rect_extents = Vector2(20, 6)
	smoke.direction = Vector2(0, -1)
	smoke.spread = 20.0
	smoke.gravity = Vector2(0, -120)
	smoke.initial_velocity_min = 30.0
	smoke.initial_velocity_max = 70.0
	smoke.scale_amount_min = 10.0
	smoke.scale_amount_max = 24.0

	var smoke_grad := Gradient.new()
	smoke_grad.set_color(0, Color(0.25, 0.25, 0.25, 0.7))
	smoke_grad.set_color(1, Color(0.1, 0.1, 0.1, 0.0))
	smoke.color_ramp = smoke_grad
	container.add_child(smoke)

	flames.emitting = true
	smoke.emitting = true

	parent.get_tree().create_timer(2.0).timeout.connect(func():
		if is_instance_valid(flames): flames.emitting = false
		if is_instance_valid(smoke): smoke.emitting = false
	)
	parent.get_tree().create_timer(2.8).timeout.connect(func():
		if is_instance_valid(container):
			container.queue_free()
	)

## Animación de expansión radial de magma fundido (tecla C)
static func play_magma_expansion_effect(parent: Node, cell_local_pos: Vector2) -> void:
	var container := Node2D.new()
	container.position = cell_local_pos
	container.z_index = 27
	parent.add_child(container)

	# 1. Ola radial expansiva de lava fundida
	var magma_wave := CPUParticles2D.new()
	magma_wave.amount = 80
	magma_wave.lifetime = 0.95
	magma_wave.explosiveness = 0.8
	magma_wave.spread = 180.0
	magma_wave.gravity = Vector2.ZERO
	magma_wave.initial_velocity_min = 120.0
	magma_wave.initial_velocity_max = 220.0
	magma_wave.scale_amount_min = 5.0
	magma_wave.scale_amount_max = 11.0

	var magma_grad := Gradient.new()
	magma_grad.set_color(0, Color(2.5, 0.6, 0.1)) # Magma incandescente
	magma_grad.add_point(0.4, Color(1.0, 0.35, 0.0))
	magma_grad.add_point(0.75, Color(0.5, 0.1, 0.0)) # Lava enfriándose
	magma_grad.set_color(1, Color(0.08, 0.08, 0.08, 0.0)) # Ceniza disipada
	magma_wave.color_ramp = magma_grad
	container.add_child(magma_wave)

	# 2. Chispas y brasas que saltan de la expansión
	var embers := CPUParticles2D.new()
	embers.amount = 35
	embers.lifetime = 0.65
	embers.spread = 180.0
	embers.gravity = Vector2(0, -90)
	embers.initial_velocity_min = 80.0
	embers.initial_velocity_max = 160.0
	embers.scale_amount_min = 2.0
	embers.scale_amount_max = 5.0

	var ember_grad := Gradient.new()
	ember_grad.set_color(0, Color(2.0, 0.9, 0.2))
	ember_grad.set_color(1, Color(0.8, 0.2, 0.0, 0.0))
	embers.color_ramp = ember_grad
	container.add_child(embers)

	magma_wave.emitting = true
	embers.emitting = true

	parent.get_tree().create_timer(2.0).timeout.connect(func():
		if is_instance_valid(magma_wave): magma_wave.emitting = false
		if is_instance_valid(embers): embers.emitting = false
	)
	parent.get_tree().create_timer(2.8).timeout.connect(func():
		if is_instance_valid(container):
			container.queue_free()
	)

## Animación festiva de explosión de confeti multicolor (tecla V)
static func play_confetti_effect(parent: Node, cell_local_pos: Vector2) -> void:
	var container := Node2D.new()
	container.position = cell_local_pos + Vector2(0, -40) # Lanzado desde el centro de la celda
	container.z_index = 30
	parent.add_child(container)

	# Colores festivos de confeti
	var colors := [
		Color(0.2, 0.7, 1.0), # Celeste
		Color(1.0, 0.85, 0.1), # Amarillo radiante
		Color(1.0, 0.2, 0.55), # Fucsia/Rosa
		Color(0.3, 0.85, 0.2) # Verde lima
	]

	var emitters: Array[CPUParticles2D] = []

	for c in colors:
		var confetti := CPUParticles2D.new()
		confetti.amount = 22
		confetti.lifetime = 1.6
		confetti.one_shot = true
		confetti.explosiveness = 0.88
		confetti.direction = Vector2(0, -1)
		confetti.spread = 70.0
		confetti.gravity = Vector2(0, 190) # Caída suave
		confetti.initial_velocity_min = 180.0
		confetti.initial_velocity_max = 320.0
		confetti.scale_amount_min = 5.0
		confetti.scale_amount_max = 9.0
		
		# Habilitar giros y rotación tridimensional en el aire para el confeti
		confetti.angle_min = -180.0
		confetti.angle_max = 180.0
		confetti.angular_velocity_min = -360.0
		confetti.angular_velocity_max = 360.0

		var grad := Gradient.new()
		grad.set_color(0, c)
		grad.add_point(0.7, c)
		grad.set_color(1, Color(c.r, c.g, c.b, 0.0)) # Finde out suave
		confetti.color_ramp = grad
		
		container.add_child(confetti)
		emitters.append(confetti)
		confetti.emitting = true

	parent.get_tree().create_timer(2.5).timeout.connect(func():
		if is_instance_valid(container):
			container.queue_free()
	)

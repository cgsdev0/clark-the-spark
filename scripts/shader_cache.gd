extends Node3D

var particle_materials = [
	preload("res://materials/sparks.tres")
]

func _ready():
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS
	for material in particle_materials:
		var particles_instance = GPUParticles3D.new()
		particles_instance.set_process_material(material)
		particles_instance.set_one_shot(true)
		particles_instance.set_emitting(true)
		self.add_child(particles_instance)

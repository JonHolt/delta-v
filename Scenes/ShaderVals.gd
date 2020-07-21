extends Sprite

export var scroll_scale = 0.7

func _ready():
	get_tree().get_root().connect("resize", self, "resize")

func resize():
	print("check")
	var size = get_viewport_rect().size
	scale = size
	material.set_shader_param("viewport_size", size)

func set_offset(offset):
	material.set_shader_param("offset", offset)


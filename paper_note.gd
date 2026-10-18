extends RefCounted
## Shared thin, creased paper built from the user's local paper texture.
static func build(title: String) -> Node3D:
	var root=Node3D.new()
	root.name="RealisticPaperNote"
	var shader=Shader.new()
	shader.code="shader_type spatial; render_mode cull_disabled; uniform sampler2D paper_texture : source_color, filter_nearest_mipmap; void fragment(){ ALBEDO=mix(vec3(0.86,0.83,0.74),texture(paper_texture,UV).rgb,0.24); ROUGHNESS=1.0; }"
	var material=ShaderMaterial.new()
	material.shader=shader
	material.set_shader_parameter("paper_texture",preload("res://assets/interiors/detour_paper.jpg"))
	var tool=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points=[Vector3(-0.16,0,-0.21),Vector3(0,0.005,-0.21),Vector3(0.16,0.012,-0.21),Vector3(-0.16,0,0.21),Vector3(0,0.005,0.21),Vector3(0.16,0,0.21)]
	for i in [0,3,1,1,3,4,1,4,2,2,4,5]:
		tool.set_normal(Vector3.UP)
		tool.set_uv(Vector2((points[i].x+0.16)/0.32,(points[i].z+0.21)/0.42))
		tool.add_vertex(points[i])
	var mesh=MeshInstance3D.new()
	mesh.mesh=tool.commit()
	mesh.material_override=material
	root.add_child(mesh)
	var label=Label3D.new()
	label.text=title.to_upper().left(25)
	label.font=preload("res://assets/font.ttf")
	label.font_size=14
	label.pixel_size=0.001
	label.position=Vector3(0,0.017,-0.145)
	label.rotation.x=-PI/2
	label.modulate=Color("353b35")
	label.outline_size=0
	label.shaded=true
	root.add_child(label)
	var ink=StandardMaterial3D.new()
	ink.albedo_color=Color("535748")
	ink.roughness=1
	for i in range(8):
		var line=MeshInstance3D.new()
		var box=BoxMesh.new()
		box.size=Vector3(0.25 if i%3!=2 else 0.19,0.001,0.0025)
		line.mesh=box
		line.material_override=ink
		line.position=Vector3(-0.012,0.017,-0.09+i*0.031)
		root.add_child(line)
	return root

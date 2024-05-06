extends Node3D


enum BlockFace {
	UP = 1,
	DOWN = 2,
	LEFT = 4,
	RIGHT = 8,
	FORWARD = 16,
	BACK = 32
}

const VERTEX_PER_SIDE := {
	BlockFace.UP : [
		Vector3(1,1,1),
		Vector3(0,1,1),
		Vector3(0,1,0),
		Vector3(1,1,1),
		Vector3(0,1,0),
		Vector3(1,1,0),
	],
	BlockFace.DOWN : [
		Vector3(1,0,0),
		Vector3(0,0,0),
		Vector3(0,0,1),
		Vector3(1,0,0),
		Vector3(0,0,1),
		Vector3(1,0,1),
	],
	BlockFace.LEFT: [
		Vector3(0,1,0),
		Vector3(0,1,1),
		Vector3(0,0,1),
		Vector3(0,1,0),
		Vector3(0,0,1),
		Vector3(0,0,0)
	],
	BlockFace.RIGHT: [
		Vector3(1,1,1),
		Vector3(1,1,0),
		Vector3(1,0,0),
		Vector3(1,1,1),
		Vector3(1,0,0),
		Vector3(1,0,1)
	],
	BlockFace.BACK: [
		Vector3(1,1,0),
		Vector3(0,1,0),
		Vector3(0,0,0),
		Vector3(1,1,0),
		Vector3(0,0,0),
		Vector3(1,0,0)
	],
	BlockFace.FORWARD: [
		Vector3(0,1,1),
		Vector3(1,1,1),
		Vector3(1,0,1),
		Vector3(0,1,1),
		Vector3(1,0,1),
		Vector3(0,0,1)
	]
}

const NORMAL_PER_SIDE := {
	BlockFace.UP: Vector3.UP,
	BlockFace.DOWN: Vector3.DOWN,
	BlockFace.LEFT: Vector3.LEFT,
	BlockFace.RIGHT: Vector3.RIGHT,
	BlockFace.FORWARD: Vector3.FORWARD,
	BlockFace.BACK: Vector3.BACK
}


const CHUNK_SIZE = 12
const CHUNK_HEIGHT = 16
const BLOCKS_PER_CHUNK = CHUNK_SIZE*CHUNK_HEIGHT*CHUNK_SIZE

func _ready():
	
	
	RenderingServer.set_debug_generate_wireframes(true)
	for i in 4:
		for j in 4:
			_generate_chunk(-i,-j)


func _create_blocks(blocks: PackedByteArray):
	blocks.clear()
	blocks.resize(BLOCKS_PER_CHUNK)
	blocks.fill(0)
	for x in CHUNK_SIZE:
		for y in CHUNK_HEIGHT:
			for z in CHUNK_SIZE:
				set_block(x,y,z,blocks,1)


func _generate_chunk(cx: int, cz: int):
	var blocks: PackedByteArray
	_create_blocks(blocks)
	var st = SurfaceTool.new()
	var mesh = ArrayMesh.new()
	
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in CHUNK_SIZE:
		for y in CHUNK_HEIGHT:
			for z in CHUNK_SIZE:
				_draw_block(st, Vector3(x,y,z), blocks)
	st.commit(mesh)
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	
	var chunk = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	var shape = mesh.create_trimesh_shape()
	collision_shape.shape = shape
	add_child(chunk)
	chunk.add_child(collision_shape)
	chunk.name = "chunk " + str(cx) + "," + str(cz)
	
	var material = StandardMaterial3D.new()
	material.albedo_texture = preload("res://icon.svg")
	mesh.surface_set_material(0, material)
	chunk.add_child(mesh_instance)
	chunk.global_position = Vector3(cx,0,cz)*CHUNK_SIZE
	


func _draw_block(st: SurfaceTool, pos: Vector3, blocks: Array):
	var x = int(pos.x)
	var y = int(pos.y)
	var z = int(pos.z)
	var block = get_block(x,y,z,blocks)
	if block == 0: return
	var face_flags = 0
	if x+1 < CHUNK_SIZE: face_flags |= get_block(x+1,y,z,blocks) * BlockFace.RIGHT
	if x-1 >= 0: face_flags |= get_block(x-1,y,z,blocks) * BlockFace.LEFT
	if y+1 < CHUNK_HEIGHT: face_flags |= get_block(x,y+1,z,blocks) * BlockFace.DOWN
	if y-1 >= 0: face_flags |= get_block(x,y-1,z, blocks) * BlockFace.UP
	if z+1 < CHUNK_SIZE: face_flags |= get_block(x,y,z+1, blocks) * BlockFace.FORWARD
	if z-1 >= 0: face_flags |= get_block(x,y,z-1, blocks) * BlockFace.BACK
	for i in BlockFace.values():
		if i & face_flags == 0:
			_draw_face(st, pos*Vector3(1,-1,1), i)

func get_block(x: int, y: int, z: int, blocks: PackedByteArray):
	return blocks[x*CHUNK_HEIGHT+y*CHUNK_SIZE+z]

func set_block(x: int, y: int, z: int, blocks: PackedByteArray, value: int):
	blocks[x*CHUNK_HEIGHT+y*CHUNK_SIZE+z] = value

func _draw_face(st: SurfaceTool, pos: Vector3, side: int):
	for i in 6:
		st.set_uv(Vector2(0,0))
		st.set_normal(NORMAL_PER_SIDE[side])
		st.set_color(_uv_to_color(Vector2(0,0)))
		st.add_vertex(pos+VERTEX_PER_SIDE[side][0])
		st.set_uv(Vector2(1,0))
		st.set_normal(NORMAL_PER_SIDE[side])
		st.set_color(_uv_to_color(Vector2(1,0)))
		st.add_vertex(pos+VERTEX_PER_SIDE[side][1])
		st.set_uv(Vector2(1,1))
		st.set_normal(NORMAL_PER_SIDE[side])
		st.set_color(_uv_to_color(Vector2(1,1)))
		st.add_vertex(pos+VERTEX_PER_SIDE[side][2])
		st.set_uv(Vector2(0,0))
		st.set_normal(NORMAL_PER_SIDE[side])
		st.set_color(_uv_to_color(Vector2(0,0)))
		st.add_vertex(pos+VERTEX_PER_SIDE[side][3])
		st.set_uv(Vector2(1,1))
		st.set_normal(NORMAL_PER_SIDE[side])
		st.set_color(_uv_to_color(Vector2(1,1)))
		st.add_vertex(pos+VERTEX_PER_SIDE[side][4])
		st.set_uv(Vector2(0,1))
		st.set_normal(NORMAL_PER_SIDE[side])
		st.set_color(_uv_to_color(Vector2(0,1)))
		st.add_vertex(pos+VERTEX_PER_SIDE[side][5])
			
	
func _uv_to_color(uv: Vector2):
	return Color(uv.x, uv.y, 0.0)


var x = 1

func _input(event):
	if event is InputEventKey and Input.is_key_pressed(KEY_P):
		var vp = get_viewport()
		vp.debug_draw = (vp.debug_draw + 1 ) % 5
	elif event is InputEventKey and Input.is_key_pressed(KEY_E):
		var rb = RigidBody3D.new()
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = SphereMesh.new()
		mesh_instance.mesh.radius = 0.5
		var collision_shape = CollisionShape3D.new()
		collision_shape.shape = SphereShape3D.new()
		collision_shape.shape.radius = 0.5
		add_child(rb)
		rb.add_child(collision_shape)
		rb.add_child(mesh_instance)
		rb.global_position = Vector3(randf()*10, 2, randf()*10)
	elif event is InputEventKey and Input.is_key_pressed(KEY_Q):
		_generate_chunk(x,0)
		x += 1

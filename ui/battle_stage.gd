extends Node3D

signal animation_finished
var hero: Node3D
var opponent: Node3D
var camera: Camera3D
var busy: bool = false
var home_camera: Vector3 = Vector3(6.6, 4.4, 8.2)
var effect_root: Node3D

func material(color: Color, luminous: bool = false) -> StandardMaterial3D:
    var mat: StandardMaterial3D = StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.9
    if luminous:
        mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return mat

func mesh_part(parent: Node3D, mesh: Mesh, at: Vector3, color: Color) -> MeshInstance3D:
    var item: MeshInstance3D = MeshInstance3D.new()
    item.mesh = mesh
    item.material_override = material(color)
    item.position = at
    parent.add_child(item)
    return item

func cube(parent: Node3D, at: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = dimensions
    return mesh_part(parent, mesh, at, color)

func fighter(at: Vector3, robe_color: Color) -> Node3D:
    var actor: Node3D = Node3D.new()
    add_child(actor)
    actor.position = at
    var robe: CylinderMesh = CylinderMesh.new()
    robe.top_radius = 0.22
    robe.bottom_radius = 0.43
    robe.height = 0.85
    robe.radial_segments = 8
    mesh_part(actor, robe, Vector3(0, 0.83, 0), robe_color)
    var head: SphereMesh = SphereMesh.new()
    head.radius = 0.22
    head.height = 0.44
    head.radial_segments = 12
    head.rings = 6
    mesh_part(actor, head, Vector3(0, 1.48, 0), Color("dcc2a1"))
    cube(actor, Vector3(0, 1.66, 0.02), Vector3(0.32,0.15,0.3), Color("202828"))
    cube(actor, Vector3(0, 1.8, 0.02), Vector3(0.13,0.17,0.13), Color("202828"))
    cube(actor, Vector3(-0.15,0.21,0), Vector3(0.18,0.42,0.24), Color("253233"))
    cube(actor, Vector3(0.15,0.21,0), Vector3(0.18,0.42,0.24), Color("253233"))
    cube(actor, Vector3(-0.34,1.06,0), Vector3(0.2,0.54,0.22), robe_color)
    cube(actor, Vector3(0.34,1.06,0), Vector3(0.2,0.54,0.22), robe_color)
    cube(actor, Vector3(0.45,0.97,0.1), Vector3(0.055,1.0,0.07), Color("c5d9ce"))
    cube(actor, Vector3(0,0.82,0), Vector3(0.57,0.10,0.53), Color("b69d64"))
    return actor

func _ready() -> void:
    var environment: WorldEnvironment = WorldEnvironment.new()
    var env: Environment = Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("142a2d")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("b1c8bf")
    env.ambient_light_energy = 0.65
    environment.environment = env
    add_child(environment)
    var sun: DirectionalLight3D = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-45, -25, 0)
    sun.light_color = Color("ffe2af")
    sun.light_energy = 1.25
    sun.shadow_enabled = true
    add_child(sun)
    cube(self, Vector3(0,-0.25,0), Vector3(12,0.5,10), Color("677166"))
    for x: int in range(-5,6):
        for z: int in range(-4,5):
            cube(self, Vector3(x,0.014,z), Vector3(0.96,0.035,0.96), Color("7b8273") if (x+z)%2 == 0 else Color("727c6e"))
    for x: int in [-5,5]:
        for z: int in [-4,4]:
            cube(self, Vector3(x,1.0,z), Vector3(0.35,2.0,0.35), Color("473b30"))
            cube(self, Vector3(x,1.85,z), Vector3(0.9,0.16,0.9), Color("34453c"))
    cube(self, Vector3(0,0.5,-4.5), Vector3(11,1,0.3), Color("465c50"))
    for index: int in range(9):
        var peak: CylinderMesh = CylinderMesh.new()
        peak.top_radius = 0
        peak.bottom_radius = 2.0
        peak.height = 3.0 + float(index % 3)
        peak.radial_segments = 5
        mesh_part(self, peak, Vector3(float(index)*3-12,0,-9-float(index%2)*2), Color("304c44"))
    hero = fighter(Vector3(-2,0,0.6), Color("437e77"))
    opponent = fighter(Vector3(2,0,-0.6), Color("934e3a"))
    hero.rotation.y = -0.5
    opponent.rotation.y = 2.6
    effect_root = Node3D.new()
    add_child(effect_root)
    camera = Camera3D.new()
    camera.position = home_camera
    camera.fov = 48
    add_child(camera)
    camera.look_at(Vector3(0,0.8,0))
    camera.current = true

func play_action(result: Dictionary) -> void:
    if busy:
        return
    busy = true
    var hero_home: Vector3 = hero.position
    var enemy_home: Vector3 = opponent.position
    var tween: Tween = create_tween()
    tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(camera, "position", Vector3(4.4,2.8,6.2), 0.22)
    if result.action != "guard":
        tween.tween_property(hero, "position", Vector3(0.6,0,-0.2), 0.22)
        tween.tween_callback(_flash.bind(str(result.skill), Vector3(1.35,1.1,-0.3)))
        tween.tween_property(opponent, "position", enemy_home + Vector3(0.3,0,-0.1), 0.09)
        tween.tween_property(opponent, "position", enemy_home, 0.13)
        tween.tween_property(hero, "position", hero_home, 0.20)
    else:
        tween.tween_callback(_flash.bind("guard", hero_home + Vector3(0,1,0)))
        tween.tween_interval(0.3)
    if int(result.incoming) > 0:
        tween.tween_property(opponent, "position", Vector3(-0.8,0,0.25), 0.20)
        tween.tween_callback(_flash.bind("enemy", hero_home + Vector3(0,1,0)))
        tween.tween_property(hero, "position", hero_home + Vector3(-0.2,0,0.1), 0.08)
        tween.tween_property(hero, "position", hero_home, 0.12)
        tween.tween_property(opponent, "position", enemy_home, 0.20)
    tween.tween_property(camera, "position", home_camera, 0.22)
    tween.tween_callback(_done)

func _flash(kind: String, at: Vector3) -> void:
    var color: Color = Color("80eee0") if kind == "sword" else Color("ffd17d")
    if kind == "enemy":
        color = Color("e8876b")
    var ring: TorusMesh = TorusMesh.new()
    ring.inner_radius = 0.48
    ring.outer_radius = 0.58
    ring.rings = 20
    ring.ring_segments = 12
    var effect: MeshInstance3D = mesh_part(effect_root, ring, at, color)
    effect.material_override = material(color, true)
    effect.rotation_degrees = Vector3(75,0,30 if kind == "sword" else 0)
    var tween: Tween = create_tween()
    tween.tween_property(effect, "scale", Vector3(2.3,2.3,2.3), 0.35)
    tween.tween_callback(effect.queue_free)

func _done() -> void:
    busy = false
    animation_finished.emit()

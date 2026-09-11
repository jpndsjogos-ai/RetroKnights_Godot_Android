extends Node2D

const PLAYER_SCENE := preload("res://scenes/Player.tscn")
const ENEMY_SCRIPT := preload("res://scripts/Enemy.gd")

var player: Player
var spawn_timer := 0.0
var hud: CanvasLayer
var level_label: Label
var xp_bar: ProgressBar
var hp_bar: ProgressBar
var status_label: Label
var game_over := false

func _ready() -> void:
    create_world()
    player = PLAYER_SCENE.instantiate()
    add_child(player)
    player.global_position = Vector2(360, 520)
    player.stats_changed.connect(_on_stats_changed)
    player.defeated.connect(_on_player_defeated)
    create_hud()
    for i in 3:
        spawn_enemy(Vector2(780 + i * 120, 500 + (i % 2) * 50))

func _process(delta: float) -> void:
    if game_over:
        return
    spawn_timer -= delta
    if spawn_timer <= 0.0 and get_tree().get_nodes_in_group("enemies").size() < 6:
        spawn_timer = 2.4
        spawn_enemy(Vector2(1100, randf_range(430, 590)))

func create_world() -> void:
    var bg := Polygon2D.new()
    bg.polygon = PackedVector2Array([Vector2(0,350),Vector2(1280,350),Vector2(1280,720),Vector2(0,720)])
    bg.color = Color("#20283b")
    add_child(bg)

    var road := Polygon2D.new()
    road.polygon = PackedVector2Array([Vector2(0,390),Vector2(1280,390),Vector2(1280,640),Vector2(0,640)])
    road.color = Color("#343b4e")
    add_child(road)

    for y in [405, 470, 535, 600]:
        var line := Line2D.new()
        line.width = 2
        line.default_color = Color("#4a5268")
        line.add_point(Vector2(0,y))
        line.add_point(Vector2(1280,y))
        add_child(line)

func spawn_enemy(pos: Vector2) -> void:
    var enemy := CharacterBody2D.new()
    enemy.set_script(ENEMY_SCRIPT)
    enemy.global_position = pos
    enemy.max_hp = 55 + player.level * 8
    enemy.xp_reward = 50 + player.level * 5
    add_child(enemy)

    var body := Polygon2D.new()
    body.polygon = PackedVector2Array([Vector2(-24,-65),Vector2(24,-65),Vector2(30,-5),Vector2(20,8),Vector2(-20,8),Vector2(-30,-5)])
    body.color = Color("#9b3946")
    enemy.add_child(body)

    var hurt := Area2D.new()
    hurt.collision_layer = 4
    hurt.collision_mask = 8
    enemy.add_child(hurt)
    var shape := CollisionShape2D.new()
    var rect := RectangleShape2D.new()
    rect.size = Vector2(45, 65)
    shape.shape = rect
    shape.position = Vector2(0,-30)
    hurt.add_child(shape)

    var hit := Area2D.new()
    hit.collision_layer = 8
    hit.collision_mask = 4
    enemy.add_child(hit)
    var hit_shape := CollisionShape2D.new()
    var hit_rect := RectangleShape2D.new()
    hit_rect.size = Vector2(55, 35)
    hit_shape.shape = hit_rect
    hit_shape.position = Vector2(-35,-30)
    hit.add_child(hit_shape)

    enemy.defeated.connect(_on_enemy_defeated)

func create_hud() -> void:
    hud = CanvasLayer.new()
    add_child(hud)

    level_label = Label.new()
    level_label.position = Vector2(28,20)
    level_label.add_theme_font_size_override("font_size", 28)
    hud.add_child(level_label)

    hp_bar = ProgressBar.new()
    hp_bar.position = Vector2(28,58)
    hp_bar.size = Vector2(300,24)
    hp_bar.max_value = 100
    hud.add_child(hp_bar)

    xp_bar = ProgressBar.new()
    xp_bar.position = Vector2(28,88)
    xp_bar.size = Vector2(300,18)
    hud.add_child(xp_bar)

    status_label = Label.new()
    status_label.position = Vector2(28,116)
    status_label.add_theme_font_size_override("font_size", 16)
    hud.add_child(status_label)

    create_touch_button("◀", Vector2(35, 565), "move_left")
    create_touch_button("▶", Vector2(145, 565), "move_right")
    create_touch_button("▲", Vector2(90, 510), "move_up")
    create_touch_button("▼", Vector2(90, 620), "move_down")

    create_touch_button("ATK", Vector2(1030, 545), "attack")
    create_touch_button("JMP", Vector2(1140, 490), "jump")
    create_touch_button("PAR", Vector2(920, 600), "parry")
    create_touch_button("SP", Vector2(1140, 600), "special")

func create_touch_button(text: String, pos: Vector2, action: String) -> void:
    var b := Button.new()
    b.text = text
    b.position = pos
    b.size = Vector2(90, 70)
    b.modulate = Color(1,1,1,0.72)
    b.add_theme_font_size_override("font_size", 20)
    b.button_down.connect(func(): Input.action_press(action))
    b.button_up.connect(func(): Input.action_release(action))
    hud.add_child(b)

func _on_stats_changed(lvl: int, current_xp: int, next_xp: int, hp: int, max_hp: int) -> void:
    level_label.text = "NÍVEL %d" % lvl
    hp_bar.value = hp
    xp_bar.max_value = next_xp
    xp_bar.value = current_xp
    status_label.text = "ATK  [J]   PULO [K]   PARRY [L]   ESPECIAL [ESPAÇO]"

func _on_enemy_defeated(reward: int) -> void:
    if is_instance_valid(player):
        player.add_xp(reward)

func _on_player_defeated() -> void:
    game_over = true
    status_label.text = "DERROTA — reinicie o jogo para tentar novamente."

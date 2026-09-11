extends CharacterBody2D
class_name Player

signal stats_changed(level: int, xp: int, xp_to_next: int, hp: int, max_hp: int)
signal defeated
signal attack_landed

const SPEED := 260.0
const LANE_SPEED := 150.0
const JUMP_SPEED := -560.0
const MAX_HP := 100
const SPECIAL_COST := 20
const ATTACK_DAMAGE := 18

var hp := MAX_HP
var xp := 0
var level := 1
var facing := 1
var attacking := false
var parrying := false
var invulnerable := false
var jump_time := 0.0
var attack_cooldown := 0.0

@onready var body_sprite: Sprite2D = $Body
@onready var sword_sprite: Sprite2D = $Sword
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D

const ARMOR_SKINS := {
    1: "res://assets/player/armor_iron.svg",
    2: "res://assets/player/armor_steel.svg",
    3: "res://assets/player/armor_gold.svg",
    4: "res://assets/player/armor_gold.svg"
}
const SWORD_SKINS := {
    1: "res://assets/player/sword_iron.svg",
    2: "res://assets/player/sword_steel.svg",
    3: "res://assets/player/sword_rune.svg",
    4: "res://assets/player/sword_rune.svg"
}

func _ready() -> void:
    add_to_group("player")
    $Hitbox.area_entered.connect(_on_hitbox_area_entered)
    apply_visual_tier()
    emit_stats()

func _physics_process(delta: float) -> void:
    attack_cooldown = max(0.0, attack_cooldown - delta)

    var x := Input.get_axis("move_left", "move_right")
    var z := Input.get_axis("move_up", "move_down")

    velocity.x = x * SPEED
    # In this 2D beat 'em up, Y is the pseudo-depth/lane axis.
    velocity.y = z * LANE_SPEED

    if x != 0:
        facing = sign(x)
        body_sprite.flip_h = facing < 0
        sword_sprite.flip_h = facing < 0
        sword_sprite.position.x = 38.0 * facing
        hitbox_shape.position.x = 42.0 * facing

    if Input.is_action_just_pressed("jump") and jump_time <= 0.0:
        jump_time = 0.35
        body_sprite.position.y = -42.0
        sword_sprite.position.y = -43.0

    if jump_time > 0.0:
        jump_time -= delta
        if jump_time <= 0.0:
            body_sprite.position.y = -24.0
            sword_sprite.position.y = -25.0

    if Input.is_action_just_pressed("attack"):
        attack()

    if Input.is_action_just_pressed("parry"):
        start_parry()

    if Input.is_action_just_pressed("special"):
        special_attack()

    move_and_slide()

    # Keep the fighter inside the lane.
    global_position.y = clamp(global_position.y, 390.0, 610.0)

func attack() -> void:
    if attacking or attack_cooldown > 0.0:
        return
    attacking = true
    attack_cooldown = 0.32
    hitbox_shape.disabled = false
    sword_sprite.rotation = deg_to_rad(-25.0 * facing)
    await get_tree().create_timer(0.12).timeout
    hitbox_shape.disabled = true
    await get_tree().create_timer(0.10).timeout
    sword_sprite.rotation = 0.0
    attacking = false

func start_parry() -> void:
    if parrying:
        return
    parrying = true
    invulnerable = true
    modulate = Color(0.7, 0.9, 1.0)
    await get_tree().create_timer(0.28).timeout
    parrying = false
    invulnerable = false
    modulate = Color.WHITE

func special_attack() -> void:
    if hp <= SPECIAL_COST or attacking:
        return
    hp -= SPECIAL_COST
    invulnerable = true
    attacking = true
    hitbox_shape.disabled = false
    hitbox_shape.shape.size = Vector2(150, 70)
    sword_sprite.modulate = Color(0.4, 0.8, 1.0)
    await get_tree().create_timer(0.30).timeout
    hitbox_shape.disabled = true
    hitbox_shape.shape.size = Vector2(58, 38)
    sword_sprite.modulate = Color.WHITE
    attacking = false
    invulnerable = false
    emit_stats()

func take_damage(amount: int) -> void:
    if invulnerable:
        return
    hp = max(0, hp - amount)
    modulate = Color(1.0, 0.45, 0.45)
    await get_tree().create_timer(0.10).timeout
    modulate = Color.WHITE
    emit_stats()
    if hp <= 0:
        defeated.emit()

func add_xp(amount: int) -> void:
    xp += amount
    while xp >= xp_to_next():
        xp -= xp_to_next()
        level += 1
        hp = min(MAX_HP, hp + 15)
        apply_visual_tier()
    emit_stats()

func xp_to_next() -> int:
    return 100 + (level - 1) * 50

func visual_tier() -> int:
    if level <= 3:
        return 1
    if level <= 7:
        return 2
    return 3

func apply_visual_tier() -> void:
    var tier := visual_tier()
    body_sprite.texture = load(ARMOR_SKINS[tier])
    sword_sprite.texture = load(SWORD_SKINS[tier])

func emit_stats() -> void:
    stats_changed.emit(level, xp, xp_to_next(), hp, MAX_HP)

func _on_hitbox_area_entered(area: Area2D) -> void:
    var enemy := area.get_parent()
    if enemy.has_method("take_damage"):
        enemy.take_damage(ATTACK_DAMAGE if not hp else ATTACK_DAMAGE)
        attack_landed.emit()

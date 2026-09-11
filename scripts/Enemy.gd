extends CharacterBody2D
class_name BeatEnemy

signal defeated(xp_reward: int)

@export var max_hp := 55
@export var damage := 8
@export var xp_reward := 55

var hp := 55
var attack_timer := 0.0
var dead := false
var target: Node2D

func _ready() -> void:
    hp = max_hp
    add_to_group("enemies")
    target = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
    if dead:
        return
    if not is_instance_valid(target):
        return

    var dx := target.global_position.x - global_position.x
    var dy := target.global_position.y - global_position.y

    velocity.x = sign(dx) * 90.0 if abs(dx) > 55 else 0.0
    velocity.y = sign(dy) * 65.0 if abs(dy) > 18 else 0.0
    move_and_slide()

    attack_timer -= delta
    if abs(dx) < 70 and abs(dy) < 35 and attack_timer <= 0.0:
        attack_timer = 1.1
        target.take_damage(damage)

    global_position.y = clamp(global_position.y, 390.0, 610.0)

func take_damage(amount: int) -> void:
    if dead:
        return
    hp -= amount
    modulate = Color(1.0, 0.5, 0.35)
    await get_tree().create_timer(0.08).timeout
    if dead:
        return
    modulate = Color.WHITE
    if hp <= 0:
        die()

func die() -> void:
    dead = true
    defeated.emit(xp_reward)
    var tween := create_tween()
    tween.tween_property(self, "scale", Vector2.ZERO, 0.18)
    await tween.finished
    queue_free()

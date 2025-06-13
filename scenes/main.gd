extends Node2D

@onready var ochin_all_scene = preload("res://scenes/ochin.tscn")
var ochin_all: Node = null
var ochin_list: Array[RigidBody2D] = []
var falling_ochins: Array[RigidBody2D] = []

@onready var ui_score_label = $UI/ScoreLabel
@onready var restart_button = $UI/RestartButton
@onready var ground_y = $Ground.global_position.y

var score := 0

# カーソル位置
var cursor_x := 600
var cursor_y := 120
const MIN_X := 100
const MAX_X := 1100

# カーソル制御
var move_speed := 400

# クールタイム制御
var can_drop := true
const DROP_COOLDOWN := 1.0
var drop_cooldown_timer := 0.0

# 次に落とす ochin RigidBody2D
var next_ochin: RigidBody2D = null

func _ready():
	ochin_all = ochin_all_scene.instantiate()
	add_child(ochin_all)
	ochin_all.visible = false  # 画面には表示しない

	# Ochin_All の子ノード (RigidBody2D) をリスト化
	for ochin in ochin_all.get_children():
		if ochin is RigidBody2D:
			ochin_list.append(ochin)
	_choose_next_ochin()
	set_process_input(true)

func _process(delta):
	_update_cursor(delta)
	if not can_drop:
		drop_cooldown_timer -= delta
		if drop_cooldown_timer <= 0:
			can_drop = true

	queue_redraw()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE and can_drop:
			spawn_falling_ochin()
			can_drop = false
			drop_cooldown_timer = DROP_COOLDOWN
			_choose_next_ochin()

func _update_cursor(delta):
	if Input.is_action_pressed("ui_left"):
		cursor_x -= move_speed * delta
	elif Input.is_action_pressed("ui_right"):
		cursor_x += move_speed * delta
	cursor_x = clamp(cursor_x, MIN_X, MAX_X)
	queue_redraw()

func _draw():
	# カーソルの落下位置を矩形で描画
	var rect_size = Vector2(100, 100)
	var rect_pos = Vector2(cursor_x - rect_size.x / 2, cursor_y - rect_size.y / 2)
	draw_rect(Rect2(rect_pos, rect_size), Color(0.3, 0.8, 1.0, 0.4), false)
	# 次に落とす ochin プレビュー
	if next_ochin:
		var sprite = next_ochin.get_node_or_null("Sprite2D")
		if sprite and sprite.texture:
			var tex = sprite.texture
			var tex_size = tex.get_size()
			var draw_pos = rect_pos + (rect_size - tex_size) / 2
			draw_texture(tex, draw_pos)

func spawn_falling_ochin():
	if ochin_list.is_empty():
		return
	if next_ochin == null:
		return
	var ochin_instance = next_ochin.duplicate()
	add_child(ochin_instance)
	ochin_instance.position = Vector2(cursor_x, cursor_y)
	ochin_instance.visible = true
	# --- 以下、自動コリジョン生成 ---
	var sprite = ochin_instance.get_node_or_null("Sprite2D")
	if sprite and sprite.texture and not ochin_instance.get_node_or_null("CollisionPolygon2D"):
		var tex = sprite.texture
		if tex is ImageTexture:
			var img = tex.get_image()
			img.lock()
			var polygons = Geometry2D.march_polygon(img, 0.1, Color(0,0,0,0))
			img.unlock()
			if polygons.size() > 0:
				var collision_polygon = CollisionPolygon2D.new()
				collision_polygon.polygon = polygons[0]
				ochin_instance.add_child(collision_polygon)
	# --- ここまで ---
	falling_ochins.append(ochin_instance)

func _choose_next_ochin():
	if ochin_list.is_empty():
		next_ochin = null
		return
	var index = randi() % ochin_list.size()
	next_ochin = ochin_list[index]
	queue_redraw()

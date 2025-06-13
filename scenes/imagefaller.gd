extends RigidBody2D
@export var texture_path: String

func _ready():
	var sprite := $Sprite2D
	var tex: Texture2D = load(texture_path)
	sprite.texture = tex
	sprite.position = Vector2.ZERO
	sprite.centered = true

	# 既存のコリジョンを削除
	for child in get_children():
		if child is CollisionPolygon2D or child is CollisionShape2D:
			child.queue_free()

	var img: Image = tex.get_image()
	var bm := BitMap.new()
	bm.create_from_image_alpha(img)
	var polygons: Array = bm.opaque_to_polygons(Rect2(Vector2.ZERO, img.get_size()), 6.0)

	var center_shift = Vector2(tex.get_width(), tex.get_height()) / 2

	for poly in polygons:
		var centered_poly = []
		for v in poly:
			centered_poly.append(v - center_shift)
		var cp := CollisionPolygon2D.new()
		cp.polygon = centered_poly
		cp.position = Vector2.ZERO
		add_child(cp)

func get_top_y() -> float:
	var sprite := $Sprite2D
	if sprite.texture:
		return global_position.y - sprite.texture.get_height() / 2
	return global_position.y

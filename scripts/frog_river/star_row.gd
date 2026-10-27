class_name StarRow
extends Control
## 结算星星：金色为获得的星数（按失误数 1～3 颗），灰色为空槽。

const COLOR_GOLD := Color(1.0, 0.78, 0.18)
const COLOR_GRAY := Color(0.82, 0.84, 0.78)

@export_range(0, 3) var count := 3:
	set(value):
		count = clampi(value, 0, 3)
		queue_redraw()


func _draw() -> void:
	for i in 3:
		_draw_star(Vector2(58 + i * 92, size.y * 0.5), 32.0, COLOR_GOLD if i < count else COLOR_GRAY)


func _draw_star(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for k in 10:
		var angle := -PI / 2.0 + k * PI / 5.0
		var r := radius if k % 2 == 0 else radius * 0.45
		points.push_back(center + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(points, color)

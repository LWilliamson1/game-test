extends Node3D
## Day/night cycle controller. Rotates a DirectionalLight3D and updates environment.

@export var sun: DirectionalLight3D
@export var cycle_duration: float = 600.0  # Seconds for a full day
@export var time_of_day: float = 0.3  # 0.0 = midnight, 0.25 = sunrise, 0.5 = noon, 0.75 = sunset

@export_group("Colors")
@export var day_color: Color = Color(1.0, 0.95, 0.85)
@export var sunset_color: Color = Color(1.0, 0.5, 0.2)
@export var night_color: Color = Color(0.1, 0.1, 0.3)
@export var day_energy: float = 1.0
@export var night_energy: float = 0.05

signal hour_changed(hour: int)

var current_hour: int = -1


func _process(delta: float) -> void:
	time_of_day += delta / cycle_duration
	if time_of_day >= 1.0:
		time_of_day -= 1.0

	_update_sun()
	_check_hour()


func _update_sun() -> void:
	if not sun:
		return

	# Rotate sun based on time of day
	var angle := time_of_day * TAU - PI / 2.0
	sun.rotation.x = angle

	# Interpolate light color and energy based on time
	var energy: float
	var color: Color

	if time_of_day > 0.2 and time_of_day < 0.8:
		# Daytime
		var day_factor := 1.0 - abs(time_of_day - 0.5) * 4.0
		day_factor = clamp(day_factor, 0.0, 1.0)
		color = sunset_color.lerp(day_color, day_factor)
		energy = lerp(night_energy, day_energy, smoothstep(0.2, 0.3, time_of_day))
		if time_of_day > 0.7:
			energy = lerp(day_energy, night_energy, smoothstep(0.7, 0.8, time_of_day))
	else:
		# Nighttime
		color = night_color
		energy = night_energy

	sun.light_color = color
	sun.light_energy = energy


func _check_hour() -> void:
	var hour := int(time_of_day * 24.0)
	if hour != current_hour:
		current_hour = hour
		hour_changed.emit(hour)


func get_formatted_time() -> String:
	var total_minutes := int(time_of_day * 24.0 * 60.0)
	var hours := total_minutes / 60
	var minutes := total_minutes % 60
	return "%02d:%02d" % [hours, minutes]

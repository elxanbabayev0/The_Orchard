extends Node
## Global game clock. Registered as the autoload "GameClock",
## so any script can use it, e.g. `GameClock.day` or `GameClock.get_hour()`.
##
## Time is counted in game minutes inside the current day (0 .. 1440).
## For now the day is an endless 24-hour loop (no sleeping).
## A sleep mechanic can later call `advance()` to skip to the morning.

## Emitted when the shown minute changes (used by the clock label).
signal minute_changed(day: int, hour: int, minute: int)
## Emitted when a new day starts (at 00:00).
signal day_changed(day: int)
## Emitted every time the clock moves, with how much game time passed (in game days).
## Trees and other growing things listen to this.
signal time_advanced(delta_days: float)

const MINUTES_PER_DAY := 1440.0

## Emitted when the debug time speed changes (the clock label shows it).
signal debug_speed_changed(speed: float)

## How many REAL seconds one game day lasts: 12 real minutes
## (decision "Day / night rework"; a balance number that may change later).
var real_seconds_per_day: float = 720.0

## Debug builds only (editor runs): F4 cycles these time speeds, so trees and
## Oona's visits can be tested without waiting. Never active in a release build.
const DEBUG_SPEEDS: Array[float] = [1.0, 10.0, 60.0]
const DEBUG_SPEED_KEY := KEY_F4
## Current debug multiplier (1.0 = normal speed). Not saved.
var debug_speed: float = 1.0
## The hour a new game starts at.
var start_hour: int = 6

## Current day number, starting from 1.
var day: int = 1
## Game minutes passed in the current day (0 .. 1440).
var minute_of_day: float = 0.0
## When true, game time does not move (later: menus, cutscenes, sleeping).
var paused: bool = false


func _ready() -> void:
	minute_of_day = start_hour * 60.0


func _process(delta: float) -> void:
	if paused:
		return
	advance(delta * debug_speed / real_seconds_per_day)


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.physical_keycode == DEBUG_SPEED_KEY:
		var next := (DEBUG_SPEEDS.find(debug_speed) + 1) % DEBUG_SPEEDS.size()
		debug_speed = DEBUG_SPEEDS[next]
		print("GameClock: debug time speed ×%d" % int(debug_speed))
		debug_speed_changed.emit(debug_speed)
		get_viewport().set_input_as_handled()


## Moves game time forward by `days` game days (0.5 = half a day).
## Used every frame now; later also by sleeping to skip to the morning.
func advance(days: float) -> void:
	if days <= 0.0:
		return
	var old_minute := int(minute_of_day)
	var old_day := day
	minute_of_day += days * MINUTES_PER_DAY
	# "while", not "if": a big jump (e.g. sleeping) can pass more than one day.
	while minute_of_day >= MINUTES_PER_DAY:
		minute_of_day -= MINUTES_PER_DAY
		day += 1
		day_changed.emit(day)
	time_advanced.emit(days)
	if int(minute_of_day) != old_minute or day != old_day:
		minute_changed.emit(day, get_hour(), get_minute())


func get_hour() -> int:
	return floori(minute_of_day / 60.0)


func get_minute() -> int:
	return int(minute_of_day) % 60


## How far through the day we are: 0.0 = midnight, 0.5 = noon, 1.0 = next midnight.
func get_day_progress() -> float:
	return minute_of_day / MINUTES_PER_DAY


# --- Save / load -------------------------------------------------------------
# Every system has the same two functions. load_save_data({}) = new-game state.

func get_save_data() -> Dictionary:
	return {
		"day": day,
		"minute_of_day": minute_of_day,
	}


func load_save_data(data: Dictionary) -> void:
	# JSON gives every number back as a float, so whole numbers are turned back with int().
	day = int(data.get("day", 1))
	minute_of_day = float(data.get("minute_of_day", start_hour * 60.0))
	# Only refresh the clock label. day_changed is NOT emitted: no new day has started.
	minute_changed.emit(day, get_hour(), get_minute())

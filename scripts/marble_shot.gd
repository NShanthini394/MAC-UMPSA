extends RefCounted
## Finger-pulled rolling shot. Preview and flight use the same friction model.
const RADIUS := 18.0
const GOAL_RADIUS := 85.0
const FRICTION := 260.0
const POWER := 6.0
const MAX_PULL := 130.0
const MIN_PULL := 8.0
const BOUNDS := Rect2(42,72,708,238)
var anchor := Vector2(145,180)
var goal := Vector2(535,182)
var position := Vector2(145,180)
var velocity := Vector2.ZERO
var rolling := false

func reset() -> void:
	position=anchor; velocity=Vector2.ZERO; rolling=false

func clamped_pull(pull: Vector2) -> Vector2:
	var start := (anchor-pull.limit_length(MAX_PULL)).clamp(BOUNDS.position,BOUNDS.end)
	return anchor-start

func prediction(pull: Vector2) -> Vector2:
	var actual := clamped_pull(pull)
	var speed := actual.length()*POWER
	return anchor-actual+actual.normalized()*speed*speed/(2.0*FRICTION)

func inside_goal(point: Vector2) -> bool:
	return point.distance_to(goal)+RADIUS <= GOAL_RADIUS

func pull_for_target(target: Vector2) -> Vector2:
	var distance := anchor.distance_to(target)
	var factor := POWER*POWER/(2.0*FRICTION)
	var length := (1.0+sqrt(1.0+4.0*factor*distance))/(2.0*factor)
	return (target-anchor).normalized()*length

func launch(pull: Vector2) -> bool:
	var actual := clamped_pull(pull)
	if actual.length()<MIN_PULL: return false
	position=anchor-actual
	velocity=actual*POWER
	rolling=true
	return true

func advance(delta: float) -> String:
	if not rolling: return "idle"
	var speed := velocity.length()
	var time := minf(maxf(delta,0.0),speed/FRICTION)
	var direction := velocity.normalized()
	position += direction*(speed*time-0.5*FRICTION*time*time)
	velocity = direction*maxf(0.0,speed-FRICTION*time)
	if not BOUNDS.has_point(position):
		rolling=false; velocity=Vector2.ZERO
		return "miss"
	if velocity.length()<0.01:
		rolling=false; velocity=Vector2.ZERO
		return "inside" if inside_goal(position) else "miss"
	return "rolling"

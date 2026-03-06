extends Control

# ---------------- NODES ----------------
@onready var back_btn: Button = $SafeArea/Main/TopBar/BackButton

@onready var question_label: Label = $SafeArea/Main/Middle/SpacerTop/QuestionPanel/QuestionLabel
@onready var answer_label: Label = $SafeArea/Main/Middle/Control/AnswerPanel/AnswerLabel
@onready var feedback_label: Label = $SafeArea/Main/Middle/FeedbackLabel

@onready var keypad: GridContainer = $SafeArea/Main/Keypad/NumPad
@onready var enter_btn: Button = $SafeArea/Main/Keypad/SidePad/EnterButton

# Mode overlay
@onready var mode_panel: Control = $SafeArea/ModePanel
@onready var add_btn: Button = $SafeArea/ModePanel/ModeVBox/AddBtn
@onready var sub_btn: Button = $SafeArea/ModePanel/ModeVBox/SubBtn
@onready var mul_btn: Button = $SafeArea/ModePanel/ModeVBox/MulBtn
@onready var div_btn: Button = $SafeArea/ModePanel/ModeVBox/DivBtn

# Optional labels (safe if missing)
@onready var score_label: Label = get_node_or_null("SafeArea/Main/TopBar/ScoreLabel")
@onready var timer_label: Label = get_node_or_null("SafeArea/Main/TopBar/TimerLabel")

# ---------------- GAME STATE ----------------
enum Mode { NONE, ADD, SUB, MUL, DIV }
var mode: int = Mode.NONE

var typed: String = ""
var correct_answer: int = 0
var a: int = 0
var b: int = 0

# streak logic
var correct_streak: int = 0
var wrong_streak: int = 0
var longest_streak: int = 0
var total_correct: int = 0

# difficulty for MUL/DIV
var muldiv_max: int = 9  # starts at 9x9

# difficulty for ADD/SUB (cap on sum/result range)
var addsub_cap: int = 20 # starts at 20
var up_step: int = 10    # +10, +20, +40...
var down_step: int = 10  # -10, -20, -40...

const MUL_DIV_MIN: int = 5
const MUL_DIV_MAX: int = 30

const ADD_SUB_MIN_CAP: int = 10
const ADD_SUB_MAX_CAP: int = 9999

# Round timer (you said “60 minute” but described “60 seconds” — using 60 seconds)
# If you truly want 60 minutes, set this to 3600.0
const ROUND_SECONDS: float = 60.0
var round_end_ms: int = 0
var round_active: bool = false

# Coins conversion
const COINS_PER_POINT: int = 1  # coins earned = (total_correct + longest_streak) * this

# End-of-round popup
var end_dialog: ConfirmationDialog


# ---------------- LIFECYCLE ----------------
func _ready() -> void:
	randomize()
	set_process(false)

	back_btn.pressed.connect(_on_back_pressed)

	_build_keypad()
	enter_btn.pressed.connect(_on_enter_pressed)

	# Hook mode selection
	add_btn.pressed.connect(func() -> void: _select_mode(Mode.ADD))
	sub_btn.pressed.connect(func() -> void: _select_mode(Mode.SUB))
	mul_btn.pressed.connect(func() -> void: _select_mode(Mode.MUL))
	div_btn.pressed.connect(func() -> void: _select_mode(Mode.DIV))

	# Make ModePanel fullscreen overlay + block clicks
	if mode_panel:
		mode_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mode_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		mode_panel.z_index = 100

	# End dialog setup
	end_dialog = ConfirmationDialog.new()
	end_dialog.title = "Time's up!"
	end_dialog.exclusive = true  # ✅ Godot 4.x (NOT popup_exclusive)
	add_child(end_dialog)

	# Buttons: OK = play again, Cancel = back
	end_dialog.confirmed.connect(func() -> void:
		_show_mode_panel()
	)
	end_dialog.canceled.connect(func() -> void:
		_on_back_pressed()
	)

	end_dialog.get_ok_button().text = "Play again"
	if end_dialog.get_cancel_button():
		end_dialog.get_cancel_button().text = "Back"

	_show_mode_panel()


func _process(_delta: float) -> void:
	if not round_active:
		return

	var ms_left: int = round_end_ms - Time.get_ticks_msec()
	if ms_left <= 0:
		_end_round()
		return

	var secs_left: int = int(ceil(ms_left / 1000.0))
	if timer_label:
		timer_label.text = "Time: %ds" % secs_left


# ---------------- MODE UI ----------------
func _show_mode_panel() -> void:
	_stop_round()

	mode = Mode.NONE
	mode_panel.visible = true
	_set_gameplay_enabled(false)

	feedback_label.text = ""
	question_label.text = ""
	typed = ""
	_update_answer_ui()

	if score_label:
		score_label.text = ""
	if timer_label:
		timer_label.text = ""


func _select_mode(m: int) -> void:
	mode = m
	mode_panel.visible = false
	_set_gameplay_enabled(true)

	_reset_difficulty_for_mode()
	_reset_round_stats()

	_start_round_timer()
	_new_question()
	_update_hud()


func _set_gameplay_enabled(enabled: bool) -> void:
	for c in keypad.get_children():
		if c is Button:
			(c as Button).disabled = not enabled
	enter_btn.disabled = not enabled


# ---------------- ROUND TIMER ----------------
func _start_round_timer() -> void:
	round_active = true
	round_end_ms = Time.get_ticks_msec() + int(ROUND_SECONDS * 1000.0)
	set_process(true)

	if timer_label:
		timer_label.text = "Time: %ds" % int(ROUND_SECONDS)


func _stop_round() -> void:
	round_active = false
	set_process(false)


func _end_round() -> void:
	if not round_active:
		return

	_stop_round()
	_set_gameplay_enabled(false)

	var score: int = total_correct + longest_streak
	var coins_earned: int = score * COINS_PER_POINT

	# Add coins to global state
	GameState.coins = int(GameState.coins) + coins_earned

	# Show results
	var mode_name: String = _mode_name(mode)
	end_dialog.dialog_text = "%s round finished!\n\nCorrect: %d\nLongest streak: %d\nScore: %d\n\n+%d coins" % [
		mode_name, total_correct, longest_streak, score, coins_earned
	]
	end_dialog.popup_centered_ratio(0.6)


# ---------------- DIFFICULTY + STATS ----------------
func _reset_round_stats() -> void:
	typed = ""
	total_correct = 0
	correct_streak = 0
	wrong_streak = 0
	longest_streak = 0
	_update_answer_ui()
	feedback_label.text = ""


func _reset_difficulty_for_mode() -> void:
	if mode == Mode.MUL or mode == Mode.DIV:
		muldiv_max = 9

	if mode == Mode.ADD or mode == Mode.SUB:
		addsub_cap = 20
		up_step = 10
		down_step = 10


func _on_correct() -> void:
	total_correct += 1

	wrong_streak = 0
	correct_streak += 1
	longest_streak = maxi(longest_streak, correct_streak)

	feedback_label.text = "Correct!"
	_update_hud()

	# every 3 correct in a row => harder
	if correct_streak % 3 == 0:
		_increase_difficulty()

	await get_tree().create_timer(0.20).timeout
	_new_question()


func _on_wrong() -> void:
	# Wrong answer disappears immediately
	typed = ""
	_update_answer_ui()

	feedback_label.text = "Wrong!"
	correct_streak = 0

	# Only decrease difficulty after 3 wrong in a row
	wrong_streak += 1
	if wrong_streak % 3 == 0:
		_decrease_difficulty()

	_update_hud()

	await get_tree().create_timer(0.20).timeout
	_new_question()


func _increase_difficulty() -> void:
	if mode == Mode.MUL or mode == Mode.DIV:
		muldiv_max = clampi(muldiv_max + 1, MUL_DIV_MIN, MUL_DIV_MAX)
	elif mode == Mode.ADD or mode == Mode.SUB:
		addsub_cap = min(addsub_cap + up_step, ADD_SUB_MAX_CAP)
		up_step = min(up_step * 2, ADD_SUB_MAX_CAP)
		down_step = 10


func _decrease_difficulty() -> void:
	if mode == Mode.MUL or mode == Mode.DIV:
		muldiv_max = clampi(muldiv_max - 1, MUL_DIV_MIN, MUL_DIV_MAX)
	elif mode == Mode.ADD or mode == Mode.SUB:
		addsub_cap = max(addsub_cap - down_step, ADD_SUB_MIN_CAP)
		down_step = min(down_step * 2, ADD_SUB_MAX_CAP)
		up_step = 10


func _update_hud() -> void:
	if score_label == null:
		return

	var diff_info := ""
	if mode == Mode.MUL or mode == Mode.DIV:
		diff_info = " %dx%d" % [muldiv_max, muldiv_max]
	elif mode == Mode.ADD or mode == Mode.SUB:
		diff_info = " cap:%d" % addsub_cap

	score_label.text = "%s  correct:%d  best:%d%s" % [
		_mode_name(mode), total_correct, longest_streak, diff_info
	]


func _mode_name(m: int) -> String:
	match m:
		Mode.ADD: return "ADD"
		Mode.SUB: return "SUB"
		Mode.MUL: return "MUL"
		Mode.DIV: return "DIV"
		_: return ""


# ---------------- QUESTION GEN ----------------
func _new_question() -> void:
	if mode == Mode.NONE:
		return
	if not round_active:
		return

	typed = ""
	_update_answer_ui()
	feedback_label.text = ""

	match mode:
		Mode.ADD:
			a = randi_range(0, addsub_cap)
			b = randi_range(0, addsub_cap - a)
			correct_answer = a + b
			question_label.text = "%d + %d = ?" % [a, b]

		Mode.SUB:
			a = randi_range(0, addsub_cap)
			b = randi_range(0, a)
			correct_answer = a - b
			question_label.text = "%d - %d = ?" % [a, b]

		Mode.MUL:
			a = randi_range(1, muldiv_max)
			b = randi_range(1, muldiv_max)
			correct_answer = a * b
			question_label.text = "%d × %d = ?" % [a, b]

		Mode.DIV:
			var divisor: int = randi_range(1, muldiv_max)
			var quotient: int = randi_range(1, muldiv_max)
			var dividend: int = divisor * quotient
			correct_answer = quotient
			question_label.text = "%d ÷ %d = ?" % [dividend, divisor]


# ---------------- KEYPAD BUILD (3x4 digits + side Enter button node) ----------------
func _build_keypad() -> void:
	keypad.columns = 3

	for c in keypad.get_children():
		c.queue_free()

	# 1–9
	for n in range(1, 10):
		keypad.add_child(_make_digit_button(str(n)))

	# Bottom row: Clear, 0, Backspace
	keypad.add_child(_make_action_button("Clear", _on_clear_pressed))
	keypad.add_child(_make_digit_button("0"))
	keypad.add_child(_make_action_button("⌫", _on_backspace_pressed))


func _make_digit_button(t: String) -> Button:
	var btn := Button.new()
	btn.text = t
	btn.custom_minimum_size = Vector2(220, 120)
	btn.pressed.connect(func() -> void: _append_digit(t))
	return btn


func _make_action_button(t: String, cb: Callable) -> Button:
	var btn := Button.new()
	btn.text = t
	btn.custom_minimum_size = Vector2(220, 120)
	btn.pressed.connect(cb)
	return btn


# ---------------- INPUT LOGIC ----------------
func _append_digit(d: String) -> void:
	if not round_active:
		return

	if typed == "0":
		typed = d
	else:
		typed += d
	_update_answer_ui()


func _on_clear_pressed() -> void:
	typed = ""
	_update_answer_ui()


func _on_backspace_pressed() -> void:
	if typed.length() > 0:
		typed = typed.substr(0, typed.length() - 1)
	_update_answer_ui()


func _on_enter_pressed() -> void:
	if mode == Mode.NONE:
		return
	if not round_active:
		return

	if typed == "":
		feedback_label.text = "Type an answer!"
		return

	var guess: int = int(typed)
	if guess == correct_answer:
		_on_correct()
	else:
		_on_wrong()


func _update_answer_ui() -> void:
	answer_label.text = (typed if typed != "" else "_")


# ---------------- NAV ----------------
func _on_back_pressed() -> void:
	_stop_round()
	get_tree().change_scene_to_file("res://scenes/world/RoomHub.tscn")

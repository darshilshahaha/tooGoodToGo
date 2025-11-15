extends Window
class_name DaySummaryPopup

signal next_day

@onready var header_label: Label = %Header
@onready var used_list: RichTextLabel = %UsedList
@onready var wasted_list: RichTextLabel = %WastedList
@onready var score_label: Label = %ScoreLabel
@onready var event_label: Label = %EventLabel
@onready var next_button: Button = %NextDayButton
var preview_mode := false

func _ready() -> void:
	next_button.pressed.connect(_on_next_day)

func show_summary(day_number: int, used: Dictionary, wasted: Dictionary, score_delta: int, event_info: Dictionary, preview: bool = false) -> void:
	header_label.text = "Day %d Summary" % day_number
	used_list.text = _format_resource_text(used, "Nothing cooked today.")
	wasted_list.text = _format_resource_text(wasted, "No waste today!")
	score_label.text = "Score Change: %d" % score_delta
	var event_text: String = str(event_info.get("description", "Quiet day."))
	var result_text: String = str(event_info.get("result", ""))
	if result_text != "":
		event_text = "%s - %s" % [event_text, result_text]
	event_label.text = "Event: %s" % event_text
	preview_mode = preview
	next_button.text = "Close" if preview_mode else "Next Day"
	popup_centered_ratio(0.5)
	grab_focus()

func _format_resource_text(resources: Dictionary, fallback: String) -> String:
	if resources.is_empty():
		return fallback
	var lines: Array = []
	for key in resources.keys():
		lines.append("• %s x%d" % [key, resources[key]])
	lines.sort()
	return "\n".join(lines)

func _on_next_day() -> void:
	hide()
	if preview_mode:
		preview_mode = false
		return
	next_day.emit()

extends Control
class_name FinalSummary

@onready var total_used_label: Label = %TotalUsed
@onready var total_wasted_label: Label = %TotalWasted
@onready var final_score_label: Label = %FinalScore
@onready var feedback_label: Label = %Feedback
@onready var back_button: Button = %MainMenuButton

func _ready() -> void:
    back_button.pressed.connect(_on_back_pressed)

func show_results(total_used: Dictionary, total_wasted: Dictionary, score: int) -> void:
    total_used_label.text = "Total Used: %s" % _format_resource_line(total_used)
    total_wasted_label.text = "Total Wasted: %s" % _format_resource_line(total_wasted)
    final_score_label.text = "Final Score: %d" % score
    feedback_label.text = _feedback_for_score(score)

func _format_resource_line(resources: Dictionary) -> String:
    if resources.is_empty():
        return "0"
    var parts: Array = []
    for key in resources.keys():
        parts.append("%s x%d" % [key, resources[key]])
    parts.sort()
    return ", ".join(parts)

func _feedback_for_score(score: int) -> String:
    if score >= 20:
        return "Amazing planner! Practically zero waste."
    elif score >= 5:
        return "Solid effort. A few tweaks can reduce waste further."
    else:
        return "Waste was high. Try planning meals closer to expiry dates."

func _on_back_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

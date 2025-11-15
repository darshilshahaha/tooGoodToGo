extends VBoxContainer
class_name RecipeUI

signal recipe_assigned(recipe_name: String, meal_type: String)
signal clear_meal(meal_type: String)

@onready var recipe_list: VBoxContainer = %RecipeList
@onready var meal_slots: VBoxContainer = %MealSlots

var meal_labels: Dictionary = {}
var meal_types: Array = []
var recipe_buttons: Dictionary = {}

func _ready() -> void:
	_cache_meal_slots()

func setup_meal_slots(meal_names: Array) -> void:
	meal_types = meal_names
	_cache_meal_slots()

func set_recipes(recipes: Array, meal_names: Array) -> void:
	meal_types = meal_names
	_cache_meal_slots()
	for child in recipe_list.get_children():
		child.queue_free()
	recipe_buttons.clear()
	for recipe in recipes:
		var card := VBoxContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_constant_override("separation", 4)
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_label := Label.new()
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.text = recipe.get("name", "Recipe")
		name_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
		row.add_child(name_label)
		var buttons := HBoxContainer.new()
		buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		for meal_type in meal_types:
			var assign_button := Button.new()
			assign_button.text = meal_type.capitalize()
			assign_button.focus_mode = Control.FOCUS_NONE
			assign_button.pressed.connect(Callable(self, "_on_assign_button_pressed").bind(recipe.get("name", "Recipe"), meal_type))
			buttons.add_child(assign_button)
			recipe_buttons[_button_key(recipe.get("name", "Recipe"), meal_type)] = assign_button
		row.add_child(buttons)
		card.add_child(row)
		if recipe.has("description"):
			var description_label := Label.new()
			description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			description_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			description_label.text = recipe.get("description", "")
			description_label.add_theme_color_override("font_color", Color(0.78, 0.83, 0.9))
			description_label.add_theme_font_size_override("font_size", 12)
			card.add_child(description_label)
		var separator := HSeparator.new()
		card.add_child(separator)
		recipe_list.add_child(card)

func update_recipe_availability(availability: Dictionary) -> void:
	for key in recipe_buttons.keys():
		var button: Button = recipe_buttons[key]
		var recipe_name: String = str(key).split("::")[0]
		var can_use: bool = bool(availability.get(recipe_name, true))
		button.disabled = not can_use

func update_meal_slot(meal_type: String, recipe_name: String) -> void:
	var label: Label = meal_labels.get(meal_type, null)
	if label:
		label.text = recipe_name if recipe_name else "None"

func show_recipe_blocked(recipe_name: String, meal_type: String) -> void:
	push_warning("Cannot assign %s to %s. Missing ingredients." % [recipe_name, meal_type])

func _cache_meal_slots() -> void:
	if meal_slots == null:
		return
	meal_labels.clear()
	for slot in meal_slots.get_children():
		if not slot is HBoxContainer:
			continue
		var meal_type := slot.name.to_lower()
		var value_name := "%sValue" % slot.name
		if slot.has_node(value_name):
			var label: Label = slot.get_node(value_name)
			meal_labels[meal_type] = label
		if slot.has_node("%sClear" % slot.name):
			var clear_button: Button = slot.get_node("%sClear" % slot.name)
			if not clear_button.pressed.is_connected(Callable(self, "_on_clear_button_pressed")):
				clear_button.pressed.connect(Callable(self, "_on_clear_button_pressed").bind(meal_type))

func _on_assign_button_pressed(recipe_name: String, meal_type: String) -> void:
	recipe_assigned.emit(recipe_name, meal_type)

func _on_clear_button_pressed(meal_type: String) -> void:
	clear_meal.emit(meal_type)

func _button_key(recipe_name: String, meal_type: String) -> String:
	return "%s::%s" % [recipe_name, meal_type]

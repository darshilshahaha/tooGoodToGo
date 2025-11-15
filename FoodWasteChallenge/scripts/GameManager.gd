extends Control

const TOTAL_DAYS := 7
const MEAL_TYPES := ["breakfast", "lunch", "dinner"]

const STARTING_INVENTORY := [
	{"name": "Tomato", "category": "vegetable", "storage": "fridge", "shelf_life": 3, "days_left": 3, "quantity": 4},
	{"name": "Bread", "category": "grain", "storage": "pantry", "shelf_life": 2, "days_left": 2, "quantity": 4},
	{"name": "Pasta", "category": "grain", "storage": "pantry", "shelf_life": 5, "days_left": 5, "quantity": 3},
	{"name": "Cheese", "category": "dairy", "storage": "fridge", "shelf_life": 4, "days_left": 4, "quantity": 3},
	{"name": "Eggs", "category": "protein", "storage": "fridge", "shelf_life": 4, "days_left": 4, "quantity": 6},
	{"name": "Spinach", "category": "vegetable", "storage": "fridge", "shelf_life": 2, "days_left": 2, "quantity": 3},
	{"name": "Chicken", "category": "protein", "storage": "fridge", "shelf_life": 3, "days_left": 3, "quantity": 2},
	{"name": "Rice", "category": "grain", "storage": "pantry", "shelf_life": 6, "days_left": 6, "quantity": 3},
	{"name": "Yogurt", "category": "dairy", "storage": "fridge", "shelf_life": 3, "days_left": 3, "quantity": 2}
]

const RECIPES := [
	{
		"name": "Sunrise Scramble",
		"meal_type": "breakfast",
		"description": "Eggs with spinach and cheese.",
		"ingredients": [
			{"item_name": "Eggs", "quantity": 2},
			{"item_name": "Spinach", "quantity": 1},
			{"item_name": "Cheese", "quantity": 1}
		]
	},
	{
		"name": "Tomato Sandwich",
		"meal_type": "lunch",
		"description": "Quick sandwich to use ripe tomatoes.",
		"ingredients": [
			{"item_name": "Tomato", "quantity": 1},
			{"item_name": "Bread", "quantity": 1}
		]
	},
	{
		"name": "Pasta Dinner",
		"meal_type": "dinner",
		"description": "Comfort pasta with tomato sauce.",
		"ingredients": [
			{"item_name": "Pasta", "quantity": 1},
			{"item_name": "Tomato", "quantity": 1},
			{"item_name": "Cheese", "quantity": 1}
		]
	},
	{
		"name": "Chicken Stir Fry",
		"meal_type": "dinner",
		"description": "Uses chicken, rice, and spinach.",
		"ingredients": [
			{"item_name": "Chicken", "quantity": 1},
			{"item_name": "Rice", "quantity": 1},
			{"item_name": "Spinach", "quantity": 1}
		]
	},
	{
		"name": "Cheesy Garlic Bread",
		"meal_type": "lunch",
		"description": "Great for using leftover bread/cheese.",
		"ingredients": [
			{"item_name": "Bread", "quantity": 1},
			{"item_name": "Cheese", "quantity": 1}
		]
	},
	{
		"name": "Yogurt Parfait",
		"meal_type": "breakfast",
		"description": "Quick breakfast to save dairy.",
		"ingredients": [
			{"item_name": "Yogurt", "quantity": 1},
			{"item_name": "Bread", "quantity": 1}
		]
	},
	{
		"name": "Veggie Rice Bowl",
		"meal_type": "lunch",
		"description": "Spinach, tomato, rice combo.",
		"ingredients": [
			{"item_name": "Rice", "quantity": 1},
			{"item_name": "Tomato", "quantity": 1},
			{"item_name": "Spinach", "quantity": 1}
		]
	}
]

const EVENTS := [
	{"id": "friend_over", "description": "A friend came over! Need one extra dinner portion.", "effect": "extra_dinner"},
	{"id": "night_out", "description": "You went out to eat, dinner is skipped.", "effect": "skip_dinner"},
	{"id": "market_deal", "description": "Local market had a deal. Pantry restocked!", "effect": "restock"},
	{"id": "surprise_leftovers", "description": "Found perfectly good leftovers.", "effect": "refund_lunch"},
	{"id": "smoothie_craving", "description": "Craving a breakfast smoothie.", "effect": "extra_breakfast"}
]

const DAY_SUMMARY_SCENE := preload("res://scenes/DaySummary.tscn")
const FINAL_SUMMARY_SCENE := preload("res://scenes/FinalSummary.tscn")

@onready var day_label: Label = %DayLabel
@onready var score_label: Label = %ScoreLabel
@onready var end_day_button: Button = %EndDayButton
@onready var summary_button: Button = %SummaryButton
@onready var inventory_ui: InventoryUI = %InventoryPanel
@onready var recipe_ui: RecipeUI = %RecipePanel

var current_day := 0
var score := 0
var inventory: Array = []
var today_meal_plan: Dictionary = {}
var meal_consumption: Dictionary = {}
var used_totals: Dictionary = {}
var wasted_totals: Dictionary = {}
var total_used: Dictionary = {}
var total_wasted: Dictionary = {}
var summary_pending := false
var last_event_info: Dictionary = {}
var last_score_delta := 0
var day_summary_window: DaySummaryPopup
var final_summary_screen: FinalSummary
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	inventory = _duplicate_inventory(STARTING_INVENTORY)
	day_summary_window = DAY_SUMMARY_SCENE.instantiate() as DaySummaryPopup
	add_child(day_summary_window)
	day_summary_window.next_day.connect(_on_next_day_from_summary)
	final_summary_screen = null
	if recipe_ui:
		recipe_ui.setup_meal_slots(MEAL_TYPES)
		recipe_ui.set_recipes(RECIPES, MEAL_TYPES)
		recipe_ui.recipe_assigned.connect(_on_recipe_assigned)
		recipe_ui.clear_meal.connect(_on_clear_meal)
	end_day_button.pressed.connect(_on_end_day_pressed)
	summary_button.pressed.connect(_on_show_summary_pressed)
	start_day()

func start_day() -> void:
	current_day += 1
	today_meal_plan.clear()
	meal_consumption.clear()
	used_totals.clear()
	wasted_totals.clear()
	for meal in MEAL_TYPES:
		today_meal_plan[meal] = null
		if recipe_ui:
			recipe_ui.update_meal_slot(meal, "")
	_apply_daily_spoilage()
	_update_top_bar()
	_update_ui_post_inventory_change()
	summary_pending = false

func _apply_daily_spoilage() -> void:
	var spoiled := {}
	for item in inventory:
		item["days_left"] = max(int(item.get("days_left", 0)) - 1, 0)
		var quantity := int(item.get("quantity", 0))
		if item["days_left"] <= 0 and quantity > 0:
			spoiled[item["name"]] = spoiled.get(item["name"], 0) + quantity
			item["quantity"] = 0
			_add_to_resource_map(wasted_totals, item["name"], quantity)
			_add_to_resource_map(total_wasted, item["name"], quantity)
	if not spoiled.is_empty():
		push_warning("Spoiled overnight: %s" % _format_resource_line(spoiled))

func _update_top_bar() -> void:
	day_label.text = "Day %d of %d" % [current_day, TOTAL_DAYS]
	score_label.text = "Score: %d" % score

func _update_ui_post_inventory_change() -> void:
	if inventory_ui:
		inventory_ui.update_inventory_display(inventory)
	if recipe_ui:
		recipe_ui.update_recipe_availability(_build_recipe_availability())

func _build_recipe_availability() -> Dictionary:
	var availability := {}
	for recipe in RECIPES:
		availability[recipe["name"]] = _can_use_recipe(recipe)
	return availability

func _on_recipe_assigned(recipe_name: String, meal_type: String) -> void:
	var normalized := meal_type.to_lower()
	var recipe := _get_recipe(recipe_name)
	if recipe.is_empty():
		return
	if today_meal_plan.get(normalized, null) == recipe:
		return
	if not _can_use_recipe(recipe):
		if recipe_ui:
			recipe_ui.show_recipe_blocked(recipe_name, normalized)
		return
	if today_meal_plan.get(normalized, null) != null:
		_release_meal(normalized)
	_consume_recipe(recipe, normalized, 1, true)
	today_meal_plan[normalized] = recipe
	if recipe_ui:
		recipe_ui.update_meal_slot(normalized, recipe_name)
	_update_ui_post_inventory_change()

func _on_clear_meal(meal_type: String) -> void:
	var normalized := meal_type.to_lower()
	if today_meal_plan.get(normalized, null) == null:
		return
	_release_meal(normalized)
	if recipe_ui:
		recipe_ui.update_meal_slot(normalized, "")
	_update_ui_post_inventory_change()

func _release_meal(meal_type: String) -> void:
	var consumption: Dictionary = meal_consumption.get(meal_type, {})
	for item_name in consumption.keys():
		var qty: int = int(consumption[item_name])
		_adjust_inventory(item_name, qty)
		_add_to_resource_map(used_totals, item_name, -qty)
		_add_to_resource_map(total_used, item_name, -qty)
	meal_consumption.erase(meal_type)
	today_meal_plan[meal_type] = null

func _consume_recipe(recipe: Dictionary, meal_type: String, multiplier: int = 1, track_meal: bool = true) -> void:
	var consumption := {}
	for ingredient in recipe.get("ingredients", []):
		var qty := int(ingredient.get("quantity", 0)) * multiplier
		if qty <= 0:
			continue
		var item_name: String = str(ingredient.get("item_name", ""))
		_adjust_inventory(item_name, -qty)
		_add_to_resource_map(used_totals, item_name, qty)
		_add_to_resource_map(total_used, item_name, qty)
		consumption[item_name] = consumption.get(item_name, 0) + qty
	if track_meal:
		meal_consumption[meal_type] = consumption

func _adjust_inventory(item_name: String, delta: int) -> void:
	for item in inventory:
		if item.get("name", "") == item_name:
			item["quantity"] = max(0, int(item.get("quantity", 0)) + delta)
			if delta > 0 and item["quantity"] > 0:
				item["days_left"] = max(item.get("days_left", item.get("shelf_life", 1)), 1)
			return
	if delta > 0:
		inventory.append({
			"name": item_name,
			"category": "misc",
			"storage": "pantry",
			"shelf_life": 2,
			"days_left": 2,
			"quantity": delta
		})

func _can_use_recipe(recipe: Dictionary) -> bool:
	for ingredient in recipe.get("ingredients", []):
		var available := _get_item_quantity(ingredient.get("item_name", ""))
		if available < int(ingredient.get("quantity", 0)):
			return false
	return true

func _get_item_quantity(item_name: String) -> int:
	for item in inventory:
		if item.get("name", "") == item_name:
			return int(item.get("quantity", 0))
	return 0

func _get_recipe(recipe_name: String) -> Dictionary:
	for recipe in RECIPES:
		if recipe.get("name", "") == recipe_name:
			return recipe
	return {}

func _on_end_day_pressed() -> void:
	if summary_pending:
		return
	last_event_info = _trigger_daily_event()
	last_score_delta = _calculate_score_delta(used_totals, wasted_totals)
	score += last_score_delta
	_update_top_bar()
	summary_pending = true
	day_summary_window.show_summary(current_day, used_totals.duplicate(), wasted_totals.duplicate(), last_score_delta, last_event_info)

func _on_show_summary_pressed() -> void:
	var preview_delta := _calculate_score_delta(used_totals, wasted_totals)
	var preview_event := {"description": "Planning preview", "result": "Score delta if you ended now: %d" % preview_delta}
	day_summary_window.show_summary(current_day, used_totals.duplicate(), wasted_totals.duplicate(), preview_delta, preview_event, true)

func _on_next_day_from_summary() -> void:
	if not summary_pending:
		return
	summary_pending = false
	if current_day >= TOTAL_DAYS:
		_show_final_summary()
	else:
		start_day()

func _trigger_daily_event() -> Dictionary:
	if rng.randf() > 0.65:
		return {"id": "none", "description": "A calm day.", "result": "No changes."}
	var event: Dictionary = EVENTS[rng.randi_range(0, EVENTS.size() - 1)]
	var result: String = ""
	match event.get("effect", ""):
		"extra_dinner":
			result = _apply_extra_portion("dinner")
		"extra_breakfast":
			result = _apply_extra_portion("breakfast")
		"skip_dinner":
			result = _apply_skip_meal("dinner")
		"refund_lunch":
			result = _apply_skip_meal("lunch", true)
		"restock":
			result = _apply_restock()
		_:
			result = "Nothing happened."
	_update_ui_post_inventory_change()
	return {"id": event.get("id", "event"), "description": event.get("description", "Event"), "result": result}

func _apply_extra_portion(meal_type: String) -> String:
	var recipe: Variant = today_meal_plan.get(meal_type, null)
	if recipe == null:
		return "No %s planned." % meal_type
	if not _can_use_recipe(recipe):
		return "Not enough ingredients for extra %s." % meal_type
	_consume_recipe(recipe, meal_type + "_extra", 1, false)
	return "Used extra ingredients for %s." % meal_type

func _apply_skip_meal(meal_type: String, mark_leftovers := false) -> String:
	if today_meal_plan.get(meal_type, null) == null:
		return "%s was already free." % meal_type.capitalize()
	_release_meal(meal_type)
	if recipe_ui:
		recipe_ui.update_meal_slot(meal_type, "")
	if mark_leftovers:
		return "%s ingredients returned to storage thanks to leftovers." % meal_type.capitalize()
	return "%s skipped, ingredients returned." % meal_type.capitalize()

func _apply_restock() -> String:
	var restock_pool := [
		{"name": "Lettuce", "category": "vegetable", "storage": "fridge", "shelf_life": 3, "days_left": 3, "quantity": 2},
		{"name": "Rice", "category": "grain", "storage": "pantry", "shelf_life": 6, "days_left": 6, "quantity": 2},
		{"name": "Milk", "category": "dairy", "storage": "fridge", "shelf_life": 3, "days_left": 3, "quantity": 1},
		{"name": "Yogurt", "category": "dairy", "storage": "fridge", "shelf_life": 3, "days_left": 3, "quantity": 2}
	]
	var haul: Dictionary = restock_pool[rng.randi_range(0, restock_pool.size() - 1)]
	inventory.append(haul.duplicate(true))
	return "Received extra %s." % haul.get("name", "ingredients")

func _calculate_score_delta(used: Dictionary, wasted: Dictionary) -> int:
	var used_total := 0
	for value in used.values():
		used_total += int(value)
	var wasted_total := 0
	for value in wasted.values():
		wasted_total += int(value)
	return used_total - (2 * wasted_total)

func _show_final_summary() -> void:
	if final_summary_screen == null:
		final_summary_screen = FINAL_SUMMARY_SCENE.instantiate() as FinalSummary
		add_child(final_summary_screen)
	final_summary_screen.show_results(total_used.duplicate(), total_wasted.duplicate(), score)
	final_summary_screen.visible = true
	end_day_button.disabled = true
	summary_button.disabled = true

func _add_to_resource_map(resource_map: Dictionary, key: String, delta: int) -> void:
	if delta == 0:
		return
	var updated: int = int(resource_map.get(key, 0)) + delta
	if updated <= 0:
		resource_map.erase(key)
	else:
		resource_map[key] = updated

func _duplicate_inventory(source: Array) -> Array:
	var clone: Array = []
	for entry in source:
		clone.append(entry.duplicate(true))
	return clone

func _format_resource_line(resources: Dictionary) -> String:
	var parts: Array = []
	for key in resources.keys():
		parts.append("%s x%d" % [key, resources[key]])
	if parts.is_empty():
		return "None"
	parts.sort()
	return ", ".join(parts)

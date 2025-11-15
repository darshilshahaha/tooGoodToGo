extends VBoxContainer
class_name InventoryUI

@onready var pantry_list: ItemList = %PantryList
@onready var fridge_list: ItemList = %FridgeList

func update_inventory_display(inventory: Array) -> void:
	if pantry_list == null or fridge_list == null:
		return
	pantry_list.clear()
	fridge_list.clear()
	for item in inventory:
		var quantity := int(item.get("quantity", 0))
		if quantity <= 0:
			continue
		var category: String = str(item.get("category", "misc"))
		var entry := "%s • %s x%d (%d days left)" % [category.capitalize(), item.get("name", "Unknown"), quantity, max(int(item.get("days_left", 0)), 0)]
		if item.get("storage", "pantry") == "fridge":
			fridge_list.add_item(entry)
		else:
			pantry_list.add_item(entry)

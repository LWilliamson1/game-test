extends Node
class_name HerbQuest
## "A Herb for the Healer" — the introductory fetch quest.
## Sage Elara needs 3 Silverleaf herbs from the wilderness.
## Completing this quest unlocks "The Ashfall Menace."

const QUEST_ID := "herb_for_healer"
const OBJ_COLLECT_HERBS := "collect_herbs"
const OBJ_RETURN_ELARA := "return_elara"

var quest_active: bool = false
var quest_complete: bool = false
var herbs_collected: int = 0


func _ready() -> void:
	add_to_group("herb_quest")
	_register_quest()
	call_deferred("_connect_npc_dialogues")

	QuestManager.quest_started.connect(_on_quest_started)
	QuestManager.quest_completed.connect(_on_quest_completed)
	InventoryManager.item_added.connect(_on_item_added)


func _register_quest() -> void:
	var quest := QuestData.new()
	quest.quest_id = QUEST_ID
	quest.title = "A Herb for the Healer"
	quest.description = "Sage Elara, the village herbalist, is running low on Silverleaf herbs needed for her potions. She's asked you to gather 3 from the hillsides outside Millhaven."
	quest.quest_type = QuestData.QuestType.SIDE
	quest.reward_xp = 75.0
	quest.reward_gold = 25

	var obj1 := QuestObjective.new()
	obj1.objective_id = OBJ_COLLECT_HERBS
	obj1.description = "Collect Silverleaf herbs from the hillsides"
	obj1.type = QuestObjective.ObjectiveType.COLLECT
	obj1.target_id = "silverleaf"
	obj1.required_count = 3

	var obj2 := QuestObjective.new()
	obj2.objective_id = OBJ_RETURN_ELARA
	obj2.description = "Return the herbs to Sage Elara"
	obj2.type = QuestObjective.ObjectiveType.TALK_TO
	obj2.target_id = "sage_elara"
	obj2.required_count = 1

	quest.objectives = [obj1, obj2]
	QuestManager.register_quest(quest)


func _connect_npc_dialogues() -> void:
	for npc in get_tree().get_nodes_in_group("npcs"):
		if npc.name == "Sage_Elara":
			_setup_elara_npc(npc)


func _setup_elara_npc(npc: CharacterBody3D) -> void:
	var script := GDScript.new()
	script.source_code = """extends CharacterBody3D

var quest_node: Node = null

func interact(player: CharacterBody3D) -> void:
	if quest_node == null:
		quest_node = get_tree().get_first_node_in_group("herb_quest")
	if quest_node:
		quest_node.elara_dialogue()
	else:
		var dialogue := DialogueData.new()
		var entry := DialogueEntry.new()
		entry.id = "greet"
		entry.speaker_name = "Sage Elara"
		entry.text = "Potions, salves, remedies. What ails you, traveler?"
		dialogue.entries = [entry]
		DialogueManager.start_dialogue(dialogue)
"""
	script.reload()
	npc.set_script(script)


## ----------- Dialogue builder -----------

func elara_dialogue() -> void:
	var dialogue := DialogueData.new()

	if quest_complete:
		var entry := DialogueEntry.new()
		entry.id = "done"
		entry.speaker_name = "Sage Elara"
		entry.text = "The potions are brewing nicely thanks to you. If you're looking for more work, I heard Elder Aldric has been troubled by something. You should speak with him."
		dialogue.entries = [entry]

	elif quest_active and InventoryManager.get_item_count("silverleaf") >= 3:
		# Turn in
		var entry1 := DialogueEntry.new()
		entry1.id = "turnin"
		entry1.speaker_name = "Sage Elara"
		entry1.text = "Wonderful! You found them! These are perfect specimens. Let me take those off your hands..."
		entry1.next_entry_id = "reward"

		var entry2 := DialogueEntry.new()
		entry2.id = "reward"
		entry2.speaker_name = "Sage Elara"
		entry2.text = "Here — take these health potions. I always keep a few extra for friends of the shop. Oh, and you should speak with Elder Aldric. He's been looking for someone capable."

		dialogue.entries = [entry1, entry2]
		DialogueManager.dialogue_ended.connect(_on_turnin, CONNECT_ONE_SHOT)

	elif quest_active:
		var entry := DialogueEntry.new()
		entry.id = "reminder"
		entry.speaker_name = "Sage Elara"
		entry.text = "Still searching? Silverleaf grows on the hillsides outside the village. Look for the silvery-green glow among the rocks and trees. I need 3 more to finish my batch."
		dialogue.entries = [entry]

	else:
		# Quest offer
		var entry1 := DialogueEntry.new()
		entry1.id = "intro"
		entry1.speaker_name = "Sage Elara"
		entry1.text = "Potions, salves, remedies... though I'm running low on supplies. I need Silverleaf herbs, but my old knees won't carry me up those hills anymore."

		var choice1 := DialogueChoice.new()
		choice1.text = "I can gather some for you. Where do they grow?"
		choice1.next_entry_id = "accept"

		var choice2 := DialogueChoice.new()
		choice2.text = "What's in it for me?"
		choice2.next_entry_id = "reward_ask"

		var choice3 := DialogueChoice.new()
		choice3.text = "Maybe later."
		choice3.next_entry_id = "decline"

		entry1.choices = [choice1, choice2, choice3]

		var entry_accept := DialogueEntry.new()
		entry_accept.id = "accept"
		entry_accept.speaker_name = "Sage Elara"
		entry_accept.text = "Bless you! Silverleaf grows on the hillsides outside the village — look for a silvery-green glow near rocks and trees. I need just 3 to finish my current batch."

		var entry_reward := DialogueEntry.new()
		entry_reward.id = "reward_ask"
		entry_reward.speaker_name = "Sage Elara"
		entry_reward.text = "Health potions, of course! A traveler can never have too many. And a bit of gold for your trouble. The herbs grow on the hillsides outside the village — I need 3."

		var entry_decline := DialogueEntry.new()
		entry_decline.id = "decline"
		entry_decline.speaker_name = "Sage Elara"
		entry_decline.text = "Of course, no rush. You know where to find me if you change your mind."

		dialogue.entries = [entry1, entry_accept, entry_reward, entry_decline]
		DialogueManager.dialogue_ended.connect(_on_offer_ended, CONNECT_ONE_SHOT)

	DialogueManager.start_dialogue(dialogue)


## ----------- Event handlers -----------

func _on_offer_ended() -> void:
	if not quest_active:
		QuestManager.start_quest(QUEST_ID)


func _on_quest_started(quest_id: String) -> void:
	if quest_id == QUEST_ID:
		quest_active = true


func _on_quest_completed(quest_id: String) -> void:
	if quest_id == QUEST_ID:
		quest_complete = true
		# Grant 3 health potions as reward
		var potion := load("res://resources/items/health_potion.tres") as ItemData
		if potion:
			InventoryManager.add_item(potion, 3)


func _on_turnin() -> void:
	# Remove the herbs from inventory
	InventoryManager.remove_item("silverleaf", 3)
	QuestManager.update_objective(QUEST_ID, OBJ_RETURN_ELARA)


func _on_item_added(item: ItemData, _quantity: int) -> void:
	if not quest_active or quest_complete:
		return
	if item.id == "silverleaf":
		herbs_collected = InventoryManager.get_item_count("silverleaf")
		if herbs_collected <= 3:
			QuestManager.update_objective(QUEST_ID, OBJ_COLLECT_HERBS)

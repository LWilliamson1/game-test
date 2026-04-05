extends Node
class_name StarterQuest
## "The Ashfall Menace" — the introductory quest.
## Registers the quest, builds NPC dialogue trees, and connects triggers.

const QUEST_ID := "ashfall_menace"
const OBJ_TALK_ELDER := "talk_elder"
const OBJ_TALK_STRANGER := "talk_stranger"
const OBJ_KILL_SKELETONS := "kill_skeletons"
const OBJ_COLLECT_AMULET := "collect_amulet"
const OBJ_RETURN_ELDER := "return_elder"

var skeletons_killed: int = 0
var amulet_collected: bool = false
var quest_active: bool = false
var quest_complete: bool = false


func _ready() -> void:
	add_to_group("starter_quest")
	_register_quest()
	_setup_dialogues()

	# Listen for quest events
	QuestManager.quest_started.connect(_on_quest_started)
	QuestManager.quest_completed.connect(_on_quest_completed)


func _register_quest() -> void:
	var quest := QuestData.new()
	quest.quest_id = QUEST_ID
	quest.title = "The Ashfall Menace"
	quest.description = "Elder Aldric has asked you to investigate the creatures emerging from Ashfall Cavern to the east of Millhaven. A mysterious stranger near the cave may know more."
	quest.quest_type = QuestData.QuestType.MAIN
	quest.reward_xp = 150.0
	quest.reward_gold = 75
	quest.prerequisite_quest_ids = ["herb_for_healer"]

	var obj1 := QuestObjective.new()
	obj1.objective_id = OBJ_TALK_STRANGER
	obj1.description = "Speak with the stranger near Ashfall Cavern"
	obj1.type = QuestObjective.ObjectiveType.TALK_TO
	obj1.target_id = "the_stranger"
	obj1.required_count = 1

	var obj2 := QuestObjective.new()
	obj2.objective_id = OBJ_KILL_SKELETONS
	obj2.description = "Defeat the skeletons near the cavern"
	obj2.type = QuestObjective.ObjectiveType.KILL
	obj2.target_id = "skeleton"
	obj2.required_count = 3

	var obj3 := QuestObjective.new()
	obj3.objective_id = OBJ_COLLECT_AMULET
	obj3.description = "Collect the Ancient Amulet"
	obj3.type = QuestObjective.ObjectiveType.COLLECT
	obj3.target_id = "ancient_amulet"
	obj3.required_count = 1

	var obj4 := QuestObjective.new()
	obj4.objective_id = OBJ_RETURN_ELDER
	obj4.description = "Return to Elder Aldric"
	obj4.type = QuestObjective.ObjectiveType.TALK_TO
	obj4.target_id = "elder_aldric"
	obj4.required_count = 1

	quest.objectives = [obj1, obj2, obj3, obj4]
	QuestManager.register_quest(quest)


func _setup_dialogues() -> void:
	# We override the NPC interact scripts at runtime via signals
	# The VillageNPCs spawn with simple greetings, but we replace them
	# when the quest is relevant by connecting to DialogueManager
	call_deferred("_connect_npc_dialogues")


func _connect_npc_dialogues() -> void:
	# Find the Elder Aldric and Stranger NPCs and override their scripts
	for npc in get_tree().get_nodes_in_group("npcs"):
		if npc.name == "Elder_Aldric":
			_setup_elder_npc(npc)
		elif npc.name == "The_Stranger":
			_setup_stranger_npc(npc)


func _setup_elder_npc(npc: CharacterBody3D) -> void:
	var script := GDScript.new()
	script.source_code = """extends CharacterBody3D

var quest_node: Node = null

func interact(player: CharacterBody3D) -> void:
	if quest_node == null:
		quest_node = get_tree().get_first_node_in_group("starter_quest")
	if quest_node:
		quest_node.elder_dialogue()
	else:
		# Fallback
		var dialogue := DialogueData.new()
		var entry := DialogueEntry.new()
		entry.id = "greet"
		entry.speaker_name = "Elder Aldric"
		entry.text = "Ah, a traveler. Millhaven hasn't seen one in some time."
		dialogue.entries = [entry]
		DialogueManager.start_dialogue(dialogue)
"""
	script.reload()
	npc.set_script(script)


func _setup_stranger_npc(npc: CharacterBody3D) -> void:
	var script := GDScript.new()
	script.source_code = """extends CharacterBody3D

var quest_node: Node = null

func interact(player: CharacterBody3D) -> void:
	if quest_node == null:
		quest_node = get_tree().get_first_node_in_group("starter_quest")
	if quest_node:
		quest_node.stranger_dialogue()
	else:
		var dialogue := DialogueData.new()
		var entry := DialogueEntry.new()
		entry.id = "greet"
		entry.speaker_name = "The Stranger"
		entry.text = "That cavern to the east... something stirs within."
		dialogue.entries = [entry]
		DialogueManager.start_dialogue(dialogue)
"""
	script.reload()
	npc.set_script(script)


## ----------- Dialogue builders -----------

func elder_dialogue() -> void:
	var dialogue := DialogueData.new()

	if quest_complete:
		# Post-quest
		var entry := DialogueEntry.new()
		entry.id = "done"
		entry.speaker_name = "Elder Aldric"
		entry.text = "You've done a great service to Millhaven, traveler. The cavern may hold more secrets yet... but that is a tale for another day."
		dialogue.entries = [entry]

	elif quest_active and amulet_collected:
		# Turn-in dialogue
		var entry1 := DialogueEntry.new()
		entry1.id = "turnin"
		entry1.speaker_name = "Elder Aldric"
		entry1.text = "You've returned! And what is that you carry? An ancient amulet... This is grave news indeed. These are relics of the old kingdom, buried beneath Ashfall long ago."
		entry1.next_entry_id = "reward"

		var entry2 := DialogueEntry.new()
		entry2.id = "reward"
		entry2.speaker_name = "Elder Aldric"
		entry2.text = "You have earned the gratitude of Millhaven. Take this gold, and an old blade from my youth. You may need it for what lies ahead."
		entry2.grant_gold = 75
		entry2.grant_xp = 50.0

		dialogue.entries = [entry1, entry2]

		# Complete the quest when this dialogue ends
		DialogueManager.dialogue_ended.connect(_on_elder_turnin, CONNECT_ONE_SHOT)

	elif quest_active:
		# Mid-quest check-in
		var entry := DialogueEntry.new()
		entry.id = "checkin"
		entry.speaker_name = "Elder Aldric"
		entry.text = "Have you dealt with the creatures at Ashfall Cavern? Seek out the stranger on the road east — he seems to know more than he lets on."
		dialogue.entries = [entry]

	elif not QuestManager.is_quest_completed("herb_for_healer"):
		# Haven't done the fetch quest yet — direct to Elara first
		var entry := DialogueEntry.new()
		entry.id = "pre_quest"
		entry.speaker_name = "Elder Aldric"
		entry.text = "Ah, a traveler. Millhaven hasn't seen one in some time. If you're looking to make yourself useful, Sage Elara at the herbalist's hut could use a hand. Come back to me once you've helped her — I may have a more... dangerous task for you."
		dialogue.entries = [entry]

	else:
		# Quest offer (herb quest is done, so this unlocks)
		var entry1 := DialogueEntry.new()
		entry1.id = "intro"
		entry1.speaker_name = "Elder Aldric"
		entry1.text = "I heard you helped Elara — good. That tells me you can handle yourself. I have a more serious problem. Creatures have been emerging from Ashfall Cavern to the east. Skeletons, if you can believe it. Our guards are stretched thin."

		var choice1 := DialogueChoice.new()
		choice1.text = "I'll look into it. What can you tell me?"
		choice1.next_entry_id = "accept"

		var choice2 := DialogueChoice.new()
		choice2.text = "Sounds dangerous. What's in it for me?"
		choice2.next_entry_id = "reward_ask"

		var choice3 := DialogueChoice.new()
		choice3.text = "Not my problem."
		choice3.next_entry_id = "decline"

		entry1.choices = [choice1, choice2, choice3]

		var entry_accept := DialogueEntry.new()
		entry_accept.id = "accept"
		entry_accept.speaker_name = "Elder Aldric"
		entry_accept.text = "Brave soul. A hooded stranger has been lurking near the cave — speak to him first, he seems to know something. Then clear those bones out. Bring back anything you find."

		var entry_reward := DialogueEntry.new()
		entry_reward.id = "reward_ask"
		entry_reward.speaker_name = "Elder Aldric"
		entry_reward.text = "Gold, of course. And I have an old sword from my adventuring days — it's yours if you clear those fiends out. A hooded stranger near the cave may have useful information."

		var entry_decline := DialogueEntry.new()
		entry_decline.id = "decline"
		entry_decline.speaker_name = "Elder Aldric"
		entry_decline.text = "I understand. But if you change your mind, the offer stands. People are frightened."

		dialogue.entries = [entry1, entry_accept, entry_reward, entry_decline]

		# Start quest when accepting
		DialogueManager.dialogue_ended.connect(_on_elder_offer_ended, CONNECT_ONE_SHOT)

	DialogueManager.start_dialogue(dialogue)


func stranger_dialogue() -> void:
	var dialogue := DialogueData.new()

	if quest_active:
		var entry1 := DialogueEntry.new()
		entry1.id = "intel"
		entry1.speaker_name = "The Stranger"
		entry1.text = "So the old man sent you. Smart. Those skeletons aren't natural — something in the cavern is raising them. An amulet of binding, old magic. Destroy the skeletons and you should find it among their remains."
		entry1.next_entry_id = "warning"

		var entry2 := DialogueEntry.new()
		entry2.id = "warning"
		entry2.speaker_name = "The Stranger"
		entry2.text = "Be careful. There are three of them guarding the entrance. They're slow but they hit hard. Take the amulet back to Aldric — he'll know what to do with it."

		dialogue.entries = [entry1, entry2]

		# Mark objective complete
		DialogueManager.dialogue_ended.connect(func():
			QuestManager.update_objective(QUEST_ID, OBJ_TALK_STRANGER)
		, CONNECT_ONE_SHOT)
	else:
		var entry := DialogueEntry.new()
		entry.id = "pre_quest"
		entry.speaker_name = "The Stranger"
		entry.text = "That cavern to the east... Ashfall Cavern, they call it. Something stirs within. Something ancient. Perhaps you should speak with the village elder."
		dialogue.entries = [entry]

	DialogueManager.start_dialogue(dialogue)


## ----------- Event handlers -----------

func _on_elder_offer_ended() -> void:
	# Check if the player chose to accept (we start quest on any non-decline ending)
	if not quest_active:
		QuestManager.start_quest(QUEST_ID)


func _on_quest_started(quest_id: String) -> void:
	if quest_id == QUEST_ID:
		quest_active = true


func _on_quest_completed(quest_id: String) -> void:
	if quest_id == QUEST_ID:
		quest_complete = true
		# Grant the iron sword reward
		var sword := load("res://resources/items/iron_sword.tres") as ItemData
		if sword:
			InventoryManager.add_item(sword)


func _on_elder_turnin() -> void:
	QuestManager.update_objective(QUEST_ID, OBJ_RETURN_ELDER)


func on_skeleton_killed(enemy: Enemy) -> void:
	if not quest_active or quest_complete:
		return
	skeletons_killed += 1
	QuestManager.update_objective(QUEST_ID, OBJ_KILL_SKELETONS)


func on_amulet_collected() -> void:
	if not quest_active or quest_complete:
		return
	amulet_collected = true
	QuestManager.update_objective(QUEST_ID, OBJ_COLLECT_AMULET)

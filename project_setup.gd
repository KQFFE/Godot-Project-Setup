extends Node
## One-shot project setup for a NEW project, runnable in any Summer Engine project.
##
## Play this scene once and it will:
##   1. create the standard folder structure,
##   2. write README.md describing that structure (only when there is no README),
##   3. write a rebindable input registry at res://ui/input_settings.gd (only if missing),
##   4. apply the standard project settings: the rebindable input actions, the
##      InputSettings autoload, window size and stretch mode, the 3D physics engine
##      and the Windows rendering driver.
##
## SAFE TO RE-RUN, AND SAFE IN AN EXISTING PROJECT. It creates a folder only when it
## is absent, writes a file only when that file is absent, and sets a project setting
## only when the key is missing. It never overwrites and never deletes, so running it
## on a project that already has the structure is a no-op.
##
## Every step prints one auditable line, so a run that changed nothing still shows
## exactly what it checked. The scene quits by itself when it is done.

## Folders created if absent. One line per folder so the log reads clearly.
var FOLDERS: PackedStringArray = PackedStringArray([
	"res://levels",
	"res://gameplay",
	"res://gameplay/player",
	"res://gameplay/enemies",
	"res://gameplay/combat",
	"res://gameplay/stats",
	"res://gameplay/items",
	"res://gameplay/skills",
	"res://ui",
	"res://scenes",
	"res://materials",
	"res://tools",
	"res://assets",
	"res://assets/models",
	"res://assets/images",
	"res://assets/materials",
	"res://assets/library",
])

const README_PATH := "res://README.md"
const INPUT_REGISTRY_PATH := "res://ui/input_settings.gd"
const INPUT_REGISTRY_AUTOLOAD := "*res://ui/input_settings.gd"
const SHELL_SCENE := "res://main.tscn"

## UI actions the engine expects to exist. Godot normally supplies these, but a
## project whose InputMap has been edited can lose them, and any Control that asks
## for a missing ui_ action errors on every focus event - which floods the console
## and breaks keyboard and gamepad menu navigation. Declared here so a new project
## never hits that.
## Declared as KEY_ constants rather than key-name strings on purpose: a name that did
## not match Godot's internal table would resolve to keycode 0 and silently bind the
## action to nothing.
const UI_CHROME_KEYS: Dictionary = {
	"ui_accept": [KEY_ENTER, KEY_SPACE],
	"ui_select": [KEY_SPACE],
	"ui_cancel": [KEY_ESCAPE],
	"ui_focus_next": [KEY_TAB],
	# Backtab, NOT plain Tab: this template also binds Tab to the area map, so
	# prev needs its own key or the two fight over the same one.
	"ui_focus_prev": [KEY_BACKTAB],
	"ui_left": [KEY_LEFT],
	"ui_right": [KEY_RIGHT],
	"ui_up": [KEY_UP],
	"ui_down": [KEY_DOWN],
	"ui_page_up": [KEY_PAGEUP],
	"ui_page_down": [KEY_PAGEDOWN],
	"ui_home": [KEY_HOME],
	"ui_end": [KEY_END],
	"ui_menu": [KEY_MENU],
	"ui_accessibility_drag_and_drop": [KEY_SPACE],
}

## Text-editing actions, declared with NO events on purpose. The engine asks for
## these while editing text fields; they only have to EXIST to stop the errors, and
## Ctrl-modified shortcuts cannot be expressed as a plain key here.
var UI_TEXT_ACTIONS: PackedStringArray = PackedStringArray([
	"ui_cut",
	"ui_copy",
	"ui_paste",
	"ui_undo",
	"ui_redo",
	"ui_text_select_all",
	"ui_text_select_word_under_caret",
	"ui_text_add_selection_for_next_occurrence",
	"ui_text_clear_carets_and_selection",
	"ui_text_submit",
	"ui_text_completion_accept",
	"ui_text_completion_query",
	"ui_text_completion_replace",
	"ui_text_dedent",
	"ui_text_indent",
	"ui_text_backspace",
	"ui_text_backspace_word",
	"ui_text_backspace_all_to_left",
	"ui_text_backspace_word_all_to_left",
	"ui_text_delete",
	"ui_text_delete_word",
	"ui_text_delete_all_to_right",
	"ui_text_delete_word_all_to_right",
	"ui_text_caret_left",
	"ui_text_caret_right",
	"ui_text_caret_up",
	"ui_text_caret_down",
	"ui_text_caret_word_left",
	"ui_text_caret_word_right",
	"ui_text_caret_line_start",
	"ui_text_caret_line_end",
	"ui_text_caret_page_up",
	"ui_text_caret_page_down",
	"ui_text_caret_document_start",
	"ui_text_caret_document_end",
	"ui_text_caret_add_below",
	"ui_text_caret_add_above",
	"ui_text_scroll_up",
	"ui_text_scroll_down",
	"ui_text_scroll_page_up",
	"ui_text_scroll_page_down",
	"ui_text_toggle_virtual_keyboard",
])

## Project settings applied when missing. Input actions are handled separately,
## because each one is its own key.
const PROJECT_SETTINGS: Dictionary = {
	"display/window/size/viewport_width": 1920,
	"display/window/size/viewport_height": 1080,
	"display/window/size/mode": 3,
	"display/window/stretch/mode": "canvas_items",
	"display/window/stretch/aspect": "expand",
	"physics/3d/physics_engine": "Jolt Physics",
	"rendering/rendering_device/driver.windows": "d3d12",
}

var _log: PackedStringArray = PackedStringArray()
var _made: int = 0
var _written: int = 0
var _set: int = 0


func _ready() -> void:
	_make_folders()
	_write_if_missing(README_PATH, README_TEMPLATE)
	_write_if_missing(INPUT_REGISTRY_PATH, INPUT_REGISTRY_TEMPLATE)
	_apply_project_settings()
	_apply_input_actions()
	ProjectSettings.save()
	_report()
	get_tree().quit()


func _make_folders() -> void:
	for folder in FOLDERS:
		if DirAccess.dir_exists_absolute(folder):
			_log.append("folder  ok       %s" % folder)
			continue
		var err := DirAccess.make_dir_recursive_absolute(folder)
		if err == OK:
			_made += 1
			_log.append("folder  CREATED  %s" % folder)
		else:
			_log.append("folder  FAILED   %s (error %d)" % [folder, err])


## Writes a file only when it is absent, so an existing README or input registry is
## never clobbered by running the setup again.
func _write_if_missing(path: String, contents: String) -> void:
	if FileAccess.file_exists(path):
		_log.append("file    ok       %s (left untouched)" % path)
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_log.append("file    FAILED   %s" % path)
		return
	file.store_string(contents)
	file.close()
	_written += 1
	_log.append("file    WROTE    %s" % path)


func _apply_project_settings() -> void:
	for key in PROJECT_SETTINGS:
		_set_if_missing(key, PROJECT_SETTINGS[key])
	# The autoload only makes sense once the registry exists, which _write_if_missing
	# has just guaranteed, so this is a straight check rather than an ordering risk.
	if FileAccess.file_exists(INPUT_REGISTRY_PATH):
		_set_if_missing("autoload/InputSettings", INPUT_REGISTRY_AUTOLOAD)
	else:
		_log.append("setting SKIPPED  autoload/InputSettings (no %s)" % INPUT_REGISTRY_PATH)
	# The shell scene is the project's persistent main scene. A brand new project has
	# none yet, and pointing main_scene at a file that does not exist breaks Play, so
	# this is only set when the scene is really there.
	if FileAccess.file_exists(SHELL_SCENE):
		_set_if_missing("application/run/main_scene", SHELL_SCENE)
	else:
		_log.append("setting SKIPPED  application/run/main_scene (create %s first)" % SHELL_SCENE)


func _set_if_missing(key: String, value: Variant) -> void:
	if ProjectSettings.has_setting(key):
		# has_setting() is true for engine built-ins too, so only report a genuine
		# pre-existing project override as kept rather than as a skip.
		_log.append("setting ok       %s" % key)
		return
	ProjectSettings.set_setting(key, value)
	_set += 1
	_log.append("setting SET      %s = %s" % [key, str(value)])


func _apply_input_actions() -> void:
	for action in _gameplay_actions():
		var key: String = "input/" + str(action)
		if ProjectSettings.has_setting(key):
			_log.append("input   ok       %s" % action)
			continue
		ProjectSettings.set_setting(key, {"deadzone": 0.5, "events": _gameplay_actions()[action]})
		_set += 1
		_log.append("input   SET      %s" % action)
	for action in UI_CHROME_KEYS:
		var key: String = "input/" + str(action)
		if ProjectSettings.has_setting(key):
			_log.append("input   ok       %s" % action)
			continue
		var events: Array = []
		for code in UI_CHROME_KEYS[action]:
			events.append(_key(int(code) as Key, false))
		ProjectSettings.set_setting(key, {"deadzone": 0.5, "events": events})
		_set += 1
		_log.append("input   SET      %s" % action)
	for action in UI_TEXT_ACTIONS:
		var key: String = "input/" + str(action)
		if ProjectSettings.has_setting(key):
			continue
		ProjectSettings.set_setting(key, {"deadzone": 0.5, "events": []})
		_set += 1
		_log.append("input   SET      %s (no default binding)" % action)


## The rebindable gameplay actions, with their default events. Movement and letter
## keys are PHYSICAL, so the default follows the KEY rather than whatever symbol a
## non-US layout prints there. Number keys for the skill bar are physical for the
## same reason: a SHIFT-modified number reports a different logical keycode.
func _gameplay_actions() -> Dictionary:
	return {
		"move_left": [_key(KEY_A, true)],
		"move_right": [_key(KEY_D, true)],
		"move_forward": [_key(KEY_W, true)],
		"move_back": [_key(KEY_S, true)],
		"attack": [_mouse_button(MOUSE_BUTTON_LEFT), _key(KEY_SPACE, false)],
		"force_move": [_mouse_button(MOUSE_BUTTON_RIGHT)],
		"inventory": [_key(KEY_I, true)],
		"dash": [_key(KEY_SPACE, true)],
		"interact": [_key(KEY_E, true)],
		"skill_tree": [_key(KEY_P, true)],
		"area_map": [_key(KEY_TAB, true)],
		"advanced_description": [_key(KEY_ALT, true)],
		"attack_in_place": [_key(KEY_SHIFT, true)],
		"pause": [_key(KEY_QUOTELEFT, true)],
		"skill_1": [_key(KEY_1, true)],
		"skill_2": [_key(KEY_2, true)],
		"skill_3": [_key(KEY_3, true)],
		"skill_4": [_key(KEY_4, true)],
		"skill_5": [_key(KEY_5, true)],
		"skill_6": [_key(KEY_6, true)],
		"skill_7": [_key(KEY_7, true)],
		"skill_8": [_key(KEY_8, true)],
		"skill_9": [_key(KEY_9, true)],
		"skill_10": [_key(KEY_0, true)],
	}


func _key(code: Key, physical: bool) -> InputEventKey:
	var event := InputEventKey.new()
	if physical:
		event.physical_keycode = code
	else:
		event.keycode = code
	return event


func _mouse_button(button: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	return event


func _report() -> void:
	print("[project_setup] %d folder(s) created, %d file(s) written, %d setting(s) set." % [
		_made, _written, _set])
	for line in _log:
		print("[project_setup] %s" % line)
	if _made == 0 and _written == 0 and _set == 0:
		print("[project_setup] Nothing to do: this project already has the full structure.")


const README_TEMPLATE := """# Project name

One paragraph describing the game, who the player is, and what the core loop is.
Replace this placeholder.

## Quick start

1. Open the project in Summer Engine.
2. Press Play. `res://main.tscn` is the main scene: the persistent shell.

## Project structure

```
res://
  main.tscn            the persistent shell: player, camera, HUD, level loader
  levels/
    level_root.gd      instances a level scene into the shell at startup
    <levelname>/       one folder per level, holding <levelname>.tscn
  gameplay/
    player/            player controller, animation, weapon attachment
    enemies/           enemy AI, contact damage, boss attacks, health bars
    combat/            health, mana, hurtboxes, status effects, damage helpers
    stats/             stats and their definitions
    items/             item data, inventory, equipment, loot
    skills/            skills, classes, projectiles
  ui/                  HUD, menus, overlays, the input registry
  scenes/              reusable scenes instanced by levels
  materials/           .tres materials used by the project
  assets/
    models/            imported 3D models (glb, gltf)
    images/            imported textures and icons
    materials/         materials kept beside the assets they belong to
    library/           curated library imports, one folder per collection
  characters/          generated character packages - do not hand-edit
  tools/               dev-only probes and one-shot utilities, never shipped
  addons/              editor plugins
```

## Where a file goes

| What it is | Where it goes | Notes |
| --- | --- | --- |
| Level content | `levels/<levelname>/` | One folder per level. Terrain, props, enemies and lighting for that place all live here. |
| Gameplay script | `gameplay/<domain>/` | Pick the domain by what it IS: player, enemies, combat, stats, items or skills. |
| UI script | `ui/` | HUD, menus, overlays, and the input registry. |
| Reusable scene | `scenes/` | Anything a level instances more than once, or that several levels share. |
| Imported 3D model | `assets/models/` | Imported from a store, a generator or an upload. |
| Imported texture or icon | `assets/images/` | |
| Material | `materials/` | A `.tres` used directly by the project. Materials that belong to one asset can sit in `assets/materials/`. |
| Library asset | `assets/library/<collection>/` | Imports from a curated library. Never mix collections. |
| Character package | `characters/` | Generated by the character pipeline. Edit the rig, never the generated files by hand. |
| Dev tool or probe | `tools/` | Runs in the editor or as its own scene. Never referenced by gameplay, never shipped. |

Two rules matter more than the rest:

- **Link, never copy.** Several levels reuse the same asset by referencing it as an
  `ext_resource`. Do not duplicate a model or texture into a level folder.
- **One asset, one home.** If a file is needed in two places, move it to the shared
  folder and reference it from both, rather than keeping two copies that drift apart.

## Levels load on entry

The project is built as a shell plus levels, so level content is only instanced while
that level is loaded.

- `res://main.tscn` is the **shell**. It owns everything that lives ACROSS levels: the
  player and its children, the camera rig, the HUD and the menus, and a `LevelRoot`.
- `res://levels/<levelname>/<levelname>.tscn` is a **level**. It owns one place:
  terrain, props, enemies, chests, and that place's lighting.
- `levels/level_root.gd` loads the level into `LevelRoot` at startup. To add a level,
  create the scene and point the loader's `level_scene` at it.

Anything that resolves the player by NodePath needs care across that boundary: a path
relative to the node itself only works while the player shares its scene. Resolve the
player by an absolute path or a group, and do it before the node's own `_ready`
depends on the reference.

## Input and key bindings

Every action is declared in one place and stays rebindable through settings; no
gameplay code reads raw keycodes. The registry lives at `ui/input_settings.gd` as the
`InputSettings` autoload, and exposes `get_default_events(action)`,
`apply_override(action, events)` and `save()` for a future rebind screen.

## Conventions

- Files are `snake_case`: `player_controller.gd`, `loot_chest.tscn`.
- A script with a `class_name` is `PascalCase` to match it: `Health.gd` holds `Health`.
- Paths are case-sensitive on Linux and when exporting. Match the name on disk exactly.
- Keep scripts under about 500 lines. Split by responsibility instead of growing one file.
"""


const INPUT_REGISTRY_TEMPLATE := """extends Node
## Central rebindable input registry, autoloaded as `InputSettings`.
##
## Owns the canonical default binding for every gameplay action, guarantees each
## action exists with at least its default events at startup, then applies any saved
## overrides from user://settings.cfg section [input].
##
## A settings or rebind screen calls get_default_events(), apply_override() and
## save(). No gameplay code should read raw keycodes.
##
## The built-in ui_ actions are NOT declared here: they are set in project settings,
## so they exist from engine boot, before any Control can ask for one.

const SETTINGS_PATH := "user://settings.cfg"

var _default_events: Dictionary = {}


func _ready() -> void:
	_default_events = _build_default_events()
	_ensure_default_actions()
	_apply_saved_overrides()


## Returns a copy of the default events for an action.
func get_default_events(action: String) -> Array:
	return (_default_events.get(action, []) as Array).duplicate()


## Replaces the runtime events for an action. Does not persist until save() is called.
func apply_override(action: String, events: Array) -> void:
	if not _default_events.has(action):
		return
	InputMap.action_erase_events(action)
	for event in events:
		if event is InputEvent:
			InputMap.action_add_event(action, event)


## Persists the current runtime bindings so they survive a restart.
func save() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	for action in _default_events.keys():
		var serialized: Array = []
		for event in InputMap.action_get_events(action):
			var data := _serialize_event(event)
			if not data.is_empty():
				serialized.append(data)
		cfg.set_value("input", action, serialized)
	cfg.save(SETTINGS_PATH)


func _build_default_events() -> Dictionary:
	return {
		"move_left": [_key(KEY_A, true)],
		"move_right": [_key(KEY_D, true)],
		"move_forward": [_key(KEY_W, true)],
		"move_back": [_key(KEY_S, true)],
		"attack": [_mouse_button(MOUSE_BUTTON_LEFT), _key(KEY_SPACE, false)],
		"force_move": [_mouse_button(MOUSE_BUTTON_RIGHT)],
		"inventory": [_key(KEY_I, true)],
		"dash": [_key(KEY_SPACE, true)],
		"interact": [_key(KEY_E, true)],
		"skill_tree": [_key(KEY_P, true)],
		"area_map": [_key(KEY_TAB, true)],
		"advanced_description": [_key(KEY_ALT, true)],
		"attack_in_place": [_key(KEY_SHIFT, true)],
		"pause": [_key(KEY_QUOTELEFT, true)],
		"skill_1": [_key(KEY_1, true)],
		"skill_2": [_key(KEY_2, true)],
		"skill_3": [_key(KEY_3, true)],
		"skill_4": [_key(KEY_4, true)],
		"skill_5": [_key(KEY_5, true)],
		"skill_6": [_key(KEY_6, true)],
		"skill_7": [_key(KEY_7, true)],
		"skill_8": [_key(KEY_8, true)],
		"skill_9": [_key(KEY_9, true)],
		"skill_10": [_key(KEY_0, true)],
	}


func _ensure_default_actions() -> void:
	for action in _default_events:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var existing: Array = InputMap.action_get_events(action)
		for default_event in _default_events[action]:
			if not _contains_event(existing, default_event):
				InputMap.action_add_event(action, default_event)


func _contains_event(events: Array, target: InputEvent) -> bool:
	for event in events:
		if event is InputEventKey and target is InputEventKey:
			var existing_key := event as InputEventKey
			var target_key := target as InputEventKey
			if existing_key.physical_keycode == target_key.physical_keycode and existing_key.keycode == target_key.keycode:
				return true
		elif event is InputEventMouseButton and target is InputEventMouseButton:
			var existing_button := event as InputEventMouseButton
			var target_button := target as InputEventMouseButton
			if existing_button.button_index == target_button.button_index:
				return true
	return false


func _apply_saved_overrides() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_PATH)
	if err != OK or not cfg.has_section("input"):
		return
	for action in cfg.get_section_keys("input"):
		if not _default_events.has(action):
			continue
		var serialized: Array = cfg.get_value("input", action, [])
		var events: Array = []
		for data in serialized:
			var event := _deserialize_event(data)
			if event != null:
				events.append(event)
		if not events.is_empty():
			apply_override(action, events)


func _serialize_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		var key := event as InputEventKey
		return {"type": "key", "physical_keycode": key.physical_keycode, "keycode": key.keycode}
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		return {"type": "mouse_button", "button_index": button.button_index}
	return {}


func _deserialize_event(data: Variant) -> InputEvent:
	if not (data is Dictionary):
		return null
	var type: String = str(data.get("type", ""))
	if type == "key":
		var key := InputEventKey.new()
		key.physical_keycode = int(data.get("physical_keycode", 0)) as Key
		key.keycode = int(data.get("keycode", 0)) as Key
		return key
	if type == "mouse_button":
		var button := InputEventMouseButton.new()
		button.button_index = int(data.get("button_index", MOUSE_BUTTON_LEFT)) as MouseButton
		return button
	return null


func _key(code: Key, physical: bool) -> InputEventKey:
	var event := InputEventKey.new()
	if physical:
		event.physical_keycode = code
	else:
		event.keycode = code
	return event


func _mouse_button(button: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	return event
"""

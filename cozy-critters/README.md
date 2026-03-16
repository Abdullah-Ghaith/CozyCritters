# Cozy Critters — Godot 4.5 Desktop Idler
## Script Drop-In & Scene Wiring Guide

---

## 1. Open in Godot 4.5

1. Open Godot 4.5, click **Import**, and select the `cozy_critters/` folder.
2. Godot will import the project. It will show errors about missing scenes — that's expected, you're about to create them.

---

## 2. Folder Structure (already created)

```
	cozy_critters/
  autoloads/          ← GameState, DayNightClock, *Registry autoloads
  data/
	animals/          ← AnimalDefinition.gd, AnimData.gd, your .tres files go here
	items/            ← HabitatItemDefinition.gd, your .tres files go here
	upgrades/         ← UpgradeDefinition.gd, your .tres files go here
  scripts/
	ui/               ← HUD, ShopPanel, CollectionLog, ShopCard scripts
  assets/
	spritesheets/     ← Put hedgehog.png etc here
	items/            ← Habitat item textures
	ui/               ← Icons, acorn image, placeholder icon.png
```

---

## 3. Create Scenes (in order)

### 3a. AnimalInstance.tscn
`res://scenes/AnimalInstance.tscn`

Node tree:
```
CharacterBody2D   [script: scripts/AnimalInstance.gd]
  AnimatedSprite2D        (name: "Sprite")
  CollisionShape2D        (name: "Collider")     ← RectangleShape2D
  Area2D                  (name: "DragArea")
	CollisionShape2D      (name: "DragShape")    ← Slightly larger RectangleShape2D
  Sprite2D                (name: "HelperIcon")   ← Assign acorn badge texture in inspector
  GPUParticles2D          (name: "SleepParticles") ← Configure "Z" floating particles
  Node                    (name: "StateMachine")   [script: scripts/AnimalStateMachine.gd]
  Node                    (name: "DragHandler")    [script: scripts/DragHandler.gd]
```

Inspector settings on root CharacterBody2D:
- Motion Mode: `Floating`
- Up Direction: `(0, -1)`

DragHandler inspector:
- `lock_y` = true
- `ground_y` = 110  (adjust to match your strip layout)

---

### 3b. HabitatItem.tscn
`res://scenes/HabitatItem.tscn`

Node tree:
```
StaticBody2D   [script: scripts/HabitatItem.gd]
  Sprite2D             (name: "Sprite")
  AnimatedSprite2D     (name: "AnimSprite")   ← optional, for animated items
  CollisionShape2D     (name: "Collider")
  Area2D               (name: "DragArea")
	CollisionShape2D   (name: "DragShape")
  Node                 (name: "DragHandler")  [script: scripts/DragHandler.gd]
```

---

### 3c. ShopCard.tscn
`res://scenes/ui/ShopCard.tscn`

Node tree:
```
PanelContainer   [script: scripts/ui/ShopCard.gd]
  VBoxContainer  (name: "VBox")
	TextureRect  (name: "IconRect")   custom_minimum_size = (64, 64)
	Label        (name: "NameLabel")
	Label        (name: "CostLabel")
	Button       (name: "BuyButton")
```

---

### 3d. ShopPanel.tscn
`res://scenes/ui/ShopPanel.tscn`

Node tree:
```
Control   [script: scripts/ui/ShopPanel.gd]
  Button          (name: "CloseButton")   text = "✕"
  TabContainer    (name: "TabContainer")
	Control       (name: "Animals")
	  ScrollContainer (name: "ScrollContainer")
		GridContainer  (name: "AnimalGrid")   columns = 4
	Control       (name: "Items")
	  ScrollContainer
		GridContainer  (name: "ItemGrid")    columns = 4
	Control       (name: "Upgrades")
	  ScrollContainer
		GridContainer  (name: "UpgradeGrid") columns = 4
```

Inspector on ShopPanel root:
- `shop_card_scene` → assign ShopCard.tscn

---

### 3e. CollectionLog.tscn
`res://scenes/ui/CollectionLog.tscn`

Node tree:
```
Control   [script: scripts/ui/CollectionLog.gd]
  Label           (name: "CountLabel")
  Button          (name: "CloseButton")  text = "✕"
  ScrollContainer (name: "ScrollContainer")
	GridContainer (name: "Grid")   columns = 5
```

---

### 3f. HUD.tscn
`res://scenes/ui/HUD.tscn`

Node tree:
```
Control   [script: scripts/ui/HUD.gd]
  Label   (name: "AcornLabel")
  Button  (name: "ShopButton")    text = "🛒 Shop"
  Button  (name: "LogButton")     text = "📖 Collection"
  Button  (name: "MinimiseButton") text = "▼"
```

Anchor/layout: Anchor the HUD to the top-right of the screen, or stretch it across the top.

---

### 3g. Main.tscn  ← Root scene
`res://scenes/Main.tscn`

Node tree:
```
Node   [script: scripts/Main.gd]
  Node                     (name: "WindowManager")   [script: scripts/WindowManager.gd]
  SubViewportContainer     (name: "StripViewport")
	SubViewport
	  Node2D               (name: "World")            [script: scripts/World.gd]
		CanvasLayer        (name: "Background",  layer=-10)  [script: scripts/Background.gd]
		  ColorRect        (name: "SkyGradient")  ← size fills strip
		  Sprite2D         (name: "Ground")       ← tiling ground texture
		Node2D             (name: "HabitatLayer")
		Node2D             (name: "AnimalLayer")
		CanvasLayer        (name: "ForegroundLayer", layer=10)
		  GPUParticles2D   (name: "AcornParticles")
		  Control          (name: "ClickReceiver")    ← full-strip Control; connect gui_input → World._on_click_receiver_gui_input()
  CanvasLayer              (name: "UILayer",  layer=128)
	Control (name: "HUD")            [scene: scenes/ui/HUD.tscn]
	Control (name: "ShopPanel")      [scene: scenes/ui/ShopPanel.tscn]
	Control (name: "CollectionLog")  [scene: scenes/ui/CollectionLog.tscn]
```

SubViewportContainer settings:
- `stretch` = true
- `custom_minimum_size` = (0, 150)

ClickReceiver settings:
- Anchors: full rect (0,0,1,1 relative to its parent CanvasLayer)
- Mouse Filter: `Stop` (so it captures clicks before animals do)
- **Important**: in the inspector, set Mouse Filter to `Pass` so clicks can fall through to animals and drag areas once registered.

World inspector:
- `animal_scene` → assign AnimalInstance.tscn
- `item_scene`   → assign HabitatItem.tscn
- `ground_y`     → 110 (match DragHandler.ground_y)

---

## 4. Autoloads (Project > Project Settings > Autoload)

Add these in order (the * means singleton):

| Name            | Path                                 |
|-----------------|--------------------------------------|
| GameState       | res://autoloads/GameState.gd         |
| DayNightClock   | res://autoloads/DayNightClock.gd     |
| AnimalRegistry  | res://autoloads/AnimalRegistry.gd    |
| ItemRegistry    | res://autoloads/ItemRegistry.gd      |
| UpgradeRegistry | res://autoloads/UpgradeRegistry.gd   |

The `project.godot` file already lists these — Godot will pick them up automatically when you open the project.

---

## 5. Create Your First Animal .tres

1. In the FileSystem panel, right-click `res://data/animals/` → **New Resource**
2. Search for `AnimalDefinition`, click Create
3. Save as `hedgehog.tres`
4. Fill in the inspector:
   - `id` = `hedgehog`
   - `display_name` = `Hedgehog`
   - `spritesheet` = your hedgehog.png (import it to `res://assets/spritesheets/` first)
   - `frame_size` = the pixel dimensions of one frame
   - `animations` → Add entries:
	 - Key: `walk` → Value: new AnimData (first_frame, frame_count, fps, looping=true)
	 - Key: `idle` → Value: new AnimData
	 - Key: `sleep` → Value: new AnimData
   - `unlock_cost` = 0 (free starter animal) or any amount
   - `helper_rate` = 0.5

---

## 6. First Run Checklist

- [ ] All 5 autoloads registered in Project Settings
- [ ] Main.tscn set as the main scene (Project Settings > Application > Run > Main Scene)
- [ ] At least one .tres animal definition created
- [ ] `icon.png` placeholder placed at `res://assets/ui/icon.png` (any 256×256 image)
- [ ] AnimalInstance.tscn and HabitatItem.tscn created and assigned in World inspector

---

## 7. Day/Night Speed

The cycle is set in `DayNightClock.gd`:
```gdscript
const REAL_SECONDS_PER_DAY: float = 45.0 * 60.0  # 45 minutes
```
Change `45.0` to any number of minutes you like.

---

## 8. Click-Through Hotkey

Press **Ctrl + Shift + C** while the app is focused to toggle click-through mode.
In passthrough mode the strip dims to 40% opacity as a visual indicator.
You can also add a system tray icon using the `godot-tray-icon` addon (open source, Godot 4 compatible).

[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/ui/LevelRoot.gd" id="1_root"]
[ext_resource type="Script" path="res://scripts/ui/TowerSelectionPanel.gd" id="2_tower_panel"]

[node name="LevelRoot" type="CanvasLayer"]
script = ExtResource("1_root")

[node name="SafeAreaRoot" type="Control" parent="."]
unique_name_in_owner = true
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="TopSection" type="Control" parent="SafeAreaRoot"]
unique_name_in_owner = true
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_bottom = -250.0
grow_horizontal = 2
grow_vertical = 2

[node name="HUD_TopBar" type="PanelContainer" parent="SafeAreaRoot"]
anchors_preset = 10
anchor_right = 1.0
offset_bottom = 86.0
grow_horizontal = 2

[node name="TopInfo" type="HBoxContainer" parent="SafeAreaRoot/HUD_TopBar"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 12.0
offset_top = 8.0
offset_right = -12.0
offset_bottom = -8.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 8

[node name="WaveLabel" type="Label" parent="SafeAreaRoot/HUD_TopBar/TopInfo"]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3
text = "🌊 1/3 • 0/6"

[node name="LivesLabel" type="Label" parent="SafeAreaRoot/HUD_TopBar/TopInfo"]
unique_name_in_owner = true
layout_mode = 2
text = "♥ 3"

[node name="CreditsLabel" type="Label" parent="SafeAreaRoot/HUD_TopBar/TopInfo"]
unique_name_in_owner = true
layout_mode = 2
text = "⚗ 100"

[node name="WavePreviewToggleButton" type="Button" parent="SafeAreaRoot/HUD_TopBar/TopInfo"]
unique_name_in_owner = true
custom_minimum_size = Vector2(128, 54)
layout_mode = 2
text = "Wave ▾"

[node name="WavePreviewPanel" type="PanelContainer" parent="SafeAreaRoot"]
unique_name_in_owner = true
anchors_preset = 9
anchor_left = 1.0
anchor_top = 0.0
anchor_right = 1.0
anchor_bottom = 0.0
offset_left = -300.0
offset_top = 92.0
offset_right = -12.0
offset_bottom = 250.0
modulate = Color(1, 1, 1, 0.78)

[node name="WavePreviewCloseButton" type="Button" parent="SafeAreaRoot/WavePreviewPanel"]
unique_name_in_owner = true
anchors_preset = 1
anchor_left = 1.0
anchor_right = 1.0
offset_left = -46.0
offset_top = 6.0
offset_right = -8.0
offset_bottom = 42.0
text = "✕"

[node name="WavePreviewLabel" type="RichTextLabel" parent="SafeAreaRoot/WavePreviewPanel"]
unique_name_in_owner = true
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 10.0
offset_top = 10.0
offset_right = -10.0
offset_bottom = -10.0
grow_horizontal = 2
grow_vertical = 2
bbcode_enabled = true
text = "[b]Next Wave[/b]\n▲ ● ◆\nReward +25"
fit_content = true
scroll_active = false

[node name="TowerInfoPanel" type="PanelContainer" parent="SafeAreaRoot"]
unique_name_in_owner = true
visible = false
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -225.0
offset_top = -160.0
offset_right = 225.0
offset_bottom = 160.0
modulate = Color(1, 1, 1, 0.72)

[node name="TowerInfoCloseButton" type="Button" parent="SafeAreaRoot/TowerInfoPanel"]
unique_name_in_owner = true
anchors_preset = 1
anchor_left = 1.0
anchor_right = 1.0
offset_left = -46.0
offset_top = 6.0
offset_right = -8.0
offset_bottom = 42.0
text = "✕"

[node name="TowerInfoVBox" type="VBoxContainer" parent="SafeAreaRoot/TowerInfoPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 12.0
offset_top = 12.0
offset_right = -12.0
offset_bottom = -12.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 8

[node name="TowerInfoLabel" type="RichTextLabel" parent="SafeAreaRoot/TowerInfoPanel/TowerInfoVBox"]
unique_name_in_owner = true
layout_mode = 2
size_flags_vertical = 3
bbcode_enabled = true
fit_content = true

[node name="TowerUpgradeButton" type="Button" parent="SafeAreaRoot/TowerInfoPanel/TowerInfoVBox"]
unique_name_in_owner = true
custom_minimum_size = Vector2(0, 52)
layout_mode = 2
text = "Upgrade"

[node name="TowerSellButton" type="Button" parent="SafeAreaRoot/TowerInfoPanel/TowerInfoVBox"]
unique_name_in_owner = true
custom_minimum_size = Vector2(0, 52)
layout_mode = 2
text = "Sell"

[node name="HUD_BottomPanel" type="Control" parent="SafeAreaRoot"]
anchors_preset = 12
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_top = -240.0
grow_horizontal = 2
grow_vertical = 0

[node name="BottomVBox" type="VBoxContainer" parent="SafeAreaRoot/HUD_BottomPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 12.0
offset_top = 8.0
offset_right = -12.0
offset_bottom = -8.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 8

[node name="TowerSelectionPanel" type="Control" parent="SafeAreaRoot/HUD_BottomPanel/BottomVBox"]
unique_name_in_owner = true
custom_minimum_size = Vector2(0, 130)
layout_mode = 2
script = ExtResource("2_tower_panel")

[node name="Header" type="HBoxContainer" parent="SafeAreaRoot/HUD_BottomPanel/BottomVBox/TowerSelectionPanel"]
layout_mode = 2

[node name="CollapseButton" type="Button" parent="SafeAreaRoot/HUD_BottomPanel/BottomVBox/TowerSelectionPanel/Header"]
unique_name_in_owner = true
custom_minimum_size = Vector2(190, 48)
layout_mode = 2
text = "▲ Towers"

[node name="Content" type="VBoxContainer" parent="SafeAreaRoot/HUD_BottomPanel/BottomVBox/TowerSelectionPanel"]
unique_name_in_owner = true
layout_mode = 2

[node name="Scroll" type="ScrollContainer" parent="SafeAreaRoot/HUD_BottomPanel/BottomVBox/TowerSelectionPanel/Content"]
layout_mode = 2
custom_minimum_size = Vector2(0, 94)
horizontal_scroll_mode = 1
vertical_scroll_mode = 2

[node name="CardContainer" type="HBoxContainer" parent="SafeAreaRoot/HUD_BottomPanel/BottomVBox/TowerSelectionPanel/Content/Scroll"]
unique_name_in_owner = true
layout_mode = 2
theme_override_constants/separation = 12

[node name="StatusLabel" type="Label" parent="SafeAreaRoot/HUD_BottomPanel/BottomVBox"]
unique_name_in_owner = true
layout_mode = 2
text = "Tap Place Tower, then choose from carousel."
autowrap_mode = 3

[node name="HUD_ActionRow" type="HBoxContainer" parent="SafeAreaRoot/HUD_BottomPanel/BottomVBox"]
layout_mode = 2
theme_override_constants/separation = 8

[node name="PlaceTowerButton" type="Button" parent="SafeAreaRoot/HUD_BottomPanel/BottomVBox/HUD_ActionRow"]
unique_name_in_owner = true
custom_minimum_size = Vector2(120, 52)
layout_mode = 2
size_flags_horizontal = 3
text = "Place"

[node name="UpgradeInfoButton" type="Button" parent="SafeAreaRoot/HUD_BottomPanel/BottomVBox/HUD_ActionRow"]
unique_name_in_owner = true
custom_minimum_size = Vector2(120, 52)
layout_mode = 2
size_flags_horizontal = 3
text = "Upgrade"

[node name="SellButton" type="Button" parent="SafeAreaRoot/HUD_BottomPanel/BottomVBox/HUD_ActionRow"]
unique_name_in_owner = true
custom_minimum_size = Vector2(120, 52)
layout_mode = 2
size_flags_horizontal = 3
text = "Sell"

[node name="SpeedButton" type="Button" parent="SafeAreaRoot/HUD_BottomPanel/BottomVBox/HUD_ActionRow"]
unique_name_in_owner = true
custom_minimum_size = Vector2(120, 52)
layout_mode = 2
size_flags_horizontal = 3
text = "x1"

[node name="PauseButton" type="Button" parent="SafeAreaRoot/HUD_BottomPanel/BottomVBox/HUD_ActionRow"]
unique_name_in_owner = true
custom_minimum_size = Vector2(120, 52)
layout_mode = 2
size_flags_horizontal = 3
text = "Pause"

[node name="PauseModal" type="PanelContainer" parent="SafeAreaRoot"]
unique_name_in_owner = true
visible = false
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -180.0
offset_top = -160.0
offset_right = 180.0
offset_bottom = 160.0
modulate = Color(1, 1, 1, 0.75)

[node name="PauseCloseButton" type="Button" parent="SafeAreaRoot/PauseModal"]
unique_name_in_owner = true
anchors_preset = 1
anchor_left = 1.0
anchor_right = 1.0
offset_left = -46.0
offset_top = 6.0
offset_right = -8.0
offset_bottom = 42.0
text = "✕"

[node name="PauseVBox" type="VBoxContainer" parent="SafeAreaRoot/PauseModal"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 16.0
offset_top = 16.0
offset_right = -16.0
offset_bottom = -16.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 10

[node name="PauseTitle" type="Label" parent="SafeAreaRoot/PauseModal/PauseVBox"]
layout_mode = 2
text = "Game Paused"
horizontal_alignment = 1

[node name="ResumeButton" type="Button" parent="SafeAreaRoot/PauseModal/PauseVBox"]
unique_name_in_owner = true
custom_minimum_size = Vector2(0, 52)
layout_mode = 2
text = "Resume"

[node name="SettingsButton" type="Button" parent="SafeAreaRoot/PauseModal/PauseVBox"]
unique_name_in_owner = true
custom_minimum_size = Vector2(0, 52)
layout_mode = 2
text = "Settings"

[node name="QuitButton" type="Button" parent="SafeAreaRoot/PauseModal/PauseVBox"]
unique_name_in_owner = true
custom_minimum_size = Vector2(0, 52)
layout_mode = 2
text = "Quit"

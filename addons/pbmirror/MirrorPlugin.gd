tool
extends EditorPlugin

const MainPanel = preload("res://addons/pbmirror/MirrorPanel.tscn")
var main_panel

const PlaybyteExportPlugin = preload("res://addons/pbmirror/PlaybyteExportPlugin.gd")
var export_plugin

func _enter_tree():
	main_panel = MainPanel.instance()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, main_panel)
	
	export_plugin = PlaybyteExportPlugin.new()
	add_export_plugin(export_plugin)
	export_plugin.connect("set_export_path", main_panel, "_set_export_path")
	export_plugin.connect("export_end", main_panel, "_export_end")

func _exit_tree():
	remove_export_plugin(export_plugin)
	remove_control_from_docks(main_panel)

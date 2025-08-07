import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
	
    const SettingsScreen({super.key});

    @override
    SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
    final _editorController = TextEditingController();

    @override
    void initState() {
        super.initState();
        _loadEditorPath();
    }

    Future<void> _loadEditorPath() async {
        final prefs = await SharedPreferences.getInstance();
        setState(() {
                _editorController.text = prefs.getString('editor_path') ?? '';
            });
    }

    Future<void> _saveEditorPath() async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('editor_path', _editorController.text);
    }

    Future<void> _pickEditor() async {
        FilePickerResult? result;
        if (Platform.isWindows) {
            result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['exe'],
            );
        } else if (Platform.isMacOS) {
            result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['app'],
            );
        } else {
            result = await FilePicker.platform.pickFiles();
        }

        if (result != null && result.files.isNotEmpty) {
            final path = result.files.single.path;
            if (path != null) {
                setState(() {
                    _editorController.text = path;
                });
            }
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Configuración'),
            ),
            body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    children: [
                        TextField(
                            controller: _editorController,
                            decoration: const InputDecoration(
                                labelText: 'Ruta del Editor de Código',
                            ),
                        ),
						TextButton(
                            onPressed: _pickEditor,
                            child: const Text('Seleccionar'),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                            onPressed: () {
                                _saveEditorPath();
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Ruta del editor guardada.')),
                                );
                            },
                            child: const Text('Guardar'),
                        ),
                    ],
                ),
            ),
        );
    }
}

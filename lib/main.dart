import 'package:flutter/material.dart';
import 'package:lionftp/file_explorer_screen.dart';
import 'package:lionftp/settings_screen.dart';

void main() {
    runApp(const MyApp());
}

class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'LionFTP',
            theme: ThemeData(
                brightness: Brightness.dark,
                primarySwatch: Colors.blue,
                visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            home: const HomePage(),
        );
    }
}
class Site {
    String name;
    String host;
    String username;
    String password;
    int port;
    String protocol; // 'FTP' or 'SFTP'

    Site({
        required this.name,
        required this.host,
        required this.username,
        required this.password,
        required this.port,
        required this.protocol,
    });
}

class SiteGroup {
    String name;
    List<Site> sites;

    SiteGroup({required this.name, required this.sites});
}

class HomePage extends StatefulWidget {
    const HomePage({super.key});

    @override
    HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
    final List<SiteGroup> _siteGroups = [
        SiteGroup(name: 'Mis Sitios', sites: [
                Site(
                    name: 'Sitio de prueba',
                    host: 'test.com',
                    username: 'testuser',
                    password: 'password',
                    port: 21,
                    protocol: 'FTP',
                ),
            ]),
    ];

    void _addSite(Site site, int groupIndex) {
        setState(() {
                _siteGroups[groupIndex].sites.add(site);
            });
    }

    void _addGroup(String name) {
        setState(() {
                _siteGroups.add(SiteGroup(name: name, sites: []));
            });
    }

    Future<void> _showAddSiteDialog() async {
        final formKey = GlobalKey<FormState>();
        String name = '';
        String host = '';
        String username = '';
        String password = '';
        int port = 21;
        String protocol = 'FTP';
        int selectedGroupIndex = 0;

        await showDialog(
            context: context,
            builder: (context) {
                return AlertDialog(
                    title: const Text('Agregar Nuevo Sitio'),
                    content: Form(
                        key: formKey,
                        child: SingleChildScrollView(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    TextFormField(
                                        decoration: const InputDecoration(labelText: 'Nombre del Sitio'),
                                        validator: (value) =>
                                        value!.isEmpty ? 'Por favor ingrese un nombre' : null,
                                        onSaved: (value) => name = value!,
                                    ),
                                    TextFormField(
                                        decoration: const InputDecoration(labelText: 'Host'),
                                        validator: (value) =>
                                        value!.isEmpty ? 'Por favor ingrese un host' : null,
                                        onSaved: (value) => host = value!,
                                    ),
                                    TextFormField(
                                        decoration: const InputDecoration(labelText: 'Usuario'),
                                        validator: (value) =>
                                        value!.isEmpty ? 'Por favor ingrese un usuario' : null,
                                        onSaved: (value) => username = value!,
                                    ),
                                    TextFormField(
                                        decoration: const InputDecoration(labelText: 'Contraseña'),
                                        obscureText: true,
                                        validator: (value) =>
                                        value!.isEmpty ? 'Por favor ingrese una contraseña' : null,
                                        onSaved: (value) => password = value!,
                                    ),
                                    TextFormField(
                                        decoration: const InputDecoration(labelText: 'Puerto'),
                                        keyboardType: TextInputType.number,
                                        initialValue: '21',
                                        validator: (value) =>
                                        value!.isEmpty ? 'Por favor ingrese un puerto' : null,
                                        onSaved: (value) => port = int.parse(value!),
                                    ),
                                    DropdownButtonFormField<String>(
                                        decoration: const InputDecoration(labelText: 'Protocolo'),
                                        value: protocol,
                                        items: ['FTP', 'SFTP']
                                            .map((label) => DropdownMenuItem(
                                                    child: Text(label),
                                                    value: label,
                                                ))
                                            .toList(),
                                        onChanged: (value) {
                                            setState(() {
                                                    protocol = value!;
                                                });
                                        },
                                    ),
                                    DropdownButtonFormField<int>(
                                        decoration: const InputDecoration(labelText: 'Grupo'),
                                        value: selectedGroupIndex,
                                        items: _siteGroups
                                            .asMap()
                                            .entries
                                            .map((entry) => DropdownMenuItem(
                                                    child: Text(entry.value.name),
                                                    value: entry.key,
                                                ))
                                            .toList(),
                                        onChanged: (value) {
                                            setState(() {
                                                    selectedGroupIndex = value!;
                                                });
                                        },
                                    ),
                                ],
                            ),
                        ),
                    ),
                    actions: [
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                            onPressed: () {
                                if (formKey.currentState!.validate()) {
                                    formKey.currentState!.save();
                                    final newSite = Site(
                                        name: name,
                                        host: host,
                                        username: username,
                                        password: password,
                                        port: port,
                                        protocol: protocol,
                                    );
                                    _addSite(newSite, selectedGroupIndex);
                                    Navigator.of(context).pop();
                                }
                            },
                            child: const Text('Agregar'),
                        ),
                    ],
                );
            },
        );
    }

    Future<void> _showAddGroupDialog() async {

        final formKey = GlobalKey<FormState>();
        String name = '';

        await showDialog(
            context: context,
            builder: (context) {
                return AlertDialog(
                    title: const Text('Agregar Nuevo Grupo'),
                    content: Form(
                        key: formKey,
                        child: TextFormField(
                            decoration: const InputDecoration(labelText: 'Nombre del Grupo'),
                            validator: (value) =>
                            value!.isEmpty ? 'Por favor ingrese un nombre' : null,
                            onSaved: (value) => name = value!,
                        ),
                    ),
                    actions: [
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                            onPressed: () {
                                if (formKey.currentState!.validate()) {
                                    formKey.currentState!.save();
                                    _addGroup(name);
                                    Navigator.of(context).pop();
                                }
                            },
                            child: const Text('Agregar'),
                        ),
                    ],
                );
            },
        );
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('LionFTP'),
                actions: [
                    IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SettingsScreen(),
                                ),
                            );
                        },
                    ),
                ],
            ),
            body: ListView.builder(
                itemCount: _siteGroups.length,
                itemBuilder: (context, index) {
                    final group = _siteGroups[index];
                    return ExpansionTile(
                        title: Text(group.name),
                        children: group.sites.map((site) {
                                return ListTile(
                                    title: Text(site.name),
                                    subtitle: Text('${site.protocol}://${site.host}:${site.port}'),
                                    trailing: ElevatedButton(
                                        onPressed: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                    FileExplorerScreen(site: site),
                                                ),
                                            );
                                        },
                                        child: const Text('Conectar'),
                                    ),
                                );
                            }).toList(),
                    );
                },
            ),
            floatingActionButton: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                    FloatingActionButton(
                        onPressed: _showAddSiteDialog,
                        heroTag: 'add_site',
                        child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton(
                        onPressed: _showAddGroupDialog,
                        heroTag: 'add_group',
                        child: const Icon(Icons.create_new_folder),
                    ),
                ],
            ),
        );
    }
}
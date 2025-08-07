
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:lionftp/main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/process_run.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FileInfo {
    final String name;
    final bool isDirectory;

    FileInfo({required this.name, required this.isDirectory});
}

class FileExplorerScreen extends StatefulWidget {
    final Site site;

    const FileExplorerScreen({super.key, required this.site});

    @override
    FileExplorerScreenState createState() => FileExplorerScreenState();
}

class FileExplorerScreenState extends State<FileExplorerScreen> {

    late Future<List<FileInfo>> _files;
    String _currentPath = '/';

    @override
    void initState() {
        super.initState();
        _files = _listFiles(_currentPath);
    }

    Future<List<FileInfo>> _listFiles(String path) async {
        if (widget.site.protocol == 'FTP') {
            return await _listFtpFiles(path);
        } else {
            return await _listSftpFiles(path);
        }
    }

    Future<List<FileInfo>> _listFtpFiles(String path) async {
        FTPConnect ftpConnect = FTPConnect(
            widget.site.host,
            user: widget.site.username,
            pass: widget.site.password,
            port: widget.site.port,
        );
        try {
            await ftpConnect.connect();
            await ftpConnect.changeDirectory(path);
            List<FTPEntry> entries = await ftpConnect.listDirectoryContent();
            await ftpConnect.disconnect();
            return entries
                .map((entry) =>
                    FileInfo(name: entry.name, isDirectory: entry.type == FTPEntryType.DIR))
                .toList();
        } catch (e) {
            // Handle error
            print('Error connecting to FTP server: $e');
            return [];
        }
    }

    Future<List<FileInfo>> _listSftpFiles(String path) async {
        final client = SSHClient(
            await SSHSocket.connect(widget.site.host, widget.site.port),
            username: widget.site.username,
            onPasswordRequest: () => widget.site.password,
        );

        try {
            final sftp = await client.sftp();
            final files = await sftp.listdir(path);
            return files
                .map((file) =>
                    FileInfo(name: file.filename, isDirectory: file.attr.isDirectory))
                .toList();
        } catch (e) {
            // Handle error
            print('Error connecting to SFTP server: $e');
            return [];
        } finally {
            client.close();
        }
    }

    void _onItemTap(FileInfo file) {
        if (file.isDirectory) {
            setState(() {
                    _currentPath = '$_currentPath${file.name}/';
                    _files = _listFiles(_currentPath);
                });
        } else {
            _openFile(file);
        }
    }

    Future<void> _openFile(FileInfo file) async {
        final prefs = await SharedPreferences.getInstance();
        final editorPath = prefs.getString('editor_path');

        if (editorPath == null || editorPath.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Por favor, configure la ruta del editor en la sección de configuración.'),
                ),
            );
            return;
        }

        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${file.name}');

        if (widget.site.protocol == 'FTP') {
            FTPConnect ftpConnect = FTPConnect(
                widget.site.host,
                user: widget.site.username,
                pass: widget.site.password,
                port: widget.site.port,
            );
            try {
                await ftpConnect.connect();
                await ftpConnect.downloadFileWithRetry(file.name, tempFile);
                await ftpConnect.disconnect();
            } catch (e) {
                print('Error downloading file via FTP: $e');
                return;
            }
        } else {
            final client = SSHClient(
                await SSHSocket.connect(widget.site.host, widget.site.port),
                username: widget.site.username,
                onPasswordRequest: () => widget.site.password,
            );

            try {
                final sftp = await client.sftp();
                final remoteFile = await sftp.open(file.name);
                final fileData = await remoteFile.readBytes();
                await tempFile.writeAsBytes(fileData);
            } catch (e) {
                print('Error downloading file via SFTP: $e');
                return;
            } finally {
                client.close();
            }
        }

        try {
            await run(editorPath, [tempFile.path]);
        } catch (e) {
            print('Error opening file with editor: $e');
        }
    }

    void _navigateBack() {
        if (_currentPath != '/') {
            setState(() {
                    _currentPath = _currentPath.substring(0, _currentPath.lastIndexOf('/'));
                    _currentPath = _currentPath.substring(0, _currentPath.lastIndexOf('/') + 1);
                    _files = _listFiles(_currentPath);
                });
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: Text('Explorador de Archivos - ${widget.site.name}'),
                leading: _currentPath != '/'
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _navigateBack,
                    )
                    : null,
            ),
            body: FutureBuilder<List<FileInfo>>(

                future: _files,
                builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No hay archivos en el directorio.'));
                    } else {
                        return ListView.builder(
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                                final file = snapshot.data![index];
                                return ListTile(
                                    title: Text(file.name),
                                    leading: Icon(
                                        file.isDirectory ? Icons.folder : Icons.insert_drive_file,
                                        color: file.isDirectory ? Color(0xfffbc63d) : null,
                                    ),

                                    onTap: () => _onItemTap(file),
                                );
                            },
                        );
                    }
                },
            ),
        );
    }
}

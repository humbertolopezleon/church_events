import 'package:material_ui/material_ui.dart';

import '../../theme/app_theme.dart';

/// Cabecera de las pantallas: título de 24 sp, subtítulo opcional (conteo) y, a la derecha, un
/// menú ⋮ con «Importar CSV» y «Exportar CSV» (los botones grandes ya no van en el cuerpo).
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onImport,
    this.onExport,
    this.exportEnabled = true,
    this.importKey = const Key('importar-csv'),
    this.exportKey = const Key('exportar-csv'),
    this.actions = const [],
  });
  final String title;
  final String? subtitle;
  final VoidCallback? onImport;
  final VoidCallback? onExport;

  /// Sin nada que exportar, la opción aparece deshabilitada.
  final bool exportEnabled;
  final Key importKey, exportKey;
  final List<Widget> actions;

  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 64 : 72);

  @override
  Widget build(BuildContext context) => AppBar(
        toolbarHeight: preferredSize.height,
        titleSpacing: 16,
        title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (subtitle != null)
                Text(subtitle!,
                    key: const Key('cabecera-subtitulo'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bodyStyle(15,
                        color: Colors.white.withValues(alpha: 0.92))),
            ]),
        actions: [
          ...actions,
          if (onImport != null || onExport != null)
            PopupMenuButton<String>(
              key: const Key('menu-csv'),
              tooltip: 'Más opciones: importar y exportar CSV',
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (v) =>
                  v == 'importar' ? onImport?.call() : onExport?.call(),
              itemBuilder: (_) => [
                if (onImport != null)
                  PopupMenuItem(
                      key: importKey,
                      value: 'importar',
                      child: const ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.upload_file_outlined),
                          title: Text('Importar CSV'))),
                if (onExport != null)
                  PopupMenuItem(
                      key: exportKey,
                      value: 'exportar',
                      enabled: exportEnabled,
                      child: const ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.table_view_outlined),
                          title: Text('Exportar CSV'))),
              ],
            ),
          const SizedBox(width: 4),
        ],
      );
}

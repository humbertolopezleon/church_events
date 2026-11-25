import 'package:material_ui/material_ui.dart';

import '../../theme/app_theme.dart';

/// Una opción extra del menú ⋮ (además de importar/exportar/plantilla/columnas).
class HeaderMenuItem {
  const HeaderMenuItem(
      {required this.key,
      required this.label,
      required this.icon,
      required this.onTap});
  final Key key;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

/// Cabecera de las pantallas: título de 24 sp, subtítulo opcional (conteo) y, a la derecha, un
/// menú ⋮ con «Importar CSV» y «Exportar CSV» (los botones grandes ya no van en el cuerpo).
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onImport,
    this.onExport,
    this.onTemplate,
    this.onColumns,
    this.importLabel = 'Importar CSV',
    this.exportLabel = 'Exportar CSV',
    this.extraItems = const [],
    this.exportEnabled = true,
    this.importKey = const Key('importar-csv'),
    this.exportKey = const Key('exportar-csv'),
    this.templateKey = const Key('plantilla-csv'),
    this.columnsKey = const Key('columnas-csv'),
    this.actions = const [],
  });
  final String title;
  final String? subtitle;
  final VoidCallback? onImport;
  final VoidCallback? onExport;

  /// Plantilla vacía y ayuda de columnas (opcionales; salen tras importar/exportar).
  final VoidCallback? onTemplate, onColumns;

  /// Textos de «Importar»/«Exportar» cuando la vista tiene más de un CSV (p. ej. Equipos).
  final String importLabel, exportLabel;

  /// Opciones extra al final del menú (otros CSV de la misma vista).
  final List<HeaderMenuItem> extraItems;

  /// Sin nada que exportar, la opción aparece deshabilitada.
  final bool exportEnabled;
  final Key importKey, exportKey, templateKey, columnsKey;
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
          if (onImport != null ||
              onExport != null ||
              onTemplate != null ||
              onColumns != null ||
              extraItems.isNotEmpty)
            PopupMenuButton<String>(
              key: const Key('menu-csv'),
              tooltip: 'Más opciones: importar y exportar CSV',
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (v) => switch (v) {
                'importar' => onImport?.call(),
                'exportar' => onExport?.call(),
                'plantilla' => onTemplate?.call(),
                'columnas' => onColumns?.call(),
                _ => extraItems[int.parse(v.substring(6))].onTap(),
              },
              itemBuilder: (_) => [
                if (onImport != null)
                  PopupMenuItem(
                      key: importKey,
                      value: 'importar',
                      child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.upload_file_outlined),
                          title: Text(importLabel))),
                if (onExport != null)
                  PopupMenuItem(
                      key: exportKey,
                      value: 'exportar',
                      enabled: exportEnabled,
                      child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.table_view_outlined),
                          title: Text(exportLabel))),
                if (onTemplate != null)
                  PopupMenuItem(
                      key: templateKey,
                      value: 'plantilla',
                      child: const ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.download_outlined),
                          title: Text('Plantilla CSV vacía'))),
                if (onColumns != null)
                  PopupMenuItem(
                      key: columnsKey,
                      value: 'columnas',
                      child: const ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.help_outline),
                          title: Text('Columnas del CSV'))),
                for (var i = 0; i < extraItems.length; i++)
                  PopupMenuItem(
                      key: extraItems[i].key,
                      value: 'extra:$i',
                      child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(extraItems[i].icon),
                          title: Text(extraItems[i].label))),
              ],
            ),
          const SizedBox(width: 4),
        ],
      );
}

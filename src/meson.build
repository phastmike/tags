gtat_sources = [
  'main.vala',
  'window.vala',
  'lines-tree-view.vala',
  'filters-tree-view.vala',
  'line-filter.vala',
  'color-scheme.vala',
  'filter-dialog-window.vala',
  'application.vala',
  ]

gtat_deps = [
  dependency('gtk4'),
]

gnome = import('gnome')

gtat_sources += gnome.compile_resources('gtat-resources',
  'gtat.gresource.xml',
  c_name: 'gtat'
)

executable('gtat', gtat_sources,
  vala_args: '--target-glib=2.50',  dependencies: gtat_deps,
  install: true,
)

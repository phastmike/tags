gtat_sources = [
  'main.vala',
  'window.vala',
  'lines_tree_view.vala',
  'filters_tree_view.vala',
  'line_filter.vala',
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

tagger_sources = [
  'main.vala',
  'window.vala',
  'lines-tree-view.vala',
  'filters-tree-view.vala',
  'line-filter.vala',
  'color-scheme.vala',
  'filter-dialog-window.vala',
  'preferences.vala',
  'preferences-window.vala',
  'application.vala',
  ]

tagger_deps = [
  dependency('gtk4'),
]

gnome = import('gnome')

tagger_sources += gnome.compile_resources('tagger-resources',
  'tagger.gresource.xml',
  c_name: 'tagger'
)

executable('tagger', tagger_sources,
  vala_args: '--target-glib=2.50',  dependencies: tagger_deps,
  install: true,
)

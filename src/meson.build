tagger_sources = [
  'main.vala',
  'window.vala',
  'lines-tree-view.vala',
  'tags-tree-view.vala',
  'tag.vala',
  'color-scheme.vala',
  'tag-dialog-window.vala',
  'preferences.vala',
  'preferences-window.vala',
  'application.vala',
  ]

tagger_deps = [
  dependency('gtk4'),
  dependency('json-glib-1.0'),
  dependency('libadwaita-1'),
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

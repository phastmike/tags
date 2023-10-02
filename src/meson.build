tags_sources = [
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

tags_deps = [
  dependency('gtk4'),
  dependency('json-glib-1.0'),
  dependency('libadwaita-1'),
]

gnome = import('gnome')

tags_sources += gnome.compile_resources('tags-resources',
  'tags.gresource.xml',
  c_name: 'tags'
)

executable('tags', tags_sources,
  vala_args: '--target-glib=2.50',  dependencies: tags_deps,
  install: true,
)

tags_sources = [
  'main.vala',
  'window.vala',
  'text-minimap.vala',
  'minimap-scroll-manager.vala',
  'lines-tree-view.vala',
  'tags-tree-view.vala',
  'tag.vala',
  'color-scheme.vala',
  'tag-dialog-window.vala',
  'preferences.vala',
  'preferences-dialog.vala',
  'application.vala',
  ]

libm = declare_dependency(link_args: ['-lm'])

tags_deps = [
  dependency('gtk4', version: '>= 4.9'),
  dependency('json-glib-1.0', version: '>= 1.6'),
  dependency('libadwaita-1', version: '>= 1.2'),
  libm
]

gnome = import('gnome')

tags_sources += gnome.compile_resources('tags-resources',
  'tags.gresource.xml',
  c_name: 'tags'
)


executable('tags',
  tags_sources,
  config_file,
  vala_args: [
  '--target-glib=2.50',
  '--Xcc=-lm',
  ],
  dependencies: tags_deps,
  install: true,
)

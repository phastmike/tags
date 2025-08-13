tags_sources = [
  'main.vala',
  'application.vala'
  ]

subdir('tag')
subdir('lines')
subdir('colors')
subdir('window')
subdir('minimap')
subdir('preferences')

libm = declare_dependency(link_args: ['-lm'])

tags_deps = [
  dependency('gtk4', version: '>= 4.9'),
  dependency('json-glib-1.0', version: '>= 1.6'),
  dependency('libadwaita-1', version: '>= 1.2'),
  dependency('gee-0.8'),
  libm
]

gnome = import('gnome')

tags_resources = gnome.compile_resources(
  'tags-resources',
  'tags.gresources.xml',
  source_dir: meson.current_source_dir(),
  c_name: 'tags'
)


executable(
  'tags',
  tags_resources,
  tags_sources,
  config_file,
  vala_args: [
  '--target-glib=2.50',
  ],
  dependencies: tags_deps,
  install: true,
)

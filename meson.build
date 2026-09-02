project('io.github.phastmike.tags', ['c', 'vala'],
          version: '2.5',
    meson_version: '>= 0.58.0',
  default_options: [ 'warning_level=2',
                   ],
)

application_id = meson.project_name()

i18n = import('i18n')
conf_data = configuration_data()
conf_data.set_quoted('APPLICATION_ID', application_id)
conf_data.set_quoted('VERSION', meson.project_version())
conf_data.set_quoted('GETTEXT_PACKAGE', application_id)
conf_data.set_quoted('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))

config_file = configure_file(
    input : 'src/config.vala.in',
    output : 'config.vala',
    configuration : conf_data
)

subdir('po')
subdir('data')
subdir('src')

run_target(
  'update-i18n',
  command: [
    'ninja',
    '-C',
    meson.global_build_root(),
    'io.github.phastmike.tags-pot',
    'io.github.phastmike.tags-update-po'
  ]
)


meson.add_install_script('build-aux/meson/postinstall.py')

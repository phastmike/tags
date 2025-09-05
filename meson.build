project('io.github.phastmike.tags', ['c', 'vala'],
          version: '1.5',
    meson_version: '>= 0.49.0',
  default_options: [ 'warning_level=2',
                   ],
)

i18n = import('i18n')
application_id = 'io.github.phastmike.tags'

conf_data = configuration_data()
conf_data.set_quoted('APPLICATION_ID', application_id)
conf_data.set_quoted('GETTEXT_PACKAGE', application_id)
conf_data.set_quoted('VERSION', meson.project_version())

config_file = configure_file(
    input : 'src/config.vala.in',
    output : 'config.vala',
    configuration : conf_data
)

subdir('po')
subdir('data')
subdir('src')

meson.add_install_script('build-aux/meson/postinstall.py')

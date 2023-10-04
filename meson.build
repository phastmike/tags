project('tags', ['c', 'vala'],
          version: '0.9.40',
    meson_version: '>= 0.45.0',
  default_options: [ 'warning_level=2',
                   ],
)

i18n = import('i18n')



subdir('data')
subdir('src')
subdir('po')

meson.add_install_script('build-aux/meson/postinstall.py')

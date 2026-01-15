## Reconfigue project

```bash
meson setup build --reconfigure
```

## Generate POT file

```bash
meson compile -C build io.github.phastmike.tags-pot
```

## Generate PO files

Add language to LINGUAS file and run:

```bash
meson compile -C build io.github.phastmike.tags-update-po
```

# Changelog

Todos los cambios relevantes de este proyecto se documentan en este archivo.

El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y el proyecto usa
[Versionado Semántico](https://semver.org/lang/es/).

## [1.0.0] - 2026-10-13

### Agregado

- Esquema JSON de `garita.json` (`schema/garita.schema.json`). Sus claves son estables desde esta versión.
- Guía de migración desde hooks propios en el README.
- Plugin de opencode (`opencode/garita.js`) que corre los mismos hooks: bloqueos, reglas de contenido y
  espejo. La confirmación de commit queda en los permisos de opencode.

### Corregido

- `grep "git push"`, `rg`, `echo` o un mensaje de commit que mencione el push ya no se bloquean: las
  comillas solo cuentan como separador si la línea tiene algo capaz de ejecutar una cadena.
- Se bloquean evasiones que pasaban: comillas o barra invertida en `git` o en el subcomando, `eval`,
  `xargs`, `find -exec`, `watch`, `doas`, `echo … | bash` y alias con `!git push` o `git config alias.x`.

## [0.3.0] - 2026-10-13

### Agregado

- Herencia de configuración: un repo cuyo `CLAUDE.md` enlaza a `<contexto>/repos/<nombre>/CLAUDE.md`
  usa el `garita.json` de ese contexto, sin espejo. También desde subdirectorios, vía git.

### Cambiado

- Sin configuración encontrada, los hooks no hacen nada. Un `{}` activa los defaults. Así el plugin se
  puede habilitar en scope de usuario.

## [0.1.0] - 2026-10-13

### Agregado

- Plugin de Claude Code con manifiesto y marketplace local en el mismo repo.
- `guard-git`: bloqueo de `git push` y sus evasiones, escritura de refs con `gh api`, reglas extra,
  rechazo de atribuciones, confirmación de commit y prohibición de `-F/--file`.
- `guard-content`: reglas de contenido por glob y regex sobre Write, Edit y MultiEdit.
- `mirror`: copia de archivos en la raíz del proyecto, por defecto `CLAUDE.md` a `AGENTS.md`.
- `bin/link-context.sh`: enlace de fichas de un repo de contexto, con `.nolink`.
- Configuración por proyecto en `.claude/garita.json` sobre `defaults.json`.
- Pruebas en `bats`, con la suite de evasiones verificada contra los hooks de origen.

### Corregido

- Un `git push` en una línea posterior de un comando multilínea ya no pasa: los saltos de línea
  cuentan como separador de comandos.

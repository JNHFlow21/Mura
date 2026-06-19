# Desktop Memory Wall Agent Context

The user wants a local, lightweight desktop memory surface: it should feel like moving a clean Excalidraw whiteboard onto the wallpaper, but it must not keep a live web wallpaper or heavy overlay running while idle.

## Style Defaults

- Start blank. Do not insert planner templates, default tasks, or inferred reminder content.
- Use very large text. If a reminder is not readable from normal desktop distance, it is too small.
- Prefer a hand-drawn feel: warm paper background, dark ink, and sparse red/blue accents.
- Keep reminders short and concrete. Do not turn the wall into a project-management database.

## Agent Safety

- Preview before applying a wallpaper when operating autonomously.
- Require explicit confirmation for visible desktop changes and restore operations.
- Keep data local under the workspace; do not sync or upload reminders.
- Use primitive commands (`status`, `board read`, `board blank`, `board patch`, `board stroke`, `render preview`, `wallpaper apply`, `wallpaper restore`) rather than hiding judgment in workflow-shaped commands.

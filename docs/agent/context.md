# Desktop Memory Wall Agent Context

The user wants a local, lightweight desktop memory surface: it should feel like moving an Excalidraw whiteboard onto the wallpaper, but it must not keep a live web wallpaper or heavy overlay running while idle.

## Style Defaults

- Use very large text first. If a reminder is not readable from normal desktop distance, it is too small.
- Prefer a hand-drawn feel: warm paper background, dark ink, light grid/dots, and sparse red/blue accents.
- Default wall structure: title, three focus items, and a short “别忘” section.
- Keep reminders short and concrete. Do not turn the wall into a project-management database.

## Agent Safety

- Preview before applying a wallpaper when operating autonomously.
- Require explicit confirmation for visible desktop changes and restore operations.
- Keep data local under the workspace; do not sync or upload reminders.
- Use primitive commands (`status`, `board read`, `board patch`, `render preview`, `wallpaper apply`, `wallpaper restore`) rather than hiding judgment in workflow-shaped commands.

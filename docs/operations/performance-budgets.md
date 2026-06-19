# Performance Budgets

Desktop Memory Wall is designed for near-zero idle cost by exporting only on explicit save/preview/apply events.

| State | Budget / expectation |
|---|---|
| Idle | No retained editor WebView required; menu bar process only. |
| Editing | One foreground WKWebView canvas editor at a time. |
| Export from editor | One display-sized canvas export after `document.fonts.ready`. |
| Fallback rendering | Default max 250 elements and 16M pixels per render job. |
| Wallpaper apply | Single `NSWorkspace` apply call after snapshot metadata is stored. |

`RenderBudget` rejects oversized fallback renders before allocating the PNG bitmap. The primary app save path writes the PNG returned by the editor bridge to avoid duplicate text layout and preserve WYSIWYG behavior.

# Performance Budgets

Desktop Memory Wall is designed for near-zero idle cost by rendering only on explicit save/preview/apply events.

| State | Budget / expectation |
|---|---|
| Idle | No retained editor WebView required; menu bar process only. |
| Editing | One foreground WKWebView/editor surface at a time. |
| Rendering | Default max 250 elements and 16M pixels per render job. |
| Wallpaper apply | Single `NSWorkspace` apply call after snapshot metadata is stored. |

`RenderBudget` rejects oversized boards before allocating the PNG bitmap. Future profiling should measure memory while rendering the user's actual display size and tune `maxPixels` if needed.

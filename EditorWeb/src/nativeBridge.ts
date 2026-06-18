export type NativeMessageKind = 'ready' | 'boardChanged' | 'exportPNG' | 'error';
export interface NativeMessage { kind: NativeMessageKind; payload?: Record<string, unknown>; }
export function encodeMessage(message: NativeMessage): string { return JSON.stringify({ payload: {}, ...message }); }

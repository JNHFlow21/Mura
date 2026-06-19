export function clientToBoard(point, rect, board) {
  return {
    x: (point.x - rect.left) * board.width / rect.width,
    y: (point.y - rect.top) * board.height / rect.height
  };
}

export function fitCanvas(container, board) {
  const scale = Math.min(container.width / board.width, container.height / board.height, 1);
  return { width: Math.round(board.width * scale), height: Math.round(board.height * scale), scale };
}

export function pointBounds(points) {
  if (!points.length) return { x: 0, y: 0, width: 0, height: 0 };
  const xs = points.map(point => point.x);
  const ys = points.map(point => point.y);
  const minX = Math.min(...xs), maxX = Math.max(...xs), minY = Math.min(...ys), maxY = Math.max(...ys);
  return { x: minX, y: minY, width: Math.max(1, maxX - minX), height: Math.max(1, maxY - minY) };
}

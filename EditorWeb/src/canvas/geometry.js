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

export function distanceToSegment(point, start, end) {
  const dx = end.x - start.x;
  const dy = end.y - start.y;
  const lengthSquared = dx * dx + dy * dy;
  if (lengthSquared === 0) return Math.hypot(point.x - start.x, point.y - start.y);
  const t = Math.max(0, Math.min(1, ((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSquared));
  return Math.hypot(point.x - (start.x + t * dx), point.y - (start.y + t * dy));
}

export function strokeContainsPoint(point, points, tolerance) {
  if (!points.length) return false;
  if (points.length === 1) return Math.hypot(point.x - points[0].x, point.y - points[0].y) <= tolerance;
  for (let index = 1; index < points.length; index += 1) {
    if (distanceToSegment(point, points[index - 1], points[index]) <= tolerance) return true;
  }
  return false;
}

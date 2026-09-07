// One revolution is always 60 minutes. Split complete turns from the final
// sector so large durations never create recursive or overlapping SVG paths.
export function point(minutes, radius) {
  const angle = ((minutes % 60) * 6 - 90) * Math.PI / 180;
  return [160 + Math.cos(angle) * radius, 160 + Math.sin(angle) * radius];
}
export function sector(start, span, radius) {
  if (span <= 0) return '';
  const a = point(start, radius);
  if (span >= 60) {
    const b = point(start + 30, radius);
    return `M${a} A${radius} ${radius} 0 0 1 ${b} A${radius} ${radius} 0 0 1 ${a} Z`;
  }
  return `M160 160 L${a} A${radius} ${radius} 0 ${span > 30 ? 1 : 0} 1 ${point(start + span, radius)} Z`;
}
export function layers(start, span, radius, opacity) {
  const duration = Math.max(0, span), turns = Math.floor(duration / 60), tail = duration % 60;
  const accumulated = .78 * (1 - Math.pow(1 - opacity / .78, turns));
  const next = .78 * (1 - Math.pow(1 - opacity / .78, turns + 1));
  return {
    full: turns ? sector(start, 60, radius) : '',
    // Limit darkness, not duration: extra turns remain distinguishable without
    // eventually turning the whole dial opaque.
    opacity: accumulated,
    tail: sector(start, tail, radius),
    tailOpacity: (next - accumulated) / (1 - accumulated),
  };
}

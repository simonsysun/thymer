export class DialModel {
  constructor() {
    this.work = 50; this.rest = 10; this.phase = 'ready'; this.running = false;
    this.elapsed = 0; this.total = 0; this.autoStart = true;
  }
  get duration() { return (this.phase === 'rest' ? this.rest : this.work) * 60; }
  get remaining() { return Math.max(0, this.duration - this.elapsed); }
  minimum(kind) { return this.phase === kind ? Math.floor(this.elapsed / 60) + 1 : 1; }
  setMinutes(kind, value) {
    if (!Number.isFinite(value)) return;
    this[kind] = Math.min(Math.floor(Number.MAX_SAFE_INTEGER / 60), Math.max(this.minimum(kind), Math.round(value)));
  }
  toggle() {
    if (this.phase === 'ready' || this.phase === 'waiting') { this.phase = 'work'; this.elapsed = 0; }
    this.running = !this.running;
  }
  reset() { this.phase = 'ready'; this.elapsed = 0; this.running = false; }
  stage(phase) {
    this.phase = phase; this.running = false;
    this.elapsed = phase === 'work' ? this.work * 60 * .36 : phase === 'rest' ? this.rest * 60 * .42 : 0;
  }
  advance(seconds) {
    if (!this.running || !Number.isFinite(seconds) || seconds <= 0) return [];
    const events = [];
    while (seconds > 0 && this.running) {
      const used = Math.min(seconds, this.remaining);
      if (this.phase === 'work') this.total += used;
      this.elapsed += used; seconds -= used;
      if (this.remaining < 1e-7) {
        this.elapsed = 0;
        if (this.phase === 'work') { this.phase = 'rest'; events.push('休息一下'); }
        else if (this.autoStart) { this.phase = 'work'; events.push('新一轮开始'); }
        else { this.phase = 'waiting'; this.running = false; events.push('休息结束，点击开始'); }
      }
    }
    return events;
  }
}
export function angularDelta(from, to) {
  let delta = to - from;
  while (delta > 180) delta -= 360;
  while (delta < -180) delta += 360;
  return delta;
}

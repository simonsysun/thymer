import { moveWork, moveCycle } from './linkage.mjs';
export class DialModel {
  constructor() {
    this.work = 50; this.rest = 10; this.phase = 'ready'; this.running = false;
    this.elapsed = 0; this.total = 0; this.autoStart = true; this.limitTwoHours = true; this.activeRest = null;
  }
  get cycle() { return this.work+this.rest; }
  cycleMinimum() { return this.minimum('work')+this.minimum('rest'); }
  setCycle(minutes) {
    if(!Number.isFinite(minutes))return false;
    const before=this.work;
    const next=moveCycle(this.work,this.rest,minutes,{workMin:this.minimum('work'),restMin:this.minimum('rest'),restMax:this.maximum('rest')});
    this.work=next.work;this.rest=next.rest;
    if(this.phase==='rest'&&this.work===before)this.activeRest=this.rest;
    return this.work<before;
  }
  get duration() { return (this.phase === 'rest' ? (this.activeRest ?? this.rest) : this.work) * 60; }
  get remaining() { return Math.max(0, this.duration - this.elapsed); }
  minimum(kind) {
    return this.phase===kind && this.elapsed>0 ? Math.floor(this.elapsed/60)+1 : 0;
  }
  maximum(kind) {
    // Enabling the limit never cuts short a longer phase already underway.
    return this.limitTwoHours ? Math.max(120, this.phase === kind ? Math.max(this[kind],kind==='rest'?(this.activeRest ?? 0):0) : 0) : Math.floor(Number.MAX_SAFE_INTEGER / 60);
  }
  setLimit(enabled) {
    this.limitTwoHours = enabled;
    if (enabled) for (const kind of ['work', 'rest']) if (this.phase !== kind) this[kind] = Math.min(120, this[kind]);
  }
  clampPresets() { if (this.limitTwoHours) { this.work = Math.min(120, this.work); this.rest = Math.min(120, this.rest); } }
  setMinutes(kind, value) {
    if (!Number.isFinite(value)) return;
    if(kind==='work') {
      const next=moveWork(this.work,this.rest,value,{min:this.minimum(kind),max:this.maximum(kind),restMax:this.maximum('rest')});
      this.work=next.work;this.rest=next.rest;
    } else {
      this.rest=Math.min(this.maximum(kind),Math.max(this.minimum(kind),Math.round(value)));
      if(this.phase==='rest')this.activeRest=this.rest;
    }
  }
  toggle() {
    if(this.cycle===0){this.running=false;return;}
    if (this.phase === 'ready' || this.phase === 'waiting') { this.phase = this.work>0?'work':'rest'; this.activeRest=this.phase==='rest'?this.rest:null;this.elapsed = 0; }
    this.running = !this.running;
  }
  reset() { this.phase = 'ready'; this.elapsed = 0; this.running = false; this.activeRest=null; this.clampPresets(); }
  stage(phase) {
    this.clampPresets();
    this.phase = phase; this.running = false; this.activeRest=phase==='rest'?this.rest:null;
    this.elapsed = phase === 'work' ? this.work * 60 * .36 : phase === 'rest' ? this.rest * 60 * .42 : 0;
  }
  advance(seconds) {
    if (!this.running || !Number.isFinite(seconds) || seconds <= 0) return [];
    const events = [];
    while (seconds > 0 && this.running) {
      if(this.cycle===0 && this.remaining===0){this.running=false;this.phase='ready';break;}
      const used = Math.min(seconds, this.remaining);
      if (this.phase === 'work') this.total += used;
      this.elapsed += used; seconds -= used;
      if (this.remaining < 1e-7) {
        if (this.limitTwoHours) this[this.phase] = Math.min(120, this[this.phase]);
        this.elapsed = 0;
        if (this.phase === 'work' && this.rest>0) { this.phase = 'rest'; this.activeRest=this.rest; events.push('Time for a break'); }
        else if (this.autoStart && this.cycle>0) { this.phase = this.work>0?'work':'rest'; this.activeRest=this.phase==='rest'?this.rest:null; events.push('New cycle started'); }
        else { this.phase = 'waiting'; this.running = false; events.push('Cycle complete. Click to start'); }
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

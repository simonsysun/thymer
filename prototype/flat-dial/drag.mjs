import { angularDelta } from './model.mjs';

// Track the pointer's bearing, not just its delta. At a stop, the hand and
// pointer disengage until the pointer sweeps across the stopped hand again.
export class DialDrag {
  constructor(value) { this.value=value; this.last=null; this.locked=false; this.previousPoint=null; }
  move({angle,radius,min,max,offset=0}) {
    this.value=Math.max(min,Math.min(max,this.value));
    if(radius<0.001) { this.last=null;this.previousPoint=null;return this.value; }
    const radians=angle*Math.PI/180;
    const position={x:Math.sin(radians)*radius,y:-Math.cos(radians)*radius};
    // A continuous precision zone, unrelated to the center button's size.
    // Normal bearings outside 32 px; progressively damp unstable central angles.
    const closest=this.previousPoint?segmentDistance(this.previousPoint,position):radius;
    const t=Math.min(1,Math.max(0,Math.min(radius,closest)/32));
    const gain=t*t*(3-2*t);
    const crossesCenter=closest<4;
    this.previousPoint=position;
    const target=(this.value+offset)*6;
    let candidate;
    if(this.locked) {
      const distance=angularDelta(angle,target);
      const travel=this.last===null?0:angularDelta(this.last,angle);
      const toTarget=this.last===null?0:angularDelta(this.last,target);
      const crossed=!crossesCenter && this.last!==null && Math.abs(travel)>1e-9 && toTarget*travel>=0 && Math.abs(toTarget)<=Math.abs(travel)+1e-9;
      this.last=angle;
      if(Math.abs(distance)>0.5 && !crossed) return this.value;
      // Consume only the part of this event after alignment, never the
      // accumulated overshoot. Outward motion stays stopped at the bound.
      candidate=this.value+(crossed ? travel-toTarget : 0)/6;
    } else {
      candidate=this.value+angularDelta(target,angle)*gain/6;
      this.last=angle;
    }
    this.value=Math.max(min,Math.min(max,candidate));
    this.locked=candidate<min-1e-9 || candidate>max+1e-9;
    return this.value;
  }
}
function segmentDistance(a,b) {
  const x=b.x-a.x,y=b.y-a.y,den=x*x+y*y;
  const t=den?Math.max(0,Math.min(1,-(a.x*x+a.y*y)/den)):0;
  return Math.hypot(a.x+t*x,a.y+t*y);
}

import { point } from './geometry.mjs';
// Endpoint priority is independent of SVG paint order. Ownership is locked by the caller.
export function pickHand(x,y,work,cycle,hub=51.2) {
  if(Math.hypot(x-160,y-160)<=hub)return null;
  const candidates=[['work',work,105.3],['rest',cycle,134]].map(([kind,minutes,radius])=>{
    const [ex,ey]=point(minutes,radius),[sx,sy]=point(minutes,kind==='rest'&&cycle-work<.4?113:hub);
    const dx=ex-sx,dy=ey-sy,t=Math.max(0,Math.min(1,((x-sx)*dx+(y-sy)*dy)/(dx*dx+dy*dy)));
    return {kind,end:Math.hypot(x-ex,y-ey),shaft:Math.hypot(x-sx-t*dx,y-sy-t*dy)};
  });
  const endpoint=candidates.filter(c=>c.end<=15).sort((a,b)=>a.end-b.end)[0];
  return endpoint?.kind??candidates.filter(c=>c.shaft<=12).sort((a,b)=>a.shaft-b.shaft||a.end-b.end)[0]?.kind??null;
}

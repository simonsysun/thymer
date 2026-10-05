import assert from 'node:assert/strict';
import { DialDrag } from './drag.mjs';
const move=(drag,angle,radius=140,extra={})=>drag.move({angle,radius,deadRadius:51,min:1,max:120,...extra});
const close=(a,b)=>assert.ok(Math.abs(a-b)<1e-8,`${a} != ${b}`);
const center=new DialDrag(50);
close(move(center,300),50);
close(move(center,306,42),51); // inside the old button-sized dead zone now responds
const precision=new DialDrag(50);
move(precision,300,12);const near=move(precision,306,12);
assert.ok(near>50&&near<51); // still responds, with less sensitivity
const frozen=move(precision,0,0);close(move(precision,180,0),frozen);
close(move(center,312,300),52);
close(move(center,318,600),53);
const limit=new DialDrag(119);
close(move(limit,354),119);close(move(limit,12),120);
close(move(limit,60),120);close(move(limit,30),120);close(move(limit,6),120);
close(move(limit,354),119); // event straddles the stopped hand at 0°
const rotations=new DialDrag(120);
for(const angle of [30,120,210,300,30,90,150,210,270,330])close(move(rotations,angle),120);
close(move(rotations,350),120);close(move(rotations,10),120);
close(move(rotations,350),118+1/3); // align on the next encounter, no debt of extra turns
const rest=new DialDrag(10);
close(move(rest,0,140,{offset:50}),10);
close(move(rest,6,400,{offset:50}),11);
const low=new DialDrag(1);
close(move(low,350),1);close(move(low,355),1);close(move(low,0),1);
close(move(low,12),2);
const limitedCenter=new DialDrag(120);
close(move(limitedCenter,30),120);close(move(limitedCenter,180,0),120);
close(move(limitedCenter,270,200),120);close(move(limitedCenter,330,200),120);
close(move(limitedCenter,350,200),120);close(move(limitedCenter,10,200),120);
close(move(limitedCenter,354,200),119);
const unlimited=new DialDrag(120);
close(move(unlimited,12,300,{max:1e6}),122);
// Running edits respect the moving elapsed-time minimum.
const running=new DialDrag(20);
close(move(running,120,140,{min:21}),21);
close(move(running,132,140,{min:21}),22);
console.log('PASS: continuous center damping, outer reach, boundary recapture, multi-turn overshoot, rest offset, minimum and moving lower bound');

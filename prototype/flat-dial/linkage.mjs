// Endpoints are cumulative minutes, never modulo-60 angles.
export function moveWork(work, rest, requested, {min=0,max=Infinity}={}) {
  return {work:Math.max(min,Math.min(max,Math.round(requested))),rest};
}
export function moveCycle(work, rest, requested, {workMin=0,restMin=0,restMax=Infinity}={}) {
  const end=Math.max(workMin+restMin,Math.min(work+restMax,Math.round(requested)));
  const nextWork=Math.max(workMin,Math.min(work,end-restMin));
  return {work:nextWork,rest:end-nextWork};
}

import assert from 'node:assert/strict';
import { DialModel, angularDelta } from './model.mjs';
import { point, sector, layers } from './geometry.mjs';

const timer = new DialModel();
assert.equal(timer.limitTwoHours, true);
timer.setMinutes("work", 240);assert.equal(timer.work, 120);
timer.setMinutes("rest", 180);assert.equal(timer.rest, 120);
timer.setLimit(false);
for (const minutes of [180, 240, 720, 1440]) {
  timer.setMinutes('work', minutes);
  assert.equal(timer.work, minutes);
}
timer.setMinutes('rest', 90);
assert.equal(timer.rest, 90);
timer.setMinutes('work', 50);
timer.toggle(); timer.advance(20 * 60); timer.toggle();
timer.setMinutes('work', 240);
assert.equal(timer.remaining, 220 * 60);
assert.equal(timer.total, 20 * 60);
assert.equal(timer.running, false);
timer.setMinutes('work', 15);
assert.equal(timer.work, 21);
assert.equal(timer.remaining, 60);
timer.stage('rest');
const restRemaining = timer.remaining;
timer.setMinutes('work', 300);
assert.equal(timer.remaining, restRemaining);
assert.equal(timer.total, 1200);

// Rest crosses twelve o'clock: from minute 58 to minute 68. It must
// start at the long hand's angle, rather than silently restarting at zero.
const wedge = sector(58, 10, 104);
assert.ok(wedge.startsWith(`M160 160 L${point(58,104)}`));
assert.ok(wedge.endsWith(`${point(68,104)} Z`));
assert.deepEqual(point(68,104), point(8,104));
assert.equal(angularDelta(354,6), 12);
assert.equal(angularDelta(6,354), -12);
let previous = 0;
for (const span of [60,120,180,240]) {
  const result = layers(0,span,134,.25);
  assert.ok(result.opacity > previous);
  assert.equal(result.tail, '');
  assert.equal((result.full.match(/ A/g) || []).length, 2);
  previous = result.opacity;
}
assert.ok(layers(0,195,134,.25).tail.endsWith(`${point(15,134)} Z`));
assert.equal(layers(0,1000000,134,.25).full.length < 200, true);
assert.equal(sector(0,0,134), '');
const beforeTurn = layers(0,119.999,134,.25), afterTurn = layers(0,120,134,.25);
assert.ok(Math.abs(beforeTurn.opacity + (1-beforeTurn.opacity)*beforeTurn.tailOpacity - afterTurn.opacity) < 1e-12);
console.log('PASS: unlimited practical durations, paused edits, unchanged ledger, rest alignment, wraparound and multi-turn layers');

const limited = new DialModel();
limited.setLimit(false);limited.setMinutes('work',240);limited.toggle();limited.advance(130*60);
const before=limited.remaining;
limited.setLimit(true);
assert.equal(limited.remaining,before);
limited.setMinutes('work',300);assert.equal(limited.work,240);
limited.advance(before);
assert.equal(limited.phase,'rest');assert.equal(limited.work,120);
limited.reset();assert.equal(limited.work,120);
limited.setMinutes('work',0);assert.equal(limited.work,0);
limited.setMinutes('rest',0);assert.equal(limited.rest,0);
console.log('PASS: default two-hour limit, explicit opt-out and non-truncating in-flight limit changes');

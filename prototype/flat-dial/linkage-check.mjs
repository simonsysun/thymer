import assert from 'node:assert/strict';
import {DialModel} from './model.mjs';
import {pickHand} from './selection.mjs';
import {point} from './geometry.mjs';
const m=new DialModel();
m.setMinutes('work',55);assert.deepEqual([m.work,m.rest,m.cycle],[55,10,65]);
m.setMinutes('work',0);assert.deepEqual([m.work,m.rest,m.cycle],[0,10,10]);
m.setMinutes('work',50);m.setCycle(45);assert.deepEqual([m.work,m.rest],[45,0]);
m.setCycle(50);assert.deepEqual([m.work,m.rest],[45,5]);
m.setCycle(0);assert.deepEqual([m.work,m.rest],[0,0]);m.toggle();assert.equal(m.running,false);assert.deepEqual(m.advance(999),[]);
for(const [work,rest,total,phase] of [[0,2,0,'rest'],[2,0,300,'work']]){
 const timer=new DialModel();timer.work=work;timer.rest=rest;timer.toggle();
 timer.advance(300);assert.equal(timer.total,total);assert.equal(timer.phase,phase);assert.equal(timer.elapsed,60);
 timer.reset();timer.autoStart=false;timer.toggle();timer.advance(300);assert.equal(timer.phase,'waiting');assert.equal(timer.running,false);
}
const active=new DialModel();active.toggle();active.advance(1200);active.toggle();active.setCycle(0);
assert.deepEqual([active.work,active.rest,active.elapsed,active.total],[21,0,1200,1200]);
const resting=new DialModel();resting.stage('rest');const before=resting.remaining;resting.setMinutes('work',0);assert.equal(resting.remaining,before);
assert.equal(pickHand(...point(50,105.3),50,50),'work');assert.equal(pickHand(...point(50,134),50,50),'rest');
assert.equal(pickHand(...point(50,80),50,50),'work');assert.equal(pickHand(160,160,0,0),null);
console.log('PASS: fixed Rest carry, zero-length phases, empty-cycle guard, skip/repeat/wait, live accounting and coincident rod selection');

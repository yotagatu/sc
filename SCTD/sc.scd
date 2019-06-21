// =====================================================================
// SuperCollider Workspace
// =====================================================================


//:  BOOT SERVER

s.boot;

//:  EVALUATE BUFFERS  

~bufnoise1 = Buffer.alloc(s, 44100, 2);
~bufnoise2 = Buffer.alloc(s, 44100, 2);
~bufnoise3 = Buffer.alloc(s, 44100, 2);

//: EVALUATE OSC CONTROL BUSSES

~bus1 = Bus.control(s);
~bus2 = Bus.control(s);

//: EVALUATE CLOCK

t = TempoClock.new(240/60);
t.tempo_() // change tempo 

//: FUNCTIONS

FreqScope.new // evaluate for frequency scoping when playing
Stethoscope.new // evaluate oscilloscope when playing
OSCFunc.trace(true) // false for stop. evaluate for osc check when communication starts


//:   SOURCE SYNTHDEF

SynthDef(\noise, {| out, bufnum, pan=0, amp=1, atk=0.001, rel=0.2, ctf=6000,maxdel=0.2,delay=0.001,decay=0.5|
	var env, sig;
	env = Env.perc(atk,rel,1,-50).kr(2);
	sig = LPF.ar(HPF.ar(PinkNoise.ar(1),ctf, 2),8000,0.8);
	sig = sig * env;
	sig = BufAllpassC.ar(bufnum,sig,delay,decay);
	sig = CompanderD.ar(sig,1,0.5,1,0.001,0.001);
	sig = Pan2.ar(sig,pan,amp);
	Out.ar(out, sig)  
}).add

//:   OSC TO TOUCHDESIGNER

(
~touchD = NetAddr("127.0.0.1", 10000);

SynthDef(\ctrl, { | amp = 1 |
	var input,filter1, filter2, output1, output2;
	input = In.ar(0);
    filter1 = BHiPass.ar(input, 6000,1);
	filter2 = BLowPass.ar(input,5000,1);
	output1 = Amplitude.kr(filter1).ampdb.linlin(-60.0,0.0,0.0,1.0);
	output2 = Amplitude.kr(filter2).ampdb.linlin(-60.0,0.0,0.0,1.0);
	Out.kr(~bus1, output1);
	Out.kr(~bus2, output2);
}).play;

OSCdef(\values, {
	~touchD.sendMsg("/values", ~bus1.getSynchronous.asFloat, ~bus2.getSynchronous.asFloat)}, "/values");
)
//:


//      EVALUATE BLOCK PATTERNS     //



//:     PATTERN 1

~noise1 = Pdef(\noise1, (
	Pbind(\instrument, \noise,
		\dur, Prand([0.15,0.15,0.15],inf),
		\amp, Prand([0.2,0.4,0.3],inf),
		\ctf, Pseq([2000,1000,160],inf),
		\rel, Prand([0.1,0.1,0.2],inf),
		\pan, 0,
		\delay, 0.007,
		\decay, -0.4,
		\bufnum, ~bufnoise1
	)
)).(t,quant:4);

//:     PATTERN 2

~noise2 = Pdef(\noise2, (
	Pbind(\instrument, \noise,
		\dur, 0.3,
		\amp, Prand([0.4,0.2,0.3],inf),
		\ctf, Pxrand([10000,14000,9000],inf),
		\rel, Prand([0.5,0.3,0.6],inf),
		\atk, 0.001,
		\pan, Pseq([-0.4,0.4],inf),
		\delay, 0.008, 
		\decay, -0.4,  
		\bufnum, ~bufnoise2
	)
)).(t,quant:4);

//:     PATTERN 3

~noise3 = Pdef(\noise3, (
	Pbind(\instrument, \noise,
		\dur, 0.15,
		\amp, Prand([0.1,0.2,0.3],inf),
		\ctf, Pseq([4000,5000,2000],inf),
		\atk, 0.001,
		\rel, Pseq([0.1,0.2,0.1],inf),
		\pan, Prand([0.3,-0.3],inf),
		\delay, 0.002,
		\decay, -0.2,
		\bufnum, ~bufnoise3
	)
)).(t,quant:4);

//: EVALUATE FADETIME

~noise1.fadeTime=8
~noise2.fadeTime=8
~noise3.fadeTime=8

//: PLAY

~noise1.play  //.stop
~noise2.play  //.stop
~noise3.play  //.stop

//:


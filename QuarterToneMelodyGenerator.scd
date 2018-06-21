
//Ideas for Melody Generator from "Techniques for Generative Melodies Inspired by Music Cognition"
//Authors of paper: Andrew R Bown, Toby Gifford, Robert Davidson
//https://www.researchgate.net/publication/274140668_Techniques_for_Generative_Melodies_Inspired_by_Music_Cognition
//Idea is to use gaussian distribution for random note selection
//this gives a feeling of closeness of the notes/durations/amplitudes so they flow together/sound more natural/enjoyable

//Set tempo clock
TempoClock.default.tempo = 120/60;
//set memory higher. Pad was causing issues
~options = Server.local.options;
~options.memSize_(4096*8);
Scale.directory;
//Array of three octaves of quartertones starting on C3
a = [130.81*(1/1), 130.81*(28/27), 130.81*(16/15), 130.81*(11/10), 130.81*(9/8), 130.81*(8/7), 130.81*(6/5), 130.81*(11/9), 130.81*(5/4), 130.81*(9/7), 130.81*(4/3), 130.81*(11/8), 130.81*(7/5), 130.81*(16/11), 130.81*(3/2), 130.81*(14/9), 130.81*(8/5), 130.81*(18/11), 130.81*(5/3), 130.81*(7/4), 130.81*(9/5), 130.81*(11/6), 130.81*(15/8), 130.81*(27/14), 130.81*(2/1), 261.63*(28/27), 261.63*(16/15), 261.63*(11/10), 261.63*(9/8), 261.63*(8/7), 261.63*(6/5), 261.63*(11/9), 261.63*(5/4), 261.63*(9/7), 261.63*(4/3), 261.63*(11/8), 261.63*(7/5), 261.63*(16/11), 261.63*(3/2), 261.63*(14/9), 261.63*(8/5), 261.63*(18/11), 261.63*(5/3), 261.63*(7/4), 261.63*(9/5), 261.63*(11/6), 261.63*(15/8), 261.63*(27/14), 523.25*(1/1), 523.25*(28/27), 523.25*(16/15), 523.25*(11/10), 523.25*(9/8), 523.25*(8/7), 523.25*(6/5), 523.25*(11/9), 523.25*(5/4), 523.25*(9/7), 523.25*(4/3), 523.25*(11/8), 523.25*(7/5), 523.25*(16/11), 523.25*(3/2), 523.25*(14/9), 523.25*(8/5), 523.25*(18/11), 523.25*(5/3), 523.25*(7/4), 523.25*(9/5), 523.25*(11/6), 523.25*(15/8), 523.25*(27/14), 523.25*(2/1)];
//Duration Array
b = [8, 4, 3, 2, 1, 1/2, 1/3, 1/4, 1/5,1/6, 1/7, 1/8, 1/9, 1/10, 1/11, 1/12, 1/13, 1/14, 1/15, 1/16];

//Creates the melody
//INPUTS
//melodyArray: array of indices corresponding to quarter tone array
//melodyArray needs to have an extra index at the end to use as upperbound
//the last note will move toward the upperbound, then quit. The final indexed note will not be included
//noteLimit: the limit to how many notes can be added between indices in melodyArray
//OUTPUTS
//quarterToneArray: 3D array. the array contains each melody chunk.
//The number of notes (excluding the upperbound) in melodyArray will be the number of sub arrays
//Each of these arrays has 3 indices: note(index), dur(index), and amp -
//dur and amp are set to 0 and changed in the following functions
(
~melody = {arg melodyArray, noteLimit;
    var index, quarterToneArray, lowerBound, upperBound;
    quarterToneArray = Array.new(32);//initialize array to output
    index = 0;
    while({index + 1 < melodyArray.size}, {//this while loop creates the sub melody arrays
        var toneRow, count;
        toneRow = Array.new(noteLimit);//limits the sub melody array to the noteLimit
        count = 0;
        lowerBound = melodyArray.at(index);
        upperBound = melodyArray.at(index + 1);
        toneRow.add([lowerBound, 0, 0]);//add the first note (from the melodyArray) to the toneRow array
		//Changing this part to exclude the reaching upperbound limit. while loop will only consist of note count
        //while({(lowerBound != upperBound) && (count < noteLimit) }, {//this portion creates the new notes
		while({(count < noteLimit) }, {
            lowerBound = round(gauss((upperBound + lowerBound)/2, 2));//mean is upper + lower/2, s.d. is 2
            toneRow.add([lowerBound, 0, 0]);
            count = count + 1;
        });

        quarterToneArray.add(toneRow);
        index = index + 1;
    });
    quarterToneArray;
};
)
//Takes in an initialDuration(index of duration array), then uses gauss curve to get durations in close proximity for remainder of durations
//INPUTS
//quarterToneArray: 3D array outputted from above function.
//initialDuration: index of the desired initial duration associated with the duration array
//OUTPUTS
//3D array with notes and durations (no amplitudes)
(
~duration1 = {arg quarterToneArray, initialDuration;
    var mainArrayCounter, portionCounter, newMelodyArray, next;
    mainArrayCounter = 0;
    //create new array for outputting. will be 3D (there may be a more efficient way to do this -
    //i.e. add to this array, not create new
    newMelodyArray = Array.new(quarterToneArray.size);
    while({mainArrayCounter < quarterToneArray.size}, {
        var melodyPortion = Array.new(quarterToneArray.at(mainArrayCounter).size);//create new melody portion array
        portionCounter = 0;
        melodyPortion = quarterToneArray.at(mainArrayCounter);
        melodyPortion.at(0).put(1, initialDuration);//add intitialDuration to first index (0)
        while({portionCounter < (melodyPortion.size - 1)}, {//size less than one because 1st index filled
            next = round(gauss(melodyPortion.at(portionCounter).at(1), 1));
            if((next < 0), {next =  0}, {});//index can't be negative
            if((next > 15), {next =  15}, {});//index can't exceed 15
            melodyPortion.at(portionCounter + 1).put(1, next);
            portionCounter = portionCounter + 1;
        });
        newMelodyArray.add(melodyPortion);
        mainArrayCounter = mainArrayCounter + 1;
    });
    newMelodyArray;
}
)
//Takes in an initialDuration(index of duration array), then applies it to all notes.
//EX: input: 10, all cells duration set to 10
//INPUTS
//quarterToneArray: 3D array outputted from above function.
//initialDuration: index of the desired initial duration associated with the duration array
//OUTPUTS
//3D array with notes and durations (no amplitudes)
(
~duration2 = {arg quarterToneArray, initialDuration;
    var rhythmChoices, mainArrayCounter, portionCounter, newMelodyArray, next;
    mainArrayCounter = 0;
    newMelodyArray = Array.new(quarterToneArray.size);
    while({mainArrayCounter < quarterToneArray.size}, {
        var melodyPortion = Array.new(32);
        portionCounter = 0;
        melodyPortion = quarterToneArray.at(mainArrayCounter);
        while({portionCounter < (melodyPortion.size)}, {
            melodyPortion.at(portionCounter).put(1, initialDuration);
            portionCounter = portionCounter + 1;
        });
        newMelodyArray.add(melodyPortion);
        mainArrayCounter = mainArrayCounter + 1;
    });
    newMelodyArray;
}
)
//adds the amplitude to the 3D array using gaussian distribution
//attempts to normalize duration array (when using ~duration1) to only allow whole melodies that are whole numbers in length
//INPUTS
//quarterToneArray: 3D array outputted from duration funtion
//freqArray: Array of quartertone frequencies (set to 'a' at beginning of code)
//durArray: Array of durations (set to b at beginning of code)
//OUTPUTS
//2D array like [[notes], [durations], [amplitudes]]
//This allows for pbind to play through each array /freq=array.at(0), /dur=array.at(1), /amp=array.at(2)
//see pbind setup below
(
~finish = {arg quarterToneArray, freqArray, durArray;
    var rhythmChoices, mainArrayCounter, portionCounter, newMelodyArray, initialAmplitude, next, finalArray, count1, count2, dur, amp, note, durSum, currentDurVal;
    mainArrayCounter = 0;
    finalArray = Array.new(100);
    dur = Array.new(100);
    amp = Array.new(100);
    note = Array.new(100);
    newMelodyArray = Array.new(quarterToneArray.size);
    while({mainArrayCounter < quarterToneArray.size}, {
        var melodyPortion = Array.new(32);
        portionCounter = 0;
        melodyPortion = quarterToneArray.at(mainArrayCounter);
		//5/2/18 -> changing this intiAmp to 1.0.rand
		initialAmplitude = 1.0.rand;
        //initialAmplitude = 1;//sets initial amplitude to 1
        melodyPortion.at(0).put(2, initialAmplitude);//add to first entry of 2D array in the third position
        while({portionCounter < (melodyPortion.size - 1)}, {
            next = gauss(melodyPortion.at(portionCounter).at(2), 0.5);// use gauss to find next amp
            if((next < 0), {next =  0}, {});//restrict to 0 minimum
            if((next > 1), {next =  1}, {});//restrict to 1.0 maximum
            melodyPortion.at(portionCounter + 1).put(2, next);
            portionCounter = portionCounter + 1;
        });
        newMelodyArray.add(melodyPortion);
        mainArrayCounter = mainArrayCounter + 1;
    });
    count1 = 0;
	//this portion attempts to normalize the duration of each melody
    while({count1 < newMelodyArray.size}, {
        count2 = 0;
        durSum = 0;
        while({count2 < newMelodyArray.at(count1).size}, {
			//sums the durations in the melody (obtains the actual duration from the durArray
			currentDurVal = durArray.at(newMelodyArray.at(count1).at(count2).at(1));
            durSum = durSum + currentDurVal;

			//obtains the note(freq) from the freq array
            //note.add(freqArray.at(newMelodyArray.at(count1).at(count2).at(0)));

			//Trying with different scales.. need to find a better way to do this shit... ffs
			//this is using minor scale at middle A, i think
			note.add(Scale.minor.degreeToFreq(newMelodyArray.at(count1).at(count2).at(0), 57.midicps, 0));

			//when on the last element, check if the sum of durations is a whole number
			//This puts a heavy weight on the last note in the chunk.... should figure this out
			if(((count2 + 1 == newMelodyArray.at(count1).size)&&((durSum%4)>0)), {dur.add(currentDurVal + (4-(durSum%4)))}, {dur.add(currentDurVal)});
            amp.add(newMelodyArray.at(count1).at(count2).at(2));
            count2 = count2 + 1;
        });
        count1 = count1 + 1;
    });
	//adds all the entries to the corresponding arrays
    finalArray.add(note);
    finalArray.add(dur);
    finalArray.add(amp);
    finalArray;
}
)
//initialize melody arrays to input into ~melody function
~malletMelody1 = [0, 3, 8, 6, 0];
~malletMelody2 = [7, 10, 13, 8, 7];
~malletMelody3 = [0, 3, 5, 8, 0];
~malletMelody4 = [7, 4, 11, 8, 7];
~droneMelody = [34, 40, 34];
~bassMelody = [0, 2, 0];
~padMelody = [34, 24, 34];
//Run the melody arrays through all the functions
~melody.(~malletMelody1, 3);
~duration1.(~melody.(~malletMelody1, 3), 5);
(
~mallet1 = ~finish.(~duration1.(~melody.(~malletMelody1, 3), 5), a, b);
~mallet2 = ~finish.(~duration1.(~melody.(~malletMelody2, 8), 7), a, b);
)
(
~mallet3 = ~finish.(~duration1.(~melody.(~malletMelody3, 3), 7), a, b);
~mallet4 = ~finish.(~duration1.(~melody.(~malletMelody4, 8), 3), a, b);
)
~drone = ~finish.(~duration2.(~melody.(~droneMelody, 2), 0), a, b);
~bass = ~finish.(~duration2.(~melody.(~bassMelody, 2), 3), a, b);
~pad = ~finish.(~duration2.(~melody.(~padMelody, 3), 1), a, b);

//Screwin around
(
~bassSeq = Pbind(
    \instrument, \bass,
    \freq, Pseq( ~bass.at(0)/2, inf),
    \dur, Pseq( ~bass.at(1)*2, inf),
    \amp, Pseq( ~bass.at(2)/4, inf);
).play(quant: 0);
)
(
~mallet3Seq.stop;
~mallet4Seq.stop;
~mallet1Seq = Pbind(
    \instrument, \mallet,
    \freq, Pseq( ~mallet1.at(0), inf),
    //\dur, 1/2,
	\dur, Pseq( ~mallet1.at(1), inf),
    \amp, 0.6,
	//Pseq( ~mallet1.at(2)*0.6, inf);
).play(quant: 0);

~mallet2Seq = Pbind(
    \instrument, \mallet,
    \freq, Pseq( ~mallet2.at(0), inf),
    \dur, 1/4,
	//Pseq( ~mallet2.at(1), inf),
    \amp, Pseq( ~mallet2.at(2)*0.5, inf);
).play(quant: 0);
)

(
~mallet1Seq.stop;
~mallet2Seq.stop;
~mallet3Seq = Pbind(
    \instrument, \mallet,
    \freq, Pseq( ~mallet1.at(0), inf),
    \dur, 1,
	//Pseq( ~mallet1.at(1)/2, inf),
    \amp, 0.6,
	//Pseq( ~mallet1.at(2)*0.6, inf);
).play(quant: 0);

~mallet4Seq = Pbind(
    \instrument, \mallet,
    \freq, Pseq( ~mallet4.at(0), inf),
    \dur, 1/4,
	//Pseq( ~mallet4.at(1), inf),
    \amp, Pseq( ~mallet4.at(2)*0.5, inf);
).play(quant: 0);
)
--------------------------
(
~padSeq = Pbind(
    \instrument, \pad,
    \freq, Pseq( ~pad.at(0), inf),
    \dur, Pseq( ~pad.at(1), inf),
    \amp, Pseq( ~pad.at(2)*0.03, inf);
).play(quant: 0);
)

(
~mallet2Seq = Pbind(
    \instrument, \mallet2,
    \freq, Pseq( ~mallet2_1.at(0)*4, inf),
    \dur, Pseq( ~mallet2_1.at(1), inf),
    \amp, Pseq( ~mallet2_1.at(2)*0.1, inf);
).play(quant: 0);

~mallet1Seq.stream = Pbind(
    \instrument, \mallet,
    \freq, Pseq( ~mallet1.at(0), inf),
    \dur, 1,
	//Pseq( ~mallet1.at(1)/2, inf),
    \amp, Pseq( ~mallet1.at(2)*0.3, inf);
).asStream;
)
(
~droneSeq = Pbind(
    \instrument, \drone,
    \freq, Pseq(~drone.at(0)/4, inf),
    \dur, Pseq(~drone.at(1), inf),
    \amp, Pseq( ~drone.at(2)*0.3, inf);
).play(quant: 0);
)

(
~padSeq.stream = Pbind(
    \instrument, \pad,
    \freq, Pseq( ~pad.at(0)*2, inf),
    \dur, Pseq( ~pad.at(1), inf),
    \amp, Pseq( ~pad.at(2)*0.0, inf);
).asStream;
)
~bassSeq.stop;
(
~mallet2Seq.stream = Pbind(
    \instrument, \mallet2,
    \freq, Pseq( ~mallet2_3.at(0)*8, inf),
    \dur, Pseq( ~mallet2_3.at(1), inf),
    \amp, Pseq( ~mallet2_3.at(2)*0.004, inf);
).asStream;
)
(
~mallet1Seq.stream = Pbind(
    \instrument, \mallet,
    \freq, Pseq( ~mallet1.at(0), inf),
    \dur, Pseq( ~mallet1.at(1), inf),
    \amp, Pseq( ~mallet1.at(2)*0.05, inf);
).asStream;
)
(
~droneSeq.stream = Pbind(
    \instrument, \drone,
    \freq, Pseq(~drone.at(0), inf),
    \dur, Pseq(~drone.at(1)*2, inf),
    \amp, Pseq( ~drone.at(2)*0.04, inf);
).asStream;
)
(
~mallet2Seq.stream = Pbind(
    \instrument, \mallet2,
    \freq, Pseq( ~mallet2_1.at(0)*4, inf),
    \dur, Pseq( ~mallet2_1.at(1), inf),
    \amp, Pseq( ~mallet2_1.at(2)*0.07, inf);
).asStream;
)
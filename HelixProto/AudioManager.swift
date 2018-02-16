//
//  AudioManager.swift
//  HelixProto
//
//  Created by Alexander Schülke on 13.02.18.
//  Copyright © 2018 Alexander Schülke. All rights reserved.
//

import Foundation
import AudioKit

class AudioManager {
    
    public var delegate: AudioManagerDelegate?
    public var sequencer = AKSequencer(filename: "4tracks")
    public var tempo: Double = 200
    
    // The interfaces to control the wav datas via MIDI
    private var sampler1 = AKMIDISampler()
    private var sampler2 = AKMIDISampler()
    private var sampler3 = AKMIDISampler()
    private var sampler4 = AKMIDISampler()

    public init() {
        
        // Load wav files into samplers
        do {
            try sampler1.loadWav("cheeb-bd")
            try sampler2.loadWav("cheeb-snr")
            try sampler3.loadWav("cheeb-hat")
            try sampler4.loadWav("cheeb-ch")
        } catch let error {
            print(error.localizedDescription)
        }
        
        // Bundle samplers to one audio output
        let mixer = AKMixer(sampler1, sampler2, sampler3, sampler4)
        AudioKit.output = mixer
        
        // Basic setup
        sequencer = AKSequencer(filename: "4tracks")
        sequencer.setLength(AKDuration(beats: 12))
        sequencer.setTempo(tempo)
        sequencer.enableLooping()
        
        // Set the instruments
        sequencer.tracks[0].setMIDIOutput(sampler1.midiIn)
        sequencer.tracks[1].setMIDIOutput(sampler2.midiIn)
        sequencer.tracks[2].setMIDIOutput(sampler3.midiIn)
        sequencer.tracks[3].setMIDIOutput(sampler4.midiIn)
        
        // Remove all previous sampler events
        for track in sequencer.tracks {
            track.clear()
        }
        
        AudioKit.start()
        
    }
    
    public func play() {
        updateLoop()
        sequencer.play()
    }
    
    public func stop() {
        sequencer.stop()
    }
    
    // Responsible for creating the audio with the sequencer by considering the provided bases in the DNA.
    public func updateLoop() {
        
        guard let basesByParts = delegate?.getBasesByParts() else {
            return
        }
        
        // Remove all previous sampler events, so old tones ar enot played
        for track in sequencer.tracks {
            track.clear()
        }
        
        // Index takes care of correct beat position and length while looping
        var index = 0
        
        // Check for each DNA part if there is a base assigned to it. If a base was assigned, determine used sampler by
        // the base's name.
        for (_, base) in basesByParts {
            if let base = base {
                if base.name == "tone1" {
                    sequencer.tracks[0].add(noteNumber: 62, velocity: 127, position: AKDuration(beats: Double(index)), duration: AKDuration(beats: 12 - index))
                } else if base.name == "tone2" {
                    sequencer.tracks[1].add(noteNumber: 60, velocity: 127, position: AKDuration(beats: Double(index)), duration: AKDuration(beats: 12 - index))
                } else if base.name == "tone3" {
                    sequencer.tracks[2].add(noteNumber: 58, velocity: 127, position: AKDuration(beats: Double(index)), duration: AKDuration(beats: 12 - index))
                } else if base.name == "tone4" {
                    sequencer.tracks[3].add(noteNumber: 56, velocity: 127, position: AKDuration(beats: Double(index)), duration: AKDuration(beats: 12 - index))
                }
            }
            index = index + 1
        }
    }
    
    public func playSample(baseName: String) {
        switch baseName {
        case "tone1":
            sampler1.play(noteNumber: 62, velocity: 127, channel: 12)
        case "tone2":
            sampler2.play(noteNumber: 62, velocity: 127, channel: 12)
        case "tone3":
            sampler3.play(noteNumber: 62, velocity: 127, channel: 12)
        case "tone4":
            sampler4.play(noteNumber: 62, velocity: 127, channel: 12)
        default:
            return
        }
    }

    
}

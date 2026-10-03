# Song Studio

A one-file music studio for singers and songwriters. It runs in the browser and needs no install.

## Open it
**Best: your own web link (free).** The repository is public, so GitHub Pages can host Song Studio. Recording and downloads work there, including on phones, and you can add it to your home screen like an app:
1. On GitHub, open the repository → **Settings** → **Pages**.
2. Under **Build and deployment**, set **Source** to **Deploy from a branch**.
3. Pick the branch that has the `song-studio` folder and the **/ (root)** folder, then **Save**.
4. After a minute or two, open `https://cjzang03-dev.github.io/Chojay/song-studio/`.

**Or offline:** download the `song-studio` folder and open `index.html` in Chrome, Edge, Safari or Firefox. Allow microphone access when asked.

## Easy mode
Song Studio opens in Easy mode: four steps on one screen.
1. **Choose a vibe** (Pop, Afrobeats, Trap, R&B, Gospel, Reggaeton, Lo-fi, Acoustic). It plays straight away; use Lower/Higher to fit your voice and Slower/Faster for speed.
2. **Write your lyrics** for the verse and chorus, with the chords shown.
3. **Sing and record** with one big button, with optional autotune.
4. **Listen and save** with simple volume sliders and a download button.

The player bar at the bottom shows the chord and your lyrics while you sing. Tap **Open full studio** for every tool.

## Studio
On a computer (980px and wider), the full studio is built around your instruments:
- **Left:** your instruments (Vocals, Drums, Chords, Bass, Melody, 808 and any you add), each with mute and solo. Tap one to work on it.
- **Middle:** the editor for that instrument. Drums get the beat grid, Chords get a chord per bar plus chord ideas, sounds and rhythms, Bass gets sounds and patterns, melodic instruments get the piano roll, and Vocals get the microphone, takes and autotune. The song's parts sit along the top; tabs pick which part you edit.
- **Right:** your lyrics, one box per part, with the current chord shown big and the part being played highlighted. Syllables per line are counted to help fit the words to the beat.
- **Bottom:** back to start, stop, play/pause, record, loop, metronome, count-in, time and bar, a song progress bar you can tap to jump, and master volume.
- **Top:** song name, style, key, tempo, Surprise me, Song parts, Keyboard, Mixer, Export and Easy mode.

On smaller screens it switches to a tab layout.

## What it does
- **Song & lyrics**: build the song from parts (verse, chorus, bridge…), pick chords for each bar (or use "Chord ideas"), and write lyrics for each part. "Surprise me" picks a key, tempo, chords and beat for you.
- **Beat & sounds**: drum styles (pop, trap, afrobeats, reggaeton, lo-fi…), an editable 16-step drum grid, swing, and chord and bass sounds and rhythms. Any part can have its own drum pattern.
- **Piano roll & channel rack** (like FL Studio): add instrument channels (synth lead, 808, bells, strings, piano…), then draw notes for each part. "Give me an idea" writes a melody or 808 line that fits your chords, and "Record keys" captures what you play on your computer keyboard while the song runs. Undo and copy-between-parts included.
- **Playlist**: the whole song on a timeline with every part, channel and vocal take. Tap the ruler to choose where playback and recording start, and drag vocal clips to line them up.
- **Vocals**: record over the music with a count-in, stack as many takes as you like (harmonies, doubles), mute, set volume, nudge timing, or import a voice memo.
- **Autotune**: pitch correction for any take, snapped to the song's key (or to any note). Pick Natural, Pop or Hard (the robot effect), or set the speed and amount yourself. A pitch view shows how you sang and how it sounds after. Your original recording is always kept.
- **Keyboard**: an on-screen piano that marks the notes in your key and the chord playing now, so you can find melodies.
- **Mix & export**: set levels, vocal reverb and echo, then download the full song or the instrumental as a WAV file.

While you sing, the big chord display shows the current and next chord and the lyrics for the part you're in.

## Also included
- **My songs:** keep many songs and switch between them; each keeps its own lyrics, beats and recordings.
- **Undo / Redo** for every change (Ctrl+Z, Ctrl+Shift+Z). Recordings are not affected by undo.
- **Hum to find chords:** hum your tune while a part plays; the studio picks a chord for each bar and can put your tune into the piano roll.
- **Modelled instruments:** piano, guitar and electric bass are physical models of real strings; drums use classic analogue-style cymbals and toms.
- **Voice tools:** add a harmony above or below a take, double a take for a fuller sound, or re-record just one part (punch-in).
- **Drum fills, crash cymbals and whooshes** per part.
- **Export:** WAV, MP3, or stems (one WAV per track in a zip).
- **Rhyme helper:** click at the end of a lyric line, or type a word, to see rhymes; tap one to add it.
- **Live pitch line:** see which note you are singing, whether it is in tune, in the key and in the chord.

Your songs and takes are saved in your browser automatically. Wear headphones when recording.

## Credits
Bundled in `vendor/`: [lamejs](https://github.com/zhuker/lamejs) (LGPL-3.0) for MP3 encoding, [JSZip](https://stuk.github.io/jszip/) (MIT) for zip files, and a rhyme list built from the [CMU Pronouncing Dictionary](http://www.speech.cs.cmu.edu/cgi-bin/cmudict) (via cmu-pronouncing-dictionary, ISC) and SCOWL common words (via wordlist-english, MIT). Licence texts are in `vendor/`.

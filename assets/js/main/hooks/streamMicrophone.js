// the duration of the audio chunk in milliseconds
// there's a bug currently where audio chunks are twice as long as they should be
const CHUNK_DURATION_IN_MS = 1_000 * 60 * 1;
const AUDIO_BITS_PER_SECOND = 128_000;
// the duration in milliseconds after which the first chunk is requested
// this determines the size of the first chunk
const REQUEST_FIRST_CHUNK_AFTER_DURATION_IN_MS = 50;
const SILENCE_THRESHOLD = 0.05;
const SAMPLE_RATE = 16_000;

// @ryanzidago
//
// StreamMicrophone is a hook that streams raw audio data into chunks to the server.
// Because .ogg can't be streamed, we need to build the chunks ourselves.
// I'm using the first chunk that contains the headers and prepend it to the rest of the chunks.
// Otherwise, it isn't possible to read any but the very first chunk.
// See Elixir forum thread here: https://elixirforum.com/t/how-to-stream-audio-chunks-from-the-browser-to-the-server/66091
const StreamMicrophone = {
  mounted() {
    console.log("StreamMicrophone mounted");
    // @ryanzidago - ensure clean state on mount
    this.stopRecording();

    this.el.addEventListener("click", () => {
      if (isRecording(this.mediaRecorder)) {
        this.stopRecording();
      } else {
        this.startRecording();
      }
    });
  },

  updated() {
    console.log("StreamMicrophone updated");
  },

  destroyed() {
    console.log("StreamMicrophone destroyed");
    this.stopRecording();
  },

  disconnected() {
    console.log("StreamMicrophone disconnected");
    this.stopRecording();
  },

  startRecording() {
    navigator.mediaDevices
      .getUserMedia({ audio: true })
      .then((stream) => {
        this.pushEvent("start_recording", {});

        this.mediaRecorder = new MediaRecorder(stream, {
          audioBitsPerSecond: AUDIO_BITS_PER_SECOND,
        });

        this.handleOnDataAvailable();
        this.handleTimeUpdate();
      })
      .catch((error) => {
        if (error.name == "NotAllowedError") {
          alert(
            "Permission to access the microphone is required in order to generate the audio transcript."
          );
        }
      });
  },

  handleOnDataAvailable() {
    this.mediaRecorder.addEventListener("dataavailable", async (event) => {
      console.log("Data available", event);

      if (event.data.size > 0) {
        if (this.firstBlob && event.data.size < 25000) {
          return;
        }

        if (!this.firstBlob) {
          this.firstBlob = event.data;
        } else {
          const chunkWithHeader = new Blob([this.firstBlob, event.data], {
            type: event.type,
          });

          this.audioChunks.push(chunkWithHeader);
          this.processChunks();

          const isSilentChunk = await isSilent(chunkWithHeader);
          if (isSilentChunk) {
            console.log("Silent chunk detected, skipping...");
          } else {
            this.audioChunks.push(chunkWithHeader);
            this.processChunks();
          }
        }
      }
    });
  },

  handleTimeUpdate() {
    this.mediaRecorder.start(CHUNK_DURATION_IN_MS);

    // Force the first chunk to be generated
    setTimeout(() => {
      this.mediaRecorder.requestData(); // Request the first chunk early
    }, REQUEST_FIRST_CHUNK_AFTER_DURATION_IN_MS);

    this.updateInterval = setInterval(() => {
      this.mediaRecorder.requestData();
    }, CHUNK_DURATION_IN_MS);
  },

  stopRecording() {
    console.log("Stop recording");
    if (this.mediaRecorder) {
      // once `this.mediaRecorder.stop()` is called, the `stop` event is triggered
      this.mediaRecorder.addEventListener("stop", () => {
        console.log("Stop recording - processing the last chunks");
        this.processChunks();
      });

      this.mediaRecorder.stop();
    }

    this.mediaRecorder = null;
    this.firstBlob = null;
    this.audioChunks = [];
    clearInterval(this.updateInterval);
    this.pushEvent("stop_recording", {});
  },

  async processChunks() {
    console.log("Process chunks");
    console.log(this.audioChunks.length);

    if (this.audioChunks.length < 1) return;

    const audioBlob = new Blob(this.audioChunks);
    console.log(audioBlob);

    audioBlob.arrayBuffer().then((buffer) => {
      const context = new AudioContext({ sampleRate: SAMPLE_RATE });

      context.decodeAudioData(buffer, (audioBuffer) => {
        const pcmBuffer = audioBufferToPcm(audioBuffer);
        const buffer = convertEndianness32(
          pcmBuffer,
          getEndianness(),
          this.el.dataset.endianness
        );
        this.upload("audio_from_user_microphone", [new Blob([buffer])]);
      });
    });

    this.audioChunks = [];
  },
};

function isRecording(mediaRecorder) {
  return mediaRecorder && mediaRecorder.state === "recording";
}

function isSilent(audioChunk) {
  return new Promise((resolve) => {
    const audioContext = new (window.AudioContext ||
      window.webkitAudioContext)();
    const fileReader = new FileReader();

    fileReader.onload = function () {
      audioContext
        .decodeAudioData(this.result)
        .then((buffer) => {
          const channelData = buffer.getChannelData(0);
          const maxAmplitude = channelData.reduce(
            (max, value) => Math.max(max, Math.abs(value)),
            0
          );
          resolve(maxAmplitude <= SILENCE_THRESHOLD);
        })
        .catch((error) => {
          console.error("Errror decoding audio data", error);
          resolve(false);
        });
    };

    fileReader.readAsArrayBuffer(audioChunk);
  });
}

function audioBufferToPcm(audioBuffer) {
  const numChannels = audioBuffer.numberOfChannels;
  const length = audioBuffer.length;
  const size = Float32Array.BYTES_PER_ELEMENT * length;
  const buffer = new ArrayBuffer(size);
  const pcmArray = new Float32Array(buffer);
  const channelDataBuffers = Array.from({ length: numChannels }, (x, channel) =>
    audioBuffer.getChannelData(channel)
  );

  // Average all channels upfront, so the PCM is always mono
  for (let i = 0; i < pcmArray.length; i++) {
    let sum = 0;

    for (let channel = 0; channel < numChannels; channel++) {
      sum += channelDataBuffers[channel][i];
    }

    pcmArray[i] = sum / numChannels;
  }

  return buffer;
}

function convertEndianness32(buffer, from, to) {
  if (from === to) return buffer;

  // If the endianness differs, we swap bytes accordingly
  for (let i = 0; i < buffer.byteLength / 4; i++) {
    const b1 = buffer[i];
    const b2 = buffer[i + 1];
    const b3 = buffer[i + 2];
    const b4 = buffer[i + 3];

    buffer[i] = b4;
    buffer[i + 1] = b3;
    buffer[i + 2] = b2;
    buffer[i + 3] = b1;
  }

  return buffer;
}

function getEndianness() {
  const buffer = new ArrayBuffer(2);
  const int16Array = new Uint16Array(buffer);
  const int8Array = new Uint8Array(buffer);

  int16Array[0] = 1;

  if (int8Array[0] === 1) {
    return "little";
  } else {
    return "big";
  }
}

export { StreamMicrophone };

const CHUNK_DURATION_IN_MS = 5_000;
const AUDIO_BITS_PER_SECOND = 128_000;
const REQUEST_FIRST_CHUNK_AFTER_DURATION_IN_MS = 50;

// @ryanzidago
//
// StreamMicrophone is a hook that streams raw audio data into chunks to the server.
// Because .ogg can't be streamed, we need to build the chunks ourselves.
// I'm using the first chunk that contains the headers and prepend it to the rest of the chunks.
// Otherwise, it isn't possible to read any but the very first chunk.
const StreamMicrophone = {
  mounted() {
    this.recording = false;
    this.mediaRecorder = null;
    this.firstBlob = null;

    this.el.addEventListener("click", () => {
      if (this.isRecording()) {
        this.stopRecording();
      } else {
        this.startRecording();
      }
    });
  },

  startRecording() {
    this.audioChunks = [];

    navigator.mediaDevices.getUserMedia({ audio: true }).then((stream) => {
      this.mediaRecorder = new MediaRecorder(stream, {
        audioBitsPerSecond: AUDIO_BITS_PER_SECOND,
      });

      this.mediaRecorder.addEventListener("dataavailable", (event) => {
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
          }
        }
      });

      this.mediaRecorder.start(CHUNK_DURATION_IN_MS);

      // Force the first chunk to be generated
      setTimeout(() => {
        this.mediaRecorder.requestData(); // Request the first chunk early
      }, REQUEST_FIRST_CHUNK_AFTER_DURATION_IN_MS);

      this.updateInterval = setInterval(() => {
        this.mediaRecorder.requestData();
      }, CHUNK_DURATION_IN_MS);
    });
  },

  stopRecording() {
    this.mediaRecorder.addEventListener("stop", () => {
      this.processChunks();
    });

    this.mediaRecorder.stop();
    this.firstBlob = null;
    clearInterval(this.updateInterval);
  },

  processChunks() {
    if (this.audioChunks.length < 1) return;

    const audioBlob = new Blob(this.audioChunks);
    this.upload("audio", [audioBlob]);
    this.audioChunks = [];
  },

  isRecording() {
    return this.mediaRecorder && this.mediaRecorder.state === "recording";
  },
};

export { StreamMicrophone };

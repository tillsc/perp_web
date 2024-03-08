class NumberLiveOcrElement extends HTMLElement {

  constructor() {
    super();
    this.tasseractWorkerFuture = import('https://cdn.jsdelivr.net/npm/tesseract.js@5/dist/tesseract.esm.min.js').
    then(({default: Tesseract}) => {
      this.Tasseract = Tesseract;
      return Tesseract.createWorker('eng');
    });
  }

  connectedCallback() {
    [...this.querySelectorAll('.number-ocr-generated')].forEach((e) => e.remove());
    this.tasseractWorkerFuture.then((worker) => {
      this.tasseractWorker = worker;
      this.input = this.querySelector('input[type=number]');
      if (!this.input) {
        console.log("No input[type=number] child found in number-ocr element", this);
      }
      else {
        this.enhanceInput();
      }
    });
  }

  async enhanceInput() {
    const btn = document.createElement('a');
    btn.innerText = 'OCR';
    btn.classList.add('number-ocr-generated');
    btn.addEventListener('click', (e) => {
      if (this.snapshotCanvas) {
        this.stopCapture();
      }
      else {
        this.initVideoPreview();
        this.startCapture();
      }
      e.preventDefault();
      return false;
    });
    const ig = this.input.closest('.input-group');
    if (ig) {
      btn.classList.add('btn', 'btn-primary');
      ig.append(btn);
    }
    else {
      this.input.after(btn);
    }
  }

  initVideoPreview() {
    this.snapshotCanvas = document.createElement('canvas');
    this.append(this.snapshotCanvas);
    this.snapshotCanvas.hidden = true;
    this.snapshotContext = this.snapshotCanvas.getContext('2d');

    this.videoPreview = document.createElement('video');
    this.append(this.videoPreview);
    this.videoPreview.addEventListener("loadedmetadata", () => {
      this.videoPreview.play();
    });
    this.videoPreview.addEventListener("canplay", (ev) => {
        if (!this.streaming) {
          this.videoRatio = this.videoPreview.videoHeight / this.videoPreview.videoWidth;
          const width = 320;
          const height = this.videoRatio * width;

          this.videoPreview.setAttribute("width", width);
          this.videoPreview.setAttribute("height", height);
          this.snapshotCanvas.setAttribute("width", width);
          this.snapshotCanvas.setAttribute("height", height);
          this.streaming = true;
        }
      }, false);
  }

  async startCapture() {
      this.stream = await navigator.mediaDevices.getUserMedia({video: true, audio: false});
      this.videoPreview.srcObject = this.stream;
      this.captureTimeout = setTimeout(() => this.captureAndParse(), 1000);
  }

  async  stopCapture() {
    clearTimeout(this.captureTimeout);
    this.snapshotCanvas.remove();
    this.snapshotCanvas = null;
    this.snapshotContext = null;
    this.videoPreview.remove();
    this.videoPreview = null;
    this.stream.getTracks().forEach(function(track) {
      track.stop();
    });
    this.stream = null;
  }

  async captureAndParse() {
    if (this.streaming) {
      this.snapshotContext.drawImage(this.videoPreview,
        this.videoPreview.videoWidth * 0.10, this.videoPreview.videoWidth * 0.10 * this.videoRatio,
        this.videoPreview.videoWidth * 0.80, this.videoPreview.videoWidth * 0.80 * this.videoRatio,
        0,0, this.snapshotCanvas.width, this.snapshotCanvas.height);
      const result = await this.tasseractWorker.recognize(this.snapshotCanvas, { tessedit_char_whitelist: '0123456789.,-'});
      const match = result.data.text.toString().match(/[0-9][0-9]+([,\.][0-9]+)?/);
      console.log(result.data.text, "MATCH:", match);
      if (match) {
        let num = parseFloat(match[0].replace(',', '.'));
        while (num > 200) { // No comma detected?
          num = num / 10;
        }
        this.input.value = num.toString();
      }
      //this.input.value = data.text;
    }
    this.captureTimeout = setTimeout(() => this.captureAndParse(), 1000);
  }

}

customElements.define('number-live-ocr', NumberLiveOcrElement);
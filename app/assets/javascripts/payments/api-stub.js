class OSPaymentsEmbed {

  constructor(params) {
    this.params = params;
  }

  logFailure(msg) {
    console.warn(msg); // eslint-disable-line no-console
  }

  createIframe(parentEl) {
    return new Promise((resolve) => {
      this.resolvePendingPromise = resolve;
      const i = document.createElement('iframe');
      i.src = '/stubbed_payments';
      i.width = '100%';
      i.height = '100%';
      i.style="border: 0; display: none;";
      parentEl.appendChild(i);
      this.iframe = i;
      this.iframe.contentWindow.addEventListener('message', this.dispatchMessage.bind(this))
    });
  }

  dispatchMessage(msgEvent) {
    const msg = JSON.parse(msgEvent.data);
    if (msg.available && this.resolvePendingPromise) {
      this.resolvePendingPromise(this);
      delete this.resolvePendingPromise;
      this.iframe.style.display = 'block';
    }
    if (this.onMessageHandler) { this.onMessageHandler(msg); };
  }

  onMessage(cb) {
    this.onMessageHandler = cb;
  }

}


window.OSPayments = OSPaymentsEmbed;

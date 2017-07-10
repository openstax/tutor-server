class OSPaymentsEmbed {

  constructor(options) {
    this.options = options;
    Object.assign(this.options.messageHandlers, {
      size:  this.applySize.bind(this),
      ready: this.onReady.bind(this),
    });
  }

  onReady() {
    this.pendingReady(this);
    delete this.pendingReady;
    this.iframe.style.display = 'block';
  }

  applySize(size) {
    this.iframe.height = size.height + 40;
  }

  logFailure(msg) {
    console.warn(msg); // eslint-disable-line no-console
  }

  createIframe(parentEl) {
    return new Promise((resolve) => {
      this.pendingReady = resolve;
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
    if (this.iframe.contentWindow !== msgEvent.source) { return; }
    let msg;
    try {
      msg = JSON.parse(msgEvent.data);
    } catch (e) {
      msg = {};
    }
    if (this.options.messageHandlers[msg.type]) {
      this.options.messageHandlers[msg.type](msg.data);
    } else {
      this.logFailure(`received message: ${msgEvent.data} without a handler`);
    }
  }

  // called by parent when the user is closing payments
  close() { }

}


window.OSPayments = OSPaymentsEmbed;

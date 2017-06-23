window.postMessage(JSON.stringify({
  available: true,
  size: {
    height: document.body.scrollHeight,
    width: document.body.scrollWidth
  }
}), '*');

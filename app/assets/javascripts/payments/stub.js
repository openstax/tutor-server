window.postMessage(JSON.stringify({
  type: 'ready'
}), '*');

window.postMessage(JSON.stringify({
  type: 'size', data: {
    height: document.body.scrollHeight,
    width: document.body.scrollWidth
  }
}), '*');

document.querySelector('button.success').addEventListener('click', function() {
  window.postMessage(JSON.stringify({ type: 'payment', data: { } }), '*');
});

document.querySelector('button.cancel').addEventListener('click', function() {
  window.postMessage(JSON.stringify({ type: 'cancel' }), '*');
});

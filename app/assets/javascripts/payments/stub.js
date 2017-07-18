window.postMessage(JSON.stringify({
  type: 'ready'
}), '*')

window.postMessage(JSON.stringify({
  type: 'size',
  data: {
    height: document.body.scrollHeight,
    width: document.body.scrollWidth
  }
}), '*');

document.querySelector('button.success').addEventListener('click', () => {
  window.postMessage(JSON.stringify({
    type: 'payment',
    data: {
      // TODO: fill in once we know what data is returned
    }
  }), '*');
});

document.querySelector('button.cancel').addEventListener('click', () => {
  window.postMessage(JSON.stringify({
    type: 'cancel',
  }), '*');
});

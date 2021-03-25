/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb


// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
// const imagePath = (name) => images(name, true)

const images = require.context('../images', true)
import MicroModal from 'micromodal'
import Carousel from './carousel'
import 'styles/homepage'


document.addEventListener('DOMContentLoaded', () => {
  MicroModal.init({
    onShow: (modal) => {
      const iframe = document.getElementById('modal-video')
      if (!iframe.getAttribute('src')) {
        iframe.setAttribute('src', iframe.getAttribute('data-src'))
      }
    },
    onClose: (modal) => {
      const doc = document.getElementById('modal-video').contentWindow
      doc.postMessage('{"event":"command", "func":"pauseVideo","args":""}', '*')
    }
  })

  const el = document.getElementById('video-modal')
  el?.addEventListener('click', () => {
    MicroModal.close('video-modal')
  }, false)

  const carousel = Carousel({
    wrapper: document.querySelector('[data-carousel-wrapper]'),
    prevButton: document.querySelector('[data-carousel-prev]'),
    nextButton: document.querySelector('[data-carousel-next]'),
  })
})

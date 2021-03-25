export default function Carousel({ wrapper, prevButton, nextButton }) {
  var prevElement
  var nextElement

  wrapper.addEventListener('scroll', onScroll, { passive: true })
  prevButton.addEventListener('click', onPrev)
  nextButton.addEventListener('click', onNext)
  window.addEventListener('resize', () => updateElements(wrapper), { passive: true })
  window.setTimeout(() => updateElements(wrapper), 10)

  function getPrevElement(list) {
    const sibling = list[0].previousElementSibling

    if (sibling instanceof HTMLElement) {
      return sibling
    }

    return sibling
  }

  function getNextElement(list) {
    const sibling = list[list.length - 1].nextElementSibling

    if (sibling instanceof HTMLElement) {
      return sibling
    }

    return null
  }

  function scrollIntoView(element) {
    let newScrollPosition

    newScrollPosition =
      element.offsetLeft +
      element.getBoundingClientRect().width / 2 -
      wrapper.getBoundingClientRect().width / 2

    wrapper.scroll({
      left: newScrollPosition,
      behavior: 'smooth',
    })
    return null
  }

  function updateElements(element) {
    const rect = element.getBoundingClientRect()

    const visibleElements = Array.from(element.children).filter((child) => {
      const childRect = child.getBoundingClientRect()
      return childRect.left >= rect.left && childRect.right <= rect.right
    })

    if (visibleElements.length > 0) {
      prevElement = getPrevElement(visibleElements)
      nextElement = getNextElement(visibleElements)

      prevButton.setAttribute('data-carousel-prev', !!prevElement)
      nextButton.setAttribute('data-carousel-next', !!nextElement)
    }

    return null
  }

  function onPrev(event) {
    if (prevElement) {
      scrollIntoView(prevElement)
    }
  }

  function onNext(event) {
    if (nextElement) {
      scrollIntoView(nextElement)
    }
  }

  function onScroll(event) {
    updateElements(event.target)
  }

  return {
    update: function(element) {
      if (element) {
        updateElements(element)
      }
    }
  }
}

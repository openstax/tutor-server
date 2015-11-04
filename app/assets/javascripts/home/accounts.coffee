$(document).ready ->

  return if OxAccount.isLoggedIn()

  $('#login.btn').on 'click', (ev)->
    ev.preventDefault()
    $(ev.target).addClass('btn-loading')
    displayLogin ->
      $(ev.target).removeClass('btn-loading')

displayLogin = (cb) ->

  OxAccount.onAvailable ->
    OxAccount.on('login', (ev, user) ->
      # Not 100% sure of the best action here.
      # For now we just trigger a reload which will redirect to app.
      # Might be better to display a short message saying "login successfull" or something
      window.location.reload()
    )
    OxAccount.displayLogin().then(cb)

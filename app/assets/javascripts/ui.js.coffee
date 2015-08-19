Tutor.Ui = {

  syntaxHighlight: (code) ->
    json = if typeof code is not 'string' then JSON.stringify(code, undefined, 2) else code

    json = json.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')

    return json.replace(
      /("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)/g,
      (match) ->
        cls = 'number'
        if (/^"/.test(match))
          if (/:$/.test(match))
            cls = 'key'
          else
            cls = 'string'
        else if (/true|false/.test(match))
          cls = 'boolean'
        else if (/null/.test(match))
          cls = 'null'

        return '<span class="' + cls + '">' + match + '</span>'
    )

  disableButton: (selector) ->
    $(selector).attr('disabled', 'disabled')
    $(selector).addClass('ui-state-disabled ui-button-disabled')
    $(selector).attr('aria-disabled', true)

  enableButton: (selector) ->
    $(selector).removeAttr('disabled')
    $(selector).removeAttr('aria-disabled')
    $(selector).removeClass('ui-state-disabled ui-button-disabled')
    $(selector).button()

  enableOnChecked: (targetSelector, sourceSelector) ->
    $(document).ready =>
      @disableButton(targetSelector)

    $(sourceSelector).on 'click', =>
      if $(sourceSelector).is(':checked')
        @enableButton(targetSelector)
      else
        @disableButton(targetSelector)

}

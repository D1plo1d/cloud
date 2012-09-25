console.log "mooooo stage 1"
$ ->
  submit = (e) ->
    $(e.target).closest("form").submit()

  $("body").on "change", "form[instantaneous='true'] select", submit
  $("body").on "blur", "form[instantaneous='true'] input", submit

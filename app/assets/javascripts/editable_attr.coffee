$ ->

  # Editting the profile's github url
  $("body").on "click", ".editable-attr .btn-edit", (e) ->
    $show = $(e.target).closest(".editable-attr")
    $edit = $show.next(".editable-attr-edit")
    $edit.height( $show.innerHeight() )
    $show.hide()
    $edit.show()

  $("body").on "ajax:complete", ".editable-attr-edit form", (e, xhr, status, error) ->
    return true if xhr.status != 200
    $edit = $(e.target).closest(".editable-attr-edit")
    $show = $edit.prev(".editable-attr")
    val = $edit.find("input").not("[type=submit]").not("[type=hidden]").val()
    $show.trigger "change", val
    $show.find("*").not(".btn, .clear").html val
    $edit.hide()
    $show.show()


  $("body").on "ajax:complete", ".editable-attr-edit", (e, xhr, status, error) ->
    if xhr.status == 200
      $(e.target).closest(".editable-attr-edit").removeClass("ajax-form-error")
      $(e.target).find(".ajax-validation-errors").remove()
      return true

    rails_errors = (JSON.parse xhr.responseText).errors

    for field, errors of rails_errors
      $errors = $(e.target).find(".#{field}-errors")
      if $errors.length == 0
        $(e.target).find("input[name$=\\[#{field}\\]]").after("<div class='#{field}-errors alert-error ajax-validation-errors'></div>")
        $errors = $(e.target).find(".#{field}-errors")
      $edit = $(e.target).closest(".editable-attr-edit")
      $edit.height( "auto" )
      $errors.html errors.join("\n")
      $(e.target).closest(".editable-attr-edit").addClass("ajax-form-error")

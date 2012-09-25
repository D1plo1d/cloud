$ ->
  # Updating the profile's name in the profile list after it's name is edited locally
  $("body").on "change", ".profile-tab-content .profile-name-js", (e, val) ->
    profile_id = $(e.target).closest(".tab-pane[data-profile-id]").data("profile-id")
    $(".profile-link-js[data-profile-id=#{profile_id}]").html(val)

  # Synchronizing basic and advanced field changes
  $("body").on "change", ".advanced-basic-tabs", (e) ->
    $field = $(e.target)
    console.log "field:"
    console.log $field
    fieldName = $field.attr("name").remove(/^[a-zA-Z_]*/)
    $other = $field.closest(".advanced-basic-tabs").find("input[name$='#{fieldName}']").not($field)
    console.log "other:"
    console.log $other
    if $field.is("[type='checkbox']")
      $other.prop("checked", $field[0].checked) if $other[0].checked != $field[0].checked
    else if $field.is("[type='hidden']") == false
      $other.val($field.val()) if $other.val() != $field.val()

  # Saving all the settings (advanced) when the basic settings save button is clicked
  $("body").on "click", ".btn-basic-profile-save", (e) ->
    $(e.target).closest(".advanced-basic-tabs").find(".btn-advanced-profile-save").click()

  $("body").on "click", ".btn-advanced-profile-save", (e) ->
    console.log "saving!"
    $("#slic3r_profiles").mask("Saving...")


  # Showing the "Saved" notification
  $("body").on "ajax:complete", ".advanced-basic-tabs", (e, xhr, status) ->
    $("#slic3r_profiles").unmask()
    unless xhr.status == 200
      try
        json = jQuery.parseJSON(xhr.responseText);
        console.log json
      return true unless json?
      errorMessage = Object.values(json.errors).map( (messages) -> messages.join("<br/>") ).join("<br/>")
      html =  "<div class=\"alert alert-error\">"
      html += "<button type=\"button\" class=\"close\" data-dismiss=\"alert\">×</button>"
      html += "<strong>Error!</strong> #{errorMessage}"
      html += "</div>"
      $(this).before(html)
      return true
    $saving =  $(this).closest(".advanced-basic-tabs").find(".saving-status")
    $saving.stop(true, true).hide().show("fade", {}, 200)

    # Hiding the "Saved" notification when an element is changed
    $(this).one "change keyup", (e) ->
      $saving =  $(this).find(".saving-status")
      $saving.stop(true, true).hide()

  # Basic + Advanced Tab Buttons
  $("#slic3r_profiles").on "click", ".config-mode .btn", ->
    $(this).closest(".config-mode").find(".btn").removeClass("active")
    $(this).addClass("active")

  # Add GCode Profile Dialog
  $("#new_g_code_profile").on "change", "[name=add_gcode_profile_slicing_radio]", ->
    $(this).parent().siblings(".btn-upload-config")
    $(this).parent().siblings(".btn-upload-config").toggle ( $(this).val() == "true" )
    
    console.log ( $(this).val() == "true" )
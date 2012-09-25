$ ->

  baseUrl = $(".print-queue-breadcrumbs-js").data("base-url")

  # Print Queue Tab

  $printQueue = $('.table-print-queue-js')

  $printQueue.on "click", "a.print-job-name-js", (e) ->
    $link = $(e.target)
    console.log $link
    if $link.hasClass("no-popover-js")
      id = $link.data("print-job-id")
      download_link = "#{baseUrl}/print_jobs/#{id}/download"
      gcode_title = $link.html().remove(/\.[a-zA-Z]+$/) + ".gcode"
      html =  "<div><a href='#{download_link}?format=original' class='print-job-download-link'><i class='icon-download'/>#{$link.html()}</a></div>"
      html += "<div><a href='#{download_link}?format=gcode' class='print-job-download-link'><i class='icon-download'/>#{gcode_title}</a></div>"
      console.log html
      $link.popover title: "Downloads", content: html, trigger: "manual"
      $link.removeClass "no-popover-js"
    $link.popover "show"
    e.stopPropagation()
    e.preventDefault()
    $("body").one "click", => $link.popover "hide"
    return false

  profiles = []
  for p in $(".profiles_list a.profile-link-js")
    $p = $(p)
    profiles.push name: $p.html(), id: $p.data("profile-id")

  # Row tooltips
  $printQueue.tooltip(selector: ".delete-print-job, .drag-handle")
  $printQueue.on "click", ".delete-print-job", (e) -> $(e.target).tooltip('hide')

  canManage = $printQueue.data("can-manage")
  opts = 
    bPaginate: false
    bLengthChange: false
    bFilter: false
    bSort: true
    bSortClasses: false
    bInfo: false
    sScrollY: "280px"
    bAutoWidth: false
    sAjaxSource: "#{baseUrl}/print_jobs.json"
    sAjaxDataProp: "print_jobs"
    aaSorting: [[ 1, "asc" ]]

    oLanguage:
      sEmptyTable: switch canManage
        when true then "The print queue is empty. Would you like to add a <a href='#' class='add-print-job-link'>print job</a>?"
        else "The print queue is empty"

    # Counter Column
    fnDrawCallback: ( oSettings ) =>
      deleted = $printQueue.data("row-deleted")
      $printQueue.data("row-deleted", false)
      console.log deleted
      # Need to redo the counters if filtered or sorted
      if ( oSettings.bSorted || oSettings.bFiltered || deleted == true )
        console.log oSettings.aiDisplay
        for i, aiDisplay of oSettings.aiDisplay.unique()
          console.log aiDisplay
          if (settings = oSettings.aoData[ aiDisplay ]) != null
            $('td:eq(0)', settings.nTr ).html( parseInt(i)+1 )

    fnCreatedRow: ( nRow, aData, iDataIndex ) ->
      $(nRow).attr("data-print-job-id", aData.id)

    aoColumns: [
      {sWidth: "16px", bSortable: false, mDataProp: (d) -> "" }
      {sWidth: "0px", bVisible: false, mDataProp: "print_order", asSorting: [ "asc" ]},
      {sWidth: "40%", mDataProp: (d) -> "<a href='#' data-print-job-id='#{d.id}' class='print-job-name-js no-popover-js'>#{d.name}</a>"},
      {mDataProp: "status_html"},
      {mDataProp: (d) =>
        if canManage == true
          html =  "<form action='#{baseUrl}/print_jobs/#{d.id}.json' method='put' instantaneous='true' data-remote='true'>"
          html += "<input name='print_job[copies_total]' type='number' min='1' step='1' value='#{d.copies_total}'></input>"
          html += "</form>"
          return html
        else
          d.copies_total
      },
      {mDataProp: (d) =>
        name = d.g_code_profile.name
        id = d.g_code_profile.id
        return name if canManage == false
        html =  "<form action='#{baseUrl}/print_jobs/#{d.id}.json' method='put' instantaneous='true' data-remote='true'>"
        html += "<select name='print_job[g_code_profile_id]'>"
        if profiles.find( (p) => p.id == id )? == false
          html += "<option value='#{id}' selected='selected'>#{name}</option>"
        for p in profiles
          html += "<option value='#{p.id}'#{" selected='selected'" if p.id == id}>#{p.name}</option>"
        html + "</select></form>"
      },
      {sWidth: "80px", mDataProp: (d) =>
        html =  "<div style='text-align: right; width: 80px'>"
        html += "<a href='#{baseUrl}/print_jobs/#{d.id}.json' data-remote='true' data-method='delete' data-confirm='Delete this Print Job?' title='Delete this Print Job' class='icon-remove delete-print-job btn-remove-icon'></a>"
        html += "<a title='Drag print jobs to change their order' class='icon-reorder drag-handle'></a>"
        html += "</div>"
        return html
      }
    ]

  # indexing rows for row reordering
  $printQueue.find("tbody td:first").each (index, row) -> $(row).html(index)

  $printQueue.dataTable(opts)

  # Drag and drop reordering
  if canManage == true
    $printQueue.addClass("draggable")

    # Preventing already printing print jobs from being moved from the top of the queue
    $("#print_queue").on "sort", ".dataTables_scrollBody tbody", (e) ->
      console.log $(e.srcElement).closest("tr").find("td:nth-child(4) .badge").data("status")
      return true if $(e.srcElement).closest("tr").find("td:nth-child(4) .badge").data("status") != "printing"
      $(this).sortable('cancel')

    $printQueue.rowReordering
      sRequestType: "PUT"
      sURL: (row, $context) =>
        $printQueue.data("moved-job-id", $context.data("print-job-id"))
        "#{baseUrl}/print_jobs/#{$context.data("print-job-id")}.json"
      sData: (row) =>
        print_job: {print_order_position: row.toPosition - 1}


  # PubSub Push Updates
  PrivatePub.subscribe baseUrl, (data, channel) =>
    row = data.print_job
    $previousRow = $printQueue.find("tr[data-print-job-id='#{row.id}']")

    # Destroy
    if data.method == "destroy"
      console.log "deleted!"
      $printQueue.data("row-deleted", true)
      $printQueue.fnDeleteRow($previousRow[0])
    # Update
    else if $previousRow.length > 0
      # TODO: We should also set the moved job id via pubsub for remote changes
      # do not redraw the table until the target of the last move operation (if any) is updated
      movedJobId = $printQueue.data("moved-job-id")
      redraw = !(movedJobId?) or movedJobId == row.id
      # Resetting the moved job if the job we're receiving is the originally moved job that spawned the other row updates
      $printQueue.data("moved-job-id", false) if movedJobId == row.id

      $printQueue.fnUpdate(row, $previousRow[0], 0, redraw)
    # Create
    else
      $printQueue.fnAddData( row )

  # Showing the Print Job's View Modal (complete with shiney 3d renders!) (TODO)
  if false
    $printQueue.on "click", "a[data-print-job-id]", (e) =>
      $("#view_print_job_modal").modal("show")
      id = $(e.target).data("print-job-id")
      $.get "#{baseUrl}/print_jobs/#{id}/show_modal", (data) ->
        $("#view_print_job_modal").html(data)
      e.preventDefault()


  # Add Print Job Button
  $("body").on "click", ".add-print-job-link", ->
    console.log "moocow"
    $(".btn-add-job-js input").click()

  $(".btn-add-job-js").on "change", "input[type='file']", (e) ->
    $form = $(e.target).closest("form")
    $form.submit()
    $f = $(e.target)
    $f.replaceWith $f.clone()


  # Users and Permissions Tab
  $("#users_and_permissions").on "ajax:success", (e, xhr, status, error) ->
    window.location.reload()

  # Other Tabs..
    
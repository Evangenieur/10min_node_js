window.addEventListener "load", ->

  ## Auto reloading
  tty.socket.on "disconnect", ->
    setTimeout ->
      window.location.reload()
    , 1000

  cmds = [
    "vim ./async.js\n"
    "i"
    ""
  ]
  recorded = {}
  lastAt = null
  recording = false
  playing = false

  renderRecord = (name, data) ->
    tpl = """
      <div id="recorded_#{name}" class="entry">
        <span class="name">#{name}</span>""" +
      (if data?.length
        total = 0
        for elem in data
          total += elem.at
        """
          <p class="info">
            <span class="length">#{length = data.length}</span>
            <span class="duration">#{
              Math.round(total / 100) / 10
            }</span>
          </p>"""
      else """
          <button class="stop">Stop</button>
        """) +
      "</div>"
    if $("#recorded_#{name}").length
      $("#recorded_#{name}").replaceWith tpl
    else
      $("#recorder").append tpl

    unless data?.length
      $("#recorded_#{name} .stop").click ->
        $(@).remove()
        stopRecorder name
        false

    $("#recorded_#{name}").click ->
      if not playing and not recording 
        console.log "playing"
        playRecorded name, ->
          $("#recorded_#{name} .playpause").remove()  
        $("#recorded_#{name} p").before """ 
          <button class="playpause">||</button>
        """
        $("#recorded_#{name} .playpause").click ->
          if playing
            playing = false
            $(@).html "Play"
          else
            playing = true
            $(@).html "||"
          false



  tty.socket.on "records", (records) ->
    recorded = records
    for name, data of recorded
      renderRecord name, data

  setupHandler = (id, tab, recorder) ->
    oldHandler = tab.handler
    lastAt = null

    tab.handler = (args...) ->
      lastAt or= (new Date()).getTime()
      recorder.push 
        target: id
        key: args[0]
        at: (new Date()).getTime() - lastAt
      lastAt = (new Date()).getTime()
      oldHandler.apply tab, args

    tab.endRecord = ->
      tab.handler = oldHandler
      delete tab.endRecord

  window.startRecorder = (name) ->
    recording = true
    i = 0
    for tty_name, tab of tty.terms
      console.log "Setup recorder #{name} for", tty_name
      setupHandler i, tab, recorded[name] or= []
      i++
    renderRecord name, recorded[name]


  window.stopRecorder = (name) ->
    records = recorded[name]
    for tty_name, tab of tty.terms
      console.log "Stopping recorder for", tty_name
      tab.endRecord?()
    renderRecord name, recorded[name]
    tty.socket.emit "record", name, recorded[name]
    recording = false
    console.log JSON.stringify recorded[name]


  
  window.playRecorded = (name, cb) ->
    return unless recorded[name]?
    playing = true
    i = 0
    objs = (tab for tty_name, tab of tty.terms)
    console.log objs
    do setupNext = ->
      unless playing 
        setTimeout setupNext, recorded[name][i].at
        return
      step = recorded[name][i]
      objs[step.target].send step.key
      i++
      if nextStep = recorded[name][i]
        setTimeout setupNext, nextStep.at
      else 
        playing = false
        cb?()

  ### Steup Recorder part ###
  $("#record-name").focus ->
    Terminal.focus = null
  
  rec = ->
    if $("#record-name").val()
      startRecorder $("#record-name").val()
      $("#record-name").val("")
  
  $("#record-name").keypress (e) ->
    if e.which is 13
      rec()
  $("#record").click rec

  ### Setup Terms ###

  tty.on "connect", ->
    win = new tty.Window
    win.on "open", ->
      console.log "Win opened", win.element.clientHeight, win.focused.rows
      console.log newHeight = ($(window).height() - 60) / 2
      console.log newRows = Math.floor(newHeight / win.element.clientHeight * win.focused.rows)
      win.resize win.focused.cols, newRows

      console.log win.focused
      win.element.style.top = "60px"
      win.element.style.left = "1px"
      win2 = new tty.Window
      win2.on "open", ->
        console.log "Win2 opened #{win.element.clientHeight}"
        win2.element.style.top = "#{win.element.clientHeight + 60}px"
        win2.element.style.left = "1px"
        win2.resize win.focused.cols, newRows

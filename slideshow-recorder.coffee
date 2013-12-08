class this.SlideshowRecorder extends Slideshow
  # options
  # * beepSrc contains the file name of the start mp3 sound
  constructor: (options) ->
    super(options)

    @timestampPages = []
    @timestampPointers = []

  initializeElements: ->
    super()

    # make sure the start button is enabled after reloading the page
    $('#start').removeAttr 'disabled'

    # initialize jPlayer
    @player = $('#player')
    @player.jPlayer
      ready: =>
        @player.jPlayer "setMedia",
          mp3: @options.beepSrc,
      swfPath: @options.swfPath,
      preload: "auto",
      wmode: "window",
      supplied: "mp3",
      keyEnabled: true,

  attachGuiHandlers: ->
    super()

    @player.bind($.jPlayer.event.ended, @startCounter)
    $('#start').click @startClickHandler
    @canvas.click @canvasClickHandler

  startClickHandler: =>
    @hidePointer()
    $('#start').attr 'disabled', 'disabled'
    @player.jPlayer 'play'

  startCounter: =>
    @hidePointer()
    @timeStarted = (new Date()).getTime() / 1000
    @timestampPages.push([@currentTimestamp(), @currentPage])
    @updateLog()
    setInterval =>
      $('#recordTime').text($.jPlayer.convertTime(@currentTimestamp()))
    , 250

  canvasClickHandler: (event) =>
    # compute coordinates
    offset = @canvas.offset()
    x = (event.pageX - offset.left) / @canvas.width()
    x = Math.round(x * 1000) / 1000
    y = (event.pageY - offset.top) / @canvas.height()
    y = Math.round(y * 1000) / 1000

    # Add circles coordinates to pointers list and show pointer
    if @timeStarted
      @timestampPointers.push [@currentTimestamp(), x, y]
      @updateLog()
    @showPointer(x,y)

  currentTimestamp: =>
    now = (new Date()).getTime() / 1000 - @timeStarted
    Math.round(now * 10) / 10
  
  updateLog: ->
    text = 'var timestampPages = ' + JSON.stringify(@timestampPages) + ';\n'
    text = text + 'var timestampPointers = ' + JSON.stringify(@timestampPointers) + ';\n'
    $('#log').text(text)

  gotoPage: (pageNum) ->
    super(pageNum)

    # log page change
    if @timeStarted
      @timestampPages.push [@currentTimestamp(), @currentPage]
      @updateLog()


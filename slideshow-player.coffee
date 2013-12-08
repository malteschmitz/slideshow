class this.SlideshowPlayer extends Slideshow

  # options
  # * adioBaseName contains the base part of filenames of the mp3 and oga encoded audio files
  # * timestampPages contains the timestamps where to start the pages (sorted by timestamps)
  #    - first element is time in seconds
  #    - second element is the number of the page to show
  # * timestampPointers contains the timestamps where the pointer should be shown
  #    - first element is time in seconds
  #    - second element is the x coordinate
  #    - third element is the y coordinate
  # * swfPath contains the path (without filename) to jPlayer.swf
  constructor: (options) ->
    super(options)

    @createPageTimestamps()
    
  initializeElements: ->
    super()

    # create annotation layer and appand it to slideshow element
    @annotationLayer = $('<div class="annotationLayer"></div>')
    $('#slideshow').append(@annotationLayer)

    # initialize jPlayer
    @player = $('#player')
    @player.jPlayer
      ready: =>
        @player.jPlayer "setMedia",
          oga: @options.audioBaseName + ".ogg",
          mp3: @options.audioBaseName + ".mp3",
      swfPath: @options.swfPath,
      preload: "auto",
      wmode: "window",
      supplied: "oga,mp3",
      keyEnabled: true,

  attachGuiHandlers: ->
    super()

    @player.bind $.jPlayer.event.timeupdate, @timeupdateHandler
    @player.bind $.jPlayer.event.play, => @isPlaying = true
    # pause event is raised in case of stop *and* pause
    @player.bind $.jPlayer.event.pause, => @isPlaying = false
    @canvas.click @togglePlayPause

  # Create an array of timestamps sorted by pages
  # number of the page is used as key and its timestamp as value
  createPageTimestamps: ->
    @pageTimestamps = []
    for value in @options.timestampPages
      old = @pageTimestamps[value[1]]
      if not old? or old > value[0]
        @pageTimestamps[value[1]] = value[0]

  timeupdateHandler: (event) =>
    current = event.jPlayer.status.currentTime
    duration = event.jPlayer.status.duration
    $("#current_time").text $.jPlayer.convertTime(current)
    $("#duration").text $.jPlayer.convertTime(duration)

    nextPage = -1
    for value in @options.timestampPages
      timestamp = value[0]
      continue if timestamp > current
      nextPage = value[1]
    if nextPage > -1 and nextPage != @currentPage
      @currentPage = nextPage
      @renderCurrentPage()

    for value in @options.timestampPointers
      timestamp = value[0]
      continue if timestamp > current
      nextPoint = value
    if nextPoint and Math.abs(current - nextPoint[0]) < .5
      @showPointer nextPoint[1], nextPoint[2]

  gotoPage: (pageNum) ->
    mode = if @isPlaying then "play" else "pause"
    @player.jPlayer('pause')
    super(pageNum)
    # jump in player to the slide matching the current page
    target = @pageTimestamps[@currentPage]
    @player.jPlayer mode, target if target?

  togglePlayPause: =>
    if @isPlaying
      @player.jPlayer "pause"
    else
      @player.jPlayer "play"
    false
  
  keydownHandler: (event) =>
    super(event)

    switch event.which
      when 32 # Space
        @togglePlayPause()
        event.preventDefault()

  renderPage: (page) ->
    viewport = super(page)
    @setupAnnotations(page, viewport)

  setupAnnotations: (page, viewport) ->
    bindInternalLink = (link, dest) =>
      link.attr('href', '#')
      link.click =>
        destination = @destinations[dest];
        if destination instanceof Array
          destRef = destination[0]
          pageNumber = if destRef instanceof Object
            @pagesRefMap[destRef.num + ' ' + destRef.gen + ' R']
          else
            destRef + 1
          if pageNumber <= @numPages
            @gotoPage(pageNumber)
        false

    bindExternalLink = (link, url) =>
      link.click =>
        @player.jPlayer("pause")
        open(url)
        false

    bindNamedAction = (link, action) =>
      link.attr('href', '#')
      link.click =>
        # See PDF reference, table 8.45 - Named action
        switch action
          # when 'GoToPage', 'Find'
          # unable to handle these without such a GUI element
          # when 'GoBack', 'GoForward'
          # unable to handles these without a history
          when 'NextPage' then nextPage()
          when 'PrevPage' then prevPage()
          when 'LastPage'
            if currentPage != @numPages
              gotoPage @numPages
          when 'FirstPage'
            if currentPage != 1
              gotoPage(1)
        false

    @annotationLayer.empty()
    canvasOffset = @canvas.offset()
    page.getAnnotations().then (annotationsData) =>
      viewport = viewport.clone dontFlip: true

      for data in annotationsData
        annotation = PDFJS.Annotation.fromData(data)
        continue unless annotation?.hasHtml()

        element = annotation.getHtmlElement(page.commonObjs)
        data = annotation.getData()
        rect = data.rect
        view = page.view
        rect = PDFJS.Util.normalizeRect([
          rect[0],
          view[3] - rect[1] + view[1],
          rect[2],
          view[3] - rect[3] + view[1]])
        $(element).css
          left: (canvasOffset.left + rect[0]) + 'px',
          top: (canvasOffset.top + rect[1]) + 'px',
          position: 'absolute'

        transform = viewport.transform
        transformStr = 'matrix(' + transform.join(',') + ')'
        CustomStyle.setProp('transform', element, transformStr)
        transformOriginStr = -rect[0] + 'px ' + -rect[1] + 'px'
        CustomStyle.setProp('transformOrigin', element, transformOriginStr)

        if data.subtype == 'Link'
          if data.url?
            bindExternalLink($(element), data.url)
          else if data.action?
            bindNamedAction($(element), data.action)
          else if data.dest?
            bindInternalLink($(element), data.dest)

        @annotationLayer.append(element)

###
  Slideshow 0.1
  (c) Malte Schmitz, December 2013
  MIT Licence
###

class this.Slideshow
  # options
  # * presentationUrl contains the fully qualified URL to the pdf file
  # * workerSrc contains the relative file name of pdf.worker.js
  # * pleaseWaitString may contain a translation of "Please wait!"
  # * loadingString may contain a translation of "Loading the presentation..."
  constructor: (@options) ->
    @options.pleaseWaitString = @options.pleaseWaitString ? 'Please wait!'
    @options.loadingString = @options.loadingString ? 'Loading the presentation...'
    PDFJS.workerSrc = @options.workerSrc if @options.workerSrc? 

    @zoom = 2
    @currentPage = 1

    @initializeElements()
    @attachGuiHandlers()
    @loadPresentation().then @renderCurrentPage

  initializeElements: ->
    # create the canvas element and attach it to the slideshow
    @canvas = $('<canvas></canvas>')
    @context = @canvas[0].getContext('2d')
    $('#slideshow').append(@canvas)

    # display initial loading text on the canvas
    @canvas[0].height = 544
    @canvas[0].width = 725
    @context.font = "24pt \"Helvetica Neue\",Helvetica,Arial,sans-serif"
    @context.fillText @options.pleaseWaitString, 10, 50
    @context.font = "16pt \"Helvetica Neue\",Helvetica,Arial,sans-serif"
    @context.fillText @options.loadingString, 10, 100

    # create pointer element
    @pointer = $('<div></div>')
    @pointer.css
      backgroundColor: "#FF0000",
      position: "absolute"
    @pointer.hide()
    $("#slideshow").append(@pointer)

    # select player element
    @player = $('#player')

  attachGuiHandlers: ->
    $("#prev").click @prevPage
    $("#next").click @nextPage
    $("#zoom-default").click @zoomDefault
    $("#zoom-out").click @zoomOut
    $("#zoom-in").click @zoomIn
    $(document).keydown @keydownHandler
    $('#slideshow').mousemove @hideCursor
    $("#fullscreen").click @toggleFullScreen
    $(document).on 'webkitfullscreenchange mozfullscreenchange fullscreenchange', @fullScreenChangeHandler

  keydownHandler: (event) =>
    switch event.which
      when 189 # -
        @zoomOut()
        event.preventDefault()
      when 48 # 0
        @zoomDefault()
        event.preventDefault()
      when 187 # +
        @zoomIn()
        event.preventDefault()
      when 37, 33 # Left, Page Up
        @prevPage()
        event.preventDefault()
      when 39, 34 # Right, Page Down
        @nextPage()
        event.preventDefault()
      when 13 # Enter
        @toggleFullScreen()
        event.preventDefault()

  loadPresentation: ->
    # Asynchronously download PDF as an ArrayBuffer
    PDFJS.getDocument(@options.presentationUrl).then (pdfDoc) =>
      pdfDoc.getDestinations().then (destinations) => @destinations = destinations

      @numPages = pdfDoc.numPages
      @pagePromises = []
      @pagesRefMap = {}
      for pageNum in [1..@numPages]
        pagePromise = pdfDoc.getPage pageNum
        pagePromise.then (pdfPage) =>
          pageRef = pdfPage.ref
          refStr = pageRef.num + ' ' + pageRef.gen + ' R'
          @pagesRefMap[refStr] = pdfPage.pageNumber
        @pagePromises.push(pagePromise)

  renderPage: (page) =>
    if @isFullScreen
      viewport = page.getViewport 1
      z = Math.min screen.width / viewport.width, screen.height / viewport.height
      viewport = page.getViewport z
    else
      viewport = page.getViewport @zoom

    @canvas[0].height = viewport.height
    @canvas[0].width = viewport.width

    # Render PDF page into canvas context
    page.render(canvasContext: @context, viewport: viewport)
    viewport

  renderCurrentPage: => 
    # Use promises to render the current page
    @pagePromises?[@currentPage - 1]?.then @renderPage

    # Update page counters
    $('#page_num').text @currentPage
    $('#page_count').text @numPages

    # Always hide pointer after rendering
    @hidePointer()

  gotoPage: (pageNum) ->
    if 0 < pageNum <= @numPages
      @currentPage = pageNum
      @renderCurrentPage()
    false

  prevPage: => @gotoPage(@currentPage - 1)

  nextPage: => @gotoPage(@currentPage + 1)

  zoomDefault: =>
    if @zoom != 2
      @zoom = 2
      @renderCurrentPage()
    false

  zoomOut: =>
    if @zoom > .3
      @zoom = @zoom / 1.2
      @renderCurrentPage()
    false

  zoomIn: =>
    if @zoom < 10
      @zoom = @zoom * 1.2
      @renderCurrentPage()
    false

  toggleFullScreen: =>
    if @isFullScreen
      @cancelFullScreen()
    else
      @requestFullScreen()
    false

  cancelFullScreen: ->
    method = document.cancelFullScreen or document.webkitCancelFullScreen or
      document.mozCancelFullScreen or document.exitFullscreen
    if method
      method.call(document)
    else
      alert "Your browser does not support the full screen API."

  requestFullScreen: ->
    element = document.getElementById('slideshow')
    method = element.requestFullScreen or element.webkitRequestFullScreen or
        element.mozRequestFullScreen or element.msRequestFullScreen
    if method
      method.call element
    else
      alert "Your browser does not support the full screen API."

  fullScreenChangeHandler: =>
    @isFullScreen = document.fullScreenElement? or !!document.mozFullScreen or !!document.webkitIsFullScreen
    if @isFullScreen
      $('#slideshow').addClass('fullscreen')
      @hideCursor()
    else
      $('#slideshow').removeClass('fullscreen')
      @showCursor()
    @renderCurrentPage()

  showCursor: =>
    clearTimeout(@hideCursorTimeout) if @hideCursorTimeout?
    delete @hideCursorTimeout
    $('#slideshow').removeClass('no-cursor')
  
  hideCursor: =>
    if @cursorJustHidden
      # prevent the hiding action to trigger mousemove
      delete @cursorJustHidden
      return
    
    @showCursor()
    if @isFullScreen
      @hideCursorTimeout = setTimeout =>
        $('#slideshow').addClass('no-cursor')
        @cursorJustHidden = true
      , 2000

  hidePointer: ->
    if @pointerTimeout?
      clearTimeout(@pointerTimeout)
      delete @pointerTimeout
      @pointer.hide()

  showPointer: (x,y) ->
    if @currentAnimationTarget? and
        x == @currentAnimationTarget[0] and
        y == @currentAnimationTarget[1]
      # prevent strange animation bugs if
      # the same animation gets started more than once
      return
    # store current parameters for the test above
    @currentAnimationTarget = [x,y]
    # compute absolut coordinates
    offset = @canvas.offset()
    radius = .03 * @canvas.width()
    x = offset.left + @canvas.width() * x
    y = offset.top + @canvas.height() * y
    # display pointer
    @pointer.stop(true, true)
    if @pointerTimeout?
      @pointer.animate
        top: y - radius,
        left: x - radius,
      ,
        duration: 300,
        done: => delete @currentAnimationTarget,
      clearTimeout(@pointerTimeout)
      delete @pointerTimeout
    else
      @pointer.show()
      @pointer.css
        top: y,
        left: x,
        opacity: 0,
        borderRadius: 0,
        width: 0,
        height: 0,
      @pointer.animate
        top: y - radius,
        left: x - radius,
        width: 2 * radius,
        height: 2 * radius,
        borderRadius: radius,
        opacity: .64,
      ,
        duration: 600,
        done: => delete @currentAnimationTarget,
        easing: "easeOutElastic",
    # start timeout to hide pointer
    @pointerTimeout = setTimeout =>
      @pointer.fadeOut duration: 600
      delete @pointerTimeout
    , 4000

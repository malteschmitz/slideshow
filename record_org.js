$(function () {
  'use strict';

  var pdfDoc = null,
    currentPage = null,
    $canvas = $('#slideshow canvas'),
    context = $canvas[0].getContext('2d'),
    player = $('#player'),
    timeStarted = null,
    slides = [],
    points = [];

  player.jPlayer({
    ready: function () {
      $(this).jPlayer("setMedia", {
        mp3: "start.mp3"
      });
    },
    swfPath: "libs",
    preload: "auto",
    wmode: "window",
    supplied: "mp3",
    keyEnabled: true
  });

  player.bind($.jPlayer.event.ended, function () {
    timeStarted = (new Date()).getTime() / 1000;
    slides.push([currentTimestamp(), currentPage]);
    updateLog();
    window.setInterval(function () {
      $('#recordTime').text($.jPlayer.convertTime(currentTimestamp()));
    }, 250);
  });

  $("#start").click(function() {
    $('#start').attr('disabled', 'disabled');
    player.jPlayer('play');
  });

  $('#start').removeAttr('disabled');

  function currentTimestamp () {
    var now = (new Date()).getTime() / 1000 - timeStarted;
    return Math.round(now * 10)/10;
  }

  function updateLog () {
    var text = 'var slides = ' + JSON.stringify(slides) + ';\n';
    text = text + 'var points = ' + JSON.stringify(points) + ';\n';
    $('#log').text(text);
  }

  $canvas.click(function (event) {
    // compute coordinates
    var x, y, offset = $canvas.offset();
    x = (event.pageX - offset.left) / $canvas.width();
    x = Math.round(x * 1000) / 1000;
    y = (event.pageY - offset.top) / $canvas.height();
    y = Math.round(y * 1000) / 1000;

    // display circle
    slideshowPointer.show(x,y);

    // add circles coordinates to pointers list
    if (timeStarted) {
      points.push([currentTimestamp(), x, y]);
      updateLog();
    }
  });

  

  // Get page info from document, resize canvas accordingly, and render page
  function renderPage (page) {
    // Using promise to fetch the page
    pdfDoc.getPage(page).then(function (page) {
      var viewport = page.getViewport(2);
      $canvas[0].height = viewport.height;
      $canvas[0].width = viewport.width;

      // Render PDF page into canvas context
      var renderContext = {
        canvasContext: context,
        viewport: viewport
      };
      page.render(renderContext);
    });

    // Update page counters
    currentPage = page;
    $('#page_num').text(currentPage);
    $('#page_count').text(pdfDoc.numPages);

    // hide pointer
    slideshowPointer.hide();

    // log page change
    if (timeStarted) {
      slides.push([currentTimestamp(), page]);
      updateLog();
    }
  }

  // Asynchronously download PDF as an ArrayBuffer
  PDFJS.getDocument("//slideshow/latex.pdf").then(function (_pdfDoc) {
    pdfDoc = _pdfDoc;
    renderPage(1);
  });

  // Go to previous page
  var prev = function () {
    if (currentPage > 1) {
      renderPage(currentPage - 1);
    }
    return false;
  };
  $("#prev").click(prev);

  // Go to next page
  var next = function () {
    if (currentPage < pdfDoc.numPages) {
      renderPage(currentPage + 1);
    }
    return false;
  };
  $("#next").click(next);

  $(window.document).keydown(function (event) {
    if (event.which == 33) {
      // page up
      prev();
      event.preventDefault();
    } else if (event.which == 34) {
      // page down
      next();
      event.preventDefault();
    }
  });
});
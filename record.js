$(function () {
  'use strict';

  var pdfDoc = null,
    currentPage = null,
    canvas = $('#the-canvas')[0],
    context = canvas.getContext('2d'),
    player = $('#player'),
    timeStarted = null,
    slides = [];

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

  

  // Get page info from document, resize canvas accordingly, and render page
  function renderPage (page) {
    // Using promise to fetch the page
    pdfDoc.getPage(page).then(function (page) {
      var viewport = page.getViewport(2);
      canvas.height = viewport.height;
      canvas.width = viewport.width;

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

    // log page change
    if (timeStarted) {
      slides.push([currentTimestamp(), page]);
      $('#log').text('var slides = ' + JSON.stringify(slides) + ';');
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
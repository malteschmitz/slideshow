$(function () {
  'use strict';

  var pdfDoc = null,
    currentPage = null,
    $canvas = $('#the-canvas'),
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

  var circle = $('<div></div>');
  circle.css({
    backgroundColor: "#FF0000",
    position: "absolute"
  });
  circle.hide();
  $("body").append(circle);

  var pointerTimeout = null;
  $canvas.click(function (event) {
    var circleRadius = .03 * $canvas.width();
    // display circle
    circle.stop();
    if (pointerTimeout) {
      circle.animate({
        top: event.pageY - circleRadius,
        left: event.pageX - circleRadius
      }, {
        duration: 300
      });
      window.clearTimeout(pointerTimeout);
      pointerTimeout = null;
    } else {
      circle.show();
      circle.css({
        top: event.pageY,
        left: event.pageX,
        opacity: 0,
        borderRadius: 0,
        width: 0,
        height: 0
      });
      circle.animate({
        top: event.pageY - circleRadius,
        left: event.pageX - circleRadius,
        width: 2 * circleRadius,
        height: 2 * circleRadius,
        borderRadius: circleRadius,
        opacity: .64
      }, {
        duration: 600,
        easing: "easeOutElastic"
      });
    }
    // add circles coordinates to pointers list
    if (timeStarted) {
      var point = [currentTimestamp()],
        offset = $canvas.offset(),
        i;
      point.push((event.pageX - offset.left) / $canvas.width());
      point.push((event.pageY - offset.top) / $canvas.height());
      for (i = 1; i < 3; i++) {
        point[i] = Math.round(point[i] * 1000) / 1000;
      }
      points.push(point);
      updateLog();
    }
    // start timeout to hide circle
    pointerTimeout = window.setTimeout(function() {
      circle.fadeOut({
        duration: 600
      });
      pointerTimeout = null;
    }, 4000);
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
    if (pointerTimeout) {
      window.clearTimeout(pointerTimeout);
      pointerTimeout = null;
      circle.hide();
    }

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
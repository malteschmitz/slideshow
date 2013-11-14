/**
 * Performs a binary search on the host array. This method can either be
 * injected into Array.prototype or called with a specified scope like this:
 * binaryIndexOf.call(someArray, searchElement);
 *
 * @param {*} searchElement The item to search for within the array.
 * @return {Number} The index of the element which defaults to -1 when not found.
 */

function binaryIndexOf(searchElement) {
  'use strict';

  var minIndex = 0;
  var maxIndex = this.length - 1;
  var currentIndex;
  var currentElement;
  var resultIndex;

  while (minIndex <= maxIndex) {
    resultIndex = currentIndex = (minIndex + maxIndex) / 2 | 0;
    currentElement = this[currentIndex];

    if (currentElement < searchElement) {
      minIndex = currentIndex + 1;
    } else if (currentElement > searchElement) {
      maxIndex = currentIndex - 1;
    } else {
      return currentIndex;
    }
  }

  return -1;
}

Array.prototype.binaryIndexOf = binaryIndexOf;

////////////////////////////////////////////////////////////////////////////////////

$(function () {
  'use strict';

  var pdfDoc = null,
    currentPage = 1,
    $canvas = $('#the-canvas'),
    context = $canvas[0].getContext('2d'),
    player = $('#player'),
    isPlaying = false;

  // mp3file, slides and points must be defined before loading this script
  // * mp3file contains the filename of the mp3 encoded audio file
  // * slides contains the timestamps where to start the pages (sorted by timestamps)
  //    - first element is time in seconds
  //    - second element is the number of the page to show
  // * points contains the timestamps where the pointer should be shown
  //    - first element is time in seconds
  //    - second element is the x coordinate
  //    - third element is the y coordinate


  // timestamps sorted by pages
  // number of the page is used as key and its timestamp as value
  var timestamps = [];
  $.each(slides, function (i, value) {
    var old = timestamps[value[1]];
    if (old === undefined || old > value[0]) {
      timestamps[value[1]] = value[0];
    }
  });

  player.jPlayer({
    ready: function () {
      $(this).jPlayer("setMedia", {
        mp3: mp3file
      });
    },
    swfPath: "libs",
    preload: "auto",
    wmode: "window",
    supplied: "mp3",
    keyEnabled: true
  });

  player.bind($.jPlayer.event.timeupdate, function (event) {
    var current = event.jPlayer.status.currentTime;
    var duration = event.jPlayer.status.duration;
    $("#current_time").text($.jPlayer.convertTime(current));
    $("#duration").text($.jPlayer.convertTime(duration));

    var nextPage = -1;
    $.each(slides, function (i, value) {
      var timestamp = value[0];
      if (timestamp > current) {
        return false;
      }
      nextPage = value[1];
    });
    if (nextPage > -1 && nextPage != currentPage) {
    	currentPage = nextPage;
    	renderPage();
    }

    var nextPoint = null;
    $.each(points, function (i, value) {
      var timestamp = value[0];
      if (timestamp > current) {
        return false;
      }
      nextPoint = value;
    });
    if (nextPoint && Math.abs(current - nextPoint[0]) < .5) {
      updatePointer(nextPoint[1], nextPoint[2]);
    }
  });

  player.bind($.jPlayer.event.play, function (event) {
    isPlaying = true;
  });

  player.bind($.jPlayer.event.pause, function (event) {
    // This event is raised in case of stop AND pause.
    isPlaying = false;
  });

  var circle = $('<div></div>');
  circle.css({
    backgroundColor: "#FF0000",
    position: "absolute"
  });
  circle.hide();
  $("body").append(circle);
  var pointerTimeout = null;
  
  function updatePointer(x,y) {
    // compute absolut coordinates
    var offset = $canvas.offset(),
      circleRadius = .03 * $canvas.width();
    x = offset.left + $canvas.width() * x;
    y = offset.top + $canvas.height() * y;
    // display circle
    circle.stop();
    if (pointerTimeout) {
      circle.animate({
        top: y - circleRadius,
        left: x - circleRadius
      }, 300);
      window.clearTimeout(pointerTimeout);
      pointerTimeout = null;
    } else {
      circle.show();
      circle.css({
        top: y,
        left: x,
        opacity: 0,
        borderRadius: 0,
        width: 0,
        height: 0
      });
      circle.animate({
        top: y - circleRadius,
        left: x - circleRadius,
        width: 2 * circleRadius,
        height: 2 * circleRadius,
        borderRadius: circleRadius,
        opacity: .64
      }, {
        duration: 600,
        easing: "easeOutElastic"
      });
    }
    // start timeout to hide circle
    pointerTimeout = window.setTimeout(function() {
      circle.fadeOut({
        duration: 600
      });
      pointerTimeout = null;
    }, 4000);
  }

  function killPointer () {
    if (pointerTimeout) {
      window.clearTimeout(pointerTimeout);
      pointerTimeout = null;
      circle.hide();
    }
  }


  function jumpInPlayer (play) {
    // jump in player to the slide matching the current page
    var target = timestamps[currentPage];
    if (target !== undefined) {
      if (play) {
        player.jPlayer("play", target);
      } else {
        player.jPlayer("pause", target);
      }
    }
  }

  // Get page info from document, resize canvas accordingly, and render page
  function renderPage () {
    // Using promise to fetch the page
    pdfDoc.getPage(currentPage).then(function (page) {
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
    $('#page_num').text(currentPage);
    $('#page_count').text(pdfDoc.numPages);

    // Hide pointer
    killPointer();
  }

  // Asynchronously download PDF as an ArrayBuffer
  PDFJS.getDocument("//slideshow/latex.pdf").then(function (_pdfDoc) {
    pdfDoc = _pdfDoc;
    renderPage();
  });

  function gotoPage (num) {
    var play = isPlaying;
    player.jPlayer("pause");
    currentPage = num;
    renderPage();
    jumpInPlayer(play);
  }

  // Go to previous page
  $("#prev").click(function () {
    if (currentPage > 1) {
      gotoPage(currentPage - 1);
    }
    return false;
  });

  // Go to next page
  $("#next").click(function () {
    if (currentPage < pdfDoc.numPages) {
      gotoPage(currentPage + 1);
    }
    return false;
  });
});
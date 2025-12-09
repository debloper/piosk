let piosk = {
  addNewUrl() {
    let newUrl = $('#new-url').val();
    if (!newUrl) return;

    // Call appendUrl with just the URL, so it uses default settings (10s, 10 cycles)
    piosk.appendUrl(newUrl); 
    $('#new-url').val('');
  },

  // MODIFIED: Now accepts duration and cycles as arguments
  appendUrl(url, duration, cycles) {
    let tmpUrl = $('#template-url').contents().clone();

    $(tmpUrl).find('a').attr('href', url).html(url);

    // If duration and cycles are provided from config, set them.
    if (duration) {
      $(tmpUrl).find('.duration-input').val(duration);
    }
    if (cycles) {
      $(tmpUrl).find('.cycles-input').val(cycles);
    }

    $('#urls .list-group').append(tmpUrl);
  },

  // MODIFIED: Now passes the full item data to appendUrl
  renderPage(data) {
    if (data && data.urls) {
      $.each(data.urls, (index, item) => {
        // Pass all the data (url, duration, cycles) to the updated function
        piosk.appendUrl(item.url, item.duration, item.cycles);
      });
    }
  },

  // Helper to toggle button loading state
  toggleLoading($btn, isLoading, loadingText = "Processing...") {
    if (isLoading) {
      $btn.data('original-html', $btn.html());
      $btn.prop('disabled', true);
      $btn.html(`<span class="spinner-border spinner-border-sm" aria-hidden="true"></span> ${loadingText}`);
    } else {
      $btn.prop('disabled', false);
      $btn.html($btn.data('original-html')); // Restore original look
    }
  },

  updatePowerBtn(isRunning) {
    const $btn = $('#toggle-kiosk');
    
    if ($btn.prop('disabled') && $btn.text().includes('...')) return;

    $btn.prop('disabled', false);

    if (isRunning) {
        $btn.removeClass('btn-success btn-secondary').addClass('btn-warning');
        $btn.html('STOP'); 
        $btn.attr('data-action', 'stop'); 
    } else {
        $btn.removeClass('btn-warning btn-secondary').addClass('btn-success');
        $btn.html('START');
        $btn.attr('data-action', 'start');
    }
  },

  checkStatus() {
    $.getJSON('/services/status')
      .done((data) => {
        piosk.updatePowerBtn(data.running);
      })
      .fail(() => {
        if (!$('#toggle-kiosk').prop('disabled')) {
            $('#toggle-kiosk').addClass('btn-secondary').prop('disabled', true).text('Offline');
        }
      });
  },

  showStatus(xhr) {
    let tmpErr = $('#template-err').contents().clone();
    let msg = xhr.responseText || xhr.message || "Unknown error";

    if (xhr.status === 200) {
        tmpErr.removeClass('alert-danger').addClass('alert-success');
    }

    tmpErr.html(msg);
    $('#urls').append(tmpErr);
    setTimeout(_ => { tmpErr.remove() }, 5000);
  }
};

$(document).ready(() => {
  $.getJSON('/config')
    .done(piosk.renderPage)
    .fail(piosk.showStatus);

  piosk.checkStatus();
  setInterval(piosk.checkStatus, 5000);

  $('#add-url').on('click', piosk.addNewUrl);
  $('#new-url').on('keyup', (e) => { if (e.key === 'Enter') piosk.addNewUrl(); });

  $('#urls').on('click', 'button.btn-close', (e) => {
    $(e.target).closest('li.list-group-item').remove();
  });

  // MODIFIED: The #execute handler now saves all settings correctly
  $('#execute').on('click', function(e) {
    const $btn = $(this);
    piosk.toggleLoading($btn, true, "Applying...");

    let config = {};
    config.urls = [];
    $('li.list-group-item').each((index, item) => {
      // Now collecting all data: url, duration, and cycles
      const url = $(item).find('a').attr('href');
      const duration = parseInt($(item).find('.duration-input').val()) || 10;
      const cycles = parseInt($(item).find('.cycles-input').val()) || 10;

      config.urls.push({
        url: url,
        duration: duration,
        cycles: cycles
      });
    });

    $.ajax({
      url: '/config',
      type: 'POST',
      data: JSON.stringify(config),
      contentType: "application/json; charset=utf-8",
      success: (data) => {
        piosk.showStatus({ status: 200, responseText: data });
      },
      error: piosk.showStatus,
      complete: () => {
          piosk.toggleLoading($btn, false);
      }
    });
  });

  $('#toggle-kiosk').on('click', function() {
    const $btn = $(this);
    const action = $btn.attr('data-action'); 
    
    if(action === 'stop' && !confirm("Stop the Kiosk display?")) return;

    const loadText = action === 'start' ? "Starting..." : "Stopping...";
    piosk.toggleLoading($btn, true, loadText);

    $.ajax({
      url: '/services/' + action, 
      type: 'POST',
      success: (data) => {
          piosk.showStatus({ status: 200, responseText: data });
      },
      error: piosk.showStatus,
      complete: () => {
           setTimeout(() => { piosk.toggleLoading($btn, false); }, 500);
      }
    });
  });
});
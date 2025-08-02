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

  showStatus(xhr) {
    let tmpErr = $('#template-err').contents().clone();
    tmpErr.html(xhr.responseText);
    $('#urls').append(tmpErr);
    setTimeout(_ => { $('.alert-danger').remove() }, 5000);
  }
};

$(document).ready(() => {
  $.getJSON('/config')
    .done(piosk.renderPage)
    .fail(piosk.showStatus);

  $('#add-url').on('click', piosk.addNewUrl);
  $('#new-url').on('keyup', (e) => { if (e.key === 'Enter') piosk.addNewUrl(); });

  $('#urls').on('click', 'button.btn-close', (e) => {
    $(e.target).closest('li.list-group-item').remove();
  });

  // MODIFIED: The #execute handler now saves all settings correctly
  $('#execute').on('click', (e) => {
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
      dataType: "json",
      success: piosk.showStatus,
      error: piosk.showStatus
    });
  });
});
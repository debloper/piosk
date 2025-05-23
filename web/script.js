let piosk = {
  addNewUrl () {
    let newUrl = $('#new-url').val()
    if (!newUrl) return

    piosk.appendUrl(newUrl)
    $('#new-url').val('')
  },
  appendUrl (url) {
    let tmpUrl = $('#template-url').contents().clone()

    $(tmpUrl).find('a').attr('href', url).html(url)
    $('#urls .list-group').append(tmpUrl)
  },
  renderPage (data) {
    $.each(data.urls, (index, item) => {
      piosk.appendUrl(item.url)
    })
  },
  showStatus (xhr) {
    let tmpErr = $('#template-err').contents().clone()
    tmpErr.html(xhr.responseText)
    $('#urls').append(tmpErr)
    setTimeout(_ => { $('.alert-danger').remove() }, 5000)
  },
  initDragAndDrop() {
    const list = document.querySelector('#urls .list-group');
    
    list.addEventListener('dragstart', (e) => {
      if (e.target.classList.contains('list-group-item')) {
        e.target.classList.add('dragging');
        e.dataTransfer.effectAllowed = 'move';
        e.dataTransfer.setData('text/plain', e.target.dataset.index);
      }
    });

    list.addEventListener('dragend', (e) => {
      if (e.target.classList.contains('list-group-item')) {
        e.target.classList.remove('dragging');
      }
    });

    list.addEventListener('dragover', (e) => {
      e.preventDefault();
      const draggingItem = list.querySelector('.dragging');
      if (!draggingItem) return;

      const siblings = [...list.querySelectorAll('.list-group-item:not(.dragging)')];
      const nextSibling = siblings.find(sibling => {
        const box = sibling.getBoundingClientRect();
        const offset = e.clientY - box.top - box.height / 2;
        return offset < 0;
      });

      list.insertBefore(draggingItem, nextSibling);
    });
  }
}

$(document).ready(() => {
  $.getJSON('/config')
  .done(piosk.renderPage)
  .fail(piosk.showStatus)

  $('#add-url').on('click', piosk.addNewUrl)
  $('#new-url').on('keyup', (e) => { if (e.key === 'Enter') piosk.addNewUrl() })

  $('#urls').on('click', 'button.btn-close', (e) => {
    $(e.target).parent().remove()
  })

  piosk.initDragAndDrop();

  $('#execute').on('click', (e) => {
    let config = {}
    config.urls = []
    $('li.list-group-item').each((index, item) => {
      config.urls.push({ url: $(item).find('a').attr('href') })
    })

    $.ajax({
      url: '/config',
      type: 'POST',
      data: JSON.stringify(config),
      contentType: "application/json; charset=utf-8",
      dataType: "json",
      success: piosk.showStatus,
      error: piosk.showStatus
    })
  })
})

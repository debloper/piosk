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
  notifyErr () {
    let tmpErr = $('#template-err').contents().clone()
    $('#urls').append(tmpErr)
    setTimeout(() => {
      $('.alert-danger').remove()
    }, 5000)
  }
}

$(document).ready(() => {
  $.getJSON('/config.json') // { urls: [ { url: 'https://...' } ] }
  .done(piosk.renderPage)
  .fail(xhr => { piosk.notifyErr(xhr.responseText) })

  $('#add-url').on('click', piosk.addNewUrl)
  $('#new-url').on('keyup', (e) => { if (e.key === 'Enter') piosk.addNewUrl() })

  $('#urls').on('click', 'button.btn-close', (e) => {
    $(e.target).parent().remove()
  })

  $('#execute').on('click', (e) => {
    let config = {}
    config.urls = []
    $('li.list-group-item').each((index, item) => {
      config.urls.push({ url: $(item).find('a').attr('href') })
    })
    console.log(config)

    // $.post( '/config', { config })
    // .fail(piosk.notifyErr)
  })
})

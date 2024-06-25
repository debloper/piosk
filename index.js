const exp = require('express')
const exe = require('child_process').exec
const nfs = require('fs')

const app = exp()

app.use(exp.static('web'))
app.use(exp.json())

app.get('/config', (req, res) => {
  res.sendFile(__dirname + '/config.json')
})

app.post('/config', (req, res) => {
  nfs.writeFile('./config.json', JSON.stringify(req.body, null, "  "), err => {
    if (err) {
      console.error(err)
      res.status(500).send('Could not save config.')
    }
    exe('reboot', err => {
      if (err) {
        console.error(err)
        res.status(500).send('Could not reboot to apply config. Retry or reboot manually.')
      }
      res.status(200).send('New config applied; rebooting for changes to take effect...')
    })
  })
})

app.listen(80, console.error)

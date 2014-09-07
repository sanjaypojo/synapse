connect = require 'connect'
quip = require 'quip'
morgan = require 'morgan'
bodyParser = require 'body-parser'
url = require 'url'
querystring = require 'querystring'
request = require 'request'
# render = require 'rendered'

api =
  key: "635576273227721"
  keySecret: "d87991411aa25c0f8538c6a28c30835a"
  callbackURL: encodeURIComponent "http://localhost:3000/link/callback"
  scope: encodeURIComponent 'user_friends read_friendlists'
  token: null
  authCode: null

console.log api

app = connect()

fbLogin = () ->
  return (req, res, next) ->
    if req.pathname == '/link/callback'
      api.authCode = req.query.code
      res.redirect '/dashboard'
    if api.authCode == null
      res.redirect(
        'https://www.facebook.com/dialog/oauth?' +
        '&client_id=' + api.key +
        '&response_type=code' +
        '&redirect_uri=' + api.callbackURL +
        '&scope=' + api.scope
      )

dashboard = () ->
  return (req, res, next) ->
    if api.authCode == null
      res.redirect '/link'
    else if api.token == null
      console.log api.authCode
      postData ="?code=#{api.authCode}" +
        "&redirect_uri=#{api.callbackURL}&client_id=#{api.key}&client_secret=#{api.keySecret}"
        console.log postData
      request
        .get 'https://graph.facebook.com/oauth/access_token' + postData, (err, response, body) ->
          if err
            console.error err
            res.error 'OAuth access token failed'
          console.log 'YYYYYYYYY'
          bodyObj = querystring.parse body
          api.token = bodyObj.access_token
          console.log api.token
          displayData(res)
    else
      displayData()

displayData = (res) ->
  console.log 'Almost there!'
  request
    .get('https://graph.facebook.com/me/taggable_friends?access_token=' + api.token, (err, response, body) ->
      if err
        console.error err
        res.error 'Fetch failed'
      console.log body
      res.ok body
    )

app
  .use (req, res, next) ->
    console.log api
    req.on 'data', (data) ->
      if data.length > 5*1000000
        req.connection.destroy()
    next()
  .use morgan('short')
  .use quip
  .use (req, res, next) ->
    parsedUrl = url.parse req.url
    req.query = querystring.parse parsedUrl.query
    req.pathname = parsedUrl.pathname
    next()
  .use '/link', fbLogin()
  .use '/dashboard', dashboard()
  .use (req, res, next) -> res.ok 'Hello :D'
  .listen 3000

connect = require 'connect'
quip = require 'quip'
morgan = require 'morgan'
bodyParser = require 'body-parser'
url = require 'url'
querystring = require 'querystring'
request = require 'request'
# render = require 'rendered'

api =
  key: "752ctmqv621kk5"
  keySecret: "RbsbfFd6UFtJ25bi"
  callbackURL: encodeURIComponent "http://localhost:3000/link/callback"
  version: "v1"
  scope: encodeURIComponent 'r_fullprofile r_emailaddress r_network r_contactinfo'
  state: 'kjansdfoim019i3jrknsdlfksldfn13092409'
  token: null
  authCode: null

app = connect()

linkedin = () ->
  return (req, res, next) ->
    if req.pathname == '/link/callback'
      api.authCode = req.query.code
      res.redirect '/dashboard'
    if api.authCode == null
      res.redirect(
        'https://www.linkedin.com/uas/oauth2/authorization?' +
        'response_type=code' +
        '&client_id=' + api.key +
        '&scope=' + api.scope +
        '&state=' + api.state +
        '&redirect_uri=' + api.callbackURL
      )

dashboard = () ->
  return (req, res, next) ->
    if api.authCode == null
      res.redirect '/link'
    else if api.token == null
      console.log api.authCode
      postData ="?grant_type=authorization_code&code=#{api.authCode}" +
        "&redirect_uri=#{api.callbackURL}&client_id=#{api.key}&client_secret=#{api.keySecret}"
        console.log postData
      request
        .get 'https://www.linkedin.com/uas/oauth2/accessToken' + postData, (err, response, body) ->
          if err
            console.error err
            res.error 'OAuth access token failed'
          console.log body
          api.token = JSON.parse(body).access_token
          displayData(res)
        # .form(
        #   grant_type: 'authorization_code'
        #   code: api.authCode
        #   redirect_uri: 'http://localhost:3000/dashboard'
        #   client_id: api.key
        #   client_secret: api.keySecret
        # )
    else
      displayData()

displayData = (res) ->
  console.log 'Almost there! ' +  api.token
  request
    .get('https://api.linkedin.com/v1/people/~/connections?oauth2_access_token=' + api.token, (err, response, body) ->
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
  .use '/link', linkedin()
  .use '/dashboard', dashboard()
  .use (req, res, next) -> res.ok 'Hello :D'
  .listen 3000

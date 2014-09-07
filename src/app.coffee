connect = require 'connect'
quip = require 'quip'
morgan = require 'morgan'
request = require 'request'
render = require 'rendered'
pr = require 'parse-request'
qs = require 'querystring'
DB = require('node-db')

dbSettings =
  host: 'ec2-54-221-223-92.compute-1.amazonaws.com'
  port: '5432'
  database: 'd5dnc8meru1323'
  user: 'svmqboeffkdmoz'
  password: 'gCDLIrD11uvHbnLfd3UJjnz8Vm'
  ssl: true

db = new DB('pg', dbSettings)


api =
  key: "635576273227721"
  keySecret: "d87991411aa25c0f8538c6a28c30835a"
  callbackURL: encodeURIComponent "http://localhost:3000/link/callback"
  scope: encodeURIComponent 'email user_friends read_friendlists'
  token: null
  authCode: null

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
          bodyObj = qs.parse body
          console.log bodyObj
          api.token = bodyObj.access_token
          displayData res
    else
      displayData res

displayData = (res) ->
  console.log 'Almost there!'
  request
    .get('https://graph.facebook.com/me?access_token=' + api.token, (err, response, body) ->
      if err
        console.error err
        res.error 'Fetch failed'
      data = JSON.parse body
      db.query res, 'select * from p_add_or_get_user', [], (err, result) ->
        if err
          res.error err
        console.log result
        console.log 'Sending response'
        res.ok body
    )

app
  .use (req, res, next) ->
    req.on 'data', (data) ->
      if data.length > 5*1000000
        req.connection.destroy()
    next()
  .use morgan('short')
  .use quip
  .use pr.url
  .use '/link', fbLogin()
  .use '/dashboard', dashboard()
  .use (req, res, next) -> render.jade res, 'login', {}
  .listen 3000

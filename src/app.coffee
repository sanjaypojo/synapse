connect = require 'connect'
quip = require 'quip'
morgan = require 'morgan'
request = require 'request'
render = require 'rendered'
pr = require 'parse-request'
qs = require 'querystring'
DB = require 'node-db'

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

fetchAuthCode = (res) ->
  res.redirect(
    'https://www.facebook.com/dialog/oauth?' +
    '&client_id=' + api.key +
    '&response_type=code' +
    '&redirect_uri=' + api.callbackURL +
    '&scope=' + api.scope
  )

fetchToken = (callback) ->
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
      callback()

completeLogin = (res) ->
  console.log 'Logging user in'
  request
    .get 'https://graph.facebook.com/me?access_token=' + api.token, (err, response, body) ->
      if err
        console.error err
        res.error 'Fetch failed'
      data = JSON.parse body
      console.log data
      db.query(
        res, 'select * from p_add_or_get_user($1, $2, $3, $4, $5, $6)',
        [data.email, data.first_name, data.last_name, data.id, data.gender, data.timezone],
        (err, result) ->
          if err
            res.error err
          console.log "User logged in with id #{result.rows[0].user_id}"
          render.jade res, 'dashboard', {name: data.first_name}
      )

fbLogin = () ->
  return (req, res, next) ->
    if req.pathname == '/link/callback'
      api.authCode = req.query.code
      res.redirect '/dashboard'
    if api.authCode == null
      fetchAuthCode res
    else
      res.redirect '/dashboard'

dashboard = () ->
  return (req, res, next) ->
    if api.authCode == null
      res.redirect '/link'
    else if api.token == null
      fetchToken () -> completeLogin res
    else
      completeLogin res

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

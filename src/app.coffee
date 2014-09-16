qs = require 'querystring'
connect = require 'connect'
morgan = require 'morgan'
cookieParser = require 'cookie-parser'
request = require 'request'
quip = require 'quip'
xml2js = require 'xml2js'
xml = new xml2js.Parser()
render = require 's-rendered'
DB = require 's-node-db'
session = require 's-node-session'
pr = require 's-parse-request'

dbSettings =
  host: 'ec2-54-221-223-92.compute-1.amazonaws.com'
  port: '5432'
  database: 'd5dnc8meru1323'
  user: 'svmqboeffkdmoz'
  password: 'gCDLIrD11uvHbnLfd3UJjnz8Vm'
  ssl: true

db = new DB('pg', dbSettings)


api =
  key: "752ctmqv621kk5"
  keySecret: "RbsbfFd6UFtJ25bi"
  callbackURL: encodeURIComponent "http://localhost:3000/link/callback"
  scope: encodeURIComponent 'r_fullprofile r_network'
  state: 'tinkerTailorSoldierSpy'
  token: null
  authCode: null

app = connect()

fetchAuthCode = (res) ->
  res.redirect(
    'https://www.linkedin.com/uas/oauth2/authorization?' +
    '&client_id=' + api.key +
    '&response_type=code' +
    '&redirect_uri=' + api.callbackURL +
    '&scope=' + api.scope +
    '&state=' + api.state
  )

fetchToken = (callback) ->
  postData ="?code=#{api.authCode}" +
    "&redirect_uri=#{api.callbackURL}&client_id=#{api.key}" +
    "&client_secret=#{api.keySecret}&grant_type=authorization_code"
  request
    .get 'https://www.linkedin.com/uas/oauth2/accessToken' + postData, (err, response, body) ->
      if err
        console.error err
        res.error 'OAuth access token failed'
      console.log 'OAuth user token received'
      bodyObj = JSON.parse body
      console.log bodyObj
      api.token = bodyObj.access_token
      callback()

completeLogin = (res) ->
  console.log 'Rendering dashboard'
  request
    .get 'https://api.linkedin.com/v1/people/~/connections?oauth2_access_token=' + api.token, (err, response, body) ->
      if err
        console.error err
        res.error 'Fetch failed'
      xml.parseString body, (err, result) ->
        console.log result.connections.person
        render.jade res, 'dashboard', {connections: result.connections.person}
      # data = JSON.parse body
      # console.log data
      # db.query(
      #   res, 'select * from p_add_or_get_user($1, $2, $3, $4, $5, $6)',
      #   [data.email, data.first_name, data.last_name, data.id, data.gender, data.timezone],
      #   (err, result) ->
      #     if err
      #       res.error err
      #     console.log "User logged in with id #{result.rows[0].user_id}"
      #     render.jade res, 'dashboard', {name: data.first_name}
      # )

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

session.initialize(db, 'syn_user')

app
  .use (req, res, next) ->
    req.on 'data', (data) ->
      if data.length > 5*1000000
        req.connection.destroy()
    next()
  .use cookieParser('Draco dormiens nunquam titillandus')
  .use session.handle(dbSettings)
  .use quip
  .use '/favicon.ico', (req, res, next) -> res.ok ' '
  .use morgan('short')
  .use pr.url
  .use '/login', (req, res, next) -> render.jade res, 'login', {}
  # .use session.authenticate
  .use '/link', fbLogin()
  .use '/dashboard', dashboard()
  .listen 3000

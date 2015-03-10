express = require('express')
path = require('path')
favicon = require('serve-favicon')
logger = require('morgan')
cookieParser = require('cookie-parser')
bodyParser = require('body-parser')
routes = require('./routes/index')
users = require('./routes/users')
app = express()
passport = require('passport')
util = require('util')
HatenaStrategy = require('passport-hatena').Strategy
session = require('express-session')

HATENA_CONSUMER_KEY = "consumerkeyhere"
HATENA_SECRET_KEY = "secretkeyhere"

# Passport session setup.
#   To support persistent login sessions, Passport needs to be able to
#   serialize users into and deserialize users out of the session.  Typically,
#   this will be as simple as storing the user ID when serializing, and finding
#   the user by ID when deserializing.  However, since this example does not
#   have a database of user records, the complete Hatena profile is serialized
#   and deserialized.
passport.serializeUser (user, done)->
  done(null, user)

passport.deserializeUser (obj, done)->
  done(null, obj)


# Use the HatenaStrategy within Passport.
#   Strategies in passport require a `verify` function, which accept
#   credentials (in this case, a token, tokenSecret, and Hatena profile), and
#   invoke a callback with a user object.
passport.use(new HatenaStrategy(
    consumerKey: HATENA_CONSUMER_KEY
    consumerSecret: HATENA_SECRET_KEY
    callbackURL: "http://127.0.0.1:3000/auth/hatena/callback"
  (token, tokenSecret, profile, done)->
    # asynchronous verification, for effect...
    process.nextTick ()->

      # To keep the example simple, the user's Hatena profile is returned to
      # represent the logged-in user.  In a typical application, you would want
      # to associate the Hatena account with a user record in your database,
      # and return that user instead.
      return done(null, profile)
  )
)

# view engine setup
app.set 'views', path.join(__dirname, 'views')
app.set 'view engine', 'jade'

# uncomment after placing your favicon in /public
#app.use(favicon(__dirname + '/public/favicon.ico'));
app.use logger('dev')
app.use bodyParser.json()
app.use bodyParser.urlencoded(extended: false)
app.use cookieParser()
app.use express.static(path.join(__dirname, 'public'))
app.use session
  secret: 'keyboard cat'

# Initialize Passport!  Also use passport.session() middleware, to support
# persistent login sessions (recommended).
app.use passport.initialize()
app.use passport.session()

#app.use '/', routes
app.use '/users', users


app.get '/', (req, res)->
  res.render 'index', { user: req.user }

app.get '/login', (req, res)->
  res.render 'login', { user: req.user }

# GET /auth/hatena
#   Use passport.authenticate() as route middleware to authenticate the
#   request.  The first step in Hatena authentication will involve redirecting
#   the user to hatena.ne.jp.  After authorization, Hatena will redirect the user
#   back to this application at /auth/hatena/callback
app.get '/auth/hatena',
  passport.authenticate 'hatena', { scope: ['read_public'] }

# GET /auth/hatena/callback
#   Use passport.authenticate() as route middleware to authenticate the
#   request.  If authentication fails, the user will be redirected back to the
#   login page.  Otherwise, the primary route function function will be called,
#   which, in this example, will redirect the user to the home page.
app.get '/auth/hatena/callback', 
  passport.authenticate 'hatena', { failureRedirect: '/login' }
  (req, res)->
    res.redirect('/')

app.get '/logout', (req, res)->
  req.logout()
  res.redirect('/')


# error handlers
# development error handler
# will print stacktrace
if app.get('env') == 'development'
  app.use (err, req, res, next) ->
    res.status err.status or 500
    res.render 'error',
      message: err.message
      error: err
    return

# catch 404 and forward to error handler
app.use (req, res, next) ->
  err = new Error('Not Found')
  err.status = 404
  next err
  return
  
# Simple route middleware to ensure user is authenticated.
#   Use this route middleware on any resource that needs to be protected.  If
#   the request is authenticated (typically via a persistent login session),
#   the request will proceed.  Otherwise, the user will be redirected to the
#   login page.
ensureAuthenticated = (req, res, next)->
  if req.isAuthenticated() then return next()
  res.redirect('/login')

module.exports = app

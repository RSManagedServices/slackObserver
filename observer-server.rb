require 'bundler/setup'
require 'uri'
require 'net/http'
require 'net/https'
require 'webrick'
require 'webrick/https'
require 'openssl'
Bundler.require(:default)
#require_relative './db.rb'


CERT_PATH = '/opt/slack-observer/cert'

Dir::mkdir('logs') unless File.directory?('logs')
$stdout.reopen('logs/shell_output.log', 'a+')
$stderr.reopen('logs/shell_output.log', 'a+')

$log = Logger.new('logs/general.log', 'daily')
$log.formatter = proc do |severity, datetime, progname, msg|
  "#{Thread.current[:logid]}:#{datetime} - #{severity}: #{msg}\n"
end


def observe_account(email, account, password,pemail)
  begin
    $log.debug("begin| email: #{email} account: #{account} password }")
    masteraccount = '/api/accounts/60072'
    uri_auth = URI.parse('https://us-3.rightscale.com/api/session')
    https_auth = Net::HTTP.new(uri_auth.host, uri_auth.port)
    https_auth.use_ssl = true
    req_auth = Net::HTTP::Post.new(uri_auth.path, initheader = {'Content-Type' => 'application/x-www-form-urlencoded'})
    req_auth['X_API_VERSION'] = '1.5'
    req_auth.set_form_data('email' => "#{email}", 'password' => "#{password}", 'account_href' => "#{masteraccount}",)
    do_auth = https_auth.request(req_auth) #perform the authentication to get the cookie
    cookie = do_auth.response['set-cookie'] #save the cookie from the response
    $log.debug("|cookie| #{cookie}")
    #puts do_auth.response['set-cookie']
    #Use cookie to authenticate and observer client account
    uri_obs = URI.parse('https://us-3.rightscale.com/global//admin_accounts/' + account.to_s + '/access')
    https_obs = Net::HTTP.new(uri_obs.host, uri_obs.port)
    https_obs.use_ssl = true
    req_obs = Net::HTTP::Post.new(uri_obs.path, {'Host' => 'us-3.rightscale.com', 'Referer' => 'https://us-3.rightscale.com/global//admin_accounts/' + account.to_s, 'cookie' => "#{cookie}"})
    https_obs.request(req_obs)
    $log.debug("done| returning #{https_obs.inspect}")
    if pemail
    return "You Should now have observer access to #{account},Email: #{email}."
    else
    return "You Should now have observer access to #{account}, I tried to use #{email} from slack as your email."
    end 
  rescue => e
    $log.fatal("|Observer|#{e}")
  end
end




class ObserverSinatra < Sinatra::Base
 set :server, %w[thin]
  set :port, 8089
  set :bind, '0.0.0.0'
  set :signals, false
  set :logging, false 
  set :show_exceptions, true
  use Rack::CommonLogger, $log
  set :static_cache_control, [:public, :max_age => 0]

  get '/creds.html' do
    $log.debug("|Creds| Params: #{params.inspect}")
    #   if params['token'] != "Uuwa3I3hmAnYuM5LhSLRYame" return end
    status 200

    return "congrats!" #{text[0]}  whooop whoopp derp #{text[1]}   #{channelid}"


  end

  post '/observe.html' do
    $log.debug("|observer| Params: #{params.inspect}")
    #   if params['token'] != "Uuwa3I3hmAnYuM5LhSLRYame" return end
    email = params['user_name']+ "@rightscale.com"
    token = params['token']
    if token != 'Uuwa3I3hmAnYuM5LhSLRYame'
      $log.debug('|observer| Token Auth Failed')
      break
    end

    text = params['text'].split(/[\s,]+/)
    account = text[0]
    password = text[1]
    email = text[2] if text[2]
    status 200
    $a = false
    if text[2]
      $a = true
    end 
   if params['text'].nil?
      return 'you need to provide data in param text'
    end

    return observe_account(email,account,password,$a)
  end

#  post '/connect.html' do
 #   $log.debug("|connect| Params: #{params.inspect}")
  #  #   if params['token'] != "Uuwa3I3hmAnYuM5LhSLRYame" return end
   # email = params['user_name']+ "@rightscale.com"
  #  token = params['token']
 #   if token != 'Uuwa3I3hmAnYuM5LhSLRYame'
 #     $log.debug('|observer| Token Auth Failed')
 #     break
 #   end



=begin
  def self.run!
    super do |server|
      server.ssl = true
      server.ssl_options = {
          :cert_chain_file  => File.dirname(__FILE__) + "/cert/server.crt",
          :private_key_file => File.dirname(__FILE__) + "/cert/server.key",
          :verify_peer      => false
      }
    end
  end

  run! if app_file == $0
=end
end

  Thin::Server.start(ObserverSinatra, '0.0.0.0', 8089, {signals: false, log: 'logs/thin.'})


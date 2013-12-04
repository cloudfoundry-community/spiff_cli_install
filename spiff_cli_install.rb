require 'sinatra/base'
require 'json/pure'
require 'httparty'

class CfCliInstall < Sinatra::Base
  enable :sessions
  attr_reader :github_access_token

  def initialize(*args)
    super
    unless @github_access_token = ENV['GITHUB_ACCESS_TOKEN']
      $stderr.puts "Please set environment variable $GITHUB_ACCESS_TOKEN"
      $stderr.puts "Create new tokens via https://github.com/settings/applications 'Personal Access Tokens' section"
      exit 1
    end
  end

  get '/' do
    fetch_latest_release_and_setup_session_variables
    erb :index, format: :html5
  end

  get '/pp' do
    fetch_latest_release_and_setup_session_variables
    erb :pp, format: :plain, layout: false
  end

  get '/install.sh' do
    fetch_latest_release_and_setup_session_variables
    erb :install, format: :plain, layout: false
  end

  def fetch_latest_release_and_setup_session_variables
    require "pp"
    pp cli_releases
    latest_cli_release = cli_releases.first
    session[:cli_release_name] = latest_cli_release["name"]
    cli_release_assets = latest_cli_release["assets"]
    session[:cli_release_asset_darwin_amd64]  = cli_release_asset(cli_release_assets, "darwin")
    session[:cli_release_asset_linux_amd64]   = cli_release_asset(cli_release_assets, "linux")
  end

  def cli_release_name
    session[:cli_release_name]
  end

  def cli_release_asset_darwin_amd64
    session[:cli_release_asset_darwin_amd64]
  end

  def cli_release_asset_linux_amd64
    session[:cli_release_asset_linux_amd64]
  end

  def cli_releases
    response = HTTParty.get(cli_releases_uri, cli_releases_headers)
    # response.body, response.code, response.message, response.headers.inspect
    JSON.parse(response.body)
  end

  def cli_releases_uri
    'https://api.github.com/repos/cloudfoundry-incubator/spiff/releases'
  end

  def cli_releases_headers
    raise "Must set @github_access_token first" unless github_access_token
    { headers: { "Authorization" => "token #{github_access_token}", "User-Agent" => "spiff_cli_install by Dr Nic Williams" } }
  end

  def request_hostname
    hostname = URI::Generic.build(scheme: request.scheme, host: request.host, port: request.port).to_s
    hostname.gsub(/:80/, '')
  end

  # +platform+ - windows, linux, darwin
  def cli_release_asset(cli_release_assets, platform, arch = "amd64")
    cli_release_assets.find {|asset| asset["name"] =~ /#{platform}[_\-]#{arch}/ }
  end

  def cli_name
    "spiff"
  end
end

# -*- coding: utf-8 -*-

require 'sinatra/base'

class TinyAdServer < Sinatra::Base

  #register Sinatra::Namespace

  disable :sessions
  disable :logging
  disable :protection

  set :root, File.expand_path('../', __FILE__)

  # ----------------------------------------------------------------------
  # ----------------------------------------------------------------------
  before do
  end

  get '/' do
    erb :"index.html"
  end

  # ----------------------------------------------------------------------
  # ----------------------------------------------------------------------
  get '/ads/:slot_id' do

    @slot_id = params[:captures][0].to_i

    @ad = [
      {
        type: 'image',
        image_url: 'https://www.google.co.jp/images/srpr/logo4w.png'
      },
      {
        type: 'image',
        image_url: 'http://k.yimg.jp/images/top/sp/logo.gif'
      },
      {
        type: 'image',
        image_url: 'http://www.microad.co.id/img/logo.png'
      },
    ][@slot_id - 1]

    coffee erb(:"ads_show.coffee")
  end

  # ----------------------------------------------------------------------
  # ----------------------------------------------------------------------
  get '/click/:campaign_id.:ad_id' do
  end

  # ----------------------------------------------------------------------
  # ----------------------------------------------------------------------
  get '/step/:step_id' do
  end
end


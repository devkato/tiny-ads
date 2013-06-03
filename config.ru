# -*- coding: utf-8 -*-

require './tiny_ad_server'

run Rack::Cascade.new [ TinyAdServer ]

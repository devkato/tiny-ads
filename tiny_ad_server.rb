# -*- coding: utf-8 -*-

require 'sinatra/base'
require 'yajl'
require 'awesome_print'
require 'logger'

# override
class Logger
  class Formatter
    def call(severity, time, progname, msg)
      #"#{time.to_s(:db)} #{severity} -- #{msg}\n"
      "#{msg}\n"
    end
  end
end

# ======================================================================
# 広告配信サーバーの参照実装クラス
# ======================================================================
class TinyAdServer < Sinatra::Base

  #register Sinatra::Namespace

  disable :sessions
  disable :logging
  disable :protection

  # ----------------------------------------------------------------------
  # 設定
  # ----------------------------------------------------------------------
  configure do

    set :root, File.expand_path('../', __FILE__)

    set :logging, nil

    # 広告表示のログを出力するloggerの定義
    imp_logger = Logger.new('./log/imp.log', 'daily')
    imp_logger.level = Logger::INFO

    set :imp_logger, imp_logger

    # 広告クリックのログを出力するloggerの定義
    click_logger = Logger.new('./log/imp.log', 'daily')
    click_logger.level = Logger::INFO

    set :imp_logger, click_logger
  end

  # ----------------------------------------------------------------------
  # 全リクエスト共通の前処理
  # ----------------------------------------------------------------------
  before do
  end

  # ----------------------------------------------------------------------
  # テストページの表示
  # ----------------------------------------------------------------------
  get '/' do
    erb :"index.html"
  end

  # ----------------------------------------------------------------------
  # ----------------------------------------------------------------------
  get '/ads/:slot_id' do

    @slot_id = params[:captures][0].to_i

    slot_source = File.expand_path("./slots/#{@slot_id}.json")

    # 指定した広告枠が登録されていない（広告リストが存在しない）
    # 場合は処理を抜ける
    unless File.exist?(slot_source)
      puts "slot doesn't exist!"
      return ""
    end

    # input
    ads = Yajl::Parser.parse(open(slot_source).read, symbolize_keys: true)

    # filtering logic
    ads = filter_ads(ads)

    # selection logic
    threshold = rand(100) + 1
    weight_total = 0
    selected_ad = nil

    ads.each do |ad|

      if weight_total >= threshold
        selected_ad = ad
        break
      end

      weight_total += ad[:weight]
    end

    # 何かしらの不備で広告が選択されなかった場合の対応
    selected_ad = ads.first if selected_ad.nil?

    # 表示すべき広告が存在しない場合は空を返す
    if selected_ad.nil?
      return ""
    end

    ap selected_ad

    @html = to_html(selected_ad, @slot_id)

    settings.imp_logger.info [
      "time:#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}",
      "slot_id:#{@slot_id}",
      "campaign_id:#{selected_ad[:campaign_id]}",
      "ad_id:#{selected_ad[:ad_id]}",
    ].join("\t")

    coffee erb(:"ads_show.coffee")
  end

  # ----------------------------------------------------------------------
  # 広告をクリックしたときの処理
  #
  # ログを出力して、urlパラメータにに指定されているページへリダイレクト
  #
  # @param slot_id     広告枠のID
  # @param campaign_id キャンペーンID
  # @param ad_id       広告ID
  # @param url         リダイレクト先のURL
  # ----------------------------------------------------------------------
  get '/click/:slot_id.:campaign_id.:ad_id' do

    settings.click_logger.info [
      "time:#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}",
      "slot_id:#{params[:slot_id]}",
      "campaign_id:#{params[:campaign_id]}",
      "ad_id:#{params[:ad_id]}"
    ].join("\t")

    redirect params[:url]
  end

  # ----------------------------------------------------------------------
  # 成果（conversion）用URL
  # ----------------------------------------------------------------------
  get '/step/:step_id' do
  end


  private


  # ----------------------------------------------------------------------
  # 広告データを配信時のデータに変換
  #
  # @param ad 表示する広告のハッシュデータ
  # ----------------------------------------------------------------------
  def to_html(ad, slot_id)

    click_url = "/click/#{slot_id}.#{ad[:campaign_id]}.#{ad[:ad_id]}?url=#{CGI.escape(ad[:url])}"

    case ad[:type]
    when 'text'
      return [
        "<a href='#{click_url}' target='_blank' style='text-decoration:none; padding:10px; border:1px solid #ccc; background-color:#fcfcfc; border-radius:5px;'>",
        "<img src='#{ad[:icon_url]}' style='vertical-align:middle; margin-right:5px;' />#{ad[:text]}",
        "</a>"
      ].join('')
    when 'image'
      return [
        "<a href='#{click_url}' target='_blank' style='text-decoration:none;'>",
        "<img src='#{ad[:image_url]}' />",
        "</a>"
      ].join('')
    else
      return ""
    end
  end

  # ----------------------------------------------------------------------
  # 広告枠に表示されている広告一覧に対して、各種絞り込み条件に
  # 合致する広告のみ返す
  #
  # @param ads 表示する広告候補の一覧
  # ----------------------------------------------------------------------
  def filter_ads(ads)

    ads = filter_by_user_agent(ads, /Chrome/)
    ads = filter_by_device(ads, 'tablet')

    return ads
  end

  # ----------------------------------------------------------------------
  # デバイス（pc / jpmobile / smartphone / tablet）で広告を絞り込む
  #
  # @TODO implementation
  #
  # @param ads    表示する広告候補の一覧
  # @param device 制限デバイス
  # ----------------------------------------------------------------------
  def filter_by_device(ads, device = nil)

    return ads
  end

  # ----------------------------------------------------------------------
  # User-Agentによる広告の絞り込み
  #
  # @TODO implementation
  #
  # @param ads        表示する広告候補の一覧
  # @param user_agent アクセスブラウザのUserAgent
  # ----------------------------------------------------------------------
  def filter_by_user_agent(ads, user_agent = nil)

    return ads
  end
end


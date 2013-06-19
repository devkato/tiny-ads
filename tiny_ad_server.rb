# -*- coding: utf-8 -*-

require 'sinatra/base'
require 'yajl'
require 'awesome_print'
require 'logger'

# ログフォーマットのoverride
class Logger
  class Formatter
    def call(severity, time, progname, msg)
      "#{msg}\n"
    end
  end
end

# ======================================================================
# 広告配信サーバーの参照実装クラス
# ======================================================================
class TinyAdServer < Sinatra::Base

  # ----------------------------------------------------------------------
  # 初期化設定
  # 
  # - 静的ファイルのディレクトリ指定
  # - 各アクションに対するloggerの設定
  # ----------------------------------------------------------------------
  configure do

    disable :sessions
    disable :logging
    disable :protection

    set :root, File.expand_path('../', __FILE__)

    set :logging, nil

    # 広告表示のログを出力するloggerの定義
    imp_logger = Logger.new('./log/imp.log', 'daily')
    imp_logger.level = Logger::INFO

    set :imp_logger, imp_logger

    # 広告クリックのログを出力するloggerの定義
    click_logger = Logger.new('./log/click.log', 'daily')
    click_logger.level = Logger::INFO

    set :click_logger, click_logger
  end

  # ----------------------------------------------------------------------
  # テストページの表示
  # ----------------------------------------------------------------------
  get '/' do
    erb :"index.html"
  end

  # ----------------------------------------------------------------------
  # 与えられた広告枠に対して表示する広告の決定を行う
  #
  # @param slot_id 広告枠ID
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
    #
    # 1. [0, 100]の数直線上にランダムでthresholdを選択する。
    # 2. 広告リストをシャッフルする
    # 3. 広告リストの0番目から、それぞれに与えられている重み（weight）
    #    を合計していき、その値がthresholdを上回った場合にその広告を
    #    表示する広告として決定する
    #
    # 下記の例の場合は、ad[2]が選択される。
    #
    # |-- ad[0] --|---- ad[1] ----|--- ad[2] ---|- ad[3] -|
    # |--------------------------------*------------------|
    # 0                                *                 100
    #                                  *
    #                               threshold(= 65)
    threshold = rand(100) + 1
    weight_total = 0
    selected_index = 0

    ads = ads.shuffle
    ads.each.with_index do |ad, i|

      if weight_total >= threshold
        selected_index = i
        break
      end

      weight_total += ad[:weight]
    end

    selected_ad = ads[selected_index]

    # 表示すべき広告が存在しない場合は空を返す
    if selected_ad.nil?
      return ""
    end

    @html = to_html(selected_ad, @slot_id)

    # ログに配信データを保存する
    settings.imp_logger.info log_data({
      slot_id:      @slot_id,
      campaign_id:  selected_ad[:campaign_id],
      ad_id:        selected_ad[:ad_id],
      user_id:      '-'
    })

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

    # ログにクリックデータを保存する
    settings.click_logger.info log_data({
      slot_id:      params[:slot_id],
      campaign_id:  params[:campaign_id],
      ad_id:        params[:ad_id],
      user_id:      '-',
    })

    redirect params[:url]
  end

  # ----------------------------------------------------------------------
  # 成果（conversion）用URL
  # @TODO
  # ----------------------------------------------------------------------
  get '/step/:step_id' do
    return ''
  end


  private


  # ----------------------------------------------------------------------
  # ログデータとして保存する際のフォーマッティング
  #
  # @param options  時刻以外に保存するデータのハッシュ。
  #                 このkeyがLTSVの各値のkeyになる。
  # ----------------------------------------------------------------------
  def log_data(options)

    options.map{|k, v|
      "#{k}:#{v}"
    }.unshift("time:#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}").join("\t")
  end


  # ----------------------------------------------------------------------
  # 広告データを配信時のデータに変換
  #
  # @param ad 表示する広告のハッシュデータ
  # ----------------------------------------------------------------------
  def to_html(ad, slot_id)

    click_url = "/click/#{slot_id}.#{ad[:campaign_id]}.#{ad[:ad_id]}?url=#{CGI.escape(ad[:url])}"

    case ad[:type]
    when 'text'
      # テキスト + アイコン
      
      return [
        "<a href='#{click_url}' target='_blank' style='text-decoration:none; padding:10px; border:1px solid #ccc; background-color:#fcfcfc; border-radius:5px;'>",
        "<img src='#{ad[:icon_url]}' style='vertical-align:middle; margin-right:5px;' />#{ad[:text]}",
        "</a>"
      ].join('')
    when 'image'
      # 画像
      
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


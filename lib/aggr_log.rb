#-*- coding: utf-8 -*-

require 'awesome_print'

class AggrLog

  def initialize
  end

  def run

    report_by_slot = {}
    report_by_campaign = {}
    report_by_ad = {}

    open(File.expand_path('./log/imp.log'), 'r').each do |l|
      log = ltsv_to_h(l)

      aggr_report(report_by_slot, log["slot_id"], :imp)
      aggr_report(report_by_campaign, log["campaign_id"], :imp)
      aggr_report(report_by_ad, log["ad_id"], :imp)
    end

    open(File.expand_path('./log/click.log'), 'r').each do |l|
      log = ltsv_to_h(l)

      aggr_report(report_by_slot, log["slot_id"], :click)
      aggr_report(report_by_campaign, log["campaign_id"], :click)
      aggr_report(report_by_ad, log["ad_id"], :click)
    end

    # dump reports

    # by zone
    dump_report(report_by_slot, 'Report for zones', 'slot_id')

    # by campaign
    dump_report(report_by_campaign, 'Report for campaigns', 'campaign_id')

    # by ad
    dump_report(report_by_campaign, 'Report for ads', 'ad_id')
  end


  private


  # ----------------------------------------------------------------------
  # レポートデータをコンソールにdumpする
  # ----------------------------------------------------------------------
  def dump_report(report, report_title, key_label)

    _key_label = " #{key_label}"
    key_label.size.upto(11) { _key_label += ' ' }

    _report_title = " #{report_title}"
    report_title.size.upto(27) { _report_title += ' ' }

    puts ''
    puts '+-----------------------------+'
    puts "|#{_report_title}|"
    puts '+-------------+-------+-------+'
    puts "|#{_key_label}|  imp  | click |"
    puts '+-------------+-------+-------+'

    report.keys.sort{|a, b| a.to_i <=> b.to_i }.each do |key|
      puts [
        "",
        sprintf('         %03d ', key),
        sprintf('   %03d ', report[key][:imp]),
        sprintf('   %03d ', report[key][:click]),
        "",
      ].join('|')

      puts '+-------------+-------+-------+'
    end
  end


  # ----------------------------------------------------------------------
  # 指定されたidをベースに集計処理を行う
  #
  # @param report   レポートデータを保存するハッシュ
  # @param id_key   集計の基にするid
  # @param incr_key 更新するデータ（imp / click）
  # ----------------------------------------------------------------------
  def aggr_report(report, id_key, incr_key)

    return if id_key.nil?

    report[id_key] = {
      imp: 0,
      click: 0,
    } unless report.has_key?(id_key)

    report[id_key][incr_key] += 1
  end

  # ----------------------------------------------------------------------
  # LTSVからHashに変換
  # ----------------------------------------------------------------------
  def ltsv_to_h(l)
    Hash[l.strip.split("\t").map{|f| f.split(":", 2)}]
  end
end

AggrLog.new.run

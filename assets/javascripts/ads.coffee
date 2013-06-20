###
広告枠毎に表示する広告を呼び出すためにscriptタグをappendする。
scriptタグのsrcが広告の呼び出しとなる。
###

# tiny_ads_slotというクラスが設定されているdivタグの一覧を取得
for div in $('div.tiny_ads_slot')

  # data-slot-idに設定されているslot idを取得
  slot_id = $(div).data('slot-id')

  # @TODO user_idの存在チェック/ない場合は作成、など

  # scriptタグを出力する
  $(document.body).append [
    "<scr",
    "ipt",
    " async",
    " type='text/javascript'",
    " charset='utf-8'",
    " src='http://localhost:9393/ads/#{slot_id}'>",
    "</script>"
  ].join('')


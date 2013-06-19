###
広告枠毎に表示する広告を呼び出すためにscriptタグをappendする。
scriptタグのsrcが広告の呼び出しとなる。
###

for div in $('div.tiny_ads_slot')

  slot_id = $(div).data('slot-id')
  #slot_type = $(div).data('slot-type')

  $(document.body).append [
    "<scr",
    "ipt",
    " async",
    " type='text/javascript'",
    " charset='utf-8'",
    " src='http://localhost:3000/ads/#{slot_id}'>",
    "</script>"
  ].join('')
    



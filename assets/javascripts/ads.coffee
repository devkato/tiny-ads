###

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
    " src='/ads/#{slot_id}'>",
    "</script>"
  ].join('')
    



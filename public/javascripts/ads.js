/*
広告枠毎に表示する広告を呼び出すためにscriptタグをappendする。
scriptタグのsrcが広告の呼び出しとなる。
*/


(function() {
  var div, slot_id, _i, _len, _ref;

  _ref = $('div.tiny_ads_slot');
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    div = _ref[_i];
    slot_id = $(div).data('slot-id');
    $(document.body).append(["<scr", "ipt", " async", " type='text/javascript'", " charset='utf-8'", " src='/ads/" + slot_id + "'>", "</script>"].join(''));
  }

}).call(this);

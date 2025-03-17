word-len = (v = "", method) ->
  return if method == \simple-word =>
    v.split(/\s|[,.;:!?，。；：︰！？、．　"]/).filter(->it)
      .map ->
        # segment by non-ascii codes
        it.split(/[\u1000-\uffff]/).map(-> if it.length => 2 else 1).reduce(((a,b) -> a + b),0) - 1
      .reduce(((a,b) -> a + b), 0)
  else v.length

hint = ({content, terms}) ->
  terms = (terms or []).filter -> it.opset == \length
  lc = {}
  if !terms.length => ret = [0, ""]
  else
    list = terms.map (t) ->
      if t.op == \range => {min,max} = t.config or {}
      else if t.op == \lte => max = (t.config or {}).val
      else if t.op == \gte => min = (t.config or {}).val
      if min? => lc.min = (lc.min or 0) >? min
      if max? => lc.max = (if !lc.max => max else lc.max) <? max
      count = word-len content, t.config.method
      lc.count = count
      [
        if min? => count - min else undefined
        if max? => max - count else undefined
      ]
    ret = [
      Math.min.apply Math, list.map(->it.0)
      Math.min.apply Math, list.map(->it.1)
    ]
    ret = if lc.min? and ret.0 < 0 => [-1, "還差 #{-ret.0} 個字"]
    else if lc.max? and ret.1 < 0 => [1, "超過 #{-ret.1} 個字"]
    else if lc.max? => [0, "還剩 #{ret.1} 個字"]
    else [0, "已經寫了 #{lc.count} 個字"]
    return {invalid: !!ret.0, text: ret.1}

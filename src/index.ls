module.exports =
  pkg:
    name: "@makeform/input"
    extend: name: \@makeform/common
    host: name: \@grantdash/composer
    dependencies: [
      {name: "marked", version: "main", path: "marked.min.js"}
      {name: "dompurify", version: "main", path: "dist/purify.min.js"}
    ]
    i18n:
      "en":
        "單位": "unit"
        "還差": "remaining to reach:"
        "超過": "exceeded by:"
        "還剩": "remaining:"
        "已寫": "written:"
        "字": "word(s)"
        config:
          autoComma: name: 'Number Formatting', desc: "Display numbers with thousands separators (commas)."
          asLink: name: 'Display as Link', desc: "Treat the entire input content as a clickable link."
          withLink: name: 'Auto Link', desc: "Automatically detect and hyper-link URLs within the content."
          asImage: name: 'Display as Image', desc: "Treat the input as an image URL and display the image with lightbox preview."
          unit: name: 'Unit', desc: "Display an additional unit label or suffix."
          placeholder: name: 'Placeholder Text', desc: "The example text shown when the field is empty."
          hint: name: 'Character Count Hint', desc: "Enable character count limit or hints."
      "zh-TW":
        "單位": "單位"
        "還差": "還差"
        "超過": "超過"
        "還剩": "還剩"
        "已寫": "已寫"
        "字": "字"
        config:
         autoComma: name: '數字逗點', desc: "內容數字以逗點做每千位分隔呈現"
         asLink: name: '呈現連結', desc: "輸入內容整體以連結呈現"
         withLink: name: '自動連結', desc: "輸入內容中若含連結，則以連結呈現"
         asImage: name: '呈現圖片', desc: "輸入內容視為圖片網址，並於檢視時顯示圖片"
         unit: name: '單位', desc: "顯示額外的單位提示"
         placeholder: name: '範例文字', desc: "內容空白時，欄位中的範例文字"
         hint: name: '字數提示', desc: "啟用字數提示"

  init: (opt) ->
    opt.pubsub.on \inited, (o = {}) ~> @ <<< o
    opt.pubsub.fire \subinit, mod: mod.call @, opt
  client: (bid) ->
    minibar: []
    meta: config:
      auto-comma: type: \boolean, name: \config.autoComma.name, desc: \config.autoComma.desc
      as-link: type: \boolean, name: \config.asLink.name, desc: \config.asLink.desc
      with-link: type: \boolean, name: \config.withLink.name, desc: \config.withLink.desc
      as-image: type: \boolean, name: \config.asImage.name, desc: \config.asImage.desc
      unit: type: \text, name: \config.unit.name, desc: \config.unit.desc
      placeholder: type: \text, name: \config.placeholder.name, desc: \config.placeholder.desc
      hint: enabled: type: \boolean, name: \config.hint.name, desc: \config.hint.desc
    render: ~> @widget.mod.child.view.render!

mod = ({root, ctx, data, parent, t}) ->
  {ldview,marked,DOMPurify} = ctx

  markedr = new marked.Renderer!
  markedr.link = (href, title, text) ->
    link = marked.Renderer.prototype.link.call @, href, title, text
    return link.replace \<a, '<a target="_blank" rel="noopener noreferrer" '
  marked.setOptions renderer: markedr
  init: ->
    lc = @mod.child
    view = {}
    @on \change, (v) ~>
      c = @content v
      if !(c?) => c = ''
      if @mod.info.config.auto-comma => c = comma(c)
      if view.get(\input).value == c => return
      if view =>
        view.get(\input).value = c
        view.render <[preview input content]>

    decomma = (v) -> "#{if v? => v else ''}".replace(/,/g,'')
    comma = (v) ->
      v = "#{if v? => v else ''}".trim!replace(/,/g,'')
      o = /^([0-9-]+)((?:\.?.+)?)$/.exec(v)
      if !o => return v
      [ret,vs] = ['', o.1.split('')]
      for i from 0 til vs.length
        ret = vs[vs.length - i - 1] + ret
        if (i % 3) == 2 and i < vs.length - 1 and /[0-9]/.exec(vs[vs.length - i - 2] or '') => ret = ',' + ret
      ret + o.2

    handler = ({node}) ~>
      nv = if !@mod.info.config.auto-comma => node.value else decomma(node.value)
      if @content(v = @value!) == nv => return
      if v and typeof(v) == \object => v.v = nv
      else v = {v: nv}
      @value v
    if !root => return
    lc.view = view = new ldview do
      root: root
      action:
        input: input: handler
        change:
          input: handler
          "enable-markdown-input": ({node}) ~>
            use-markdown = node.checked
            if !use-markdown => lc.preview = false
            if typeof(v = @value!) != \object => v = {v: v or ''}
            v.markdown = use-markdown
            @value v
            view.render!
        click:
          mode: ({node}) ~>
            if !@mod.info.config.show-markdown-option => return
            lc.preview = if node.getAttribute(\data-name) == \preview => true else false
            view.render!
      text:
        unit: ({node}) ~> t(@mod.info.config.unit or '')
      handler:
        remains: ({node}) ~>
          enabled = !!(@mod.info.config.hint or {}).enabled
          if !enabled =>
            # d-none: !enabled, or enabled but !ret.text
            # this ensures remains shown only if there are content
            # so container won't shrink due to empty remains' margin-top -1em
            node.classList.toggle \d-none, !enabled
            return node.textContent = ""
          content = "#{@content! or ''}"
          terms = @serialize!term
          ret = hint {content, terms, t}
          node.textContent = ret.text
          node.classList.toggle \d-none, !ret.text
          node.classList.toggle \text-danger, !!ret.invalid

        "enable-markdown-input": ({node}) ~>
          node.checked = (@value! or {}).markdown
        "has-unit": ({node}) ~>
          node.classList.toggle \d-none, !@mod.info.config.unit
        "enable-markdown": ({node}) ~> node.classList.toggle \d-none, !@mod.info.config.show-markdown-option
        mode: ({node}) ~>
          use-markdown = (@value! or {}).markdown and @mod.info.config.show-markdown-option
          node.classList.toggle \d-none, !use-markdown
          node.classList.toggle \active, !(lc.preview xor (node.getAttribute(\data-name) == \preview))
        preview: ({node}) ~>
          if !view => return
          node.classList.toggle \d-none, !lc.preview
          node.innerHTML = DOMPurify.sanitize(marked.parse view.get(\input).value)
        input: ({node}) ~>
          readonly = !!@mod.info.meta.readonly
          if readonly => node.setAttribute \readonly, true
          else node.removeAttribute \readonly
          node.classList.toggle \is-invalid, @status! == 2
          if @mod.info.config.placeholder => node.setAttribute \placeholder, @mod.info.config.placeholder
          else node.removeAttribute \placeholder
        content: ({node}) ~>
          content = @content!
          value = @value! or {}
          if !@is-empty! and @mod.info.config.auto-comma => content = comma(content)
          text = if @is-empty! => "n/a"
          else content + (if @mod.info.config.unit => (" " + t(that)) else "")
          node.classList.toggle \text-muted, @is-empty!
          node.innerText = text
          use-markdown = @mod.info.config.show-markdown-option and value.markdown
          if !use-markdown => node.innerText = text
          else node.innerHTML = DOMPurify.sanitize(marked.parse content)
          if @mod.info.config.as-link and !@is-empty! =>
            href = content.replace(/^(javascript:|data:)/,'')
            if !/^https?:\/\//.exec(href) => href = "https://#href"
            if /^https?:\/\/[^.\s]+\.[^.\s]+/.exec(href) =>
              node.innerHTML = ""
              node.appendChild(child = document.createElement \a)
              child.setAttribute \href, href
              child.setAttribute \target, "_blank"
              child.setAttribute \rel, "noreferrer noopener"
              child.innerText = text
          else if @mod.info.config.with-link and !@is-empty! =>
            node.innerHTML = ""
            content.split(/([\s])/).map (c,i) ->
              if /^https?:\/\/[^.\s]+\.[^.\s]+/.exec(c) =>
                child = document.createElement \a
                child.setAttribute \href, c
                child.setAttribute \target, "_blank"
                child.setAttribute \rel, "noreferrer noopener"
                child.innerText = c
              else child = document.createTextNode(c)
              node.appendChild(child)
          if @mod.info.config.as-image and !@is-empty! =>
            node.innerHTML = ""
            node.appendChild(child = document.createElement \img)
            child.setAttribute \src, text

  render: -> if @mod.child.view => @mod.child.view.render!
  is-empty: (v) ->
    v = @content(v)
    return (typeof(v) == \undefined) or (typeof(v) == \string and v.trim! == "") or v == null
  is-equal: (u, v) ->
    eu = @is-empty u
    ev = @is-empty v
    if eu xor ev => return false
    if eu and ev =>
      if (u or v) and (u or {}).markdown != (v or {}).markdown => return false
      return true
    return JSON.stringify(u) == JSON.stringify(v)

  content: (v) ->
    if v and typeof(v) == \object => v.v else v


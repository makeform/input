module.exports =
  pkg:
    name: "@makeform/input", extend: {name: "@makeform/common"}
    dependencies: [
      {name: "marked", version: "main", path: "marked.min.js"}
      {name: "dompurify", version: "main", path: "dist/purify.min.js"}
    ]
    i18n:
      "en": "單位": "unit"
      "zh-TW": "單位": "單位"
  init: (opt) -> opt.pubsub.fire \subinit, mod: mod(opt)

mod = ({root, ctx, data, parent, t}) -> 
  {ldview,marked,DOMPurify} = ctx

  markedr = new marked.Renderer!
  markedr.link = (href, title, text) ->
    link = marked.Renderer.prototype.link.call @, href, title, text
    return link.replace \<a, '<a target="_blank" rel="noopener noreferrer" '
  marked.setOptions renderer: markedr

  lc = {}
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
          if !enabled => return node.textContent = ""
          content = "#{@content! or ''}"
          terms = @serialize!term
          ret = hint {content, terms}
          node.textContent = ret.text
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


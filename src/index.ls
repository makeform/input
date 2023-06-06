module.exports =
  pkg:
    name: "@makeform/input", extend: {name: "@makeform/common"}
    dependencies: [{name: "marked", version: "main", path: "marked.min.js"}]
    i18n:
      "en": "單位": "unit"
      "zh-TW": "unit": "單位"
  init: (opt) -> opt.pubsub.fire \subinit, mod: mod(opt)

mod = ({root, ctx, data, parent, t}) -> 
  {ldview,marked} = ctx
  lc = {}
  init: ->
    lc = @mod.child
    view = {}
    @on \change, (v) ~>
      c = @content v
      if !(c?) => c = ''
      if view.get(\input).value == c => return
      if view =>
        view.get(\input).value = c
        view.render <[preview input content]>
    handler = ({node}) ~>
      if @content(v = @value!) == (nv = node.value) => return
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
            lc.markdown = node.checked
            if !lc.markdown => lc.preview = false
            if typeof(v = @value!) != \object => v = {v: v}
            v.markdown = lc.markdown
            @value v
            view.render!
        click:
          mode: ({node}) ->
            lc.preview = if node.getAttribute(\data-name) == \preview => true else false
            view.render!
      text:
        unit: ({node}) ~> t(@mod.info.config.unit or '')
      handler:
        "has-unit": ({node}) ~>
          node.classList.toggle \d-none, !@mod.info.config.unit
        "enable-markdown": ({node}) ~> node.classList.toggle \d-none, !@mod.info.config.show-markdown-option
        mode: ({node}) ~>
          node.classList.toggle \d-none, !lc.markdown
          node.classList.toggle \active, !(lc.preview xor (node.getAttribute(\data-name) == \preview))
        preview: ({node}) ~>
          if !view => return
          node.classList.toggle \d-none, !lc.preview
          node.innerHTML = marked.parse view.get(\input).value
        input: ({node}) ~>
          readonly = !!@mod.info.meta.readonly
          if readonly => node.setAttribute \readonly, true
          else node.removeAttribute \readonly
          node.classList.toggle \is-invalid, @status! == 2
          if @mod.info.config.placeholder => node.setAttribute \placeholder, @mod.info.config.placeholder
          else node.removeAttribute \placeholder
        content: ({node}) ~>
          val = @content!
          text = if @is-empty! => "n/a"
          else val + (if @mod.info.config.unit => that else "")
          node.classList.toggle \text-muted, @is-empty!
          node.innerText = text
          if @mod.info.config.as-link and !@is-empty! =>
            node.innerHTML = ""
            node.appendChild(child = document.createElement \a)
            child.setAttribute \href, val.replace(/^javascript:/,'')
            child.setAttribute \target, "_blank"
            child.setAttribute \rel, "noreferrer noopener"
            child.innerText = text

  render: -> if @mod.child.view => @mod.child.view.render!
  is-empty: (v) ->
    v = @content(v)
    return (typeof(v) == \undefined) or (typeof(v) == \string and v.trim! == "") or v == null
  content: (v) ->
    if v and typeof(v) == \object => v.v else v


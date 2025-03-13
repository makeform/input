# @makeform/input

Text input widget suitable for one line short text, links or number.


## config

 - `asLink`: render input content as a link in view mode
 - `withLink`: render links inside input content as links in view mode
 - `asImage`: render input content as an image in view mode
 - `autoComma`: automatically add comma in input content. default false
   - yet comma will still be removed in underlying value .
 - `unit`: optional, a string representing unit of this field if provided.
   - shown as a small dimmed text at the corner of this widget if provided
 - `placeholder`: placeholder text to be shown. optional, nothing will be shown if omitted.

it also provides following configs for using in `@makeform/textarea` or any other widgets want to extend `@makeform/input` and use related features:

 - `showMarkdownOption`: default false. show markdown related options if true


## License

MIT

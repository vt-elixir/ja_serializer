locals_without_parens = [attributes: 1, location: 1, has_many: 2, has_one: 2]

[
  inputs: ["*.{ex,exs}", "{bench,lib,test}/**/*.{ex,exs}"],
  line_length: 80,
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ]
]

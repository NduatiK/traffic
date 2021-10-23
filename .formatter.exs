[
  surface_line_length: 120,
  surface_inputs: ["{lib,test}/**/*.{ex,exs,sface}"],
  import_deps: [:ecto, :phoenix, :surface],
  inputs: ["*.{ex,exs}", "priv/*/seeds.exs", "{config,lib,test}/**/*.{ex,exs}"],
  subdirectories: ["priv/*/migrations"]
]

defmodule Sunxi.MixProject do
  use Mix.Project

  @github_org "gworkman"
  @version "0.1.0"

  def project do
    [
      app: :sunxi,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      compilers: Mix.compilers() ++ [:elixir_make],
      make_cwd: "c_src",
      description: description(),
      package: package(),
      deps: deps(),
      # ExDoc configuration
      name: "Sunxi",
      source_url: "https://github.com/#{@github_org}/sunxi",
      docs: [
        main: "Sunxi.FEL",
        extras: ["README.md", "CHANGELOG.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    "Elixir bindings for sunxi-tools, allowing interaction with Allwinner devices in FEL mode."
  end

  defp package do
    [
      licenses: ["GPL-2.0-or-later"],
      links: %{"GitHub" => "https://github.com/#{@github_org}/sunxi"},
      files: [
        "lib",
        "c_src",
        "mix.exs",
        "README.md",
        "CHANGELOG.md",
        "LICENSE*",
        ".formatter.exs"
      ],
      exclude_patterns: [
        "c_src/sunxi-tools/sunxi-*",
        "c_src/sunxi-tools/*.o",
        "c_src/sunxi-tools/bin2fex",
        "c_src/sunxi-tools/fex2bin",
        "c_src/sunxi-tools/sunxi-fel",
        "c_src/sunxi-tools/sunxi-fexc",
        "c_src/sunxi-tools/sunxi-pio",
        "c_src/sunxi-tools/sunxi-bootinfo",
        "c_src/sunxi-tools/sunxi-nand-part",
        "**/.DS_Store"
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:elixir_make, "~> 0.9", runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end
end

defmodule Sunxi.MixProject do
  use Mix.Project

  @github_org "gworkman"
  @version "0.1.5"

  def project do
    [
      app: :sunxi,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      compilers: Mix.compilers() ++ [:elixir_make],
      make_cwd: "c_src",
      make_env: &make_env/0,
      description: description(),
      package: package(),
      deps: deps(),
      # ExDoc configuration
      name: "Sunxi",
      source_url: "https://github.com/#{@github_org}/sunxi",
      docs: [
        main: "readme",
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

  # On macOS the `sunxi` dependency's Makefile defaults to the Intel Homebrew
  # path (/usr/local/opt/dtc) and its sub-make does not propagate libfdt include
  # flags, so host builds fail to find libfdt.h / -lfdt. Point the toolchain at
  # the local Homebrew prefix (works for both Apple Silicon and Intel) so the
  # build works without any external shell/direnv setup.
  defp make_env do
    case :os.type() do
      {:unix, :darwin} -> darwin_make_env()
      _ -> %{}
    end
  end

  defp darwin_make_env do
    with brew when is_binary(brew) <- System.find_executable("brew"),
         {output, 0} <- System.cmd(brew, ["--prefix"]) do
      prefix = String.trim(output)

      %{
        "DTC_PREFIX" => Path.join([prefix, "opt", "dtc"]),
        "CPATH" => prepend_path(Path.join(prefix, "include"), System.get_env("CPATH")),
        "LIBRARY_PATH" =>
          prepend_path(Path.join(prefix, "lib"), System.get_env("LIBRARY_PATH"))
      }
    else
      _ -> %{}
    end
  end

  defp prepend_path(dir, existing) when existing in [nil, ""], do: dir
  defp prepend_path(dir, existing), do: dir <> ":" <> existing

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

defmodule RTMP.MixProject do
  use Mix.Project

  def project do
    [
      app: :r_t_m_p,
      version: "0.0.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # ExDoc specific
      name: "RTMP",
      source_url: "https://github.com/YannickFricke/rtmp_ex",
      homepage_url: "https://github.com/YannickFricke/rtmp_ex",
      docs: [
        # The main page in the docs
        main: "RTMP"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # An opinionated code formatter by Adobe
      {:styler, "~> 0.10", only: [:dev, :test], runtime: false},

      # For generating the documentation
      {:ex_doc, "~> 0.30.9", only: :dev, runtime: false}
    ]
  end
end

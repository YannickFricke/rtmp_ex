defmodule RTMP.MixProject do
  use Mix.Project

  def project do
    [
      app: :r_t_m_p,
      version: "0.0.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end
end

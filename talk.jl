### A Pluto.jl notebook ###
# v0.14.7

using Markdown
using InteractiveUtils

# ╔═╡ d088c772-c7b4-11eb-1796-7365ee1abe49
begin
	# instantiate environment
	using Pkg
	Pkg.activate(@__DIR__)
	Pkg.instantiate()
	
	# setup page for WGLMakie scenes
	using JSServe
	Page()
end

# ╔═╡ 995980f5-aa29-46a1-834e-9458c71f8914
begin
	# load packages used in this talk
	using GeoStats
	using GeoTables
	using MeshViz
	using PlutoUI
	
	# default vizualization options
	import WGLMakie as WGL
	theme = WGL.Theme(
		resolution = (650,500)
	)
	WGL.set_theme!(theme)
end

# ╔═╡ b85daaf1-d07b-44d0-9cef-cc19087d792d
md"""
# Geostatistical Learning

[Júlio Hoffimann, Ph.D.](https://juliohm.github.io)
"""

# ╔═╡ 48346d09-8487-487a-8c1e-abc7ef26e377
BRA = GeoTables.gadm("BRA", children=true);

# ╔═╡ f2dc93af-24c4-4c21-8dc6-fad124923998
viz(BRA.geometry)

# ╔═╡ Cell order:
# ╟─d088c772-c7b4-11eb-1796-7365ee1abe49
# ╟─995980f5-aa29-46a1-834e-9458c71f8914
# ╟─b85daaf1-d07b-44d0-9cef-cc19087d792d
# ╠═48346d09-8487-487a-8c1e-abc7ef26e377
# ╠═f2dc93af-24c4-4c21-8dc6-fad124923998

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
	using FileIO
	using PlyIO
	
	# default vizualization settings
	import WGLMakie as WGL
	theme = WGL.Theme(
		resolution = (650,500),
		colormap = :inferno,
		aspect = 1,
	)
	WGL.set_theme!(theme)
	
	# helper function to read meshes
	function readply(fname)
		ply = load_ply(fname)
		x = ply["vertex"]["x"]
  		y = ply["vertex"]["y"]
  		z = ply["vertex"]["z"]
  		points = Point.(x, y, z)
  		connec = [connect(Tuple(c.+1)) for c in ply["face"]["vertex_indices"]]
  		SimpleMesh(points, connec)
	end
end;

# ╔═╡ e02bb839-dbe3-4e05-ad48-e39020d605d1
html"""
<img src="https://juliacon.org/assets/shared/img/logo_20.svg"> <font size=20>2021</font>
"""

# ╔═╡ b85daaf1-d07b-44d0-9cef-cc19087d792d
md"""
# Geostatistical Learning

Júlio Hoffimann, Ph.D. ([julio.hoffimann@impa.br](mailto:julio.hoffimann@impa.br))

*Postdoctoral fellow in Industrial Mathematics*

Instituto de Matemática Pura e Aplicada
"""

# ╔═╡ 26ff713f-9ab8-460d-a748-bca8217d4ee5
html"""
<img src="https://icm2018.impa.br/images/logo-impa.png", width=200>
"""

# ╔═╡ 5bd7385d-afa7-49ae-83a7-6879c48c770e
md"""

### In this talk...

- *What is **geo**statistical learning? What are the challenges?*
- *Why the **Julia** programming language? Why not Python or R?*
"""

# ╔═╡ 2ff88b3a-9ed1-4495-93d7-75945b1ca9e7
md"""
## The two connotations of "Geo"

### Geo ≡ Earth

From Greek *geō-* the term **Geo** means Earth as in **Geo**logy, **Geo**physics and **Geo**sciences.

![earth](https://upload.wikimedia.org/wikipedia/commons/thumb/9/9d/MODIS_Map.jpg/1920px-MODIS_Map.jpg)

### Geo ≡ Geospatial

**Geo** can also mean Geospatial as in **Geo**spatial sciences.

> In [GeoStats.jl](https://github.com/JuliaEarth/GeoStats.jl) we adopt the second connotation and refer to **geo**statistics as the branch of statistics developed for **geo**spatial data.
"""

# ╔═╡ 75797373-7126-4209-883d-41261ba211eb
md"""
## But what is geospatial data?

Very generally, **geo**spatial data is the combination of:

1. a **table** of attributes with
2. a geospatial **domain**

The concept of **table** is widespread. We support any table implementing the [Tables.jl](https://github.com/JuliaData/Tables.jl) interface, including named tuples, dataframes, SQL databases, Excel spreadsheets, Apache Arrow, etc.

By geospatial **domain** we mean any *discretization* of a region in physical space. We support any domain implementing the [Meshes.jl]() interface, including Cartesian grids, point sets, collections of geometries and general unstructured meshes.

A 3D grid is an example of a geospatial domain:
"""

# ╔═╡ dc2345d4-b338-4c3c-aaa4-789988832406
let
	# discretization of cube region
	grid = CartesianGrid(10, 10, 10)
	
	# visualization of grid domain
	viz(grid)
end

# ╔═╡ d52c37cb-232a-49d3-a6af-ccad1405ddb8
md"""
## Examples of geospatial data

### 3D grid data
"""

# ╔═╡ 89bb5a1c-d905-4b3b-81ff-343dbf14d306
begin
	# table with 1000 measurements of φ and κ and Sₒ
	𝒯 = (φ = rand(1000), κ = rand(1000), Sₒ = rand(1000))
	
	# domain with 1000 finite elements
	𝒟 = CartesianGrid(10, 10, 10)
	
	# combine table with domain
	Ω = georef(𝒯, 𝒟)
end

# ╔═╡ fa553a82-6f35-4d6e-845c-a97cd54be7f6
viz(Ω, variable = :φ)

# ╔═╡ 706e294d-ce1b-4be1-b1cf-00a27bc3ede3
md"""
### 2D grid data (a.k.a. image)
"""

# ╔═╡ 916d8af0-4065-4e6f-bf99-4d473523eba8
begin
	# download image from Google Earth
	img = load(download("http://www.gstatic.com/prettyearth/assets/full/1408.jpg"))
	
	# georeference color attribute on 2D grid
	Ι = georef((color = img,))
end

# ╔═╡ ea422ea7-42ef-4245-8767-d6631cca3ed3
viz(Ι, variable = :color)

# ╔═╡ 9fdcf73b-3c3d-4f2d-b8bf-d15f1dcf15cd
md"""
### 3D mesh data
"""

# ╔═╡ 4527d107-2849-4b80-9c52-3db6fc888ec2
begin
	# download mesh of Beethoven
	ℳ = readply(download(
			"https://people.sc.fsu.edu/~jburkardt/data/ply/beethoven.ply"))
	
	# compute attributes on triangles
	A = log.(area.(ℳ))
	C = centroid.(ℳ)
	X = first.(coordinates.(C))
	Z = last.(coordinates.(C))
	
	# combine attribute table with mesh
	👤 = georef((A = A, X = X, Z = Z), ℳ)
end

# ╔═╡ 9f1128e8-13ae-4334-bb9f-cc718e80d024
viz(👤, variable = :A)

# ╔═╡ 6f07a125-7801-4f53-8372-39a2e34d87be
md"""
## Learning from geospatial data
"""

# ╔═╡ Cell order:
# ╟─d088c772-c7b4-11eb-1796-7365ee1abe49
# ╟─995980f5-aa29-46a1-834e-9458c71f8914
# ╟─e02bb839-dbe3-4e05-ad48-e39020d605d1
# ╟─b85daaf1-d07b-44d0-9cef-cc19087d792d
# ╟─26ff713f-9ab8-460d-a748-bca8217d4ee5
# ╟─5bd7385d-afa7-49ae-83a7-6879c48c770e
# ╟─2ff88b3a-9ed1-4495-93d7-75945b1ca9e7
# ╟─75797373-7126-4209-883d-41261ba211eb
# ╠═dc2345d4-b338-4c3c-aaa4-789988832406
# ╟─d52c37cb-232a-49d3-a6af-ccad1405ddb8
# ╠═89bb5a1c-d905-4b3b-81ff-343dbf14d306
# ╠═fa553a82-6f35-4d6e-845c-a97cd54be7f6
# ╟─706e294d-ce1b-4be1-b1cf-00a27bc3ede3
# ╠═916d8af0-4065-4e6f-bf99-4d473523eba8
# ╠═ea422ea7-42ef-4245-8767-d6631cca3ed3
# ╟─9fdcf73b-3c3d-4f2d-b8bf-d15f1dcf15cd
# ╠═4527d107-2849-4b80-9c52-3db6fc888ec2
# ╠═9f1128e8-13ae-4334-bb9f-cc718e80d024
# ╟─6f07a125-7801-4f53-8372-39a2e34d87be

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
	using CSV
	
	# specific functionality from ML stack
	using MLJ: @load, coerce, Multiclass
	using LossFunctions: value, MisclassLoss, AggMode
	
	# skip prompt to download data dependencies
	ENV["DATADEPS_ALWAYS_ACCEPT"] = "true"
	
	# default vizualization settings
	import WGLMakie as WGL
	theme = WGL.Theme(
		resolution = (650,500),
		colormap = :viridis,
		aspect = :data,
		markersize = 2
	)
	WGL.set_theme!(theme)
	
	# helper function to read meshes
	function loadply(fname)
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
<img src="https://juliacon.org/assets/shared/img/logo_20.svg" width=250> <font size=20>2021</font>
"""

# ╔═╡ b85daaf1-d07b-44d0-9cef-cc19087d792d
md"""
# Geostatistical Learning

#### Challenges and Opportunities
"""

# ╔═╡ 79e973b5-2cb2-4c3b-af9d-a44307fdd659
md"""
Júlio Hoffimann, Ph.D. ([julio.hoffimann@impa.br](mailto:julio.hoffimann@impa.br))

*Postdoctoral fellow in Industrial Mathematics*

Instituto de Matemática pura e Aplicada
"""

# ╔═╡ 26ff713f-9ab8-460d-a748-bca8217d4ee5
html"""
<img src="https://icm2018.impa.br/images/logo-impa.png", width=150>
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

**Geo** can also mean Geospatial as in **Geo**spatial sciences and Computational **Geo**metry.

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
"""

# ╔═╡ dc2345d4-b338-4c3c-aaa4-789988832406
let
	# discretization of cube region
	grid = CartesianGrid(10, 10, 10)
	
	# visualize 3D grid on GPU
	viz(grid)
end

# ╔═╡ d52c37cb-232a-49d3-a6af-ccad1405ddb8
md"""
## Examples of geospatial data

Thanks to **Julia's multiple-dispatch**, we were able to achieve a very **clean user interface**, including a universal `georef` function to combine various types of tables and geospatial domains.

### 3D grid data
"""

# ╔═╡ 89bb5a1c-d905-4b3b-81ff-343dbf14d306
begin
	# table with 1000 measurements of φ and κ and Sₒ
	𝒯 = (φ = rand(1000), κ = rand(1000), Sₒ = rand(1000))
	
	# domain with 1000 finite elements
	𝒟 = CartesianGrid(10, 10, 10)
	
	# combine table with domain
	rock = georef(𝒯, 𝒟)
end

# ╔═╡ fa553a82-6f35-4d6e-845c-a97cd54be7f6
viz(rock, variable = :φ)

# ╔═╡ 706e294d-ce1b-4be1-b1cf-00a27bc3ede3
md"""
### 2D grid data (a.k.a. image)
"""

# ╔═╡ 916d8af0-4065-4e6f-bf99-4d473523eba8
begin
	# download image from Google Earth
	img = load(download("http://www.gstatic.com/prettyearth/assets/full/1408.jpg"))
	
	# georeference color attribute on 2D grid
	city = georef((color = img,))
end

# ╔═╡ ea422ea7-42ef-4245-8767-d6631cca3ed3
viz(city, variable = :color)

# ╔═╡ 9fdcf73b-3c3d-4f2d-b8bf-d15f1dcf15cd
md"""
### 3D mesh data
"""

# ╔═╡ 4527d107-2849-4b80-9c52-3db6fc888ec2
begin
	# download mesh file
	ℳ = loadply(
		download("https://people.sc.fsu.edu/~jburkardt/data/ply/beethoven.ply")
	)
	
	# compute attributes on triangles
	𝒜 = log.(area.(ℳ))
	
	# combine attribute table with mesh
	👤 = georef((𝒜 = 𝒜,), ℳ)
end

# ╔═╡ 9f1128e8-13ae-4334-bb9f-cc718e80d024
viz(👤, variable = :𝒜)

# ╔═╡ 7df28235-efaf-42f9-9943-c7d452dfd347
md"""
### 2D geometry set data
"""

# ╔═╡ 330a3630-38fa-4948-9498-c336fb0dc8f5
# download Brazil geographic data
BRA = GeoTables.gadm("BRA", children = true)

# ╔═╡ 472ba4c4-4d03-48f8-81ba-0ebe9b78d635
let
	# compute attributes per state
	table = (letters = length.(BRA.NAME_1),)
	
	# georeference table with states
	🇧🇷 = georef(table, domain(BRA))
	
	# visualize states in different color
	viz(🇧🇷, variable = :letters)
end

# ╔═╡ a076baa5-6442-4f27-920d-5788b0b23fa6
md"""
### More examples

Please check the [GeoStatsTutorials](https://github.com/JuliaEarth/GeoStatsTutorials) for more examples and features:
"""

# ╔═╡ d1ed848a-6221-4386-8066-83b1b6ede92f
html"""
<iframe width="560" height="315" src="https://www.youtube.com/embed/videoseries?list=PLsH4hc788Z1f1e61DN3EV9AhDlpbhhanw" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
"""

# ╔═╡ 6f07a125-7801-4f53-8372-39a2e34d87be
md"""
## Learning from geospatial data

Let's recall the definition of well-posed learning problems:

> **Definition ([Mitchell 1997](http://www.cs.cmu.edu/~tom/mlbook.html)):** A computer program is said to **learn** from experience $$\mathcal{E}$$ with respect to some class of tasks $$\mathcal{T}$$ and performance measure $$\mathcal{P}$$, if its performance at tasks in $$\mathcal{T}$$, as measured by $$\mathcal{P}$$, improves with experience $$\mathcal{E}$$.

**Example:** classical statistical learning via empirical risk minimization

$$\hat{f} = \arg\min_{h\in\mathcal{H}} \mathbb{E}_{(\mathbf{x},y) \sim \Pr}\left[\mathcal{L}(y, h(\mathbf{x}))\right] \approx \frac{1}{n} \sum_{i=1}^n \mathcal{L}(y^{(i)},h(\mathbf{x}^{(i)}))$$

where $$\mathcal{E}$$ is a data set with $$n$$ samples, $$\mathcal{P}$$ is the empirical risk and $$\mathcal{T}$$ is a classical learning task such as regression or classification.

Assumptions which do **not** hold in geospatial applications:

1. training samples are i.i.d.
2. train and test distributions are equal
3. samples share a common support (i.e. volume)
"""

# ╔═╡ 0b1e0eb1-8188-49b1-ac38-a14b51e2f1b8
md"""
### Can't hold onto assumptions ⚠️

Suppose we are given a crop classification model:

- **features ($$\mathbf{x}$$):** bands of satellite image
- **target ($$y$$):** crop type (soy, corn, ...)

and are asked to estimate its **generalization error** w.r.t. a *green field* (South East) knowing that annotations are only available at a nearby *brown field* (North West):
"""

# ╔═╡ 58bc4235-e61b-4c9a-8ede-3633e1c2f7a9
begin
	# attributes and coordinates x and y
	data = georef(CSV.File("data/agriculture.csv"), (:x, :y))
	
	# adjust scientific type of crop column
	Ω = coerce(data, :crop => Multiclass)
	
	# 20%/80% split along the (1, -1) direction
	Ωₛ, Ωₜ = split(Ω, 0.2, (1.0, -1.0))
	
	# visualize geospatial domains
	viz(domain(Ωₛ), elementcolor = :saddlebrown,
		axis = (xlabel = "longitude", ylabel = "latitude"))
	viz!(domain(Ωₜ), elementcolor = :green)
	WGL.lines!([(270,660), (720,1140)],
		       linestyle = :dash, color = :black)
	WGL.annotations!(["brown field (𝒟ₛ)","green field (𝒟ₜ)"],
		             [WGL.Point(500,1200), WGL.Point(-50,300)],
		             textsize = 30, color = [:saddlebrown,:green])
	WGL.current_figure()
end

# ╔═╡ df79f3a8-4d99-46a2-acd2-838f6e442526
begin
	# learning task: satellite bands → crop type
	𝓉 = ClassificationTask((:band1, :band2, :band3, :band4), :crop)
	
	# learning problem: train in Ωₛ and predict in Ωₜ
	𝓅 = LearningProblem(Ωₛ, Ωₜ, 𝓉)
	
	# learning model: decision tree
	𝓂 = @load DecisionTreeClassifier pkg=DecisionTree
	
	# learning strategy: naive pointwise learning
	𝓁 = PointwiseLearn(𝓂())
	
	# loss function: misclassification loss
	ℒ = MisclassLoss()
	
	# classical 10-fold cross-validation
	cv = CrossValidation(10, loss = Dict(:crop => ℒ))
	
	# estimate of generalization error
	ϵ̂cv = error(𝓁, 𝓅, cv)[:crop]
	
	# train in Ωₛ and predict in Ωₜ
	Ω̂ₜ = solve(𝓅, 𝓁)
	
	# actual error of the model
	ϵ = value(ℒ, Ωₜ.crop, Ω̂ₜ.crop, AggMode.Mean())
end;

# ╔═╡ ff7c5f94-363e-442d-b76b-0403608d0cb9
md"""
Let's follow the traditional k-fold cross-validation methodology:

1. subdivide the *brown field* $\mathcal{D}_s$ into k random folds
2. average the empirical risk over the folds

$$\hat\epsilon(h) = \frac{1}{k} \sum_{j=1}^k \frac{1}{|\mathcal{D}_s^{(j)}|} \int_{\mathcal{D}_s^{(j)}} \mathcal{L}(y_\mathbf{u}, h(\mathbf{x}_\mathbf{u}))d\mathbf{u}$$
"""

# ╔═╡ 0cc70b6e-8f0c-44ac-a83a-2d82e4db3348
LocalResource("assets/cvsetup.png")

# ╔═╡ 8b05bd01-1ba7-4f8a-80cc-bdc5a69024f9
md"""
#### Result:

The model's estimated error is **$(round(ϵ̂cv*100, digits=2))%** misclassification. However, when we deploy the model in the *green field* $\mathcal{D}_t$ the error is much higher with **$(round(ϵ*100, digits=2))%** of the samples misclassified. The error is **$(round(ϵ / ϵ̂cv, digits=2))** times higher than expected.
"""

# ╔═╡ 56fbe58f-facd-4922-b7cf-8cbadb52be83
let
	fig = WGL.Figure(resolution = (650,300))
	viz(fig[1,1], Ω̂ₜ, variable = :crop,
	    axis = (
			title = "predicted crop type",
			xlabel = "longitude", ylabel="latitude"
		)
	)
	viz(fig[1,2], Ωₜ, variable = :crop,
		axis = (
			title = "actual crop type",
			xlabel = "longitude", ylabel="latitude"
		)
	)
	WGL.linkaxes!(filter(x -> x isa WGL.Axis, fig.content)...)
	fig
end

# ╔═╡ 77c82d92-3331-4217-b8de-153ea94bfbc8
md"""
#### What happened?

Classical cross-validation (CV) relies heavily on i.i.d. samples and equal distributions:

1. hold-out points at **random** (red points)
2. learn model with remaining points (other colors)
3. estimate error using prediction at hold-out points

(Stone 1974, Geisser 1975)
"""

# ╔═╡ b6dd59bd-cb71-44b2-8a69-a0b04bb69664
LocalResource("assets/cv.png")

# ╔═╡ 952dce52-9950-4b66-9348-f804b2887fdf
md"""
### Geostatistical validation

In an attempt to avoid the super optimism of CV, the spatial statistics community proposed various alternative methods such as block cross-validation (BCV) and leave-ball-out (LBO).

These methods rely on **systematic partitions** of the source domain, which are often parameterized with a spatial correlation length $r > 0$.
"""

# ╔═╡ 8347ecd2-305d-4a81-9ba0-8fefc0d01db2
LocalResource("assets/bcv-lbo.png")

# ╔═╡ Cell order:
# ╟─d088c772-c7b4-11eb-1796-7365ee1abe49
# ╟─995980f5-aa29-46a1-834e-9458c71f8914
# ╟─e02bb839-dbe3-4e05-ad48-e39020d605d1
# ╟─b85daaf1-d07b-44d0-9cef-cc19087d792d
# ╟─79e973b5-2cb2-4c3b-af9d-a44307fdd659
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
# ╟─7df28235-efaf-42f9-9943-c7d452dfd347
# ╠═330a3630-38fa-4948-9498-c336fb0dc8f5
# ╠═472ba4c4-4d03-48f8-81ba-0ebe9b78d635
# ╟─a076baa5-6442-4f27-920d-5788b0b23fa6
# ╟─d1ed848a-6221-4386-8066-83b1b6ede92f
# ╟─6f07a125-7801-4f53-8372-39a2e34d87be
# ╟─0b1e0eb1-8188-49b1-ac38-a14b51e2f1b8
# ╟─58bc4235-e61b-4c9a-8ede-3633e1c2f7a9
# ╟─df79f3a8-4d99-46a2-acd2-838f6e442526
# ╟─ff7c5f94-363e-442d-b76b-0403608d0cb9
# ╟─0cc70b6e-8f0c-44ac-a83a-2d82e4db3348
# ╟─8b05bd01-1ba7-4f8a-80cc-bdc5a69024f9
# ╟─56fbe58f-facd-4922-b7cf-8cbadb52be83
# ╟─77c82d92-3331-4217-b8de-153ea94bfbc8
# ╟─b6dd59bd-cb71-44b2-8a69-a0b04bb69664
# ╟─952dce52-9950-4b66-9348-f804b2887fdf
# ╟─8347ecd2-305d-4a81-9ba0-8fefc0d01db2

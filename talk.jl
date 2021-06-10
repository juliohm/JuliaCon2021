### A Pluto.jl notebook ###
# v0.14.7

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

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
	using DataFrames
	using MeshViz
	using PlutoUI
	using FileIO
	using PlyIO
	using CSV
	
	# load classical ML stack
	import MLJ
	
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

##### Package:
"""

# ╔═╡ 432d56b2-bd58-43bd-a9ed-0e8e42e2303b
html"""
<img src="https://github.com/JuliaEarth/GeoStats.jl/blob/master/docs/src/assets/logo-text.svg?raw=true" width=350>
"""

# ╔═╡ 79e973b5-2cb2-4c3b-af9d-a44307fdd659
md"""
Júlio Hoffimann, Ph.D. ([julio.hoffimann@impa.br](mailto:julio.hoffimann@impa.br))

*Postdoctoral fellow in Industrial Mathematics*

Instituto de Matemática pura e Aplicada
"""

# ╔═╡ 1e4e92a3-549b-46ee-905d-3dc4c82b12de
html"""
<img src="https://icm2018.impa.br/images/logo-impa.png" width=120>
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

> In this talk we adopt the second connotation and refer to **geo**statistics as the branch of statistics developed for **geo**spatial data.
"""

# ╔═╡ 75797373-7126-4209-883d-41261ba211eb
md"""
## But what is geospatial data?

Very generally, **geo**spatial data is the combination of:

1. a **table** of attributes with
2. a geospatial **domain**

The concept of **table** is widespread. We support any table implementing the [Tables.jl](https://github.com/JuliaData/Tables.jl) interface, including named tuples, dataframes, SQL databases, Excel spreadsheets, Apache Arrow, etc.

By geospatial **domain** we mean any *discretization* of a region in physical space. We support any domain implementing the [Meshes.jl]() interface, including Cartesian grids, point sets, collections of geometries and general unstructured meshes.

Thanks to [Makie.jl](https://github.com/JuliaPlots/Makie.jl), we can visualize all these domains directly on the GPU:
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
	tab = (φ = rand(1000), κ = rand(1000), Sₒ = rand(1000))
	
	# domain with 1000 finite elements
	dom = CartesianGrid(10, 10, 10)
	
	# combine table with domain
	rock = georef(tab, dom)
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
	
	# assign log-area of triangles to mesh
	👤 = georef((area = log.(area.(ℳ)),), ℳ)
end

# ╔═╡ 9f1128e8-13ae-4334-bb9f-cc718e80d024
viz(👤, variable = :area)

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
	attr = (letters = length.(BRA.NAME_1),)
	
	# combine attributes with states
	🇧🇷 = georef(attr, domain(BRA))
	
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

> **Definition ([Mitchell 1997](http://www.cs.cmu.edu/~tom/mlbook.html)).** A computer program is said to **learn** from experience $\mathcal{E}$ with respect to some class of tasks $\mathcal{T}$ and performance measure $\mathcal{P}$, if its performance at tasks in $\mathcal{T}$, as measured by $\mathcal{P}$, improves with experience $\mathcal{E}$.

**Example:** classical statistical learning via empirical risk minimization

$$\hat{f} = \arg\min_{h\in\mathcal{H}} \mathbb{E}_{(\mathbf{x},y) \sim \Pr}\left[\mathcal{L}(y, h(\mathbf{x}))\right] \approx \frac{1}{n} \sum_{i=1}^n \mathcal{L}(y^{(i)},h(\mathbf{x}^{(i)}))$$

where $\mathcal{E}$ is a data set with $n$ samples, $\mathcal{P}$ is the empirical risk and $\mathcal{T}$ is a classical learning task such as regression or classification.

Assumptions which do **not** hold in geospatial applications:

1. training samples are i.i.d.
2. train and test distributions are equal
3. samples share a common support (i.e. volume)
"""

# ╔═╡ 0b1e0eb1-8188-49b1-ac38-a14b51e2f1b8
md"""
### Can't hold onto classical assumptions

Suppose we are given a crop classification model:

- **features ($$\mathbf{x}$$):** bands of satellite image
- **target ($$y$$):** crop type (soy, corn, ...)

and are asked to estimate its **generalization error** w.r.t. a *target domain* knowing that annotations of crop type are only available at a nearby *source domain*:
"""

# ╔═╡ 58bc4235-e61b-4c9a-8ede-3633e1c2f7a9
begin
	# attributes and coordinates x and y
	data = georef(CSV.File("data/agriculture.csv"), (:x, :y))
	
	# adjust scientific type of crop column
	Ω = MLJ.coerce(data, :crop => MLJ.Multiclass)
	
	# 20%/80% split along the (1, -1) direction
	Ωₛ, Ωₜ = split(Ω, 0.2, (1.0, -1.0))
	
	# visualize geospatial domains
	viz(domain(Ωₛ), elementcolor = :royalblue,
		axis = (xlabel = "longitude", ylabel = "latitude"))
	viz!(domain(Ωₜ), elementcolor = :gray)
	WGL.lines!([(270,660), (720,1140)],
		       linestyle = :dash, color = :black)
	WGL.annotations!(["source (𝒟ₛ)","target (𝒟ₜ)"],
		             [WGL.Point(500,1200), WGL.Point(100,300)],
		             textsize = 30, color = [:royalblue,:gray])
	WGL.current_figure()
end

# ╔═╡ df79f3a8-4d99-46a2-acd2-838f6e442526
begin
	# learning task: satellite bands → crop type
	𝓉 = ClassificationTask((:band1, :band2, :band3, :band4), :crop)
	
	# learning problem: train in Ωₛ and predict in Ωₜ
	𝓅 = LearningProblem(Ωₛ, Ωₜ, 𝓉)
	
	# learning model: decision tree
	𝓂 = @MLJ.load DecisionTreeClassifier pkg=DecisionTree
	
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
	ϵ = mean(ℒ(Ωₜ.crop, Ω̂ₜ.crop))
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
#### Result

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

Classical cross-validation (CV) relies heavily on the previously stated assumptions in order to:

1. hold-out points at **random** (red points)
2. learn model with remaining points (other colors)
3. estimate error using prediction at hold-out points

(Stone 1974, Geisser 1975)
"""

# ╔═╡ b6dd59bd-cb71-44b2-8a69-a0b04bb69664
LocalResource("assets/cv.png")

# ╔═╡ 952dce52-9950-4b66-9348-f804b2887fdf
md"""
#### Geostatistical validation

In order to avoid the super optimism of CV, the spatial statistics community proposed various alternative methods such as block cross-validation (BCV) and leave-ball-out (LBO).

These methods rely on **systematic partitions** of the source domain, which are often parameterized with a spatial correlation length $r > 0$.
"""

# ╔═╡ 8347ecd2-305d-4a81-9ba0-8fefc0d01db2
LocalResource("assets/bcv-lbo.png")

# ╔═╡ bf339a05-c886-4d28-9db8-ed03a0d6dce6
md"""
**GeoStats.jl** provides extremely efficient parallel implementations for all these methods. We were able to exploit multiple threads and other concepts from high-performance computing that are readily available in the language.

Thanks to **Julia's expressive power**, we can create advanced pipelines with just a few lines of code:
"""

# ╔═╡ 51c1ab1b-1984-4198-9ccd-a3e3810cbbc6
let
	# learning task: satellite bands → crop type
	𝓉 = ClassificationTask((:band1, :band2, :band3, :band4), :crop)
	
	# learning problem: train in Ωₛ and predict in Ωₜ
	𝓅 = LearningProblem(Ωₛ, Ωₜ, 𝓉)
	
	# learning model: decision tree
	𝒽 = MLJ.@load DecisionTreeClassifier pkg=DecisionTree
	
	# learning strategy: naive pointwise learning
	𝓁 = PointwiseLearn(𝒽())
	
	# loss function: misclassification loss
	ℒ = MisclassLoss()
	
	# block cross-validation with r = 30.
	bcv = BlockCrossValidation(30., loss = Dict(:crop => ℒ))
	
	# estimate of generalization error
	ϵ̂ = error(𝓁, 𝓅, bcv)[:crop]
	
	# train in Ωₛ and predict in Ωₜ
	Ω̂ₜ = solve(𝓅, 𝓁)
	
	# actual error of the model
	ϵ = mean(ℒ(Ωₜ.crop, Ω̂ₜ.crop))
	
	# display estimate and actual error
	(ϵ̂ = ϵ̂, ϵ = ϵ)
end

# ╔═╡ 1e8f1812-b7ad-42a8-b9f0-5616fae25f39
md"""
We support any learning model implementing the [MLJ.jl](https://github.com/alan-turing-institute/MLJ.jl) interface, which means all learning models from [scikit-learn](https://scikit-learn.org) and more:
"""

# ╔═╡ b54eb16c-aa1d-448e-823a-2a9ebe645205
MLJ.models() |> DataFrame

# ╔═╡ e1334779-0753-4fe1-90dd-25b638c832b2
md"""
### A new learning framework (Hoffimann et al. 2021)

More generally, we propose a new framework to advance this research:

>**Definition (GL).** Given a source geospatial domain $\mathcal{D}_s$ and a source learning task $\mathcal{T}_s$, a target geospatial domain $\mathcal{D}_t$ and a target learning task $\mathcal{T}_t$, **Geostatistical Learning** consists of learning $\mathcal{T}_t$ over $\mathcal{D}_t$ using the knowledge acquired while learning $\mathcal{T}_s$ over $\mathcal{D}_s$, assuming that the data in $\mathcal{D}_s$ and $\mathcal{D}_t$ are a single realization of the involved geospatial processes.
"""

# ╔═╡ 689a31fa-a7ff-42c3-abdb-4cce2365abd4
html"""
<p align="center">
    <img src="https://i.postimg.cc/d3BpsStQ/domains.png">
</p>
"""

# ╔═╡ 063407c4-4119-44e3-8f1c-9dc9c5aba5b1
md"""
Geostatistical Learning (or GL for short) is a **necessary change of perspective** in order to evolve existing statistical methodologies into new methodologies that are useful for geospatial data.

To clarify this statement, we share real-world examples in the next section that would be too difficult to express and solve with the classical framework.
"""

# ╔═╡ 15c012fc-30d1-419b-a644-b2246d392c61
md"""
#### Geostatistical clustering

Suppose we are given a micro-CT image such as the image by [Niu et al. 2020.](http://www.digitalrocksportal.org/projects/324), and are asked to segment it into homogeneous geobodies before proceeding with additional statistical analysis:
"""

# ╔═╡ 2fd86dfd-382a-4da3-b628-774e0f47f68e
begin
	μCT = load("data/muCT.tif")
	
	ℛ = georef((μCT = μCT,))
	
	viz(ℛ, variable = :μCT)
end

# ╔═╡ 90ef4204-7646-4b49-9fa0-f2be2edf10ad
md"""
The segmentation problem can sometimes be solved via unsupervised clustering. However, classical clustering methods such as K-means fail to produce *contiguous* clusters due to the noise in the image:
"""

# ╔═╡ 72900a48-74d3-4f53-8ada-75cf206f70b8
md"""
Number of clusters: $(@bind k PlutoUI.Slider(20:5:30, show_value=true))
"""

# ╔═╡ 2d266c6e-c6b9-4ec7-80ce-4cdbd51d046f
let
	# load classical K-means
	kmeans = @MLJ.load KMeans pkg=Clustering
	
	# convert color to floating point
	F = Float64.(μCT)
	
	# feature matrix (single column)
	X = reshape(F, length(F), 1)
	
	# instantiate machine
	mach = MLJ.machine(kmeans(k = k), X)
	
	# fit machine to data
	MLJ.fit!(mach)
	
	# cluster assignments
	c = MLJ.predict(mach)
	
	# georeference the assignments
	𝒞 = georef((c = reshape(c, size(μCT)),))
	
	# visualize clusters
	viz(𝒞, variable = :c)
end

# ╔═╡ 6117b062-4bf7-499a-9423-313b680f1177
md"""
We provide *geostatistical clustering* alternatives to address this issue. For example, we provide a generalization of Simple Linear Iterative Clustering (SLIC) that works with any geospatial data:
"""

# ╔═╡ a787f0dc-aeb0-4959-9f74-be9dc3ade1ad
begin
	# georeference the micro-CT image
	ℐ = georef((μCT = Float64.(μCT),))
	
	# request k = 45 contiguous clusters
	𝒞 = cluster(ℐ, SLIC(45, 0.07))
end;

# ╔═╡ eda5e7da-e51f-4fc9-800e-cb128e082513
let
	fig = WGL.Figure(resolution = (650,300))
	viz(fig[1,1], ℛ, variable = :μCT)
	viz(fig[1,2], 𝒞, variable = :cluster)
	WGL.linkaxes!(filter(x -> x isa WGL.Axis, fig.content)...)
	fig
end

# ╔═╡ Cell order:
# ╟─d088c772-c7b4-11eb-1796-7365ee1abe49
# ╟─995980f5-aa29-46a1-834e-9458c71f8914
# ╟─e02bb839-dbe3-4e05-ad48-e39020d605d1
# ╟─b85daaf1-d07b-44d0-9cef-cc19087d792d
# ╟─432d56b2-bd58-43bd-a9ed-0e8e42e2303b
# ╟─79e973b5-2cb2-4c3b-af9d-a44307fdd659
# ╟─1e4e92a3-549b-46ee-905d-3dc4c82b12de
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
# ╟─bf339a05-c886-4d28-9db8-ed03a0d6dce6
# ╠═51c1ab1b-1984-4198-9ccd-a3e3810cbbc6
# ╟─1e8f1812-b7ad-42a8-b9f0-5616fae25f39
# ╟─b54eb16c-aa1d-448e-823a-2a9ebe645205
# ╟─e1334779-0753-4fe1-90dd-25b638c832b2
# ╟─689a31fa-a7ff-42c3-abdb-4cce2365abd4
# ╟─063407c4-4119-44e3-8f1c-9dc9c5aba5b1
# ╟─15c012fc-30d1-419b-a644-b2246d392c61
# ╟─2fd86dfd-382a-4da3-b628-774e0f47f68e
# ╟─90ef4204-7646-4b49-9fa0-f2be2edf10ad
# ╟─72900a48-74d3-4f53-8ada-75cf206f70b8
# ╟─2d266c6e-c6b9-4ec7-80ce-4cdbd51d046f
# ╟─6117b062-4bf7-499a-9423-313b680f1177
# ╠═a787f0dc-aeb0-4959-9f74-be9dc3ade1ad
# ╟─eda5e7da-e51f-4fc9-800e-cb128e082513

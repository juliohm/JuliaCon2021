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
  		points = Point3.(x, y, z)
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

*Postdoctoral researcher in Industrial Mathematics*

Instituto de Matemática Pura e Aplicada
"""

# ╔═╡ 1e4e92a3-549b-46ee-905d-3dc4c82b12de
html"""
<img src="https://icm2018.impa.br/images/logo-impa.png" width=120>
"""

# ╔═╡ 5bd7385d-afa7-49ae-83a7-6879c48c770e
md"""

### In this talk...

- *What is **geo**statistical learning?*
- *What are the challenges?*
"""

# ╔═╡ fb6f8f9e-9735-4ed9-8f82-7dadadf656c1
md"""
##### Package:
"""

# ╔═╡ 432d56b2-bd58-43bd-a9ed-0e8e42e2303b
html"""
<img src="https://github.com/JuliaEarth/GeoStats.jl/blob/master/docs/src/assets/logo-text.svg?raw=true" width=350>
"""

# ╔═╡ 54717f0d-08e8-4549-9664-85e976736422
html"<button onclick='present()'>Start presentation</button>"

# ╔═╡ 2ff88b3a-9ed1-4495-93d7-75945b1ca9e7
md"""
## The two connotations of "Geo"

### Geo ≡ Earth

From Greek *geō-* the term **Geo** means Earth as in **Geo**logy, **Geo**physics and **Geo**sciences.

![earth](https://upload.wikimedia.org/wikipedia/commons/thumb/9/9d/MODIS_Map.jpg/1920px-MODIS_Map.jpg)

### Geo ≡ Geospatial

**Geo** can also mean Geospatial as in **Geo**spatial sciences and Computational **Geo**metry.

![sphere](https://as2.ftcdn.net/jpg/01/68/75/61/500_F_168756180_YaRuL7bc9DuAEIDBRMSLFOXs7Alxd4G2.jpg)

In this talk we adopt the second connotation and refer to **geo**statistics as the branch of statistics developed for **geo**spatial data.
"""

# ╔═╡ 75797373-7126-4209-883d-41261ba211eb
md"""
## What is geospatial data?

Very generally, (discrete) **geo**spatial data is the combination of:

1. a **table** of attributes (or features) with
2. a discretization of a geospatial **domain**

The concept of **table** is widespread. We support any table implementing the [Tables.jl](https://github.com/JuliaData/Tables.jl) interface, including named tuples, dataframes, SQL databases, Excel spreadsheets, Apache Arrow, etc.

Given a **domain** (or region) in physical space, we can discretize it into *elements*. We support any domain implementing the [Meshes.jl]() interface, including Cartesian grids, point sets, collections of geometries and general unstructured meshes.

Thanks to [Makie.jl](https://github.com/JuliaPlots/Makie.jl), we can visualize all these domains efficiently on the GPU:
"""

# ╔═╡ 2a196dad-ec23-4942-9e30-3f2876a65f75
let
	# Beethoven model by John Burkardt
	# https://people.sc.fsu.edu/~jburkardt/data/ply/ply.html
	👤 = loadply("data/beethoven.ply")
	
	# visualize geospatial domain
	viz(👤, showfacets = true)
end

# ╔═╡ d52c37cb-232a-49d3-a6af-ccad1405ddb8
md"""
## Examples of geospatial data

We introduce the **`georef`** function to combine tables with domains:

$$\textbf{georef}\text{(table, domain)} \mapsto \text{data}$$

And the functions **`values`** and **`domain`** to recover the table and domain from the data:

$$\begin{align*}\textbf{values}\text{(data)} &\mapsto \text{table}\\ \textbf{domain}\text{(data)} &\mapsto \text{domain}\end{align*}$$
"""

# ╔═╡ df7dc253-1558-4890-9a7c-1844f342beae
md"""
### 3D grid data
"""

# ╔═╡ 89bb5a1c-d905-4b3b-81ff-343dbf14d306
begin
	# table with 1000 values of φ and κ and Sₒ
	tab = (φ = rand(1000), κ = rand(1000), Sₒ = rand(1000))
	
	# domain with 1000 hexahedron elements
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
	
	# georeference 2D array on Cartesian grid
	city = georef((color = img,))
end

# ╔═╡ ea422ea7-42ef-4245-8767-d6631cca3ed3
viz(city, variable = :color)

# ╔═╡ 7df28235-efaf-42f9-9943-c7d452dfd347
md"""
### Map data
"""

# ╔═╡ 330a3630-38fa-4948-9498-c336fb0dc8f5
begin
	# download Brazil map data
	BRA = GeoTables.gadm("BRA", children = true)

	# table with state names and their lengths
	attributes = (state = BRA.NAME_1, strlen = length.(BRA.NAME_1))
	
	# combine attributes with states
	🇧🇷 = georef(attributes, domain(BRA))
end

# ╔═╡ 472ba4c4-4d03-48f8-81ba-0ebe9b78d635
viz(🇧🇷, variable = :strlen, showfacets = true, decimation = 0.02)

# ╔═╡ dbb62666-ea4b-4715-bb09-a9fa30326e85
md"""
### Mesh data
"""

# ╔═╡ a130112d-0a93-4ec6-b787-6fbc9b669b03
let
	# fox skull model by Artec Group Inc.
	# https://www.artec3d.com/3d-models/fox-skull
	fox = loadply("data/fox.ply")
	
	# compute area of elements
	tab = (area = log.(area.(fox)),)
	
	# georeference areas on mesh
	ℳ = georef(tab, fox)
	
	# visualize mesh with colors
	viz(ℳ, variable = :area)
end

# ╔═╡ 9c631159-fc8a-4b31-b564-85de6bdd9f2c
md"""
Thanks to **Julia's multiple-dispatch**, we provide a **clean user interface** that can combine very diverse types of tables and geospatial domains.
"""

# ╔═╡ 6f07a125-7801-4f53-8372-39a2e34d87be
md"""
## Learning from geospatial data

### The classical learning framework

Recall the definition of well-posed learning problems:

> **Definition ([Mitchell 1997](http://www.cs.cmu.edu/~tom/mlbook.html)).** A computer program is said to **learn** from experience $\mathcal{E}$ with respect to some class of tasks $\mathcal{T}$ and performance measure $\mathcal{P}$, if its performance at tasks in $\mathcal{T}$, as measured by $\mathcal{P}$, improves with experience $\mathcal{E}$.

**Example:** classical statistical learning via empirical risk minimization

$$\hat{f} = \arg\min_{h\in\mathcal{H}} \mathbb{E}_{(\mathbf{x},y) \sim \Pr}\left[\mathcal{L}(y, h(\mathbf{x}))\right] \approx \frac{1}{n} \sum_{i=1}^n \mathcal{L}(y^{(i)},h(\mathbf{x}^{(i)}))$$

where $\mathcal{E}$ is a data set with $n$ samples, $\mathcal{P}$ is the empirical risk and $\mathcal{T}$ is a classical learning task such as regression or classification.

#### Classical assumptions

1. training samples are i.i.d.
2. train and test distributions are equal
3. samples share a common support (i.e. volume)

Assumptions which do **not** hold in **geo**spatial applications.
"""

# ╔═╡ 0b1e0eb1-8188-49b1-ac38-a14b51e2f1b8
md"""
## Example I - Why the error is so high?

Suppose we are given a **classification model for pixels** of an image:

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

1. subdivide the *source domain* $\mathcal{D}_s$ into k random folds
2. average the empirical risk over the folds

$$\hat\epsilon(h) = \frac{1}{k} \sum_{j=1}^k \frac{1}{|\mathcal{D}_s^{(j)}|} \int_{\mathcal{D}_s^{(j)}} \mathcal{L}(y_\mathbf{u}, h(\mathbf{x}_\mathbf{u}))d\mathbf{u}$$
"""

# ╔═╡ 0cc70b6e-8f0c-44ac-a83a-2d82e4db3348
LocalResource("assets/cvsetup.png")

# ╔═╡ 8b05bd01-1ba7-4f8a-80cc-bdc5a69024f9
md"""
### Result

The model's estimated error is **$(round(ϵ̂cv*100, digits=2))%** misclassification. However, when we deploy the model in the *target domain* $\mathcal{D}_t$ the error is much higher with **$(round(ϵ*100, digits=2))%** of the samples misclassified.

The error is **$(round(ϵ / ϵ̂cv, digits=2))** times higher than expected.
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
## What happened?

Cross-validation (CV) relies heavily on the classical assumptions in order to:

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

In order to avoid the super optimism of CV, the geostatistics community proposed various alternative methods such as block cross-validation (BCV) and leave-ball-out (LBO).

These methods rely on **systematic partitions** of the source domain, which are often parameterized with a spatial correlation length $r > 0$.
"""

# ╔═╡ 8347ecd2-305d-4a81-9ba0-8fefc0d01db2
LocalResource("assets/bcv-lbo.png")

# ╔═╡ bf339a05-c886-4d28-9db8-ed03a0d6dce6
md"""
We provide efficient **parallel implementations** for all these methods:
"""

# ╔═╡ 51c1ab1b-1984-4198-9ccd-a3e3810cbbc6
let
	# learning task: bands → crop type
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
and support any learning model implementing the [MLJ.jl](https://github.com/alan-turing-institute/MLJ.jl) interface, which means all learning models from [scikit-learn](https://scikit-learn.org) and more:
"""

# ╔═╡ b54eb16c-aa1d-448e-823a-2a9ebe645205
MLJ.models() |> DataFrame

# ╔═╡ 15c012fc-30d1-419b-a644-b2246d392c61
md"""
## Example II - Why the clusters are everywhere?

Suppose we are given a micro-CT image such as the image by [Niu et al. 2020.](http://www.digitalrocksportal.org/projects/324), and are asked to segment it into homogeneous geobodies before proceeding with additional statistical analysis:
"""

# ╔═╡ 2fd86dfd-382a-4da3-b628-774e0f47f68e
begin
	# load micro-CT image
	μCT = load("data/muCT.tif")
	
	# georeference image
	ℛ = georef((μCT = μCT,))
	
	# visualize image
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
### Geostatistical clustering

We provide *geostatistical clustering* methods to address this issue such as a generalization of Simple Linear Iterative Clustering (SLIC) that works with any geospatial data, not just images:
"""

# ╔═╡ a787f0dc-aeb0-4959-9f74-be9dc3ade1ad
begin
	# georeference the micro-CT image
	ℐ = georef((μCT = Float64.(μCT),))
	
	# request k = 45 contiguous clusters
	𝒞 = cluster(ℐ, SLIC(45, 0.07))
end

# ╔═╡ eda5e7da-e51f-4fc9-800e-cb128e082513
let
	fig = WGL.Figure(resolution = (650,300))
	viz(fig[1,1], ℛ, variable = :μCT)
	viz(fig[1,2], 𝒞, variable = :cluster)
	WGL.linkaxes!(filter(x -> x isa WGL.Axis, fig.content)...)
	fig
end

# ╔═╡ 9ccd7061-ebac-4a2f-bca3-3e54e4566bfe
md"""
Thanks to **Julia's high-performance**, our implementations scale.
"""

# ╔═╡ e1334779-0753-4fe1-90dd-25b638c832b2
md"""
## Geostatistical learning (Hoffimann et al 2021)

The previous examples illustrate the value of statistical learning methodologies developed specifically for geospatial data. We propose a new learning framework to advance this research:

[Hoffimann et al. 2021. Geostatistical Learning: Challenges and Opportunities](https://arxiv.org/abs/2102.08791)

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
We argue that **geostatistical learning** is a **necessary change of perspective** to advance the field. Examples like the following example with non-trivial geospatial domains are too difficult to express and/or solve properly within the classical learning framework.
"""

# ╔═╡ 2190d7f4-fd0b-4c8f-ad9c-cb960b158362
md"""
## More advanced example

Suppose we are given an airplane and a helicopter model, and are asked to learn the distribution of [wind-chill index](https://en.wikipedia.org/wiki/Wind_chill#Original_model) (WCI) on the surface of these models given measurements of wind velocity $v$ at specific points (e.g. pitot tubes) and a reference air temperature $T_a$:

$$WCI = (10\sqrt v - v + 10.5) \cdot (33 - T_a)$$

Let's assume that the airplane flies at moderate speeds and that we can interpolate the measurements of wind velocity with *geostatistical estimation*:
"""

# ╔═╡ 303cbee7-ad48-4cf2-9808-77016b0f6833
begin
	# airplane model by John Burkardt
	# https://people.sc.fsu.edu/~jburkardt/data/ply/ply.html
	✈ = loadply("data/airplane.ply")
	
	# wind velocity on two sensors on the wings
	𝒮 = georef((v=[1.0, 2.0],), [(1300.0,600.0,50.0), (500.0,600.0,50.0)])
	
	# geostatistical estimation problem
	ℯ = EstimationProblem(𝒮, ✈, :v)
	
	# pick one of the estimation solvers
	𝓀 = Kriging(:v => (variogram=GaussianVariogram(range=300.0),))
	
	# interpolate wind velocity on the airplane
	airplane = solve(ℯ, 𝓀)
	
	# visualize interpolation
	viz(airplane, variable = :v)
end

# ╔═╡ 6cba8ce5-48ef-4fd2-91bb-393f143742e7
md"""
Let's assume that we are more uncertain about the wind velocity on the helicopter due to intense vorticity. In this case, we simulate multiple realizations with *geostatistical simulation*:
"""

# ╔═╡ 2b9387d9-0daf-46b9-95ff-3effb1d544ef
begin
	# helicopter model by John Burkardt
	# https://people.sc.fsu.edu/~jburkardt/data/ply/ply.html
	🚁 = loadply("data/helicopter.ply")
	
	# geostatistical simulation problem
	𝓈 = SimulationProblem(🚁, :v => Float64, 3)
	
	# pick one of the simulation solvers
	ℊ = LUGS(:v => (variogram=GaussianVariogram(range=2.0),))
	
	# simulate wind velocity on the helicopter
	ensemble = solve(𝓈, ℊ)
	
	# initialize visualization
	fig = WGL.Figure(resolution = (650, 300))
	
	# visualize realizations in the ensemble
	for i in 1:3
		viz(fig[1,i], ensemble[i], variable = :v)
	end
	
	# display visualization
	WGL.current_figure()
end

# ╔═╡ 6caa0fb1-f028-4dad-9db8-5a528c6d1c62
md"""
Let's assume that there exists a reliable physics-based simulation model for the WCI on the airplane:
"""

# ╔═╡ 32f95691-e48f-4b49-94a5-d576d60e493a
begin
	# air temperature in degrees Celsius
	Tₐ = 22.0
	
	# wind velocity on airplane
	v  = airplane.v
	
	# some expensive physics-based simulation
	WCI = @. (10*√v - v + 10.5) * (33 - Tₐ)
	
	# georeference results of simulation
	ℳₛ = georef((v = v, WCI = WCI), ✈)
end;

# ╔═╡ 626b66b8-fd3a-45f3-966f-8c9be2bc98c4
md"""
Finally, let's try to predict the WCI on the helicopter using the results of the physics-based simulation that are only available for the airplane:
"""

# ╔═╡ d6a1ef20-ce99-4732-adc5-8a87613654b1
let	
	# regression task v → WCI
	𝓉 = RegressionTask(:v, :WCI)
	
	# learning model
	𝒽 = MLJ.@load DecisionTreeRegressor pkg=DecisionTree
	
	# learning strategy
	𝓁 = PointwiseLearn(𝒽())
	
	# initialize visualization
	fig = WGL.Figure(resolution = (650, 300))
	
	# solve and visualize prediction on each realization
	for i in 1:3
		# target realization
		ℳₜ = ensemble[i]
	
		# learning problem
		𝓅 = LearningProblem(ℳₛ, ℳₜ, 𝓉)
	
		# solve the problem
		ℳ̂ₜ = solve(𝓅, 𝓁)
	
		# visualize prediction
		viz(fig[1,i], ℳ̂ₜ, variable = :WCI)
	end
	
	# display visualization
	WGL.current_figure()
end

# ╔═╡ a076baa5-6442-4f27-920d-5788b0b23fa6
md"""
## Challenges and Opportunities

We have many challenges to address:

- Efficient geostatistical modeling with **geodesics**
- Adequate correlation structures on **manifolds**
- Models developed specifically for the **sphere**
- Many more challenges...
"""

# ╔═╡ fad8f51c-8dcf-48b1-b7ed-8cb3b45da7ad
html"""
<img src="https://upload.wikimedia.org/wikipedia/commons/a/a4/Geodesic_lines_in_a_sphere_%28closed_curved_space%29.png" width=300>
"""

# ╔═╡ c69da448-f49d-4448-844e-82f612f437e3
md"""
and research opportunities in computational **geo**metry and **geo**statistics.
"""

# ╔═╡ 6340be6f-a2ee-4aa8-9b42-338b52be9a22
md"""
### Join our community

If you share the feeling that **geo**statistics could be more widely used in the industry, come join us. Your help will make a difference.

#### Getting started

Subscribe to the [GeoStats.jl](https://github.com/JuliaEarth/GeoStats.jl) tutorials on YouTube:
"""

# ╔═╡ db6b5401-629d-4ebc-8736-3fdf1ec07363
html"""
<iframe width="560" height="315" src="https://www.youtube.com/embed/videoseries?list=PLsH4hc788Z1f1e61DN3EV9AhDlpbhhanw" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
"""

# ╔═╡ d3ee2dde-e678-435d-99bf-99852d4f88e6
md"""
and join the community channels:

[![Gitter](https://img.shields.io/badge/chat-on%20gitter-bc0067?style=flat-square)](https://gitter.im/JuliaEarth/GeoStats.jl)
[![Zulip](https://img.shields.io/badge/chat-on%20zulip-9cf?style=flat-square)](https://julialang.zulipchat.com/#narrow/stream/276201-geostats.2Ejl)
"""

# ╔═╡ efe21def-6feb-4bd5-8bdb-e74fadf1c919
md"""
##### LINKS

This notebook is available online: [https://github.com/juliohm/juliacon2021](https://github.com/juliohm/juliacon2021)

I am happy to connect: [julio.hoffimann@impa.br](mailto:julio.hoffimann@impa.br)
"""

# ╔═╡ Cell order:
# ╟─d088c772-c7b4-11eb-1796-7365ee1abe49
# ╟─995980f5-aa29-46a1-834e-9458c71f8914
# ╟─e02bb839-dbe3-4e05-ad48-e39020d605d1
# ╟─b85daaf1-d07b-44d0-9cef-cc19087d792d
# ╟─79e973b5-2cb2-4c3b-af9d-a44307fdd659
# ╟─1e4e92a3-549b-46ee-905d-3dc4c82b12de
# ╟─5bd7385d-afa7-49ae-83a7-6879c48c770e
# ╟─fb6f8f9e-9735-4ed9-8f82-7dadadf656c1
# ╟─432d56b2-bd58-43bd-a9ed-0e8e42e2303b
# ╟─54717f0d-08e8-4549-9664-85e976736422
# ╟─2ff88b3a-9ed1-4495-93d7-75945b1ca9e7
# ╟─75797373-7126-4209-883d-41261ba211eb
# ╠═2a196dad-ec23-4942-9e30-3f2876a65f75
# ╟─d52c37cb-232a-49d3-a6af-ccad1405ddb8
# ╟─df7dc253-1558-4890-9a7c-1844f342beae
# ╠═89bb5a1c-d905-4b3b-81ff-343dbf14d306
# ╠═fa553a82-6f35-4d6e-845c-a97cd54be7f6
# ╟─706e294d-ce1b-4be1-b1cf-00a27bc3ede3
# ╠═916d8af0-4065-4e6f-bf99-4d473523eba8
# ╠═ea422ea7-42ef-4245-8767-d6631cca3ed3
# ╟─7df28235-efaf-42f9-9943-c7d452dfd347
# ╠═330a3630-38fa-4948-9498-c336fb0dc8f5
# ╠═472ba4c4-4d03-48f8-81ba-0ebe9b78d635
# ╟─dbb62666-ea4b-4715-bb09-a9fa30326e85
# ╠═a130112d-0a93-4ec6-b787-6fbc9b669b03
# ╟─9c631159-fc8a-4b31-b564-85de6bdd9f2c
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
# ╟─15c012fc-30d1-419b-a644-b2246d392c61
# ╟─2fd86dfd-382a-4da3-b628-774e0f47f68e
# ╟─90ef4204-7646-4b49-9fa0-f2be2edf10ad
# ╟─72900a48-74d3-4f53-8ada-75cf206f70b8
# ╟─2d266c6e-c6b9-4ec7-80ce-4cdbd51d046f
# ╟─6117b062-4bf7-499a-9423-313b680f1177
# ╠═a787f0dc-aeb0-4959-9f74-be9dc3ade1ad
# ╟─eda5e7da-e51f-4fc9-800e-cb128e082513
# ╟─9ccd7061-ebac-4a2f-bca3-3e54e4566bfe
# ╟─e1334779-0753-4fe1-90dd-25b638c832b2
# ╟─689a31fa-a7ff-42c3-abdb-4cce2365abd4
# ╟─063407c4-4119-44e3-8f1c-9dc9c5aba5b1
# ╟─2190d7f4-fd0b-4c8f-ad9c-cb960b158362
# ╠═303cbee7-ad48-4cf2-9808-77016b0f6833
# ╟─6cba8ce5-48ef-4fd2-91bb-393f143742e7
# ╠═2b9387d9-0daf-46b9-95ff-3effb1d544ef
# ╟─6caa0fb1-f028-4dad-9db8-5a528c6d1c62
# ╠═32f95691-e48f-4b49-94a5-d576d60e493a
# ╟─626b66b8-fd3a-45f3-966f-8c9be2bc98c4
# ╠═d6a1ef20-ce99-4732-adc5-8a87613654b1
# ╟─a076baa5-6442-4f27-920d-5788b0b23fa6
# ╟─fad8f51c-8dcf-48b1-b7ed-8cb3b45da7ad
# ╟─c69da448-f49d-4448-844e-82f612f437e3
# ╟─6340be6f-a2ee-4aa8-9b42-338b52be9a22
# ╟─db6b5401-629d-4ebc-8736-3fdf1ec07363
# ╟─d3ee2dde-e678-435d-99bf-99852d4f88e6
# ╟─efe21def-6feb-4bd5-8bdb-e74fadf1c919

# 📘 广州坡度等级分析项目 - 脚本详细讲解

本项目旨在通过对广州地区数字高程模型（DEM）数据进行坡度分析，结合水系缓冲区和土壤适宜性评分，实现空间环境的综合评价与地图可视化。以下内容详细解释 `scripts/02_slope_map_guangzhou.R` 及相关脚本的每一步功能，帮助学习者理解坡度分析的完整流程。

---

## Step 1: 🧰 使用到的 R 包

以下 R 包是本项目所依赖的核心工具：

- **terra**：处理栅格数据（DEM、坡度、重分类）
- **sf**：读取和处理矢量数据（shapefile）
- **tmap**：地图制图（静态或交互）
- **tidyverse**：数据处理、管道操作等

---

## Step 2: 📂 数据读取部分

```r
# 读取水系矢量线、广州边界和数字高程模型（DEM）
river <- st_read("data/gzwater/gzwater.shp")
gz_boundary <- st_read("data/gz_boundary/gzbianjie.shp")
dem <- rast("data/dem_250m/dem_250m.tif")
```

---

## Step 3: 🗺️ 水系缓冲区构建

```r
# 构建水系的 50m 和 100m 缓冲区，并计算环状缓冲区
riverBuffer1 <- st_buffer(river, dist = 50) %>% st_union()
riverBuffer2 <- st_buffer(river, dist = 100) %>% st_union()
river_ring <- st_difference(riverBuffer2, riverBuffer1)
```

---

## Step 4: 🧭 DEM 裁剪与坡度计算

```r
# 将全国 DEM 裁剪为广州区域，并计算坡度（单位：度）
dem_gz <- mask(crop(dem, vect(gz_boundary)), vect(gz_boundary))
slope <- terrain(dem_gz, v = "slope", unit = "degrees")
```

---

## Step 5: 🧮 坡度等级重分类

```r
# 将连续坡度值划分为 6 个等级，便于可视化和后续分析
rcl <- matrix(c(
  0, 2.5, 10,
  2.5, 5, 9,
  5, 7.5, 8,
  7.5, 10, 7,
  10, 15, 6,
  15, 43, 2
), ncol = 3, byrow = TRUE)
slope_reclass <- classify(slope, rcl)
```

---

## Step 6: 🖼️ 地图制图与输出

```r
# 构建坡度等级地图：含图例、指北针、比例尺、经纬度坐标等
slope_plot <- tm_shape(slope_reclass) +
  tm_raster(...) +
  tm_shape(gz_boundary) + tm_borders() +
  tm_compass() + tm_scale_bar() + tm_graticules() + tm_layout(...)
```

```r
# 导出地图为高分辨率 PNG 文件
tmap_save(slope_plot, "output/maps/slope_class_map_guangzhou.png")
```

```r
# 保存坡度原始值和重分类栅格为 GeoTIFF 文件
writeRaster(slope, "output/rasters/slope_guangzhou.tif")
writeRaster(slope_reclass, "output/rasters/slope_class.tif")
```

---

## Step 7: ✅ 模块总结

- 该脚本完整展示了从 DEM → 坡度计算 → 缓冲区叠加 → 地图可视化的全过程。
- 适用于初学者学习地理空间分析与地图自动化制作。

---

## Step 8: 🌱 土壤适宜性评分分析（`02_soil_analysis.R`）

### Step 8.1: 📂 数据读取部分

```r
# 读取土壤矢量图层，使用已有 DEM 栅格作为参考对齐范围与分辨率
soil <- st_read("data/soil/GZsoil.shp")
dem_ras <- rast("output/rasters/slope_class.tif")
```

---

### Step 8.2: 🧮 土壤评分与重分类

```r
# 合并专家打分表
soil_score_tbl <- tibble(DOMSOIL_clean = ..., score = ...)
soil <- left_join(soil, soil_score_tbl, by = "DOMSOIL_clean")

# 栅格化
soil_raster <- rasterize(vect(soil), dem_ras, field = "score")

# 分五级等级：Very Poor ~ Very Good
rcl <- matrix(...); soil_class_5cat <- classify(soil_raster, rcl)
```

---

### Step 8.3: 🖼️ 地图输出与保存

```r
# 输出带图例、指北针、比例尺和边界的静态地图
soil_plot <- tm_shape(soil_class_5cat) + tm_raster(...) + ...
tmap_save(soil_plot, "output/maps/soil_classification_map.png")
```

```r
# 保存评分结果为 GeoTIFF 文件
writeRaster(soil_class_5cat, "output/rasters/soil_class_5cat.tif")
```

---

### Step 8.4: ✅ 模块总结

- 该脚本展示了基于 AHP 框架的土壤适宜性空间评分方法。
- 可直接用于垃圾填埋场等空间选址项目。

---

## Step 9: 🌊 水体距离适宜性评分分析（`02c_water_score_distance_A.R`）

---

### Step 9.1: 📂 数据读取与投影

```r
# 读取水体矢量、广州边界以及基础 DEM
water <- st_read("data/gzwater/gzwater.shp")
dem_250 <- rast("output/rasters/slope_class.tif")
gz_boundary <- st_read("data/gz_boundary/gzbianjie.shp")

# 投影到米制坐标系 EPSG:32649
dem_250 <- project(dem_250, "EPSG:32649")
water <- water %>% st_simplify(dTolerance = 100, preserveTopology = FALSE) %>%
  st_transform("EPSG:32649")
gz_boundary <- st_transform(gz_boundary, "EPSG:32649")
```

---

### Step 9.2: 🧮 水体缓冲、栅格化与距离计算

```r
# 对水体缓冲 10 米，栅格化（值为 1）
water_buf <- st_buffer(water, 10)
water_ras <- rasterize(vect(water_buf), dem_250, field = 1, touches = TRUE)

# 将水体外区域设为 NA
src <- classify(water_ras, cbind(0, NA))
src[water_ras == 1] <- 1

# 基于栅格计算每一点到最近水体的欧式距离
dist_ras <- distance(src)
```

---

### Step 9.3: ✂️ 剪裁到广州范围

```r
# 裁剪和掩膜到广州市行政边界
dist_ras <- mask(crop(dist_ras, vect(gz_boundary)), vect(gz_boundary))
```

---

### Step 9.4: 🏷️ 官方 6 档打分标准

```r
# 按距离重新分类为 6 个等级（分数：0–10）
rcl <- matrix(c(
  0,   50,   0,
  50, 100,   2,
  100,150,   4,
  150,200,   6,
  200,250,   8,
  250,Inf,  10
), ncol = 3, byrow = TRUE)

score_ras <- classify(dist_ras, rcl)
writeRaster(score_ras, "output/rasters/water_score_125m.tif", overwrite = TRUE)
```

---

### Step 9.5: 🖼️ 地图制作与保存

```r
tmap_mode("plot")

scale_cat <- tm_scale_categorical(
  values = c("#4F9DB8", "#C8E547", "#E649D8", "#D47A5D", "#2E2F93", "#00A087"),
  labels = c("0", "2", "4", "6", "8", "10")
)
leg_col <- tm_legend(title = "River", frame = FALSE)

water_map <- tm_shape(score_ras) +
  tm_raster(col.scale = scale_cat, col.legend = leg_col) +
  tm_shape(gz_boundary) + tm_borders(lwd = 1.2) +
  tm_compass(type = "arrow", position = c("left", "top")) +
  tm_scalebar(position = c("right", "bottom")) +
  tm_title("Water-Distance Suitability (125 m, Official 6-Class)") +
  tm_layout(
    frame = TRUE,
    inner.margins = c(0.08, 0.08, 0.08, 0.08),
    outer.margins = c(0.02, 0.02, 0.02, 0.02)
  )

tmap_save(water_map, "output/maps/water_score_125m.png", width = 1920, height = 1080, dpi = 300)
```

---

### Step 9.6: ✅ 模块总结

- 采用官方推荐的水体距离适宜性评分标准（0–10分，6等级）。
- 统一以 125 m 分辨率输出，图例配色鲜明。
- 为后续 MCDA 综合适宜性分析提供可靠输入层。

---
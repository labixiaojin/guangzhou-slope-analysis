# 📘 广州坡度等级分析项目 - 脚本详细讲解

本文档详细解释 `scripts/02_slope_map_guangzhou.R` 中每一步的功能，帮助学习者理解坡度分析的完整流程。

---

## 🧰 使用到的 R 包

- **terra**：处理栅格数据（DEM、坡度、重分类）
- **sf**：读取和处理矢量数据（shapefile）
- **tmap**：地图制图（静态或交互）
- **tidyverse**：数据处理、管道操作等

---

## 📂 数据读取部分

```r
river <- st_read("data/gzwater/gzwater.shp")
gz_boundary <- st_read("data/gz_boundary/gzbianjie.shp")
dem <- rast("data/dem_250m/dem_250m.tif")
```

- 读取水系矢量线、广州边界、数字高程模型（DEM）。

---

## 🗺️ 水系缓冲区构建

```r
riverBuffer1 <- st_buffer(river, dist = 50) %>% st_union()
riverBuffer2 <- st_buffer(river, dist = 100) %>% st_union()
river_ring <- st_difference(riverBuffer2, riverBuffer1)
```

- 构建水系的 50m 和 100m 缓冲区，并计算环状缓冲区。

---

## 🧭 DEM 裁剪与坡度计算

```r
dem_gz <- mask(crop(dem, vect(gz_boundary)), vect(gz_boundary))
slope <- terrain(dem_gz, v = "slope", unit = "degrees")
```

- 将全国 DEM 裁剪为广州区域，并计算坡度（单位：度）。

---

## 🧮 坡度等级重分类

```r
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

- 将连续坡度值划分为 6 个等级，便于可视化和后续分析。

---

## 🖼️ 地图制图与输出

```r
slope_plot <- tm_shape(slope_reclass) +
  tm_raster(...) +
  tm_shape(gz_boundary) + tm_borders() +
  tm_compass() + tm_scale_bar() + tm_graticules() + tm_layout(...)
```

- 构建坡度等级地图：含图例、指北针、比例尺、经纬度坐标等。

```r
tmap_save(slope_plot, "output/maps/slope_class_map_guangzhou.png")
```

- 导出地图为高分辨率 PNG 文件。

```r
writeRaster(slope, "output/rasters/slope_guangzhou.tif")
writeRaster(slope_reclass, "output/rasters/slope_class.tif")
```

- 保存坡度原始值和重分类栅格为 GeoTIFF 文件。

---

## ✅ 总结

该脚本完整展示了从 DEM → 坡度计算 → 缓冲区叠加 → 地图可视化的全过程，适用于初学者学习地理空间分析与地图自动化制作。
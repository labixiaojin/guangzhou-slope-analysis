# ──────────────────────────────────────────────────────────────────
#  Water-Distance Suitability  · 50 m 解析度   (terra + tmap v4)
#  -- 官方 6 档打分 0-2-4-6-8-10，颜色按示例自定义
# ──────────────────────────────────────────────────────────────────

# —— 0. 清理环境 —— ------------------------------------------------
rm(list = ls())
if (!is.null(dev.list())) dev.off()
gc(); cat("\014")                                    # 清屏（RStudio 有效）

# —— 0.1 设置工作目录 —— -------------------------------------------
setwd("/Users/rui/Desktop/guangzhou-slope-analysis") # ← 请按实际路径修改

# —— 0.2 加载 R 包 —— ---------------------------------------------
library(terra)   # 栅格分析
library(sf)      # 矢量数据
library(tmap)    # 地图制图 (v4)
library(dplyr)   # 数据管道

# —— 0.3 文件路径 —— -----------------------------------------------
water_path <- "data/gzwater/gzwater.shp"            # 水系（线）
dem_path   <- "output/rasters/slope_class.tif"      # 250 m DEM
gz_path    <- "data/gz_boundary/gzbianjie.shp"      # 广州市边界

# ──────────────────────────────────────────────────────────────────
# 1. 读取 DEM -> 投影到 UTM 49N (EPSG:32649) -> 细分分辨率
# ──────────────────────────────────────────────────────────────────
dem_250 <- terra::rast(dem_path) |>
  terra::project("EPSG:32649")             # 投影到米制

# ★ 细分 DEM：250 m → 50 m  (fact = 5) ★
dem <- terra::disagg(dem_250, fact = 5)             # 复制最近值即可
# 若只需 125 m，请改 fact = 2

# 开启多线程以加速 distance()
terra::terraOptions(progress = TRUE,
                    threads   = parallel::detectCores())

# ──────────────────────────────────────────────────────────────────
# 2. 读取水体 → 简化 → 投影 → 10 m 缓冲 → 栅格化 (1 = 水体, NA = 其他)
# ──────────────────────────────────────────────────────────────────
water <- sf::st_read(water_path, quiet = TRUE) |>
  sf::st_simplify(dTolerance = 100, preserveTopology = FALSE) |>
  sf::st_transform("EPSG:32649")

water_buf <- sf::st_buffer(water, 10)               # 10 m 细缓冲
water_ras <- terra::rasterize(terra::vect(water_buf), dem,
                              field = 1, touches = TRUE)

src <- terra::classify(water_ras, cbind(0, NA))     # 非水体设 NA
src[water_ras == 1] <- 1                            # 水体像元 = 1

# ──────────────────────────────────────────────────────────────────
# 3. 计算到最近水体的距离（米） —— 分辨率 50 m，耗时数分钟
# ──────────────────────────────────────────────────────────────────
dist_ras <- terra::distance(src)

# ──────────────────────────────────────────────────────────────────
# 4. 剪裁 / 掩膜到广州市行政边界
# ──────────────────────────────────────────────────────────────────
gz_boundary <- sf::st_read(gz_path, quiet = TRUE) |>
  sf::st_transform("EPSG:32649")

dist_ras <- terra::crop(dist_ras, terra::vect(gz_boundary)) |>
  terra::mask(terra::vect(gz_boundary))

# ──────────────────────────────────────────────────────────────────
# 5. 官方 6 档距离 → 适宜性分数 0-10
# ──────────────────────────────────────────────────────────────────
rcl <- matrix(c(
  0,   50,   0,   # <50 m      → 0
  50,  100,   2,   # 50-100 m   → 2
  100,  150,   4,   # 100-150 m  → 4
  150,  200,   6,   # 150-200 m  → 6
  200,  250,   8,   # 200-250 m  → 8
  250,   Inf, 10    # >250 m     →10
), ncol = 3, byrow = TRUE)

score_ras <- terra::classify(dist_ras, rcl)
terra::writeRaster(score_ras,
                   "output/rasters/water_score_50m.tif",
                   overwrite = TRUE)

# ──────────────────────────────────────────────────────────────────
# 6. 制图 (tmap v4) —— 官方风格颜色 + 分数图例
# ──────────────────────────────────────────────────────────────────
tmap_mode("plot")                                   # 静态绘图

scale_cat <- tm_scale_categorical(
  values = c("#4F9DB8",  # 青蓝   对应 0
             "#C8E547",  # 黄绿   对应 2
             "#E649D8",  # 亮紫   对应 4
             "#D47A5D",  # 砖橙   对应 6
             "#2E2F93",  # 深蓝   对应 8
             "#00A087"), # 墨绿   对应10
  labels = c("0", "2", "4", "6", "8", "10")
)
leg_col <- tm_legend(title = "River", frame = FALSE) # 去掉图例边框

water_map <- tm_shape(score_ras) +
  tm_raster(col.scale = scale_cat, col.legend = leg_col) +
  tm_shape(gz_boundary) + tm_borders(lwd = 1.2) +
  tm_compass(type = "arrow", position = c("left", "top")) +
  tm_scalebar(position = c("right", "bottom")) +
  tm_title("Water-Distance Suitability (50 m, Official 6-Class)") +
  tm_layout(frame          = TRUE,
            inner.margins  = c(0.08, 0.08, 0.08, 0.08),
            outer.margins  = c(0.02, 0.02, 0.02, 0.02))

water_map   # 显示

# —— 导出 PNG —— ---------------------------------------------------
dir.create("output/maps", recursive = TRUE, showWarnings = FALSE)
tmap_save(water_map,
          "output/maps/water_score_50m.png",
          width = 1920, height = 1080, dpi = 300)


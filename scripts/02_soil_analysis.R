# —— 初始化环境 —— 
rm(list = ls())                         # 清空所有变量
if (!is.null(dev.list())) dev.off()     # 若有图形设备，则关闭
gc()                                    # 手动触发内存回收
cat("\014")                             # 清空控制台（仅 RStudio 有效）

# —— 设置工作目录（确保所有相对路径都从此出发） ——
setwd("/Users/rui/Desktop/guangzhou-slope-analysis")

# —— 加载所需 R 包 ——
library(sf)        # 处理矢量数据
library(terra)     # 处理栅格数据
library(dplyr)     # 数据整理（管道、mutate、join）
library(tibble)    # 创建干净的数据表
library(tmap)      # 制图工具（静态地图）

# —— 设置输入文件路径 ——
soil_shp_path <- "/Users/rui/Desktop/第二讲/数据/土壤/GZsoil.shp"  # 土壤矢量数据路径
dem_ref_raster <- "output/rasters/slope_class.tif"                 # 用作参考的 DEM 栅格（分辨率、范围、投影）

# —— Step 1：读取数据并评分 ——

dem_ras <- rast(dem_ref_raster)              # 读取 DEM 栅格
soil <- st_read(soil_shp_path)               # 读取土壤矢量数据
soil <- st_transform(soil, crs(dem_ras))     # 将土壤图层投影转换为 DEM 一致坐标系

soil <- soil %>% mutate(DOMSOIL_clean = toupper(DOMSOIL))  # 标准化字段，转大写以便匹配评分表

# 构建土壤类型评分表（根据专家经验或文献设定）
soil_score_tbl <- tibble(
  DOMSOIL_clean = toupper(c("Alh", "LP", "Acf", "ACh", "Acu", "SCh", "Atc", "Fle", "Gle", "LVh", "UR", "WR")),
  score = c(10, 8, 8, 7, 6, 6, 3, 2, 2, 2, 0, 0)
)

# 合并土壤图层属性表与评分字段
soil <- left_join(soil, soil_score_tbl, by = "DOMSOIL_clean")

# 转换为 terra 格式用于栅格化
soil_vect <- vect(soil)

# 栅格化：将土壤评分矢量图层转换为栅格（值为评分）
soil_raster <- rasterize(soil_vect, dem_ras, field = "score", touches = TRUE)

# 保存原始分数栅格
writeRaster(soil_raster, "output/rasters/soil_class.tif", overwrite = TRUE)

# —— Step 2：重分类为五个等级（便于图例表达） ——

# 构建重分类矩阵：将连续分数（0-10）划分为 5 个等级
rcl <- matrix(c(
  0, 2, 1,    # Very Poor
  2, 4, 2,    # Poor
  4, 6, 3,    # Moderate
  6, 8, 4,    # Good
  8, 10, 5    # Very Good
), ncol = 3, byrow = TRUE)

# 应用重分类
soil_class_5cat <- classify(soil_raster, rcl)

# 保存重分类后的栅格
writeRaster(soil_class_5cat, "output/rasters/soil_class_5cat.tif", overwrite = TRUE)

# —— Step 3：地图可视化输出 ——

# 读取广州市行政边界（用于叠加外轮廓线）
gz_boundary <- st_read("data/gz_boundary/gzbianjie.shp")  # ← 若你已换位置请改路径
gz_outer <- st_union(gz_boundary)                        # 合并为单个多边形边界线

# 构建地图对象（含图例、比例尺、指北针、刻度、边框）
soil_plot <- 
  tm_shape(soil_class_5cat) +
  tm_raster(
    title = "Soil Suitability Level",
    palette = "YlGnBu",
    style = "cat",
    labels = c("Very Poor", "Poor", "Moderate", "Good", "Very Good")
  ) +
  tm_shape(gz_outer) + 
  tm_borders(lwd = 1.2, col = "black") +                             # 外边界线
  tm_graticules(lines = FALSE, labels.show = TRUE) +                # 经纬度刻度线（隐藏网格）
  tm_compass(type = "arrow", size = 2, position = c("left", "top")) + # 指北针
  tm_scale_bar(position = c("right", "bottom"), text.size = 0.6) +    # 比例尺
  tm_layout(
    main.title = "Soil Suitability Classification - Guangzhou",
    main.title.size = 1.4,
    frame = TRUE,
    legend.outside = TRUE,
    legend.title.size = 1,
    legend.text.size = 0.8,
    legend.frame = FALSE,
    inner.margins = c(0.08, 0.08, 0.08, 0.08),
    outer.margins = c(0.02, 0.02, 0.02, 0.02)
  )

# 显示地图
soil_plot

# —— Step 4：保存地图为高质量 PNG 文件 ——

output_dir <- "output/maps"                                         # 设置输出目录
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)     # 如目录不存在则创建
tmap_save(soil_plot, filename = file.path(output_dir, "soil_classification_map.png"), width = 1920, height = 1080, dpi = 300)

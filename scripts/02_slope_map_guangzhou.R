# —— 初始化环境 ——
rm(list = ls())                         # 清空变量
if (!is.null(dev.list())) dev.off()     # 关闭图形设备
gc()                                    # 回收内存
cat("\014")                             # 清空控制台（仅限RStudio）


# —— 加载必要包 ——
library(sf)         # 矢量数据处理
library(terra)      # 栅格数据处理
library(tmap)       # 地图可视化
library(tidyverse)  # 数据整理与管道操作

# —— 设置为静态地图模式（适合高质量导图） ——
tmap_mode("plot")


# —— Step 1：读取广州边界和水系矢量数据 ——
gz_boundary <- st_read("data/gz_boundary/gzbianjie.shp")
river <- st_read("data/gzwater/gzwater.shp")


# —— Step 2：读取 DEM 并裁剪为广州范围 ——
dem <- rast("data/DEM")

# ❗投影统一：将行政边界投影转换为 DEM 所用 CRS（WGS84，经纬度）
gz_boundary <- st_transform(gz_boundary, crs(dem))
gz_boundary_v <- vect(gz_boundary)  # 转换为 terra 可识别格式

# 裁剪 DEM 为广州边界内区域
dem_crop <- crop(dem, gz_boundary_v)
dem_gz <- mask(dem_crop, gz_boundary_v)

# 可视化裁剪结果（可选）
plot(dem_gz, main = "Clipped DEM - Guangzhou")


# —— Step 3：坡度计算（单位为“度”） ——
slope <- terrain(dem_gz, v = "slope", unit = "degrees")


# —— Step 4：坡度等级重分类（用于可视化和叠加分析） ——
rcl <- matrix(c(
  0, 2.5, 10,
  2.5, 5, 9,
  5, 7.5, 8,
  7.5, 10, 7,
  10, 15, 6,
  15, 43, 2
), ncol = 3, byrow = TRUE)

slope_reclass <- classify(slope, rcl)

# 查看分类频数（可选）
freq(slope_reclass)


# —— Step 5：生成河流缓冲区（50米 & 50–100米环带） ——
riverBuffer1 <- river %>%
  st_buffer(dist = 50) %>%
  st_union()

riverBuffer2 <- river %>%
  st_buffer(dist = 100) %>%
  st_union()

river_ring <- st_difference(riverBuffer2, riverBuffer1)

# 保存缓冲区结果（可选）
st_write(riverBuffer1, "riverBuffer1.shp", delete_dsn = TRUE)
st_write(river_ring, "river_ring.shp", delete_dsn = TRUE)


# —— Step 6：合并行政区，只显示广州最外围边界 ——
gz_outer <- st_union(gz_boundary)  # ✅ 只显示轮廓线，不要内部线

# —— Step 7：构建地图对象（含图例、边界、经纬度、美化） ——
slope_plot <- tm_shape(slope_reclass) +
  
  # 主体：坡度等级图层
  tm_raster(title = "Slope Class", palette = "YlGnBu") +
  
  # ✅ 添加外轮廓行政边界线
  tm_shape(gz_outer) + 
  tm_borders(lwd = 1.2, col = "black") +
  
  # ✅ 添加经纬度刻度标签，不显示格网线
  tm_graticules(lines = FALSE, labels.show = TRUE) +
  
  # ✅ 添加指北针和比例尺
  tm_compass(type = "arrow", size = 2, position = c("left", "top")) +
  tm_scale_bar(position = c("right", "bottom"), text.size = 0.6) +
  
  # ✅ 美化版面布局设置
  tm_layout(
    main.title = "Slope Classification - Guangzhou",
    main.title.size = 1.4,
    frame = TRUE,                         # 显示地图边框
    legend.outside = TRUE,                # 图例置于地图外部
    legend.title.size = 1,
    legend.text.size = 0.8,
    legend.frame = FALSE,                 # ✅ 去除图例边框
    inner.margins = c(0.08, 0.08, 0.08, 0.08),  # 地图内部边距
    outer.margins = c(0.02, 0.02, 0.02, 0.02)   # 图像整体居中留白
  )


# —— Step 8：预览地图（静态图） ——
slope_plot


# —— Step 9：保存结果图层与地图（可选） ——
# 保存坡度图层与分类图层为 GeoTIFF
writeRaster(slope, "slope_guangzhou.tif", overwrite = TRUE)
writeRaster(slope_reclass, "slope_class.tif", overwrite = TRUE)

# 保存地图为高分辨率 PNG 图片
tmap_save(slope_plot,
          filename = "slope_class_map_guangzhou.png",
          dpi = 300, width = 8, height = 6, units = "in")
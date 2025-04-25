# 📘 Lesson 2: AHP 多因子适宜性分析与地图制图（广州案例）

<p align="center">
  <img src="output/maps/slope_class_map_guangzhou.png" width="100%"><br>
</p>

---

## 📖 目录

- [项目简介](#-项目简介)
- [学习背景](#-学习背景)
- [项目结构](#-项目结构)
- [数据获取说明](#-数据获取说明)
- [使用方法](#-使用方法)
- [依赖包](#-所需-r-包)
- [输出示例](#-输出示例)
- [脚本详解（3大分析模块）](scripts/README.md)
- [许可协议](#-许可协议)

---

# 📍 项目简介

本项目基于 R 语言，围绕广州市进行坡度、土壤、水体距离等因子适宜性分析，使用 **AHP 层次分析法** 思想，生成分级地图，最终为城市选址、多因子评价打下基础。  
核心包包括：`terra`、`sf`、`tmap`、`dplyr`。

---

# 📚 学习背景

本项目属于**自建 R 地理空间学习课程**的第 2 课，主题是：

- 熟悉 DEM 数据处理与坡度计算
- 学会不同要素（坡度、土壤、水体）的标准化评分
- 应用适合 MCDA（多标准决策分析）的方法
- 形成适合进一步进行 AHP、加权叠加的输入数据
- 生成高质量空间地图

---

# 📂 项目结构

```text
guangzhou-slope-analysis/
├── data/          # 📁 输入数据（shapefile，DEM等）
├── output/        # 📁 输出地图和栅格（PNG、TIF）
│   ├── maps/      #   - 各地图输出
│   └── rasters/   #   - 分级结果栅格
├── scripts/       # 📁 脚本文件（主脚本和补充分析）
├── .gitignore     # 📄 忽略部分大文件
└── README.md      # 📄 本说明文档
```

---

# 📥 数据获取说明

由于 DEM 数据体积较大，未纳入本仓库。请从以下链接下载：

👉 [住宅区+DEM 数据下载（百度网盘）](https://pan.baidu.com/s/17GucH-eBUg7rHgJ1tKJfuQ?pwd=ahmc) 提取码：**ahmc**

✅ 下载后将解压的内容放置到项目 `data/住宅区+dem/` 目录。

主要数据内容：
- 广州市 DEM（250m 分辨率）
- 广州住宅区矢量边界

---

# 🛠️ 使用方法

1. 克隆本项目或下载 ZIP。
2. 将下载的数据文件放入 `data/` 文件夹下对应位置。
3. 用 RStudio / VSCode 打开项目。
4. 按顺序执行以下脚本：
   - `scripts/02_slope_map_guangzhou.R`  
     ➔ 提取坡度 ➔ 重分类 ➔ 出图
   - `scripts/02_soil_analysis.R`  
     ➔ 土壤类型赋分 ➔ 重分类 ➔ 出图
   - `scripts/02c_water_score_distance_A.R`  
     ➔ 基于距离水体的得分 ➔ 出图
5. 所有输出结果存储在 `output/` 文件夹。

🔵 *建议按脚本顺序执行，每次运行前确保工作目录正确设置。*

---

# 📦 所需 R 包

```r
install.packages(c("terra", "sf", "tmap", "dplyr", "tibble"))
```
- 适用 R 版本：推荐 R >= 4.2
- tmap 版本：V4（静态制图模式）

---

# 🗺️ 输出示例

<p align="center">
  <img src="output/maps/slope_class_map_guangzhou.png" width="100%" alt="Slope Classification Map"><br>
  <em>坡度等级地图（依据 6 级分类，适配官方标准）</em><br><br>
  
  <img src="output/maps/soil_classification_map.png" width="100%" alt="Soil Suitability Map"><br>
  <em>土壤适宜性地图（根据土壤类型重分类）</em><br><br>
  
  <img src="output/maps/water_score_50m.png" width="100%" alt="Water Distance Suitability Map">
  <br><em>水体距离适宜性地图（官方 6 档打分标准）</em>
</p>

---

# 🛠️ 当前脚本进展（已完成）

| 脚本名称 | 内容概述 |
| :--- | :--- |
| `02_slope_map_guangzhou.R` | 坡度提取 ➔ 坡度重分类 ➔ 地图制作 |
| `02_soil_analysis.R` | 土壤类型打分 ➔ 土壤适宜性分级 ➔ 地图制作 |
| `02c_water_score_distance_A.R` | 水体距离栅格 ➔ 官方标准得分 ➔ 地图制作 |

👉 每个脚本的详细解析见：[scripts/README.md](scripts/README.md)

---

# 📄 许可协议

本项目基于 **MIT License** 开源。  
可自由用于学习、教学与非商业项目中。引用请注明来源。

---

# ✍️ 作者信息

- 作者：Rui
- 创建时间：2025年4月
- 版本：Lesson 2（持续更新中）
- 未来方向：继续拓展 AHP 综合适宜性分析、土地利用多因子评价等案例
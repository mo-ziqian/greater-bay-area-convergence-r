# 复现说明（单文件夹发布包）

## 1) 数据准备

请自行准备 4 个原始 Excel 文件：

- `BayArea-zh-CN-1.xls`（人口）
- `BayArea-zh-CN-2.xls`（GDP）
- `BayArea-zh-CN-3.xls`（人均GDP）
- `BayArea-zh-CN-4.xls`（就业人口）

建议将原始数据仅本地保存，不上传 GitHub。

## 2) 环境依赖

R 4.1+，安装依赖包：

```r
install.packages(c(
  "readxl", "dplyr", "tidyr", "ggplot2", "scales",
  "plm", "stargazer", "gridExtra"
))
```

## 3) 文件夹内目录（发布包）

```text
github_upload/
├─ greater_bay_area_economy.R
├─ README.md
├─ REPRODUCTION.md
├─ UPLOAD_CHECKLIST.md
├─ 实证结果汇总表.csv
├─ .gitignore
├─ data/
│  └─ raw/                  # 放 4 个 xls
└─ output/                  # 运行后自动生成结果
```

## 4) 运行脚本

执行：

```r
source("greater_bay_area_economy.R", encoding = "UTF-8")
```

## 5) 输出说明

脚本会生成图表和汇总结果（如 `实证结果汇总表.csv`）。

## 6) 发布建议

- 发布包内仅保留：代码、说明文档、示例结果
- 不包含：课程课件、个人信息、未授权数据全文

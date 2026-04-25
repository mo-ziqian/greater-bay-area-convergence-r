library(readxl)
library(dplyr)
library(tidyr)
library(ggplot2)

# -----------------------------
# GitHub 发布版：单文件夹可运行脚本
# -----------------------------
data_dir <- file.path("data", "raw")
output_dir <- "output"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

file_paths <- file.path(data_dir, c(
  "BayArea-zh-CN-1.xls",  # 人口
  "BayArea-zh-CN-2.xls",  # GDP
  "BayArea-zh-CN-3.xls",  # 人均GDP
  "BayArea-zh-CN-4.xls"   # 就业人口
))

missing_files <- file_paths[!file.exists(file_paths)]
if (length(missing_files) > 0) {
  stop(
    paste0(
      "缺少原始数据文件，请先把以下文件放到 ", data_dir, " 目录：\n",
      paste("- ", basename(missing_files), collapse = "\n")
    )
  )
}

clean_wide_to_long <- function(data, indicator_name) {
  data_clean <- data[-1, ]
  col_names_candidate <- as.vector(data_clean[1, ])
  valid_cols <- !is.na(col_names_candidate)
  data_clean <- data_clean[, valid_cols]
  colnames(data_clean) <- col_names_candidate[valid_cols]
  data_clean <- data_clean[-1, ]

  colnames(data_clean)[1] <- "年份"
  data_clean$年份 <- suppressWarnings(as.numeric(data_clean$年份))

  data_long <- data_clean %>%
    pivot_longer(
      cols = -年份,
      names_to = "城市",
      values_to = indicator_name,
      values_drop_na = TRUE
    )

  data_long[[indicator_name]] <- gsub("[^0-9.-]", "", data_long[[indicator_name]])
  data_long[[indicator_name]] <- suppressWarnings(as.numeric(data_long[[indicator_name]]))

  data_long %>% filter(!is.na(城市), 城市 != "", !is.na(年份))
}

# 读取数据
data_list <- lapply(file_paths, function(path) read_excel(path, sheet = 1))
names(data_list) <- c("data1", "data2", "data3", "data4")

# 清洗与合并
data1_pop <- clean_wide_to_long(data_list[["data1"]], "人口")
data2_gdp <- clean_wide_to_long(data_list[["data2"]], "GDP")
data3_per_gdp <- clean_wide_to_long(data_list[["data3"]], "人均GDP")
data4_emp <- clean_wide_to_long(data_list[["data4"]], "就业人口")

full_panel_data <- data1_pop %>%
  left_join(data2_gdp, by = c("城市", "年份")) %>%
  left_join(data3_per_gdp, by = c("城市", "年份")) %>%
  left_join(data4_emp, by = c("城市", "年份"))

full_panel_clean <- full_panel_data %>%
  filter(!is.na(人口), !is.na(GDP), !is.na(人均GDP), 年份 >= 2000)

# σ收敛（变异系数）
yearly_sigma <- full_panel_clean %>%
  group_by(年份) %>%
  summarise(
    人均GDP均值 = mean(人均GDP),
    人均GDP标准差 = sd(人均GDP),
    人均GDP变异系数 = 人均GDP标准差 / 人均GDP均值,
    .groups = "drop"
  ) %>%
  arrange(年份)

sigma_correlation <- cor(yearly_sigma$年份, yearly_sigma$人均GDP变异系数)

sigma_plot <- ggplot(yearly_sigma, aes(x = 年份, y = 人均GDP变异系数)) +
  geom_line(color = "#2E86AB", linewidth = 1.2) +
  geom_point(color = "#A23B72", size = 2.5) +
  geom_smooth(method = "lm", se = FALSE, color = "red", linetype = "dashed") +
  labs(
    title = "大湾区九市人均GDP σ收敛趋势（2000-2022）",
    x = "年份",
    y = "人均GDP变异系数"
  ) +
  theme_bw()

ggsave(file.path(output_dir, "σ收敛趋势图.png"), sigma_plot, width = 10, height = 6, dpi = 300)

# 绝对β收敛（截面）
city_growth_summary <- full_panel_clean %>%
  group_by(城市) %>%
  summarise(
    初始年份 = min(年份),
    最终年份 = max(年份),
    期数 = 最终年份 - 初始年份,
    初始人均GDP = mean(人均GDP[年份 == 初始年份]),
    最终人均GDP = mean(人均GDP[年份 == 最终年份]),
    年均增长率 = ((最终人均GDP / 初始人均GDP)^(1 / 期数) - 1) * 100,
    初始ln人均GDP = log(初始人均GDP),
    .groups = "drop"
  ) %>%
  filter(期数 > 0)

beta_regression <- lm(年均增长率 ~ 初始ln人均GDP, data = city_growth_summary)
beta_coef <- coef(beta_regression)["初始ln人均GDP"]
beta_p <- summary(beta_regression)$coefficients["初始ln人均GDP", "Pr(>|t|)"]

beta_plot <- ggplot(city_growth_summary, aes(x = 初始ln人均GDP, y = 年均增长率)) +
  geom_point(size = 4, alpha = 0.75, color = "#F18F01") +
  geom_smooth(method = "lm", color = "#C73E1D", linewidth = 1.2, se = TRUE, alpha = 0.2) +
  labs(
    title = "大湾区九市人均GDP绝对β收敛散点图",
    x = "初始人均GDP对数",
    y = "年均增长率（%）"
  ) +
  theme_bw()

ggsave(file.path(output_dir, "β收敛散点图.png"), beta_plot, width = 10, height = 6, dpi = 300)

# 结果汇总
result_summary <- data.frame(
  分析类型 = c("σ收敛（变异系数）", "绝对β收敛（全样本）"),
  核心指标 = c("变异系数-年份相关系数", "β系数（初始ln人均GDP）"),
  指标数值 = round(c(sigma_correlation, beta_coef), 4),
  P值 = c(NA, round(beta_p, 4)),
  结论 = c(
    ifelse(sigma_correlation < 0, "存在σ收敛", "不存在σ收敛"),
    ifelse(beta_coef < 0 & beta_p < 0.05, "存在显著β收敛",
           ifelse(beta_coef < 0 & beta_p < 0.1, "存在弱β收敛", "不存在β收敛"))
  )
)

write.csv(
  result_summary,
  file.path(output_dir, "实证结果汇总表.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

print(result_summary)
cat("运行完成：输出已保存到 ", output_dir, "\n")

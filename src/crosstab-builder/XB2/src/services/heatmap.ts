// Heatmap service for crosstab visualization
import { CellData, IntersectResult } from "./cellLoader";

export type Metric = "Size" | "Sample" | "RowPercentage" | "ColumnPercentage" | "Index";

export type HeatmapColor =
  | "red500"
  | "red400"
  | "red300"
  | "red200"
  | "red100"
  | "green100"
  | "green200"
  | "green300"
  | "green400"
  | "green500"
  | "none";

export interface HeatmapScale {
  min: number;
  max: number;
  metric: Metric;
}

export function getHeatmapColor(value: number, scale: HeatmapScale): HeatmapColor {
  if (value < scale.min || value > scale.max) {
    return "none";
  }

  // Normalize value to 0-1 range
  const normalized = (value - scale.min) / (scale.max - scale.min);

  if (normalized < 0.1) return "red500";
  if (normalized < 0.2) return "red400";
  if (normalized < 0.3) return "red300";
  if (normalized < 0.4) return "red200";
  if (normalized < 0.5) return "red100";
  if (normalized < 0.6) return "green100";
  if (normalized < 0.7) return "green200";
  if (normalized < 0.8) return "green300";
  if (normalized < 0.9) return "green400";
  return "green500";
}

export function colorToHex(color: HeatmapColor): string {
  const colorMap: Record<HeatmapColor, string> = {
    red500: "#df535e",
    red400: "#e6757e",
    red300: "#ec989f",
    red200: "#f2babf",
    red100: "#f8dddf",
    green100: "#def4f7",
    green200: "#bceaf0",
    green300: "#9be0e9",
    green400: "#79d5e2",
    green500: "#58cbda",
    none: "",
  };
  return colorMap[color] || "";
}

export function calculateHeatmapScale(
  cells: Map<string, CellData>,
  metric: Metric
): HeatmapScale {
  let min = Infinity;
  let max = -Infinity;

  for (const cellData of cells.values()) {
    if (cellData.type === "Success") {
      const value = getMetricValue(cellData.data, metric);
      if (value !== null) {
        min = Math.min(min, value);
        max = Math.max(max, value);
      }
    }
  }

  // Default to 0-100 if no valid values
  if (min === Infinity || max === -Infinity) {
    min = 0;
    max = 100;
  }

  return { min, max, metric };
}

function getMetricValue(data: IntersectResult, metric: Metric): number | null {
  switch (metric) {
    case "Size":
      return data.size;
    case "Sample":
      return data.sample;
    case "RowPercentage":
      return data.rowPercentage;
    case "ColumnPercentage":
      return data.columnPercentage;
    case "Index":
      return data.index;
    default:
      return null;
  }
}


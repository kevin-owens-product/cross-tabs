import React from "react";
import { HeatmapScale } from "../services/heatmap";
import { colorToHex, getHeatmapColor } from "../services/heatmap";
import "./HeatmapLegend.scss";

interface HeatmapLegendProps {
  scale: HeatmapScale;
  onClose?: () => void;
}

export function HeatmapLegend({ scale, onClose }: HeatmapLegendProps) {
  const steps = 10;
  const stepSize = (scale.max - scale.min) / steps;

  return (
    <div className="heatmap-legend">
      <div className="legend-header">
        <span className="legend-title">Heatmap Scale</span>
        {onClose && (
          <button onClick={onClose} className="legend-close" aria-label="Close legend">
            ×
          </button>
        )}
      </div>
      <div className="legend-content">
        <div className="legend-gradient">
          {Array.from({ length: steps + 1 }).map((_, i) => {
            const value = scale.min + stepSize * i;
            const color = getHeatmapColor(value, scale);
            const hexColor = colorToHex(color);
            return (
              <div
                key={i}
                className="gradient-step"
                style={{ backgroundColor: hexColor }}
                title={`${value.toFixed(1)}`}
              />
            );
          })}
        </div>
        <div className="legend-labels">
          <span className="legend-min">{scale.min.toFixed(1)}</span>
          <span className="legend-max">{scale.max.toFixed(1)}</span>
        </div>
        <div className="legend-metric">
          Metric: <strong>{scale.metric}</strong>
        </div>
      </div>
    </div>
  );
}


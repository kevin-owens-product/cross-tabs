import React from "react";
import { Modal } from "./Modal";
import "./HeatmapModal.scss";

interface HeatmapModalProps {
  currentMetric: string | null;
  onClose: () => void;
  onSelect: (metric: string) => void;
}

const metrics = [
  { value: "Size", label: "Size" },
  { value: "Sample", label: "Sample" },
  { value: "RowPercentage", label: "Row Percentage" },
  { value: "ColumnPercentage", label: "Column Percentage" },
  { value: "Index", label: "Index" },
];

export function HeatmapModal({
  currentMetric,
  onClose,
  onSelect,
}: HeatmapModalProps) {
  return (
    <Modal
      type="heatmap"
      title="Select Heatmap Metric"
      onClose={onClose}
      onConfirm={() => {}}
    >
      <div className="heatmap-modal">
        <p>Choose a metric to visualize as a heatmap:</p>
        <div className="metric-list">
          {metrics.map((metric) => (
            <button
              key={metric.value}
              onClick={() => onSelect(metric.value)}
              className={`metric-button ${currentMetric === metric.value ? "active" : ""}`}
            >
              {metric.label}
            </button>
          ))}
        </div>
        {currentMetric && (
          <button
            onClick={() => onSelect("")}
            className="clear-button"
          >
            Clear Heatmap
          </button>
        )}
      </div>
    </Modal>
  );
}


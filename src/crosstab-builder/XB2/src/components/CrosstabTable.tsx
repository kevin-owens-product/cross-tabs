import React, { useEffect } from "react";
import { AudienceItem } from "../types";
import { CellData } from "../services/cellLoader";
import { DraggableItem } from "./DraggableItem";
import { getHeatmapColor, colorToHex, HeatmapScale, Metric } from "../services/heatmap";
import "./CrosstabTable.scss";

interface CrosstabTableProps {
  rows: AudienceItem[];
  columns: AudienceItem[];
  cells: Map<string, CellData>;
  isLoading?: boolean;
  heatmapScale?: HeatmapScale | null;
  heatmapMetric?: Metric | null;
  onCellClick?: (rowId: string, columnId: string) => void;
  onCellLoad?: (rowId: string, columnId: string) => void;
  onRowRemove?: (rowId: string) => void;
  onColumnRemove?: (columnId: string) => void;
  onRowReorder?: (newOrder: AudienceItem[]) => void;
  onColumnReorder?: (newOrder: AudienceItem[]) => void;
}

export function CrosstabTable({
  rows,
  columns,
  cells,
  isLoading = false,
  heatmapScale,
  heatmapMetric,
  onCellClick,
  onCellLoad,
  onRowRemove,
  onColumnRemove,
  onRowReorder,
  onColumnReorder,
}: CrosstabTableProps) {
  const handleRowDrop = (targetId: string, sourceId: string) => {
    if (!onRowReorder) return;
    
    const sourceIndex = rows.findIndex((r) => r.id === sourceId);
    const targetIndex = rows.findIndex((r) => r.id === targetId);
    
    if (sourceIndex === -1 || targetIndex === -1) return;
    
    const newRows = [...rows];
    const [removed] = newRows.splice(sourceIndex, 1);
    newRows.splice(targetIndex, 0, removed);
    
    onRowReorder(newRows);
  };

  const handleColumnDrop = (targetId: string, sourceId: string) => {
    if (!onColumnReorder) return;
    
    const sourceIndex = columns.findIndex((c) => c.id === sourceId);
    const targetIndex = columns.findIndex((c) => c.id === targetId);
    
    if (sourceIndex === -1 || targetIndex === -1) return;
    
    const newColumns = [...columns];
    const [removed] = newColumns.splice(sourceIndex, 1);
    newColumns.splice(targetIndex, 0, removed);
    
    onColumnReorder(newColumns);
  };
  const getCellKey = (rowId: string, columnId: string): string => {
    return `${rowId}:${columnId}:default`;
  };

  const getCellBackgroundColor = (rowId: string, columnId: string): string | undefined => {
    if (!heatmapScale || !heatmapMetric) return undefined;

    const cellKey = getCellKey(rowId, columnId);
    const cellData = cells.get(cellKey);

    if (cellData && cellData.type === "Success") {
      let value: number | null = null;
      switch (heatmapMetric) {
        case "Size":
          value = cellData.data.size;
          break;
        case "Sample":
          value = cellData.data.sample;
          break;
        case "RowPercentage":
          value = cellData.data.rowPercentage;
          break;
        case "ColumnPercentage":
          value = cellData.data.columnPercentage;
          break;
        case "Index":
          value = cellData.data.index;
          break;
      }

      if (value !== null) {
        const color = getHeatmapColor(value, heatmapScale);
        return colorToHex(color);
      }
    }

    return undefined;
  };

  const renderCellContent = (rowId: string, columnId: string): React.ReactNode => {
    const cellKey = getCellKey(rowId, columnId);
    const cellData = cells.get(cellKey);
    const backgroundColor = getCellBackgroundColor(rowId, columnId);

    if (!cellData) {
      return (
        <div className="cell-placeholder" onClick={() => onCellLoad?.(rowId, columnId)}>
          Click to load
        </div>
      );
    }

    switch (cellData.type) {
      case "Loading":
        return <div className="cell-loading">Loading...</div>;
      case "Success":
        return (
          <div className="cell-data" style={{ backgroundColor }}>
            <div className="cell-value">{cellData.data.size.toLocaleString()}</div>
            <div className="cell-percentage">
              {cellData.data.rowPercentage.toFixed(1)}%
            </div>
          </div>
        );
      case "Failure":
        return <div className="cell-error">Error</div>;
      default:
        return <div className="cell-placeholder">—</div>;
    }
  };

  if (rows.length === 0 && columns.length === 0) {
    return (
      <div className="crosstab-table empty">
        <div className="empty-message">
          <p>Add rows and columns to start building your crosstab</p>
        </div>
      </div>
    );
  }

  return (
    <div className="crosstab-table">
      {isLoading && (
        <div className="table-loading-overlay">
          <div className="loading-spinner">Loading cells...</div>
        </div>
      )}
      <div className="table-wrapper">
        <table role="grid" aria-label="Crosstab table">
          <thead>
            <tr>
              <th className="row-header-cell" scope="rowgroup"></th>
              {columns.map((col) => (
                <th key={col.id} className="column-header-cell" scope="col">
                  <DraggableItem
                    id={col.id}
                    onDrop={handleColumnDrop}
                    className="header-draggable"
                  >
                    <div className="header-content">
                      <span>{col.caption.text}</span>
                      {onColumnRemove && (
                        <button
                          className="remove-button"
                          onClick={(e) => {
                            e.stopPropagation();
                            onColumnRemove(col.id);
                          }}
                          title="Remove column"
                          aria-label={`Remove column ${col.caption.text}`}
                        >
                          ×
                        </button>
                      )}
                    </div>
                  </DraggableItem>
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {rows.map((row) => (
              <tr key={row.id}>
                <td className="row-header-cell" scope="row">
                  <DraggableItem
                    id={row.id}
                    onDrop={handleRowDrop}
                    className="header-draggable"
                  >
                    <div className="header-content">
                      <span>{row.caption.text}</span>
                      {onRowRemove && (
                        <button
                          className="remove-button"
                          onClick={(e) => {
                            e.stopPropagation();
                            onRowRemove(row.id);
                          }}
                          title="Remove row"
                          aria-label={`Remove row ${row.caption.text}`}
                        >
                          ×
                        </button>
                      )}
                    </div>
                  </DraggableItem>
                </td>
                {columns.map((col) => (
                  <td
                    key={`${row.id}-${col.id}`}
                    className="data-cell"
                    onClick={() => onCellClick?.(row.id, col.id)}
                    role="gridcell"
                    aria-label={`Cell ${row.caption.text} by ${col.caption.text}`}
                    tabIndex={0}
                    onKeyPress={(e) => {
                      if (e.key === "Enter" || e.key === " ") {
                        e.preventDefault();
                        onCellClick?.(row.id, col.id);
                      }
                    }}
                  >
                    {renderCellContent(row.id, col.id)}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}


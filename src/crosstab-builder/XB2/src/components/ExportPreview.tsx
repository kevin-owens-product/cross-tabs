import React, { useState, useMemo } from "react";
import { Modal } from "./Modal";
import { AudienceItem } from "../types";
import { CellData } from "../services/cellLoader";
import "./ExportPreview.scss";

interface ExportPreviewProps {
  rows: AudienceItem[];
  columns: AudienceItem[];
  cells: Map<string, CellData>;
  onExport: (options: ExportOptions) => void;
  onClose: () => void;
}

export interface ExportOptions {
  format: "excel" | "csv";
  includeMetadata: boolean;
  selectedRows?: string[];
  selectedColumns?: string[];
  includeRowTotals: boolean;
  includeColumnTotals: boolean;
  metrics: string[];
}

export function ExportPreview({
  rows,
  columns,
  cells,
  onExport,
  onClose,
}: ExportPreviewProps) {
  const [options, setOptions] = useState<ExportOptions>({
    format: "excel",
    includeMetadata: true,
    includeRowTotals: true,
    includeColumnTotals: true,
    metrics: ["Size", "RowPercentage"],
  });

  const [selectedRows, setSelectedRows] = useState<Set<string>>(
    new Set(rows.map((r) => r.id))
  );
  const [selectedColumns, setSelectedColumns] = useState<Set<string>>(
    new Set(columns.map((c) => c.id))
  );

  const previewData = useMemo(() => {
    const previewRows = rows.filter((r) => selectedRows.has(r.id));
    const previewColumns = columns.filter((c) => selectedColumns.has(c.id));

    return previewRows.map((row) => {
      const rowData: any = { row: row.caption.text };
      previewColumns.forEach((col) => {
        const cellKey = `${row.id}:${col.id}:default`;
        const cellData = cells.get(cellKey);
        if (cellData && cellData.type === "Success") {
          rowData[col.caption.text] = cellData.data.size.toLocaleString();
        } else {
          rowData[col.caption.text] = "—";
        }
      });
      return rowData;
    });
  }, [rows, columns, cells, selectedRows, selectedColumns]);

  const handleExport = () => {
    onExport({
      ...options,
      selectedRows: Array.from(selectedRows),
      selectedColumns: Array.from(selectedColumns),
    });
    onClose();
  };

  const toggleRow = (rowId: string) => {
    const newSet = new Set(selectedRows);
    if (newSet.has(rowId)) {
      newSet.delete(rowId);
    } else {
      newSet.add(rowId);
    }
    setSelectedRows(newSet);
  };

  const toggleColumn = (columnId: string) => {
    const newSet = new Set(selectedColumns);
    if (newSet.has(columnId)) {
      newSet.delete(columnId);
    } else {
      newSet.add(columnId);
    }
    setSelectedColumns(newSet);
  };

  return (
    <Modal
      type="export-preview"
      title="Export Preview & Options"
      onClose={onClose}
      onConfirm={handleExport}
    >
      <div className="export-preview">
        <div className="export-options">
          <div className="option-group">
            <label>Format</label>
            <select
              value={options.format}
              onChange={(e) =>
                setOptions({ ...options, format: e.target.value as "excel" | "csv" })
              }
            >
              <option value="excel">Excel (.xlsx)</option>
              <option value="csv">CSV</option>
            </select>
          </div>

          <div className="option-group">
            <label>
              <input
                type="checkbox"
                checked={options.includeMetadata}
                onChange={(e) =>
                  setOptions({ ...options, includeMetadata: e.target.checked })
                }
              />
              Include Metadata
            </label>
          </div>

          <div className="option-group">
            <label>
              <input
                type="checkbox"
                checked={options.includeRowTotals}
                onChange={(e) =>
                  setOptions({ ...options, includeRowTotals: e.target.checked })
                }
              />
              Include Row Totals
            </label>
          </div>

          <div className="option-group">
            <label>
              <input
                type="checkbox"
                checked={options.includeColumnTotals}
                onChange={(e) =>
                  setOptions({ ...options, includeColumnTotals: e.target.checked })
                }
              />
              Include Column Totals
            </label>
          </div>
        </div>

        <div className="selection-section">
          <h3>Select Rows ({selectedRows.size} of {rows.length})</h3>
          <div className="selection-list">
            {rows.map((row) => (
              <label key={row.id} className="selection-item">
                <input
                  type="checkbox"
                  checked={selectedRows.has(row.id)}
                  onChange={() => toggleRow(row.id)}
                />
                <span>{row.caption.text}</span>
              </label>
            ))}
          </div>
        </div>

        <div className="selection-section">
          <h3>Select Columns ({selectedColumns.size} of {columns.length})</h3>
          <div className="selection-list">
            {columns.map((col) => (
              <label key={col.id} className="selection-item">
                <input
                  type="checkbox"
                  checked={selectedColumns.has(col.id)}
                  onChange={() => toggleColumn(col.id)}
                />
                <span>{col.caption.text}</span>
              </label>
            ))}
          </div>
        </div>

        <div className="preview-section">
          <h3>Preview</h3>
          <div className="preview-table-container">
            <table className="preview-table">
              <thead>
                <tr>
                  <th>Row</th>
                  {columns
                    .filter((c) => selectedColumns.has(c.id))
                    .map((col) => (
                      <th key={col.id}>{col.caption.text}</th>
                    ))}
                </tr>
              </thead>
              <tbody>
                {previewData.slice(0, 10).map((row, i) => (
                  <tr key={i}>
                    <td>{row.row}</td>
                    {columns
                      .filter((c) => selectedColumns.has(c.id))
                      .map((col) => (
                        <td key={col.id}>{row[col.caption.text] || "—"}</td>
                      ))}
                  </tr>
                ))}
              </tbody>
            </table>
            {previewData.length > 10 && (
              <p className="preview-note">
                Showing first 10 rows of {previewData.length} total
              </p>
            )}
          </div>
        </div>
      </div>
    </Modal>
  );
}


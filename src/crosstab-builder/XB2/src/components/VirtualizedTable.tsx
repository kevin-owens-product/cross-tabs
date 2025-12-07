import React, { useMemo, useRef, useEffect, useState } from "react";
import { AudienceItem } from "../types";
import { CellData } from "../services/cellLoader";
import "./VirtualizedTable.scss";

interface VirtualizedTableProps {
  rows: AudienceItem[];
  columns: AudienceItem[];
  cells: Map<string, CellData>;
  rowHeight?: number;
  columnWidth?: number;
  visibleRows?: number;
  visibleColumns?: number;
}

// Virtual scrolling component for large tables
export function VirtualizedTable({
  rows,
  columns,
  cells,
  rowHeight = 60,
  columnWidth = 150,
  visibleRows = 20,
  visibleColumns = 10,
}: VirtualizedTableProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [scrollTop, setScrollTop] = useState(0);
  const [scrollLeft, setScrollLeft] = useState(0);

  const startRow = Math.floor(scrollTop / rowHeight);
  const endRow = Math.min(startRow + visibleRows, rows.length);
  const visibleRowRange = useMemo(() => {
    return { start: startRow, end: endRow };
  }, [startRow, endRow]);

  const startCol = Math.floor(scrollLeft / columnWidth);
  const endCol = Math.min(startCol + visibleColumns, columns.length);
  const visibleColRange = useMemo(() => {
    return { start: startCol, end: endCol };
  }, [startCol, endCol]);

  const handleScroll = (e: React.UIEvent<HTMLDivElement>) => {
    setScrollTop(e.currentTarget.scrollTop);
    setScrollLeft(e.currentTarget.scrollLeft);
  };

  const totalHeight = rows.length * rowHeight;
  const totalWidth = columns.length * columnWidth;
  const offsetY = startRow * rowHeight;
  const offsetX = startCol * columnWidth;

  return (
    <div
      ref={containerRef}
      className="virtualized-table"
      onScroll={handleScroll}
      style={{
        height: visibleRows * rowHeight,
        width: "100%",
        overflow: "auto",
      }}
    >
      <div
        style={{
          height: totalHeight,
          width: totalWidth,
          position: "relative",
        }}
      >
        <div
          style={{
            transform: `translate(${offsetX}px, ${offsetY}px)`,
            position: "absolute",
            top: 0,
            left: 0,
          }}
        >
          <table>
            <thead>
              <tr>
                <th style={{ width: columnWidth, height: rowHeight }}></th>
                {columns.slice(visibleColRange.start, visibleColRange.end).map((col) => (
                  <th
                    key={col.id}
                    style={{ width: columnWidth, height: rowHeight }}
                  >
                    {col.caption.text}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {rows.slice(visibleRowRange.start, visibleRowRange.end).map((row) => (
                <tr key={row.id} style={{ height: rowHeight }}>
                  <td style={{ width: columnWidth }}>{row.caption.text}</td>
                  {columns.slice(visibleColRange.start, visibleColRange.end).map((col) => {
                    const cellKey = `${row.id}:${col.id}:default`;
                    const cellData = cells.get(cellKey);
                    return (
                      <td key={col.id} style={{ width: columnWidth }}>
                        {cellData && cellData.type === "Success"
                          ? cellData.data.size.toLocaleString()
                          : "—"}
                      </td>
                    );
                  })}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}


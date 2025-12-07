// Export service for crosstab data
import { Flags } from "../types";
import { AudienceItem } from "../types";
import { CellData, IntersectResult } from "./cellLoader";

export interface ExportData {
  metadata: {
    locations: string[];
    waves: string[];
    date: string;
    base?: any;
    name?: string;
    heatmap?: string;
  };
  settings: {
    orientation: "Rows" | "Columns";
    activeMetrics: string[];
    email: boolean;
  };
  results: {
    rows: Array<{ id: string; label: string; questionNames: string[] }>;
    columns: Array<{ id: string; label: string; questionNames: string[] }>;
    cells: Array<{
      rowId: string;
      columnId: string;
      value: {
        sample: number;
        size: number;
        rowPercentage: number;
        columnPercentage: number;
        index: number;
      };
      backgroundColor?: string;
    }>;
  };
}

export class ExportService {
  private flags: Flags;

  constructor(flags: Flags) {
    this.flags = flags;
  }

  async exportToExcel(
    rows: AudienceItem[],
    columns: AudienceItem[],
    cells: Map<string, CellData>,
    metadata: ExportData["metadata"],
    settings: ExportData["settings"]
  ): Promise<string> {
    const exportData: ExportData = {
      metadata,
      settings,
      results: {
        rows: rows.map((r) => ({
          id: r.id,
          label: r.caption.text,
          questionNames: [],
        })),
        columns: columns.map((c) => ({
          id: c.id,
          label: c.caption.text,
          questionNames: [],
        })),
        cells: this.prepareCells(rows, columns, cells),
      },
    };

    try {
      const response = await fetch(
        `${this.flags.env.uri.api}/v3/exports/crosstab.xlsx`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${this.flags.token}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify(this.encodeExportData(exportData)),
        }
      );

      if (!response.ok) {
        throw new Error(`Export failed: ${response.statusText}`);
      }

      const blob = await response.blob();
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `${metadata.name || "crosstab"}.xlsx`;
      document.body.appendChild(a);
      a.click();
      window.URL.revokeObjectURL(url);
      document.body.removeChild(a);

      return "Export successful";
    } catch (error) {
      throw new Error(`Failed to export: ${error instanceof Error ? error.message : "Unknown error"}`);
    }
  }

  async exportToCSV(
    rows: AudienceItem[],
    columns: AudienceItem[],
    cells: Map<string, CellData>
  ): Promise<void> {
    const csvRows: string[] = [];

    // Header row
    const headerRow = ["", ...columns.map((c) => c.caption.text)];
    csvRows.push(headerRow.join(","));

    // Data rows
    for (const row of rows) {
      const rowData = [row.caption.text];
      for (const col of columns) {
        const cellKey = `${row.id}:${col.id}:default`;
        const cellData = cells.get(cellKey);
        if (cellData && cellData.type === "Success") {
          rowData.push(cellData.data.size.toString());
        } else {
          rowData.push("");
        }
      }
      csvRows.push(rowData.join(","));
    }

    const csvContent = csvRows.join("\n");
    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "crosstab.csv";
    document.body.appendChild(a);
    a.click();
    window.URL.revokeObjectURL(url);
    document.body.removeChild(a);
  }

  private prepareCells(
    rows: AudienceItem[],
    columns: AudienceItem[],
    cells: Map<string, CellData>
  ): ExportData["results"]["cells"] {
    const result: ExportData["results"]["cells"] = [];

    for (const row of rows) {
      for (const col of columns) {
        const cellKey = `${row.id}:${col.id}:default`;
        const cellData = cells.get(cellKey);
        if (cellData && cellData.type === "Success") {
          result.push({
            rowId: row.id,
            columnId: col.id,
            value: cellData.data,
          });
        }
      }
    }

    return result;
  }

  private encodeExportData(data: ExportData): any {
    // Transform to API format
    return {
      metadata: {
        locations: data.metadata.locations,
        waves: data.metadata.waves,
        date: data.metadata.date,
        base: data.metadata.base,
        name: data.metadata.name,
        heatmap: data.metadata.heatmap,
        averageTimeFormat: "days", // TODO: Get from settings
      },
      settings: {
        orientation: data.settings.orientation.toLowerCase(),
        activeMetrics: data.settings.activeMetrics,
        email: data.settings.email,
      },
      results: data.results,
    };
  }
}


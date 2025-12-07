// Cell loading service for crosstab data
import { Flags } from "../types";

export type CellData = 
  | { type: "NotAsked" }
  | { type: "Loading" }
  | { type: "Success"; data: IntersectResult }
  | { type: "Failure"; error: string };

export interface IntersectResult {
  sample: number;
  size: number;
  rowPercentage: number;
  columnPercentage: number;
  index: number;
}

export interface CellKey {
  rowId: string;
  columnId: string;
  baseId?: string;
}

export interface BulkCellRequest {
  rows: Array<{ id: string; expression: any }>;
  columns: Array<{ id: string; expression: any }>;
  locations: string[];
  waves: string[];
  baseAudience?: any;
}

export class CellLoader {
  private flags: Flags;
  private loadingCells: Map<string, AbortController> = new Map();
  private cellCache: Map<string, CellData> = new Map();

  constructor(flags: Flags) {
    this.flags = flags;
  }

  async loadCell(key: CellKey): Promise<CellData> {
    const cacheKey = this.getCacheKey(key);
    
    // Check cache first
    const cached = this.cellCache.get(cacheKey);
    if (cached && cached.type === "Success") {
      return cached;
    }

    // Cancel any existing request for this cell
    const existingController = this.loadingCells.get(cacheKey);
    if (existingController) {
      existingController.abort();
    }

    // Create new request
    const controller = new AbortController();
    this.loadingCells.set(cacheKey, controller);

    try {
      const response = await fetch(
        `${this.flags.env.uri.api}/api/v1/crosstabs/intersect`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${this.flags.token}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            row: { id: key.rowId },
            col: { id: key.columnId },
            base: key.baseId,
          }),
          signal: controller.signal,
        }
      );

      if (!response.ok) {
        throw new Error(`Failed to load cell: ${response.statusText}`);
      }

      const data: IntersectResult = await response.json();
      const cellData: CellData = { type: "Success", data };
      
      // Cache the result
      this.cellCache.set(cacheKey, cellData);
      this.loadingCells.delete(cacheKey);
      
      return cellData;
    } catch (error: any) {
      this.loadingCells.delete(cacheKey);
      
      if (error.name === "AbortError") {
        return { type: "NotAsked" };
      }
      
      return {
        type: "Failure",
        error: error.message || "Failed to load cell",
      };
    }
  }

  async loadBulkCells(request: BulkCellRequest): Promise<Map<string, CellData>> {
    const results = new Map<string, CellData>();

    try {
      const response = await fetch(
        `${this.flags.env.uri.api}/api/v1/crosstabs/bulk-intersect`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${this.flags.token}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify(request),
        }
      );

      if (!response.ok) {
        throw new Error(`Failed to load cells: ${response.statusText}`);
      }

      const data = await response.json();
      
      // Process bulk response
      if (data.cells) {
        for (const cell of data.cells) {
          const key: CellKey = {
            rowId: cell.rowId,
            columnId: cell.columnId,
            baseId: cell.baseId,
          };
          const cacheKey = this.getCacheKey(key);
          const cellData: CellData = {
            type: "Success",
            data: cell.data,
          };
          results.set(cacheKey, cellData);
          this.cellCache.set(cacheKey, cellData);
        }
      }

      return results;
    } catch (error: any) {
      // Return failure for all requested cells
      for (const row of request.rows) {
        for (const col of request.columns) {
          const key: CellKey = {
            rowId: row.id,
            columnId: col.id,
            baseId: request.baseAudience?.id,
          };
          const cacheKey = this.getCacheKey(key);
          results.set(cacheKey, {
            type: "Failure",
            error: error.message || "Failed to load cells",
          });
        }
      }
      return results;
    }
  }

  cancelCell(key: CellKey): void {
    const cacheKey = this.getCacheKey(key);
    const controller = this.loadingCells.get(cacheKey);
    if (controller) {
      controller.abort();
      this.loadingCells.delete(cacheKey);
    }
  }

  cancelAll(): void {
    for (const controller of this.loadingCells.values()) {
      controller.abort();
    }
    this.loadingCells.clear();
  }

  clearCache(): void {
    this.cellCache.clear();
  }

  getCacheKey(key: CellKey): string {
    return `${key.rowId}:${key.columnId}:${key.baseId || "default"}`;
  }

  getCached(key: CellKey): CellData | undefined {
    return this.cellCache.get(this.getCacheKey(key));
  }
}


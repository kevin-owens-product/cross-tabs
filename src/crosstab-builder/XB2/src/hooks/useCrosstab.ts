import { useState, useCallback, useMemo } from "react";
import { useApp } from "../context/AppContext";
import { AudienceItem, XBProjectId } from "../types";
import { CellLoader, CellKey, CellData } from "../services/cellLoader";

export interface CrosstabState {
  rows: AudienceItem[];
  columns: AudienceItem[];
  cells: Map<string, CellData>;
  isLoading: boolean;
}

export function useCrosstab(projectId?: XBProjectId) {
  const { flags, state } = useApp();
  const [crosstabState, setCrosstabState] = useState<CrosstabState>({
    rows: [],
    columns: [],
    cells: new Map(),
    isLoading: false,
  });

  const cellLoader = useMemo(() => new CellLoader(flags), [flags]);

  // Load project data
  const loadProject = useCallback(() => {
    if (!projectId || state.projects.type !== "Success") {
      return;
    }

    const project = state.projects.data[projectId];
    if (project && project.data) {
      setCrosstabState({
        rows: project.data.rows || [],
        columns: project.data.columns || [],
        cells: new Map(),
        isLoading: false,
      });
    }
  }, [projectId, state.projects]);

  // Add row
  const addRow = useCallback((item: AudienceItem, index?: number) => {
    setCrosstabState((prev) => {
      const newRows = [...prev.rows];
      if (index !== undefined) {
        newRows.splice(index, 0, item);
      } else {
        newRows.push(item);
      }
      return { ...prev, rows: newRows };
    });
  }, []);

  // Add column
  const addColumn = useCallback((item: AudienceItem, index?: number) => {
    setCrosstabState((prev) => {
      const newColumns = [...prev.columns];
      if (index !== undefined) {
        newColumns.splice(index, 0, item);
      } else {
        newColumns.push(item);
      }
      return { ...prev, columns: newColumns };
    });
  }, []);

  // Remove row
  const removeRow = useCallback((rowId: string) => {
    setCrosstabState((prev) => {
      const newRows = prev.rows.filter((r) => r.id !== rowId);
      const newCells = new Map(prev.cells);
      
      // Remove all cells for this row
      for (const [key] of newCells.entries()) {
        const [rId] = key.split(":");
        if (rId === rowId) {
          newCells.delete(key);
        }
      }
      
      return { ...prev, rows: newRows, cells: newCells };
    });
  }, []);

  // Remove column
  const removeColumn = useCallback((columnId: string) => {
    setCrosstabState((prev) => {
      const newColumns = prev.columns.filter((c) => c.id !== columnId);
      const newCells = new Map(prev.cells);
      
      // Remove all cells for this column
      for (const [key] of newCells.entries()) {
        const [, cId] = key.split(":");
        if (cId === columnId) {
          newCells.delete(key);
        }
      }
      
      return { ...prev, columns: newColumns, cells: newCells };
    });
  }, []);

  // Reorder rows
  const reorderRows = useCallback((newOrder: AudienceItem[]) => {
    setCrosstabState((prev) => ({ ...prev, rows: newOrder }));
  }, []);

  // Reorder columns
  const reorderColumns = useCallback((newOrder: AudienceItem[]) => {
    setCrosstabState((prev) => ({ ...prev, columns: newOrder }));
  }, []);

  // Load cell
  const loadCell = useCallback(async (key: CellKey) => {
    const cacheKey = cellLoader.getCacheKey(key);
    
    // Check if already loading or cached
    const cached = crosstabState.cells.get(cacheKey);
    if (cached && (cached.type === "Loading" || cached.type === "Success")) {
      return;
    }

    // Set loading state
    setCrosstabState((prev) => {
      const newCells = new Map(prev.cells);
      newCells.set(cacheKey, { type: "Loading" });
      return { ...prev, cells: newCells, isLoading: true };
    });

    // Load cell data
    const cellData = await cellLoader.loadCell(key);
    
    setCrosstabState((prev) => {
      const newCells = new Map(prev.cells);
      newCells.set(cacheKey, cellData);
      return { ...prev, cells: newCells, isLoading: false };
    });
  }, [cellLoader, crosstabState.cells]);

  // Load all visible cells
  const loadAllCells = useCallback(async () => {
    if (crosstabState.rows.length === 0 || crosstabState.columns.length === 0) {
      return;
    }

    setCrosstabState((prev) => ({ ...prev, isLoading: true }));

    try {
      const results = await cellLoader.loadBulkCells({
        rows: crosstabState.rows.map((r) => ({
          id: r.id,
          expression: r.definition,
        })),
        columns: crosstabState.columns.map((c) => ({
          id: c.id,
          expression: c.definition,
        })),
        locations: [], // TODO: Get from project metadata
        waves: [], // TODO: Get from project metadata
      });

      setCrosstabState((prev) => ({
        ...prev,
        cells: results,
        isLoading: false,
      }));
    } catch (error) {
      setCrosstabState((prev) => ({ ...prev, isLoading: false }));
    }
  }, [cellLoader, crosstabState.rows, crosstabState.columns]);

  // Get cell data
  const getCellData = useCallback(
    (rowId: string, columnId: string, baseId?: string): CellData => {
      const key: CellKey = { rowId, columnId, baseId };
      const cacheKey = cellLoader.getCacheKey(key);
      return (
        crosstabState.cells.get(cacheKey) || { type: "NotAsked" }
      );
    },
    [cellLoader, crosstabState.cells]
  );

  return {
    crosstabState,
    loadProject,
    addRow,
    addColumn,
    removeRow,
    removeColumn,
    reorderRows,
    reorderColumns,
    loadCell,
    loadAllCells,
    getCellData,
  };
}


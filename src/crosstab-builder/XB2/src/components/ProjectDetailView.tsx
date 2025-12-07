import React, { useState, useEffect, useCallback, useMemo } from "react";
import { useApp } from "../context/AppContext";
import { XBProjectId, AudienceItem } from "../types";
import { CrosstabTable } from "./CrosstabTable";
import { AddRowColumnModal } from "./AddRowColumnModal";
import { useCrosstab } from "../hooks/useCrosstab";
import { useUndoRedo } from "../hooks/useUndoRedo";
import { useAutoSave } from "../hooks/useAutoSave";
import { useToastContext } from "./ToastProvider";
import { useKeyboardShortcuts, KeyboardShortcutsModal } from "./KeyboardShortcuts";
import { calculateHeatmapScale, HeatmapScale, Metric } from "../services/heatmap";
import { ExportService } from "../services/export";
import { HeatmapModal } from "./HeatmapModal";
import { HeatmapLegend } from "./HeatmapLegend";
import { ExportPreview, ExportOptions } from "./ExportPreview";
import { LoadingSkeleton, TableRowSkeleton } from "./LoadingSkeleton";
import "./ProjectDetailView.scss";

interface ProjectDetailViewProps {
  projectId?: XBProjectId;
  onBack: () => void;
  onSave: () => void;
}

export function ProjectDetailView({
  projectId,
  onBack,
  onSave,
}: ProjectDetailViewProps) {
  const { flags, state, updateProject } = useApp();
  const {
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
  } = useCrosstab(projectId);

  // Undo/Redo for crosstab state
  const {
    state: undoRedoState,
    setState: setUndoRedoState,
    undo,
    redo,
    canUndo,
    canRedo,
  } = useUndoRedo(crosstabState);

  // Sync undo/redo state with crosstab state
  useEffect(() => {
    if (undoRedoState !== crosstabState) {
      setUndoRedoState(crosstabState);
    }
  }, [crosstabState, undoRedoState, setUndoRedoState]);

  const [isDirty, setIsDirty] = useState(false);
  const [projectName, setProjectName] = useState("");
  const [activeModal, setActiveModal] = useState<"addRow" | "addColumn" | "heatmap" | "export" | null>(null);
  const [heatmapMetric, setHeatmapMetric] = useState<Metric | null>(null);
  const [heatmapScale, setHeatmapScale] = useState<HeatmapScale | null>(null);
  const [showHeatmapLegend, setShowHeatmapLegend] = useState(false);
  const [saveStatus, setSaveStatus] = useState<"saved" | "saving" | "unsaved">("saved");

  const exportService = useMemo(() => new ExportService(flags), [flags]);
  const toast = useToastContext();
  const { showShortcuts, setShowShortcuts } = useKeyboardShortcuts();

  // Auto-save functionality
  const { forceSave } = useAutoSave(
    { rows: crosstabState.rows, columns: crosstabState.columns, name: projectName },
    {
      onSave: async () => {
        if (!projectId) return;
        setSaveStatus("saving");
        await updateProject(projectId, {
          name: projectName,
          data: {
            rows: crosstabState.rows,
            columns: crosstabState.columns,
          },
        });
        setSaveStatus("saved");
        setIsDirty(false);
      },
      enabled: !!projectId && isDirty,
      onSaveSuccess: () => {
        toast.success("Auto-saved");
      },
      onSaveError: (error) => {
        toast.error(`Auto-save failed: ${error.message}`);
        setSaveStatus("unsaved");
      },
    }
  );

  useEffect(() => {
    loadProject();
  }, [loadProject]);

  useEffect(() => {
    if (projectId && state.projects.type === "Success") {
      const project = state.projects.data[projectId];
      if (project) {
        setProjectName(project.name || "");
      }
    }
  }, [projectId, state.projects]);

  // Auto-load cells when rows/columns change
  useEffect(() => {
    if (crosstabState.rows.length > 0 && crosstabState.columns.length > 0) {
      // Load all cells after a short delay
      const timer = setTimeout(() => {
        loadAllCells();
      }, 500);
      return () => clearTimeout(timer);
    }
  }, [crosstabState.rows.length, crosstabState.columns.length, loadAllCells]);

  // Calculate heatmap scale when metric changes
  useEffect(() => {
    if (heatmapMetric && crosstabState.cells.size > 0) {
      const scale = calculateHeatmapScale(crosstabState.cells, heatmapMetric);
      setHeatmapScale(scale);
    } else {
      setHeatmapScale(null);
    }
  }, [heatmapMetric, crosstabState.cells]);

  const handleSave = async () => {
    if (!projectId) return;

    setSaveStatus("saving");
    try {
      await updateProject(projectId, {
        name: projectName,
        data: {
          rows: crosstabState.rows,
          columns: crosstabState.columns,
        },
      });
      setIsDirty(false);
      setSaveStatus("saved");
      toast.success("Project saved successfully");
    } catch (error) {
      setSaveStatus("unsaved");
      toast.error(`Failed to save: ${error instanceof Error ? error.message : "Unknown error"}`);
    }
  };

  const handleAddRow = (item: AudienceItem) => {
    addRow(item);
    setIsDirty(true);
    setActiveModal(null);
  };

  const handleAddColumn = (item: AudienceItem) => {
    addColumn(item);
    setIsDirty(true);
    setActiveModal(null);
  };

  const handleRemoveRow = (rowId: string) => {
    removeRow(rowId);
    setIsDirty(true);
    setSaveStatus("unsaved");
    toast.info("Row removed", {
      action: {
        label: "Undo",
        onClick: () => {
          // TODO: Implement undo for remove
          toast.info("Undo not yet implemented");
        },
      },
    });
  };

  const handleRemoveColumn = (columnId: string) => {
    removeColumn(columnId);
    setIsDirty(true);
    setSaveStatus("unsaved");
    toast.info("Column removed", {
      action: {
        label: "Undo",
        onClick: () => {
          // TODO: Implement undo for remove
          toast.info("Undo not yet implemented");
        },
      },
    });
  };

  const handleRowReorder = useCallback((newOrder: AudienceItem[]) => {
    reorderRows(newOrder);
    setIsDirty(true);
  }, [reorderRows]);

  const handleColumnReorder = useCallback((newOrder: AudienceItem[]) => {
    reorderColumns(newOrder);
    setIsDirty(true);
  }, [reorderColumns]);

  // Keyboard shortcuts
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key === "z" && !e.shiftKey) {
        e.preventDefault();
        if (canUndo) {
          undo();
          toast.info("Undone");
        }
      } else if ((e.ctrlKey || e.metaKey) && (e.key === "y" || (e.key === "z" && e.shiftKey))) {
        e.preventDefault();
        if (canRedo) {
          redo();
          toast.info("Redone");
        }
      } else if ((e.ctrlKey || e.metaKey) && e.key === "s") {
        e.preventDefault();
        if (isDirty) {
          handleSave();
        }
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [canUndo, canRedo, undo, redo, isDirty, handleSave, toast]);

  const handleCellClick = (rowId: string, columnId: string) => {
    const cellData = getCellData(rowId, columnId);
    if (cellData.type === "NotAsked") {
      loadCell({ rowId, columnId });
    }
  };

  const handleExport = async (options: ExportOptions) => {
    toast.info("Preparing export...");
    try {
      const rowsToExport = options.selectedRows
        ? crosstabState.rows.filter(r => options.selectedRows!.includes(r.id))
        : crosstabState.rows;
      const columnsToExport = options.selectedColumns
        ? crosstabState.columns.filter(c => options.selectedColumns!.includes(c.id))
        : crosstabState.columns;

      if (options.format === "excel") {
        await exportService.exportToExcel(
          rowsToExport,
          columnsToExport,
          crosstabState.cells,
          {
            locations: [], // TODO: Get from project metadata
            waves: [], // TODO: Get from project metadata
            date: new Date().toISOString(),
            name: projectName || "Untitled Crosstab",
            heatmap: heatmapMetric || undefined,
          },
          {
            orientation: "Rows",
            activeMetrics: options.metrics,
            email: false,
          }
        );
      } else {
        await exportService.exportToCSV(
          rowsToExport,
          columnsToExport,
          crosstabState.cells
        );
      }
      toast.success("Export completed successfully");
    } catch (error) {
      toast.error(`Export failed: ${error instanceof Error ? error.message : "Unknown error"}`);
    }
  };

  const handleExportCSV = async () => {
    toast.info("Preparing CSV export...");
    try {
      await exportService.exportToCSV(
        crosstabState.rows,
        crosstabState.columns,
        crosstabState.cells
      );
      toast.success("CSV export completed");
    } catch (error) {
      toast.error(`Export failed: ${error instanceof Error ? error.message : "Unknown error"}`);
    }
  };

  const handleHeatmapSelect = (metric: string) => {
    setHeatmapMetric(metric as Metric);
    setActiveModal(null);
    if (metric) {
      setShowHeatmapLegend(true);
      toast.info(`Heatmap applied: ${metric}`);
    } else {
      setShowHeatmapLegend(false);
      toast.info("Heatmap cleared");
    }
  };

  return (
    <div className="project-detail-view">
      <div className="project-detail-header">
        <button onClick={onBack} className="back-button">
          ← Back
        </button>
        <div className="project-name-wrapper">
          <input
            type="text"
            value={projectName}
            onChange={(e) => {
              setProjectName(e.target.value);
              setIsDirty(true);
              setSaveStatus("unsaved");
            }}
            placeholder="Untitled Crosstab"
            className="project-name-input"
          />
          <span className={`save-status save-status-${saveStatus}`}>
            {saveStatus === "saving" && "Saving..."}
            {saveStatus === "saved" && "Saved"}
            {saveStatus === "unsaved" && "Unsaved"}
          </span>
        </div>
        <div className="header-actions">
          <button onClick={() => setActiveModal("addRow")} className="action-button">
            Add Row
          </button>
          <button onClick={() => setActiveModal("addColumn")} className="action-button">
            Add Column
          </button>
          {crosstabState.rows.length > 0 && crosstabState.columns.length > 0 && (
            <>
              <button onClick={loadAllCells} className="action-button">
                Load All Cells
              </button>
              <button onClick={() => setActiveModal("heatmap")} className="action-button">
                {heatmapMetric ? `Heatmap: ${heatmapMetric}` : "Apply Heatmap"}
              </button>
              <div className="export-buttons">
                <button onClick={() => setActiveModal("export")} className="action-button">
                  Export...
                </button>
              </div>
            </>
          )}
          <div className="undo-redo-buttons">
            <button
              onClick={undo}
              disabled={!canUndo}
              className="action-button"
              title="Undo (Ctrl+Z)"
            >
              ↶ Undo
            </button>
            <button
              onClick={redo}
              disabled={!canRedo}
              className="action-button"
              title="Redo (Ctrl+Y)"
            >
              ↷ Redo
            </button>
          </div>
          <button
            onClick={handleSave}
            className="save-button"
            disabled={!isDirty || saveStatus === "saving"}
            title="Save (Ctrl+S)"
          >
            {saveStatus === "saving" ? "Saving..." : "Save"}
          </button>
          <button
            onClick={() => setShowShortcuts(true)}
            className="action-button"
            title="Keyboard shortcuts (Ctrl+?)"
          >
            ⌨️
          </button>
        </div>
      </div>
      <div className="project-detail-content">
        <div className="crosstab-builder">
          {crosstabState.isLoading && crosstabState.rows.length === 0 ? (
            <div className="loading-skeleton-container">
              <table>
                <thead>
                  <tr>
                    <th></th>
                    {Array.from({ length: 5 }).map((_, i) => (
                      <th key={i}>
                        <LoadingSkeleton type="rect" height={40} width={150} />
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {Array.from({ length: 10 }).map((_, i) => (
                    <TableRowSkeleton key={i} columns={5} />
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <CrosstabTable
              rows={crosstabState.rows}
              columns={crosstabState.columns}
              cells={crosstabState.cells}
              isLoading={crosstabState.isLoading}
              heatmapScale={heatmapScale}
              heatmapMetric={heatmapMetric}
              onCellClick={handleCellClick}
              onCellLoad={handleCellClick}
              onRowRemove={handleRemoveRow}
              onColumnRemove={handleRemoveColumn}
              onRowReorder={handleRowReorder}
              onColumnReorder={handleColumnReorder}
            />
          )}
        </div>
      </div>
      {activeModal === "addRow" && (
        <AddRowColumnModal
          type="addRow"
          onClose={() => setActiveModal(null)}
          onConfirm={handleAddRow}
        />
      )}
      {activeModal === "addColumn" && (
        <AddRowColumnModal
          type="addColumn"
          onClose={() => setActiveModal(null)}
          onConfirm={handleAddColumn}
        />
      )}
      {activeModal === "heatmap" && (
        <HeatmapModal
          currentMetric={heatmapMetric}
          onClose={() => setActiveModal(null)}
          onSelect={handleHeatmapSelect}
        />
      )}
      {activeModal === "export" && (
        <ExportPreview
          rows={crosstabState.rows}
          columns={crosstabState.columns}
          cells={crosstabState.cells}
          onExport={handleExport}
          onClose={() => setActiveModal(null)}
        />
      )}
      {showShortcuts && (
        <KeyboardShortcutsModal onClose={() => setShowShortcuts(false)} />
      )}
      {showHeatmapLegend && heatmapScale && (
        <HeatmapLegend
          scale={heatmapScale}
          onClose={() => setShowHeatmapLegend(false)}
        />
      )}
    </div>
  );
}


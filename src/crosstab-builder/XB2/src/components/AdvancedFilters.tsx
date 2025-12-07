import React, { useState } from "react";
import { Modal } from "./Modal";
import "./AdvancedFilters.scss";

export interface FilterOptions {
  dateRange?: {
    start: Date | null;
    end: Date | null;
  };
  owner?: string[];
  quickFilter?: "today" | "thisWeek" | "thisMonth" | "thisYear" | null;
}

interface AdvancedFiltersProps {
  filters: FilterOptions;
  onFiltersChange: (filters: FilterOptions) => void;
  onClose: () => void;
}

export function AdvancedFilters({ filters, onFiltersChange, onClose }: AdvancedFiltersProps) {
  const [localFilters, setLocalFilters] = useState<FilterOptions>(filters);

  const handleQuickFilter = (filter: FilterOptions["quickFilter"]) => {
    const now = new Date();
    let start: Date | null = null;
    let end: Date | null = null;

    switch (filter) {
      case "today":
        start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        end = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59);
        break;
      case "thisWeek":
        const weekStart = new Date(now);
        weekStart.setDate(now.getDate() - now.getDay());
        weekStart.setHours(0, 0, 0, 0);
        start = weekStart;
        end = new Date(now);
        break;
      case "thisMonth":
        start = new Date(now.getFullYear(), now.getMonth(), 1);
        end = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);
        break;
      case "thisYear":
        start = new Date(now.getFullYear(), 0, 1);
        end = new Date(now.getFullYear(), 11, 31, 23, 59, 59);
        break;
    }

    setLocalFilters({
      ...localFilters,
      quickFilter: filter,
      dateRange: { start, end },
    });
  };

  const handleApply = () => {
    onFiltersChange(localFilters);
    onClose();
  };

  const handleClear = () => {
    const cleared = {
      dateRange: undefined,
      owner: undefined,
      quickFilter: null,
    };
    setLocalFilters(cleared);
    onFiltersChange(cleared);
    onClose();
  };

  return (
    <Modal
      type="filters"
      title="Advanced Filters"
      onClose={onClose}
      onConfirm={handleApply}
    >
      <div className="advanced-filters">
        <div className="filter-section">
          <h3>Quick Filters</h3>
          <div className="quick-filters">
            {(["today", "thisWeek", "thisMonth", "thisYear"] as const).map((filter) => (
              <button
                key={filter}
                onClick={() => handleQuickFilter(filter)}
                className={`quick-filter-button ${localFilters.quickFilter === filter ? "active" : ""}`}
              >
                {filter === "today" && "Today"}
                {filter === "thisWeek" && "This Week"}
                {filter === "thisMonth" && "This Month"}
                {filter === "thisYear" && "This Year"}
              </button>
            ))}
          </div>
        </div>

        <div className="filter-section">
          <h3>Date Range</h3>
          <div className="date-range-inputs">
            <div className="date-input-group">
              <label>Start Date</label>
              <input
                type="date"
                value={localFilters.dateRange?.start ? localFilters.dateRange.start.toISOString().split("T")[0] : ""}
                onChange={(e) => {
                  const date = e.target.value ? new Date(e.target.value) : null;
                  setLocalFilters({
                    ...localFilters,
                    dateRange: {
                      ...localFilters.dateRange,
                      start: date,
                    },
                    quickFilter: null, // Clear quick filter when manual date selected
                  });
                }}
              />
            </div>
            <div className="date-input-group">
              <label>End Date</label>
              <input
                type="date"
                value={localFilters.dateRange?.end ? localFilters.dateRange.end.toISOString().split("T")[0] : ""}
                onChange={(e) => {
                  const date = e.target.value ? new Date(e.target.value) : null;
                  setLocalFilters({
                    ...localFilters,
                    dateRange: {
                      ...localFilters.dateRange,
                      end: date,
                    },
                    quickFilter: null, // Clear quick filter when manual date selected
                  });
                }}
              />
            </div>
          </div>
        </div>

        <div className="filter-actions">
          <button onClick={handleClear} className="clear-button">
            Clear All Filters
          </button>
        </div>
      </div>
    </Modal>
  );
}


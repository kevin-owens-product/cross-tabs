// Basic test setup for useCrosstab hook
import { renderHook, act } from "@testing-library/react";
import { useCrosstab } from "../hooks/useCrosstab";
import { AppProvider } from "../context/AppContext";
import React from "react";

// Mock the AppContext
jest.mock("../context/AppContext", () => ({
  useApp: () => ({
    flags: {
      token: "test-token",
      env: { uri: { api: "http://test.api" } },
    },
    state: {
      projects: { type: "Success", data: {} },
      folders: { type: "Success", data: {} },
    },
  }),
}));

describe("useCrosstab", () => {
  it("should initialize with empty state", () => {
    const { result } = renderHook(() => useCrosstab());
    expect(result.current.crosstabState.rows).toEqual([]);
    expect(result.current.crosstabState.columns).toEqual([]);
  });

  it("should add a row", () => {
    const { result } = renderHook(() => useCrosstab());
    const newRow = {
      id: "row-1",
      definition: { type: "Expression", expression: { operator: "And", expressions: [] } },
      caption: { text: "Test Row" },
    };

    act(() => {
      result.current.addRow(newRow);
    });

    expect(result.current.crosstabState.rows).toHaveLength(1);
    expect(result.current.crosstabState.rows[0].id).toBe("row-1");
  });

  it("should add a column", () => {
    const { result } = renderHook(() => useCrosstab());
    const newCol = {
      id: "col-1",
      definition: { type: "Expression", expression: { operator: "And", expressions: [] } },
      caption: { text: "Test Column" },
    };

    act(() => {
      result.current.addColumn(newCol);
    });

    expect(result.current.crosstabState.columns).toHaveLength(1);
    expect(result.current.crosstabState.columns[0].id).toBe("col-1");
  });
});


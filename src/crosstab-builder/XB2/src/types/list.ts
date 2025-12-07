// List page specific types

export type Tab = "AllProjects" | "MyProjects" | "SharedProjects";

export type SortBy =
  | "NameAsc"
  | "NameDesc"
  | "LastModifiedAsc"
  | "LastModifiedDesc"
  | "CreatedAsc"
  | "CreatedDesc"
  | "OwnedByAsc"
  | "OwnedByDesc";

export type ProjectOwner = 
  | { type: "Me" }
  | { type: "NotMe"; email: string };

export type Selection = 
  | { type: "NotSelected" }
  | { type: "SelectedProjects"; projectIds: string[] };

export interface ProjectsFoldersViewData {
  projects: any[]; // XBProject[]
  folders: Array<{ times?: { updatedAt: string; createdAt: string }; folder: any }>; // XBFolder[]
  notShownWhenSearchCount: number;
  emptySearchResult: boolean;
  isEmpty: boolean;
}


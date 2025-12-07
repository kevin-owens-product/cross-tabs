// Core data types migrated from Elm

export type XBProjectId = string;
export type XBFolderId = string;
export type AudienceId = string;

export interface Flags {
  token: string;
  user: User;
  env: Stage;
  feature?: string;
  pathPrefix?: string;
  can: Permissions;
  helpMode: boolean;
  supportChatVisible: boolean;
  revision?: string;
  referrer: Referrer;
  platform2Url: string;
}

export type Referrer = "Platform2Referrer" | "OtherReferrer";

export interface User {
  email: string;
  planHandle: UserPlan;
  // Add other user fields as needed
}

export type UserPlan = string; // TODO: Define specific plan types

export interface Permissions {
  useCrosstabs: boolean;
  // Add other permissions as needed
}

export interface Stage {
  uri: {
    api: string;
    signOut?: (options: { redirectTo: string }) => string;
    app?: string;
    attributes?: string;
    collections?: string;
    audiences?: string;
    audiencesCore?: string;
    datasets?: string;
    analytics?: string;
    serviceLayer?: string;
  };
}

export interface XBProject {
  id: XBProjectId;
  name: string;
  metadata: XBProjectMetadata;
  data: XBProjectData;
  createdAt: string; // ISO date string
  updatedAt: string; // ISO date string
  folderId?: XBFolderId;
  shared: Shared;
  owner: CrosstabUser;
  // Add other project fields as needed
}

export interface XBProjectMetadata {
  locations: string[];
  waves: string[];
  base: BaseAudience;
  metrics: Metric[];
  metricsTransposition: MetricsTransposition;
  headerSize: XBProjectHeaderSize;
  name?: string;
}

export interface XBProjectData {
  rows: AudienceItem[];
  columns: AudienceItem[];
  // Add other data fields as needed
}

export type XBProjectHeaderSize = number;

export interface XBFolder {
  id: XBFolderId;
  name: string;
  createdAt: string;
  updatedAt: string;
}

export interface AudienceItem {
  id: AudienceItemId;
  definition: AudienceDefinition;
  caption: Caption;
}

export type AudienceItemId = string;

export type AudienceDefinition =
  | { type: "Expression"; expression: Expression }
  | { type: "Average"; average: Average }
  | { type: "DeviceBasedUsage"; deviceBasedUsage: DeviceBasedUsage };

export interface Expression {
  operator: LogicOperator;
  expressions: Expression[];
  leafData?: LeafData;
}

export type LogicOperator = "And" | "Or";

export interface LeafData {
  namespaceCode: string;
  questionCode: string;
  datapointCode?: string;
  suffixCode?: string;
}

export interface Average {
  // Define average structure
}

export interface DeviceBasedUsage {
  // Define device based usage structure
}

export interface Caption {
  text: string;
  // Add other caption fields as needed
}

export interface BaseAudience {
  // Define base audience structure
}

export type Metric = "Size" | "Sample" | "RowPercentage" | "ColumnPercentage" | "Index";

export type MetricsTransposition = "Rows" | "Columns";

export interface CrosstabUser {
  id: string;
  email: string;
  // Add other user fields as needed
}

export type Shared = "NotShared" | { Shared: SharedData };

export interface SharedData {
  sharees: Sharee[];
  // Add other shared fields as needed
}

export type Sharee = { User: CrosstabUser } | { Organisation: { id: string } };

export interface XBUserSettings {
  doNotShowAgain: DoNotShowAgain[];
  sharedProjectWarningDismissed: boolean;
  // Add other settings fields as needed
}

export type DoNotShowAgain = string; // TODO: Define specific types

export type Route = 
  | { type: "ProjectList" }
  | { type: "Project"; projectId?: XBProjectId }
  | { type: "ExternalUrl"; url: string };

export type WebData<T> = 
  | { type: "NotAsked" }
  | { type: "Loading" }
  | { type: "Failure"; error: string }
  | { type: "Success"; data: T };


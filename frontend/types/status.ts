/**
 * ステータス（カンバン列）。
 * docs/api-design.md の `Status` 型に準拠（camelCase, HEX color）。
 */
export type Status = {
  id: number;
  name: string;
  color: string; // 例: "#3498DB"
  position: number;
};

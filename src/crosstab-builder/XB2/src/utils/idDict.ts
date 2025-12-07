// Type-safe dictionary with string keys
export interface IdDict<K extends string, V> {
  [key: string]: V;
}

export function empty<K extends string, V>(): IdDict<K, V> {
  return {};
}

export function insert<K extends string, V>(
  key: K,
  value: V,
  dict: IdDict<K, V>
): IdDict<K, V> {
  return { ...dict, [key]: value };
}

export function remove<K extends string, V>(
  key: K,
  dict: IdDict<K, V>
): IdDict<K, V> {
  const { [key]: _, ...rest } = dict;
  return rest;
}

export function get<K extends string, V>(
  key: K,
  dict: IdDict<K, V>
): V | undefined {
  return dict[key];
}

export function keys<K extends string, V>(dict: IdDict<K, V>): K[] {
  return Object.keys(dict) as K[];
}

export function values<K extends string, V>(dict: IdDict<K, V>): V[] {
  return Object.values(dict);
}

export function size<K extends string, V>(dict: IdDict<K, V>): number {
  return Object.keys(dict).length;
}

export function isEmpty<K extends string, V>(dict: IdDict<K, V>): boolean {
  return Object.keys(dict).length === 0;
}


import { DevInspectResults } from '@mysten/sui.js';

// TO DO: we can't just remove the 0th byte; that will fail if there are more than 128 items
// in the response. Instead we need to parse the ULEB128 and remove that
export function parseViewResults(result: DevInspectResults): number[] {
  // @ts-ignore
  let data = result.results.Ok[0][1].returnValues[0][0] as number[];

  // Delete the first tunnecessary ULEB128 length auto-added by the sui bcs view-function response
  data.splice(0, 1);
  // data.splice(0, 1);

  return data;
}

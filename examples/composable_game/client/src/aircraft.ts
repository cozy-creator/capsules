import {
  schemaToStringArray,
  JSTypes,
  moveStructValidator,
  serializeByField,
  parseViewResultsFromVector,
  bcs,
  getSigner,
  getAddress,
  provider,
  SupportedJSTypes,
  SupportedMoveTypes
} from '../../../../sdk/typescript/src/';

const aircraftSchema = {
  name: 'String',
  manufacturer: 'String',
  max_speed_mph: 'Option<u16>',
  weight_lbs: 'Option<u32>',
  armaments: 'vector<String>'
} as const; // Ensure the schema fields cannot be modified

// Define the schema type
type Aircraft = JSTypes<typeof aircraftSchema>;

// Create an object of type `Aircraft`
// Note that fields do not need to be defined in the same order as the schema
const hellcat: Aircraft = {
  name: 'F6F Hellcat',
  manufacturer: 'Grumman',
  armaments: ['6x 50-caliber machine guns', '2x 20mm cannons'],
  max_speed_mph: { some: 376 },
  weight_lbs: { none: null }
};

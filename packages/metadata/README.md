### Schemas

This is a list of industry-standard Sui schemas. Anyone can define their own schema, but using standardized schemas makes it a little easier for client-apps to consume on-chain data. Feel free to fork this repo and pull in your own schemas! We'll probably create a separate folder for this once we gather enough schemas...

### Basic Asset Schema

| Field Name | Type  | Optional | Intended Use                                                   |
| ---------- | ----- | -------- | -------------------------------------------------------------- |
| name       | ascii | true     | Individual name                                                |
| image/png  | ascii | true     | An https url pointing to a png thumbnail-image to be displayed |

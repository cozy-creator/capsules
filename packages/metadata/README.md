### Schemas

This is a list of industry-standard Sui schemas. Anyone can define their own schema, but using standardized schemas makes it a little easier for client-apps to consume on-chain data. Feel free to fork this repo and pull in your own schemas! We'll probably create a separate folder for this once we gather enough schemas...

### Basic Asset Schema

| Field Name | Type  | Optional | Intended Use                                                   |
| ---------- | ----- | -------- | -------------------------------------------------------------- |
| name       | ascii | true     | Individual name                                                |
| image/png  | ascii | true     | An https url pointing to a png thumbnail-image to be displayed |

### Package Metadata

Metadata we might want per package:
Wallets will use this to display more useful information to users
explorers can use this to display website-free interfaces
developers can use this in explorers to better understand what the package does and how to interface with it

link to docs: URL,
link to source: URL, (this might be stored on-chain) (what other artifacts are stored on chain per package?)
verified build: bool (this might already be on-chain)
client-app to construct transactions for package: URL, or VecMap<String,URL>
description: String,
successor: object-id, a more recent version we should migrate to
vulnerability status: insecure = must migrate, buggy, yanked
human-readable description to display in wallet, per function-call

3rd party metadata: if this package is safe or not (insecure, malicious, or trusted)

Of relevance to this might be: a package library on-chain that maps names + version to package-ids, while also providing info about package security

# Converter

## Installation

```
npm install 
npm run build
npx serve
```

## Usage

In order to convert an heterogenous array of values into an homogenous array of bytes you need to follow some encoding rules:

- The input prompt must start and end with brackets []
- the value must be followed by :type

Example

```
["kyrie":string, 6:u8, false:bool, ["a","b"]:vector<string>, [4,5,6]:vector<u8>]
```
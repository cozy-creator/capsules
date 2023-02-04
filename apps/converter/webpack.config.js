const { dirname } = require("path");
const path = require("path");
const webpack = require('webpack');

module.exports = {
  entry: "./src/index.ts",
  mode: "production",
  output: {
    path: path.resolve(__dirname, "dist"),
    filename: "bundle.js",
  },
  resolve: {
    extensions: [".ts", ".js"],
  },
  module: {
    rules: [
      {
        test: /\.ts$/,
        use: "ts-loader",
        exclude: /node_modules/,
        include: [path.resolve(__dirname, "src")]
      },
    ],
  },
};

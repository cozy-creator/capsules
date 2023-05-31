export function truncateEthAddress(address: string = "") {
  const prefix = address.substring(0, 5);
  const suffix = address.substring(address.length - 5);

  return prefix + "..." + suffix;
}

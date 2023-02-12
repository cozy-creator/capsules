export function truncate0x(str: string) {
  const regex = /^(0x[a-zA-Z0-9]{5})[a-zA-Z0-9]+([a-zA-Z0-9]{5})$/;
  const match = str.match(regex);

  if (!match) return str;
  return `${match[1]}…${match[2]}`;
}

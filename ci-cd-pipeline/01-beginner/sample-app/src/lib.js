function greet(name) {
  if (!name || typeof name !== 'string') {
    throw new TypeError('name must be a non-empty string');
  }
  return `Hello, ${name.trim()}!`;
}

function add(a, b) {
  if (typeof a !== 'number' || typeof b !== 'number' || Number.isNaN(a) || Number.isNaN(b)) {
    throw new TypeError('a and b must be numbers');
  }
  return a + b;
}

module.exports = { greet, add };

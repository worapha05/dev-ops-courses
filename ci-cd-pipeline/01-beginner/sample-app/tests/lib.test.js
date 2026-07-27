const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { greet, add } = require('../src/lib');

describe('greet', () => {
  it('returns a greeting', () => {
    assert.equal(greet('DevOps'), 'Hello, DevOps!');
  });

  it('trims whitespace', () => {
    assert.equal(greet(' CI '), 'Hello, CI!');
  });

  it('rejects empty name', () => {
    assert.throws(() => greet(''), TypeError);
  });
});

describe('add', () => {
  it('adds two numbers', () => {
    assert.equal(add(2, 3), 5);
  });

  it('rejects non-numbers', () => {
    assert.throws(() => add('2', 3), TypeError);
  });
});

const fs = require('fs');
const path = require('path');

const srcDir = path.join(__dirname, '..', 'src');
const forbidden = /debugger;/;

function walk(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const full = path.join(dir, entry.name);
    return entry.isDirectory() ? walk(full) : [full];
  });
}

let failed = false;
for (const file of walk(srcDir).filter((f) => f.endsWith('.js'))) {
  const content = fs.readFileSync(file, 'utf8');
  if (forbidden.test(content)) {
    console.error(`lint fail: ${file} contains debugger`);
    failed = true;
  }
}

if (failed) {
  process.exit(1);
}
console.log('lint ok');

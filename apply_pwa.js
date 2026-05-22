// Beaver Jewels PWA Post-Export Patch Script
// Run this script after exporting the game from Godot to the 'gh-pages' directory to automatically re-apply PWA capabilities.
// Usage: node apply_pwa.js

const fs = require('fs');
const path = require('path');

const PWA_ASSETS_DIR = path.join(__dirname, 'pwa_assets');
const EXPORT_DIR = path.join(__dirname, 'gh-pages');
const INDEX_HTML_PATH = path.join(EXPORT_DIR, 'index.html');

console.log('\x1b[36m%s\x1b[0m', '--------------------------------------------------------');
console.log('\x1b[32m%s\x1b[0m', 'Applying PWA / Install App capabilities to Beaver Jewels...');
console.log('\x1b[36m%s\x1b[0m', '--------------------------------------------------------');

// 1. Verify directories
if (!fs.existsSync(PWA_ASSETS_DIR)) {
    console.error(`\x1b[31mError: Source directory '${PWA_ASSETS_DIR}' not found! Make sure you run this script from the project root.\x1b[0m`);
    process.exit(1);
}
if (!fs.existsSync(EXPORT_DIR) || !fs.existsSync(INDEX_HTML_PATH)) {
    console.error(`\x1b[31mError: Exported HTML file '${INDEX_HTML_PATH}' not found! Run the Godot Web export first.\x1b[0m`);
    process.exit(1);
}

// 2. Copy manifest, service worker, and icon
try {
    fs.copyFileSync(path.join(PWA_ASSETS_DIR, 'manifest.json'), path.join(EXPORT_DIR, 'manifest.json'));
    fs.copyFileSync(path.join(PWA_ASSETS_DIR, 'sw.js'), path.join(EXPORT_DIR, 'sw.js'));
    fs.copyFileSync(path.join(PWA_ASSETS_DIR, 'icon_512.png'), path.join(EXPORT_DIR, 'icon_512.png'));
    console.log('\x1b[32m✓\x1b[0m Copied manifest.json, sw.js, and icon_512.png successfully.');
} catch (err) {
    console.error('\x1b[31mError copying PWA assets:\x1b[0m', err.message);
    process.exit(1);
}

// 3. Read index.html
let html;
try {
    html = fs.readFileSync(INDEX_HTML_PATH, 'utf8');
} catch (err) {
    console.error('\x1b[31mError reading index.html:\x1b[0m', err.message);
    process.exit(1);
}

// 4. Inject Manifest link if not present
if (!html.includes('rel="manifest"')) {
    console.log('Injecting PWA manifest link into <head>...');
    const manifestLink = '\t\t<link rel="manifest" href="manifest.json">\n\n\t</head>';
    html = html.replace('</head>', manifestLink);
    console.log('\x1b[32m✓\x1b[0m Injected manifest link.');
} else {
    console.log('\x1b[33m✓ Manifest link already present in index.html.\x1b[0m');
}

// 5. Inject Service Worker registration if not present
if (!html.includes('navigator.serviceWorker.register')) {
    console.log('Injecting Service Worker registration script...');
    const swCode = `\t\t\tif ('serviceWorker' in navigator) {
\t\t\t\twindow.addEventListener('load', () => {
\t\t\t\t\tnavigator.serviceWorker.register('sw.js')
\t\t\t\t\t\t.then((reg) => console.log('Service Worker registered', reg))
\t\t\t\t\t\t.catch((err) => console.error('Service Worker registration failed', err));
\t\t\t\t});
\t\t\t}
\t\t\tconst GODOT_CONFIG =`;
    html = html.replace('const GODOT_CONFIG =', swCode);
    console.log('\x1b[32m✓\x1b[0m Injected service worker registration.');
} else {
    console.log('\x1b[33m✓ Service worker registration already present in index.html.\x1b[0m');
}

// 6. Save index.html
try {
    fs.writeFileSync(INDEX_HTML_PATH, html, 'utf8');
    console.log('\x1b[32m✓\x1b[0m Saved patched index.html successfully.');
} catch (err) {
    console.error('\x1b[31mError writing patched index.html:\x1b[0m', err.message);
    process.exit(1);
}

console.log('\x1b[36m%s\x1b[0m', '--------------------------------------------------------');
console.log('\x1b[32m%s\x1b[0m', 'PWA Patching COMPLETE! Beaver Jewels is fully installable.');
console.log('\x1b[36m%s\x1b[0m', '--------------------------------------------------------');

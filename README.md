# Beaver Jewels

A Godot game.

## Repository Details
- **Remote URL:** `https://github.com/AlexZ005/beaver-jewels.git`

## Deployment to GitHub Pages

To deploy the contents of the `gh-pages/` directory to the `gh-pages` branch, use the following command:

godot --headless --export-release "Web" gh-pages/index.html
node .\apply_pwa.js
cd gh-pages
git init
git remote add origin git@github.com:AlexZ005/beaver-jewels.git
git commit -m "gh-pages"
git push --set-upstream origin gh-pages --force

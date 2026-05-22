godot --headless --export-release "Web" gh-pages/index.html
node .\apply_pwa.js
cd gh-pages
git init
git remote add origin git@github.com:AlexZ005/beaver-jewels.git
git add *
git commit -m "gh-pages"
git push --set-upstream origin gh-pages --force
REM cleaning

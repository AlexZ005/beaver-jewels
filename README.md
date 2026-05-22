# Beaver Jewels

A Godot game.

## Repository Details
- **Remote URL:** `https://github.com/AlexZ005/beaver-jewels.git`

## Deployment to GitHub Pages

To deploy the contents of the `gh-pages/` directory to the `gh-pages` branch, use the following command:

```powershell
# If using git subtree (recommended)
git subtree push --prefix gh-pages origin gh-pages
```

Alternatively, if you want to manually update the branch using an orphan branch method:

```powershell
# Create/Switch to orphan gh-pages branch
git checkout --orphan gh-pages

# Clean the branch
git rm -rf .

# Copy files from the gh-pages folder in main (assuming you are at root and folder exists)
git checkout main -- gh-pages/*
mv gh-pages/* .
rmdir gh-pages

# Commit and push
git add .
git commit -m "Deploy gh-pages contents"
git push origin gh-pages --force

# Switch back to main
git checkout main
```

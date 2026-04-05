const fs = require('fs');
const git = require('isomorphic-git');
const http = require('isomorphic-git/http/node');
const path = require('path');

const dir = 'C:\\Users\\MARCI0\\Desktop\\MoniflyAPP';
const repoUrl = 'https://github.com/Marcio-silf/monifly-app.git';
const token = process.env.GITHUB_TOKEN;

// Folders to include (source)
const includeDirs = ['lib', 'web', 'android', 'ios', 'supabase', 'test', 'windows', 'assets', 'landing', 'landing_monifly'];
// Files to include (root)
const includeFiles = ['pubspec.yaml', 'pubspec.lock', 'README.md', '.env.example', '.gitignore', 'analysis_options.yaml', 'package.json', 'package-lock.json', 'monifly.iml', 'monifly_app.iml', 'supabase_setup.sql', 'supabase_subscriptions_update.sql'];

(async () => {
  try {
    console.log("Initializing git for source directory...");
    await git.init({ fs, dir, defaultBranch: 'source' });
    
    const allFiles = [];
    
    const scanDir = (currentPath) => {
        const list = fs.readdirSync(currentPath);
        list.forEach((file) => {
            const fullPath = path.join(currentPath, file);
            const stat = fs.statSync(fullPath);
            const relPath = path.relative(dir, fullPath).replace(/\\/g, '/');
            
            if (stat.isDirectory()) {
                if (includeDirs.includes(relPath) || includeDirs.some(d => relPath.startsWith(d + '/'))) {
                  scanDir(fullPath);
                }
            } else {
                if (includeFiles.includes(relPath) || includeDirs.some(d => relPath.startsWith(d + '/'))) {
                  allFiles.push(relPath);
                }
            }
        });
    };
    
    scanDir(dir);
    
    console.log(`Adding ${allFiles.length} files to git (source branch)...`);
    for (const f of allFiles) {
      await git.add({ fs, dir, filepath: f });
    }
    
    console.log("Committing source code...");
    await git.commit({
      fs,
      dir,
      author: {
        name: 'Marcio Silva',
        email: 'marcio@monifly.com.br',
      },
      message: 'Full source code backup via Antigravity',
    });
    
    console.log("Pushing source to GitHub branch 'source'...");
    await git.push({
      fs,
      http,
      dir,
      url: repoUrl,
      remote: 'origin',
      ref: 'source',
      onAuth: () => ({ username: token }),
      force: true,
    });
    
    console.log("Source code uploaded successfully to branch 'source'!");
  } catch (err) {
    console.error("Error during push:", err);
  }
})();

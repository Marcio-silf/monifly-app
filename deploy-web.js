const fs = require('fs');
const git = require('isomorphic-git');
const http = require('isomorphic-git/http/node');

const dir = 'C:\\Users\\MARCI0\\Desktop\\MoniflyAPP\\build\\web';
const repoUrl = 'https://github.com/Marcio-silf/monifly-app.git';
const token = process.env.GITHUB_TOKEN;

(async () => {
  try {
    console.log("Initializing git inside web build directory...");
    await git.init({ fs, dir, defaultBranch: 'main' });
    
    const getFiles = (currentDir) => {
        let results = [];
        const list = fs.readdirSync(currentDir);
        list.forEach((file) => {
            file = currentDir + '/' + file;
            const stat = fs.statSync(file);
            if (stat && stat.isDirectory()) {
                if (!file.includes('.git')) {
                    results = results.concat(getFiles(file));
                }
            } else {
                results.push(file);
            }
        });
        return results;
    };
    
    console.log("Adding files to local git...");
    const files = getFiles(dir);
    let count = 0;
    for (const f of files) {
      const relPath = f.substring(dir.length + 1).replace(/\\/g, '/');
      await git.add({ fs, dir, filepath: relPath });
      count++;
    }
    console.log(`Added ${count} files.`);
    
    console.log("Committing files...");
    await git.commit({
      fs,
      dir,
      author: {
        name: 'Marcio Silva',
        email: 'marcio@monifly.com.br',
      },
      message: 'Initial web deploy via Antigravity',
    });
    
    console.log("Pushing to GitHub...");
    await git.push({
      fs,
      http,
      dir,
      url: repoUrl,
      remote: 'origin',
      ref: 'main',
      onAuth: () => ({ username: token }),
      force: true,
    });
    
    console.log("Web build uploaded successfully!");
  } catch (err) {
    console.error("Error during push:", err);
  }
})();

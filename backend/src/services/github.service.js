const axios = require('axios');
const AdmZip = require('adm-zip');

const GITHUB_API = 'https://api.github.com';

function authHeaders() {
  const token = process.env.GITHUB_TOKEN;
  if (!token) {
    throw new Error('GITHUB_TOKEN is not configured on the server');
  }
  return {
    Authorization: `Bearer ${token}`,
    Accept: 'application/vnd.github+json',
  };
}

// Accepts "owner/repo", a full https URL, or a .git URL.
function parseRepo(repoUrl) {
  const cleaned = repoUrl.trim().replace(/\.git$/, '').replace(/\/$/, '');
  const match = cleaned.match(/(?:github\.com[/:])?([^/]+)\/([^/]+)$/);
  if (!match) {
    throw new Error(`Could not parse owner/repo from "${repoUrl}"`);
  }
  return { owner: match[1], repo: match[2] };
}

async function getDefaultBranch(owner, repo) {
  const { data } = await axios.get(`${GITHUB_API}/repos/${owner}/${repo}`, {
    headers: authHeaders(),
  });
  return data.default_branch;
}

async function getRepoTree(owner, repo, branch) {
  const { data } = await axios.get(
    `${GITHUB_API}/repos/${owner}/${repo}/git/trees/${branch}?recursive=1`,
    { headers: authHeaders() }
  );
  return data.tree
    .filter((entry) => entry.type === 'blob')
    .map((entry) => ({
      path: entry.path,
      size: entry.size,
      sha: entry.sha,
    }));
}

async function fetchFileContent(owner, repo, path, ref) {
  const encodedPath = encodeURIComponent(path);
  const { data } = await axios.get(
    `${GITHUB_API}/repos/${owner}/${repo}/contents/${encodedPath}`,
    { headers: authHeaders(), params: { ref } }
  );
  if (data.content && data.encoding === 'base64') {
    const buf = Buffer.from(data.content, 'base64');
    return buf.toString('utf8');
  }
  return data.content || '';
}

// Streams the repo's zipball (GitHub's own export) for a given ref/branch.
async function fetchRepoZipballStream(owner, repo, ref) {
  return axios.get(`${GITHUB_API}/repos/${owner}/${repo}/zipball/${ref}`, {
    headers: authHeaders(),
    responseType: 'stream',
  });
}

// Pushes every file inside zipBuffer as a single new commit on top of the
// repo's current default branch, using the Git Data API (blobs -> tree -> commit -> ref).
async function pushZipAsCommit(owner, repo, zipBuffer, commitMessage) {
  const headers = authHeaders();
  const branch = await getDefaultBranch(owner, repo);

  const { data: refData } = await axios.get(
    `${GITHUB_API}/repos/${owner}/${repo}/git/ref/heads/${branch}`,
    { headers }
  );
  const parentCommitSha = refData.object.sha;

  const { data: parentCommit } = await axios.get(
    `${GITHUB_API}/repos/${owner}/${repo}/git/commits/${parentCommitSha}`,
    { headers }
  );
  const baseTreeSha = parentCommit.tree.sha;

  const zip = new AdmZip(zipBuffer);
  const entries = zip.getEntries().filter((e) => !e.isDirectory);
  if (entries.length === 0) {
    throw new Error('Uploaded zip contains no files');
  }

  const treeItems = [];
  for (const entry of entries) {
    const { data: blob } = await axios.post(
      `${GITHUB_API}/repos/${owner}/${repo}/git/blobs`,
      {
        content: entry.getData().toString('base64'),
        encoding: 'base64',
      },
      { headers }
    );
    treeItems.push({
      path: entry.entryName,
      mode: '100644',
      type: 'blob',
      sha: blob.sha,
    });
  }

  const { data: newTree } = await axios.post(
    `${GITHUB_API}/repos/${owner}/${repo}/git/trees`,
    { base_tree: baseTreeSha, tree: treeItems },
    { headers }
  );

  const { data: newCommit } = await axios.post(
    `${GITHUB_API}/repos/${owner}/${repo}/git/commits`,
    {
      message: commitMessage || 'Update project files',
      tree: newTree.sha,
      parents: [parentCommitSha],
    },
    { headers }
  );

  await axios.patch(
    `${GITHUB_API}/repos/${owner}/${repo}/git/refs/heads/${branch}`,
    { sha: newCommit.sha },
    { headers }
  );

  return {
    branch,
    commitSha: newCommit.sha,
    commitUrl: newCommit.html_url,
    filesPushed: treeItems.length,
  };
}

module.exports = {
  parseRepo,
  getDefaultBranch,
  getRepoTree,
  fetchFileContent,
  fetchRepoZipballStream,
  pushZipAsCommit,
};

const express = require('express');
const multer = require('multer');
const router = express.Router();
const { findById } = require('../data/projects.store');
const github = require('../services/github.service');

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 50 * 1024 * 1024 }, // 50 MB
});

// Link an existing GitHub repository to a project.
router.post('/:id/github/connect', (req, res) => {
  const project = findById(req.params.id);
  if (!project) return res.status(404).json({ message: 'Project not found' });

  const { repoUrl } = req.body;
  if (!repoUrl) return res.status(400).json({ message: 'repoUrl is required' });

  try {
    github.parseRepo(repoUrl); // validates the format
    project.githubRepoUrl = repoUrl;
    res.status(200).json({ message: 'Repository connected', project });
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// Pull: download the connected repo's current default branch as a zip.
router.get('/:id/github/pull', async (req, res) => {
  const project = findById(req.params.id);
  if (!project) return res.status(404).json({ message: 'Project not found' });
  if (!project.githubRepoUrl) {
    return res.status(400).json({ message: 'No GitHub repository connected to this project' });
  }

  try {
    const { owner, repo } = github.parseRepo(project.githubRepoUrl);
    const branch = await github.getDefaultBranch(owner, repo);
    const upstream = await github.fetchRepoZipballStream(owner, repo, branch);

    res.setHeader('Content-Type', 'application/zip');
    res.setHeader(
      'Content-Disposition',
      `attachment; filename="${repo}-${branch}.zip"`
    );
    upstream.data.pipe(res);
  } catch (err) {
    const status = err.response?.status === 404 ? 404 : 500;
    res.status(status).json({ message: err.response?.data?.message || err.message });
  }
});

// Push: accept a zip of modified project files and commit them to the repo.
router.post('/:id/github/push', upload.single('zip'), async (req, res) => {
  const project = findById(req.params.id);
  if (!project) return res.status(404).json({ message: 'Project not found' });
  if (!project.githubRepoUrl) {
    return res.status(400).json({ message: 'No GitHub repository connected to this project' });
  }
  if (!req.file) {
    return res.status(400).json({ message: 'A zip file is required (field name "zip")' });
  }

  try {
    const { owner, repo } = github.parseRepo(project.githubRepoUrl);
    const result = await github.pushZipAsCommit(
      owner,
      repo,
      req.file.buffer,
      req.body.message
    );
    res.status(200).json({ message: 'Pushed successfully', ...result });
  } catch (err) {
    const status = err.response?.status === 404 ? 404 : 500;
    res.status(status).json({ message: err.response?.data?.message || err.message });
  }
});

// List the files in the connected GitHub repo for the current default branch.
router.get('/:id/github/tree', async (req, res) => {
  const project = findById(req.params.id);
  if (!project) return res.status(404).json({ message: 'Project not found' });
  if (!project.githubRepoUrl) {
    return res.status(400).json({ message: 'No GitHub repository connected to this project' });
  }

  try {
    const { owner, repo } = github.parseRepo(project.githubRepoUrl);
    const branch = await github.getDefaultBranch(owner, repo);
    const files = await github.getRepoTree(owner, repo, branch);
    res.status(200).json({ files, branch });
  } catch (err) {
    const status = err.response?.status === 404 ? 404 : 500;
    res.status(status).json({ message: err.response?.data?.message || err.message });
  }
});

// Get individual file contents (text) from the connected GitHub repo.
router.get('/:id/github/file', async (req, res) => {
  const project = findById(req.params.id);
  if (!project) return res.status(404).json({ message: 'Project not found' });
  if (!project.githubRepoUrl) {
    return res.status(400).json({ message: 'No GitHub repository connected to this project' });
  }
  const { path } = req.query;
  if (!path) return res.status(400).json({ message: 'path query param is required' });

  try {
    const { owner, repo } = github.parseRepo(project.githubRepoUrl);
    const branch = await github.getDefaultBranch(owner, repo);
    const content = await github.fetchFileContent(owner, repo, path, branch);
    res.status(200).json({ path, content });
  } catch (err) {
    const status = err.response?.status === 404 ? 404 : 500;
    res.status(status).json({ message: err.response?.data?.message || err.message });
  }
});

module.exports = router;

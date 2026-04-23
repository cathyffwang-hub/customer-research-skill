#!/usr/bin/env node
/**
 * Git 自动更新检查：skill 每次被调用前，先检查远端是否有新 commit，
 * 有则自动 git pull 拉取最新版本。
 *
 * 使用：node scripts/update-check.js
 */

const { execSync } = require('child_process');
const path = require('path');

const SKILL_DIR = path.resolve(__dirname, '..');

function run(cmd, opts = {}) {
  return execSync(cmd, {
    cwd: SKILL_DIR,
    stdio: ['ignore', 'pipe', 'pipe'],
    encoding: 'utf8',
    ...opts,
  }).trim();
}

function safeRun(cmd) {
  try {
    return { ok: true, out: run(cmd) };
  } catch (e) {
    return { ok: false, out: (e.stderr || e.stdout || e.message || '').toString().trim() };
  }
}

function main() {
  // 非 git 仓库直接跳过（同事可能还没 clone 成 git 仓库）
  const isGit = safeRun('git rev-parse --is-inside-work-tree');
  if (!isGit.ok || isGit.out !== 'true') {
    console.log('[客户调研大纲生成] 非 git 仓库，跳过自动更新');
    return;
  }

  // fetch 远端
  const fetched = safeRun('git fetch --quiet');
  if (!fetched.ok) {
    console.log('[客户调研大纲生成] git fetch 失败，跳过自动更新：' + fetched.out);
    return;
  }

  // 比较本地和远端
  const local = safeRun('git rev-parse HEAD');
  const remote = safeRun('git rev-parse @{u}');
  if (!local.ok || !remote.ok) {
    console.log('[客户调研大纲生成] 无法比较版本，跳过（可能未设置 upstream）');
    return;
  }

  if (local.out === remote.out) {
    console.log('[客户调研大纲生成] 已是最新版本 ✅');
    return;
  }

  console.log('[客户调研大纲生成] 检测到更新，正在 git pull...');
  const pulled = safeRun('git pull --ff-only');
  if (pulled.ok) {
    console.log('[客户调研大纲生成] 更新成功 ✅');
    console.log(pulled.out);
  } else {
    console.log('[客户调研大纲生成] git pull 失败（可能有本地修改冲突）：' + pulled.out);
  }
}

main();

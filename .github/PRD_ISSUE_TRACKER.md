# 用 GitHub Issues 追踪 WordLite PRD

基准文档：仓库根目录 `WordLite_PRD.md`。

**已在 GitHub 发布**（`nancliu/lite-danci`）：

| 类型 | Issue | 标签 |
|------|-------|------|
| 主追踪（MVP §3.1、验收 §6、§7 清单） | <https://github.com/nancliu/lite-danci/issues/1> | `prd`, `mvp`, `tracking` |
| Backlog | [#2](https://github.com/nancliu/lite-danci/issues/2) … [#7](https://github.com/nancliu/lite-danci/issues/7) | `prd`, `backlog` |

PRD 正文 **§7** 已增加指向 #1 的链接，便于从文档跳进 GitHub。

---

## 标签说明

| Label | 用途 |
|--------|------|
| `prd` | 与 PRD 直接对应 |
| `mvp` | 属于 §3.1 MVP 范围 |
| `tracking` | 汇总类主 Issue |
| `backlog` | §3.2 / §7 后续 |

---

## 本机 `gh` 路径（Cursor 沙箱与部分终端可能未加入 PATH）

常见安装位置：

`C:\Program Files\GitHub CLI\gh.exe`

在 PowerShell 中可先设变量再调用：

```powershell
$gh = "C:\Program Files\GitHub CLI\gh.exe"
& $gh auth status
```

---

## 主 Issue 正文源文件

仓库内与 GitHub #1 正文一致的可编辑副本：

- `.github/prd_tracking_issue_body.md`

若要在 GitHub 上大改结构，可本地改该文件后整段粘贴到 Issue，或使用：

```powershell
Set-Location d:\projects\lite-danci
& "C:\Program Files\GitHub CLI\gh.exe" issue edit 1 --body-file ".github/prd_tracking_issue_body.md"
```

（注意：`issue edit` 会**整体替换**正文，编辑前先打开 GitHub 复制备份。）

---

## Backlog 正文草稿（与 #2–#7 对应）

目录：`.github/backlog_bodies/`（`01`…`06`）。新建同类 Issue 时可复制修改。

---

## 旧版：仅手动创建时的说明

若需在**另一仓库**重复流程，仍可按下列标题与正文手动建 Issue（与此前文档一致）。

**标题：** `[PRD 追踪] WordLite MVP 与验收状态（对照 WordLite_PRD.md）`

**正文：** 见 `.github/prd_tracking_issue_body.md`。

---

## 备注：较旧 `gh issue create` 无 `--json` 输出

若需脚本解析新建 Issue 编号，可看命令打印的最后一行 URL，或升级 GitHub CLI 后使用 `--json number,url`。

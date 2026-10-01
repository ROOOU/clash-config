# clash-config —— 我的 Clash Verge Rev 全局覆写配置

一套"换任何订阅都生效"的配置：放在 GitHub 上，任何机器 `git pull && ./install.sh` 即可同步。

## 三个文件的分工

| 文件 | 装到哪 | 作用 |
|---|---|---|
| `Script.js` | 全局扩展脚本（`profiles/Script.js`） | 只管结构：自动补齐策略组（🚀节点选择/📨 Telegram/🤖 AI服务/…）、补齐 13 个 rule-providers 及配套规则、兜底 `MATCH` 永远最后、香港节点组没香港节点时退回 🚀节点选择 |
| `rules.yaml` | 全局「编辑规则」（`profiles/<uid>.yaml`，`prepend/append/delete`） | 我自己的上网规则（从 Quantumult X 的 `[filter_local]` 1:1 转换而来），可视化可编辑 |
| `Merge.yaml` | 全局扩展配置（`profiles/Merge.yaml`） | 只放设置类字段（`profile.store-selected`）。**注意：扩展配置里写 `rules` 是整体替换，会清空订阅规则，所以规则一律放 `rules.yaml`** |

执行顺序（官方）：
`订阅原文 → 应用设置 → 全局扩展配置 → 全局扩展脚本 → 订阅扩展配置 → 订阅扩展脚本 → 应用设置回写`

所以实际规则优先级：`Script.js` 插入的规则集规则 → `rules.yaml` 的 prepend → 订阅自带规则 → 兜底 `MATCH`。

## 用法

```bash
git clone https://github.com/ROOOU/clash-config.git && cd clash-config
./install.sh              # 备份旧文件 → 安装三个文件 → 重启 Clash Verge
./install.sh --no-restart # 只装不重启
```

换订阅：直接在 Clash Verge 里导入新订阅并选中即可，规则/策略组照样生效。
改规则：编辑 `rules.yaml`（一行一条 `"类型,值,策略组"`）→ `./install.sh` → 或直接在
Clash Verge 的「编辑规则」界面改（写完记得回来同步到本仓库）。

## QX → Clash 转换对照

| QX | Clash |
|---|---|
| `host-suffix, x, 组` | `DOMAIN-SUFFIX,x,组` |
| `host-keyword, x, 组` | `DOMAIN-KEYWORD,x,组` |
| `direct` | `DIRECT` |
| `🚀节点选择` / `全球加速` / `香港节点` | `🚀节点选择` / `🌍 全球加速` / `香港节点` |
| 行首 `-` | QX 里表示禁用，这里注释保留 |

## 支持的平台

- macOS：`~/Library/Application Support/io.github.clash-verge-rev.clash-verge-rev`
- Linux：`~/.local/share/io.github.clash-verge-rev.clash-verge-rev`（或 `~/.config/...`）
- Windows：把三个文件分别覆盖到 `%APPDATA%\io.github.clash-verge-rev.clash-verge-rev\profiles\`
  下的同名文件（脚本用 `Script.js`，合并用 `Merge.yaml`，规则用「编辑规则」界面的文件）

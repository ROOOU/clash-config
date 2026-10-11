# clash-config —— 我的 Clash Verge Rev 全局覆写配置

一套"换任何订阅都生效"的配置：放在 GitHub 上，任何机器 `git pull && ./install.sh` 即可同步。

## 三个文件的分工

| 文件 | 装到哪 | 作用 |
|---|---|---|
| `Script.js` | 全局扩展脚本（`profiles/Script.js`） | 只管结构：自动补齐策略组（🚀节点选择/📨 Telegram/🤖 AI服务/…）、补齐 13 个 rule-providers 及配套规则、把 `rules.yaml` 的自定义规则**注入成 MY_RULES 并插在最前**、兜底 `MATCH` 永远最后、香港节点组没香港节点时退回 🚀节点选择 |
| `rules.yaml` | 每个订阅的「编辑规则」文件（`profiles/<uid>.yaml`，`prepend/append/delete`） | 自定义规则的**唯一来源**（从 Quantumult X 的 `[filter_local]` 1:1 转换而来），可视化管理；`install.sh` 会把它同步进 `Script.js` |
| `Merge.yaml` | 全局扩展配置（`profiles/Merge.yaml`） | 只放设置类字段（`profile.store-selected`）。**注意：扩展配置里写 `rules` 是整体替换，会清空订阅规则** |

### ⚠️ 踩过的坑：`rules` 类型的「编辑规则」文件是**订阅级**的

`profiles.yaml` 里只有 uid 为 `Merge` / `Script` 的两个文件是全局的；「编辑规则」（`type: rules`）
每个订阅各自一份（`option.rules: <uid>`）。所以**换订阅后 rules.yaml 那套规则会失效**。
现在由 `install.sh` 把 `rules.yaml` 生成到 `Script.js` 的 `MY_RULES` 里（全局脚本对每个订阅都跑），
换订阅也照样生效；同时仍然把内容写进各订阅的「编辑规则」文件，方便在界面里看/改。

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

## macOS 注意：Quantumult X 与 Clash Verge 不能同时开

两者都用 TUN 抢路由，谁后开谁接管（实测 QX 的 Tunnel 开着时，Clash Verge 即使界面显示运行中，
核心 `/connections` 也是 0 流量——改 Clash 规则对本机上网完全没有影响）。

判断谁在接管本机流量：

```bash
# 1) Clash 核心是不是在干活（0 字节 = 空转）
curl -s --unix-socket /var/run/clash-verge-service/users/501/verge-mihomo.sock \
     http://localhost/connections
# 2) 系统 DNS 是不是 198.19.0.3（QX 的 TUN 地址段，Clash 是 198.18.x）
scutil --dns | grep nameserver
```

要用 Clash Verge：退出 Quantumult X，然后打开 Clash 的 TUN 模式（或系统代理）。
要用 QX：把同样的规则加进 QX 的 `[filter_local]`（`host-suffix, x, 🚀节点选择`）。
⚠️ **QX 的配置别去改 `~/Library/Group Containers/group.com.crossutility.quantumult-x/Documents/configuration/default.conf`**——
那是 QX 启动时从主配置导出的副本，你改了下次启动就被覆盖。真正的配置在 iCloud 里：

```
~/Library/Mobile Documents/iCloud~com~crossutility~quantumult-x/Documents/Profiles/Mac-<随机>.conf
```

要离线改：先完全退出 QX（`osascript -e 'quit app "Quantumult X"'` + `pkill -f "Quantumult X Tunnel"`），
再改这个文件，然后 `open -a "Quantumult X"`；启动后 `grep` 确认规则还在（没被覆盖）即生效。
也可以在 QX 界面里改（配置文件 → 编辑 → 保存）。


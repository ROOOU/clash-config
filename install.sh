#!/usr/bin/env bash
# 把本仓库的 Clash Verge Rev 全局覆写配置装到本机（macOS / Linux）。
# 用法：./install.sh [--no-restart]
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
NO_RESTART=0
[ "${1:-}" = "--no-restart" ] && NO_RESTART=1

# 1) 找 Clash Verge Rev 的配置目录
APP=""
for d in \
  "$HOME/Library/Application Support/io.github.clash-verge-rev.clash-verge-rev" \
  "$HOME/.local/share/io.github.clash-verge-rev.clash-verge-rev" \
  "$HOME/.config/io.github.clash-verge-rev.clash-verge-rev" \
  ; do
  if [ -d "$d/profiles" ] && [ -f "$d/profiles.yaml" ]; then APP="$d"; break; fi
done
if [ -z "$APP" ]; then
  echo "❌ 没找到 Clash Verge Rev 配置目录；请先在目标机器上安装并打开一次 Clash Verge Rev。"
  exit 1
fi
echo "📁 Clash Verge 配置目录：$APP"

# 2) 从 profiles.yaml 里按类型找「全局」覆写文件（每种类型的第一个条目）
file_of_type() { # $1 = rules / groups / proxies
  awk -v want="$1" '
    /^- uid:/        { type=""; file="" }
    /^[ \t]+type:/   { type=$2 }
    /^[ \t]+file:/   { file=$2; if (type==want && file!="") { print file; exit } }
  ' "$APP/profiles.yaml"
}
file_of_uid() { # $1 = 固定 uid（全局扩展配置用 Merge，全局扩展脚本用 Script）
  awk -v want="$1" '
    /^- uid:/        { uid=$3; file="" }
    /^[ \t]+file:/   { file=$2; if (uid==want && file!="") { print file; exit } }
  ' "$APP/profiles.yaml"
}
files_of_type() { # $1 = rules —— 列出所有匹配（每个订阅一份）
  awk -v want="$1" '
    /^- uid:/        { type=""; file="" }
    /^[ \t]+type:/   { type=$2 }
    /^[ \t]+file:/   { file=$2; if (type==want && file!="") print file }
  ' "$APP/profiles.yaml"
}

# 把 rules.yaml 的自定义规则注入 Script.js（全局扩展脚本，对所有订阅生效）。
# 原因：Clash Verge Rev 的「编辑规则」文件是**订阅级**的（profiles.yaml 里挂在某个订阅的 rules 下），
# 换订阅就不再生效；只有 uid 为 Merge/Script 的两个文件是真正全局的。
generate_script() {
  python3 - "$SRC" <<'PY'
import sys, re, json
try:
    import yaml
except ImportError:
    sys.exit("❌ 需要 PyYAML（pip3 install pyyaml）")
src = sys.argv[1]
data = yaml.safe_load(open(src + "/rules.yaml")) or {}
rules = [r for r in (data.get("prepend") or []) if isinstance(r, str)]
body = "\n".join("  " + json.dumps(r, ensure_ascii=False) + "," for r in rules)
var = "var MY_RULES = [\n" + body + "\n];" if body else "var MY_RULES = [];"
tmpl = open(src + "/Script.js").read()
out, n = re.subn(
    r"(// >>> AUTO-RULES-START\n).*?(// <<< AUTO-RULES-END)",
    lambda m: m.group(1) + var + "\n" + m.group(2),
    tmpl, flags=re.S)
if not n:
    sys.exit("❌ Script.js 里找不到 AUTO-RULES 标记")
open(src + "/.Script.generated.js", "w").write(out)
print(f"🧩 已从 rules.yaml 生成 {len(rules)} 条自定义规则 → .Script.generated.js")
PY
}

TS="$(date +%Y%m%d-%H%M%S)"
backup() { # $1 = 目标文件
  [ -f "$1" ] && cp "$1" "$1.bak-$TS" && echo "     （已备份 $(basename "$1").bak-${TS}）"
  return 0
}

install_one() { # $1 = 源文件, $2 = 目标文件
  if [ -z "$2" ]; then echo "⚠️  找不到对应的覆写条目，跳过 $1"; return 0; fi
  backup "$APP/profiles/$2"
  cp "$SRC/$1" "$APP/profiles/$2"
  echo "✅ $1  →  profiles/$2"
}

generate_script
install_one ".Script.generated.js" "$(file_of_uid Script)"
install_one "Merge.yaml" "$(file_of_uid Merge)"
# 自定义规则同时写进每个订阅的「编辑规则」文件（方便在界面里看/改；真正生效靠上面的全局脚本）
while IFS= read -r f; do
  [ -n "$f" ] && install_one "rules.yaml" "$f"
done <<< "$(files_of_type rules)"

# 3) 重启应用让它重新生成运行时配置
if [ "$NO_RESTART" = "0" ]; then
  if command -v osascript >/dev/null 2>&1; then
    echo "🔄 重启 Clash Verge…"
    osascript -e 'quit app "Clash Verge"' >/dev/null 2>&1 || true
    sleep 6
    open -a "Clash Verge" >/dev/null 2>&1 || true
    sleep 15
    echo "✅ 完成。在「策略组」里确认：🚀节点选择/📨 Telegram/🤖 AI服务… 都在。"
  else
    echo "ℹ️  非 macOS：请手动重启 Clash Verge Rev 使配置生效。"
  fi
else
  echo "ℹ️  已跳过重启，请手动重启 Clash Verge Rev。"
fi

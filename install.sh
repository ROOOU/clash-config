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

install_one "Script.js"  "$(file_of_uid Script)"
install_one "Merge.yaml" "$(file_of_uid Merge)"
install_one "rules.yaml" "$(file_of_type rules)"

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

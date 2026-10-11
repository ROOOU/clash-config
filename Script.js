// ============================================================
// Clash Verge Rev —— 全局扩展脚本（对所有订阅生效）
// 职责（只管"结构"，你自己的上网规则放在 rules.yaml）：
//   1) 保证规则用到的策略组一定存在（订阅里没有就自动建，节点取当前订阅的全部节点）；
//   2) 保证自定义规则集（rule-providers）存在，并插入配套的 RULE-SET/GEOSITE 规则；
//   3) 兜底 MATCH 永远放在规则表最后；
//   4) 只有"香港节点"特殊：有香港/港/HK 关键字的节点就用它们，没有就退回 🚀节点选择。
// 位置：设置 → 覆写 → 扩展脚本（全局），对应 profiles/Script.js
// ============================================================

// 需要的策略组：["组名", [候选(第一个是默认)], 类型]；"AUTO" = 当前订阅的全部节点

// ── 自定义上网规则（由 install.sh 从 rules.yaml 自动生成，勿手改；
//    放在脚本里是为了「换任何订阅都生效」——rules.yaml 那个「编辑规则」文件其实是订阅级的）──
// >>> AUTO-RULES-START
var MY_RULES = [];
// <<< AUTO-RULES-END
var MY_GROUPS = [
  ["🚀节点选择", ["AUTO"], "select"],
  ["📨 Telegram", ["🚀节点选择", "DIRECT"], "select"],
  ["🤖 AI服务", ["🚀节点选择", "DIRECT"], "select"],
  ["🎬 国际媒体", ["🚀节点选择", "DIRECT"], "select"],
  ["🌍 全球加速", ["🚀节点选择", "DIRECT"], "select"],
  ["📺 港台番剧", ["DIRECT", "🚀节点选择"], "select"],
  ["🎮 游戏平台", ["DIRECT", "🚀节点选择"], "select"],
  ["🍎 苹果服务", ["DIRECT", "🚀节点选择"], "select"],
  ["💬 微信/国内", ["DIRECT", "🚀节点选择"], "select"],
  ["🛑 广告拦截", ["REJECT", "DIRECT"], "select"],
  ["🐟 漏网之鱼", ["🚀节点选择", "DIRECT", "REJECT"], "select"]
];

// 需要的规则集（每天自动更新；jsdelivr 国内可直连）
var BM7 = "https://cdn.jsdelivr.net/gh/blackmatrix7/ios_rule_script@master/rule/Clash/";
var MY_PROVIDERS = {
  "Telegram": "Telegram/Telegram.yaml",
  "AI服务": "OpenAI/OpenAI.yaml",
  "YouTube": "YouTube/YouTube.yaml",
  "Netflix": "Netflix/Netflix.yaml",
  "Disney": "Disney/Disney.yaml",
  "HBO": "HBO/HBO.yaml",
  "PrimeVideo": "PrimeVideo/PrimeVideo.yaml",
  "Spotify": "Spotify/Spotify.yaml",
  "Bahamut": "Bahamut/Bahamut.yaml",
  "国内直连": "ChinaMax/ChinaMax.yaml",
  "广告拦截": "Advertising/Advertising.yaml",
  "GFWList": "Global/Global.yaml",
  "苹果服务": "Apple/Apple.yaml"
};

// 规则集配套的规则（插在 rules.yaml 的规则之前；只加订阅里没有的）
var MY_PROVIDER_RULES = [
  "RULE-SET,广告拦截,🛑 广告拦截",
  "RULE-SET,国内直连,DIRECT",
  "RULE-SET,Telegram,📨 Telegram",
  "GEOSITE,telegram,📨 Telegram",
  "RULE-SET,AI服务,🤖 AI服务",
  "GEOSITE,openai,🤖 AI服务",
  "RULE-SET,YouTube,🎬 国际媒体",
  "RULE-SET,Netflix,🎬 国际媒体",
  "RULE-SET,Disney,🎬 国际媒体",
  "RULE-SET,HBO,🎬 国际媒体",
  "RULE-SET,PrimeVideo,🎬 国际媒体",
  "RULE-SET,Spotify,🎬 国际媒体",
  "RULE-SET,Bahamut,📺 港台番剧",
  "GEOSITE,bahamut,📺 港台番剧",
  "RULE-SET,GFWList,🌍 全球加速",
  "GEOSITE,geolocation-!cn,🌍 全球加速",
  "GEOIP,CN,DIRECT",
  "GEOSITE,cn,DIRECT"
];

function main(config, profileName) {
  config = config || {};

  // 当前订阅里所有可用节点名
  var nodeNames = [];
  (config.proxies || []).forEach(function (p) {
    if (p && p.name) nodeNames.push(p.name);
  });
  (config["proxy-groups"] || []).forEach(function (g) {
    if (g && g.name) nodeNames.push(g.name);
  });

  // ---- 补齐策略组 ----
  var groups = config["proxy-groups"] || (config["proxy-groups"] = []);
  var haveGroups = {};
  groups.forEach(function (g) {
    if (g && g.name) haveGroups[g.name] = true;
  });
  MY_GROUPS.forEach(function (item) {
    var name = item[0];
    if (haveGroups[name]) return;
    var proxies = [];
    item[1].forEach(function (c) {
      if (c === "AUTO") {
        nodeNames.forEach(function (n) {
          if (n !== name && proxies.indexOf(n) < 0) proxies.push(n);
        });
      } else if (proxies.indexOf(c) < 0) {
        proxies.push(c);
      }
    });
    groups.push({ name: name, type: item[2] || "select", proxies: proxies });
    haveGroups[name] = true;
  });

  // ---- 香港节点：有香港节点就用，没有就退回 🚀节点选择 ----
  if (!haveGroups["香港节点"]) {
    var ps = [];
    nodeNames.forEach(function (n) {
      if (/香港|🇭🇰|Hong\s?Kong|\bHK\b/i.test(n) && ps.indexOf(n) < 0) ps.push(n);
    });
    if (ps.indexOf("🚀节点选择") < 0) ps.push("🚀节点选择");
    if (ps.indexOf("DIRECT") < 0) ps.push("DIRECT");
    groups.push({ name: "香港节点", type: "select", proxies: ps });
    haveGroups["香港节点"] = true;
  }

  // ---- 补齐规则集 ----
  var providers = config["rule-providers"] || (config["rule-providers"] = {});
  Object.keys(MY_PROVIDERS).forEach(function (tag) {
    if (providers[tag]) return;
    providers[tag] = {
      type: "http",
      behavior: "classical",
      url: BM7 + MY_PROVIDERS[tag],
      path: "./ruleset/" + tag + ".yaml",
      interval: 86400
    };
  });

  // ---- 规则：规则集规则插到最前（去重），兜底 MATCH 放最后 ----
  var rules = config.rules || (config.rules = []);
  var finalMatch = null;
  rules = rules.filter(function (r) {
    if (typeof r === "string" && r.indexOf("MATCH") === 0) {
      if (!finalMatch) finalMatch = r;
      return false;
    }
    return true;
  });
  var existing = {};
  rules.forEach(function (r) { existing[r] = true; });
  var toAdd = MY_PROVIDER_RULES.filter(function (r) { return !existing[r]; });
  // 自定义规则优先级最高：排在规则集规则之前
  var custom = (typeof MY_RULES !== "undefined" ? MY_RULES : []).filter(function (r) {
    return r && !existing[r];
  });
  config.rules = custom.concat(toAdd).concat(rules);
  config.rules.push(finalMatch || "MATCH,🐟 漏网之鱼");

  return config;
}

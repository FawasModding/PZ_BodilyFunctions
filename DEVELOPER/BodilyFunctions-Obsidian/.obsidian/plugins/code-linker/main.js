/* Code Linker 1.6.0 — bundled from src/ by esbuild. Do not edit directly; edit src/ and run "npm run build". */
"use strict";
var __getOwnPropNames = Object.getOwnPropertyNames;
var __commonJS = (cb, mod) => function __require() {
  return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
};

// src/shared/markdown.js
var require_markdown = __commonJS({
  "src/shared/markdown.js"(exports2, module2) {
    "use strict";
    var splitLines2 = (s) => (s || "").split("\n").map((x) => x.trim()).filter(Boolean);
    var LINK_PATTERN = "\\[([^\\]]*)\\]\\(([^)]+)\\)";
    var linkRegex2 = () => new RegExp(LINK_PATTERN, "g");
    var LINK_TITLE = /^([\s\S]*?)\s+(?:"([^"]*)"|'([^']*)')$/;
    function splitTarget2(raw) {
      const s = String(raw == null ? "" : raw).trim();
      const m = LINK_TITLE.exec(s);
      if (!m)
        return { url: s, title: "" };
      return { url: m[1].trim(), title: m[2] != null ? m[2] : m[3] };
    }
    var withTitle2 = (url, title) => title ? url + ' "' + title + '"' : url;
    var isFenceLine = (line) => {
      const s = line.trimStart();
      return s.startsWith("```") || s.startsWith("~~~");
    };
    var INLINE_CODE = /`[^`\n]+`/g;
    function inMatch(line, col, re) {
      re.lastIndex = 0;
      let m;
      while ((m = re.exec(line)) !== null) {
        if (col > m.index && col < m.index + m[0].length)
          return true;
      }
      return false;
    }
    var inInlineCode = (line, col) => inMatch(line, col, INLINE_CODE);
    function locate(lines, pos) {
      let start = 0, i = 0;
      for (; i < lines.length; i++) {
        if (pos <= start + lines[i].length)
          break;
        start += lines[i].length + 1;
      }
      return { i, col: pos - start, line: lines[i] || "" };
    }
    function inCode2(text, pos) {
      if (/^---\r?\n/.test(text)) {
        const end = text.indexOf("\n---", 3);
        if (end !== -1 && pos <= end + 4)
          return true;
      }
      const lines = text.split("\n");
      const { i, col, line } = locate(lines, pos);
      let fenced = false;
      for (let k = 0; k < i; k++)
        if (isFenceLine(lines[k]))
          fenced = !fenced;
      if (fenced)
        return true;
      return inMatch(line, col, INLINE_CODE);
    }
    function inLink2(text, pos) {
      const { col, line } = locate(text.split("\n"), pos);
      return inMatch(line, col, linkRegex2());
    }
    function isProtected(text, pos) {
      return inCode2(text, pos) || inLink2(text, pos);
    }
    function inTableCell2(text, pos) {
      const lines = text.split("\n");
      const lineIdx = (text.slice(0, pos).match(/\n/g) || []).length;
      if (!lines[lineIdx] || !lines[lineIdx].includes("|"))
        return false;
      const isDelimiter = (l) => l.includes("|") && l.includes("-") && /^[\s|:-]+$/.test(l);
      let top = lineIdx, bot = lineIdx;
      while (top > 0 && lines[top - 1].trim() !== "")
        top--;
      while (bot < lines.length - 1 && lines[bot + 1].trim() !== "")
        bot++;
      for (let i = top; i <= bot; i++)
        if (isDelimiter(lines[i]))
          return true;
      return false;
    }
    function rewriteLinks(text, fn) {
      const lines = text.split("\n");
      let fenced = false, count = 0;
      for (let i = 0; i < lines.length; i++) {
        if (isFenceLine(lines[i])) {
          fenced = !fenced;
          continue;
        }
        if (fenced)
          continue;
        lines[i] = lines[i].replace(linkRegex2(), (whole, name, target, offset) => {
          if (inInlineCode(lines[i], offset))
            return whole;
          const out = fn(name, target);
          if (out == null)
            return whole;
          count++;
          return out;
        });
      }
      return { text: lines.join("\n"), count };
    }
    function rewriteFences(text, lang, fn) {
      const lines = text.split("\n");
      let count = 0;
      for (let i = 0; i < lines.length; i++) {
        const open = new RegExp("^\\s*(`{3,}|~{3,})\\s*" + lang + "\\s*$").exec(lines[i]);
        if (!open)
          continue;
        const close = new RegExp("^\\s*" + open[1][0] + "{" + open[1].length + ",}\\s*$");
        let j = i + 1;
        while (j < lines.length && !close.test(lines[j]))
          j++;
        const body = lines.slice(i + 1, j);
        const out = fn(body);
        if (out) {
          lines.splice(i + 1, body.length, ...out);
          count++;
          j = i + 1 + out.length;
        }
        i = j;
      }
      return { text: lines.join("\n"), count };
    }
    function wordAt(line, ch) {
      const s = String(line == null ? "" : line);
      if (!s)
        return "";
      const isWord = (c) => /[\p{L}\p{Nd}]/u.test(c || "");
      const at = Math.max(0, Math.min(ch, s.length));
      if (!isWord(s[at]) && !isWord(s[at - 1]))
        return "";
      let start = at;
      while (start > 0 && isWord(s[start - 1]))
        start--;
      let end = at;
      while (end < s.length && isWord(s[end]))
        end++;
      return s.slice(start, end);
    }
    module2.exports = { splitLines: splitLines2, linkRegex: linkRegex2, splitTarget: splitTarget2, withTitle: withTitle2, rewriteLinks, rewriteFences, isFenceLine, inInlineCode, locate, inCode: inCode2, inLink: inLink2, isProtected, inTableCell: inTableCell2, wordAt };
  }
});

// src/constants.js
var require_constants = __commonJS({
  "src/constants.js"(exports2, module2) {
    "use strict";
    var { splitLines: splitLines2 } = require_markdown();
    var PRESETS2 = {
      // {code-root} keeps the note portable: the file holds a relative path, the absolute code
      // root is filled in on render/click. Namespaced, so a link says which linker owns it —
      // the bare {root} it replaces was filled by the reference linker too.
      vscode: "vscode://file/{code-root}/{path}:{line}",
      // {jetbrainsProduct} resolves to the chosen JetBrains IDE (the "JetBrains IDE" setting).
      jetbrains: "jetbrains://{jetbrainsProduct}/navigate/reference?project={project}&path={path}:{line}",
      file: "file:///{code-root}/{path}",
      // Web permalinks: {gitRemote}/{gitSha} come from the file's git repo at insert time,
      // pinning the link to that exact commit. GitLab serves blobs under /-/blob.
      github: "{gitRemote}/blob/{gitSha}/{path}#L{line}",
      gitlab: "{gitRemote}/-/blob/{gitSha}/{path}#L{line}"
    };
    var PRISM_LANG2 = {
      csharp: "csharp",
      typescript: "typescript",
      javascript: "javascript",
      python: "python",
      java: "java",
      cpp: "cpp",
      php: "php",
      go: "go",
      rust: "rust"
    };
    var JETBRAINS_PRODUCTS2 = [
      ["idea", "IntelliJ IDEA"],
      ["pycharm", "PyCharm"],
      ["webstorm", "WebStorm"],
      ["phpstorm", "PhpStorm"],
      ["rubymine", "RubyMine"],
      ["clion", "CLion"],
      ["goland", "GoLand"],
      ["rider", "Rider"],
      ["rustrover", "RustRover"],
      ["datagrip", "DataGrip"]
    ];
    var DEFAULT_SETTINGS2 = {
      trigger: "@@",
      uriTemplate: PRESETS2.file,
      jetbrainsProduct: "idea",
      // IDE the JetBrains preset opens; {product} in the template
      codeRoot: "",
      // empty => parent folder of the vault
      scanRoots: "",
      // one path per line, relative to codeRoot
      skipDirs: "obj\nbin\n.git\nLibrary\nTemp\nnode_modules",
      // one folder name per line
      useGitignore: true,
      // also prune paths a .gitignore (from the scan root down) excludes
      editors: [],
      // user-defined editor presets, each { name, template }
      hiddenPresets: ["github", "gitlab"],
      // presets kept out of the pickers; revealed on first run if the remote matches
      presetsInitialized: false,
      // whether the one-time preset reveal has run
      recentPresets: [],
      // preset keys, most-recent first, to float recent picks up the picker
      askOnInsert: true,
      // ask which editor format to use on every insert (vs. a fixed preset)
      showStatusBar: false,
      // show the active editor preset in the status bar, click to switch
      showRibbonIcon: true,
      // ribbon entry to the index panel
      enabledLanguages: null,
      // null on first run => every built-in enabled
      languagesFile: "code-languages.json",
      // vault-relative JSON of extra/override languages
      disabledKinds: [],
      // "<langId>:<kind>" keys hidden from suggestions (query-time filter)
      autoRefresh: true,
      // watch scan folders and rebuild the index when code changes
      hoverPreview: true,
      // show the file-snippet popover when hovering a code link
      hoverBefore: 3,
      // preview lines shown above the target line
      hoverAfter: 20,
      // preview lines shown below the target line
      markStaleLinks: true,
      // underline links whose stored line has drifted from the code
      minChars: 1,
      maxResults: 12,
      maxFileSizeKb: 2048,
      // 0 = no limit; larger files are indexed by name only, not parsed
      contextMenu: true,
      // the "Convert"/"Find and open" items in the editor right-click menu
      // Breaks a tie when a link lands in both our index and the reference linker's and carries
      // no binding to say whose it is. A binding always decides on its own, so this only ever
      // settles the genuinely ambiguous case.
      linkPrecedence: 20
    };
    function parseSkip2(skipDirs) {
      const names = /* @__PURE__ */ new Set();
      const paths = /* @__PURE__ */ new Set();
      for (const raw of splitLines2(skipDirs)) {
        const s = raw.split("\\").join("/").replace(/^\.?\//, "").replace(/\/+$/, "");
        if (!s)
          continue;
        if (s.includes("/"))
          paths.add(s);
        else
          names.add(s);
      }
      return { names, paths };
    }
    function underSkip2(rel, skip) {
      const segs = rel.split("/").filter(Boolean);
      for (const s of segs)
        if (skip.names.has(s))
          return true;
      if (skip.paths.size) {
        let acc = "";
        for (const seg of segs) {
          acc = acc ? acc + "/" + seg : seg;
          if (skip.paths.has(acc))
            return true;
        }
      }
      return false;
    }
    var LANGUAGES_TEMPLATE2 = `[
  {
    "id": "kotlin",
    "name": "Kotlin",
    "prism": "kotlin",
    "extensions": [".kt", ".kts"],
    "patterns": [
      { "re": "^\\\\s*(?:(?:public|private|internal|open|abstract|sealed|data)\\\\s+)*(class|interface|object)\\\\s+([A-Za-z_]\\\\w*)", "kindGroup": 1, "nameGroup": 2 },
      { "re": "^\\\\s*(?:(?:public|private|internal|override|suspend|inline)\\\\s+)*fun\\\\s+([A-Za-z_]\\\\w*)", "kind": "fn", "nameGroup": 1 }
    ]
  }
]
`;
    var PATH_CHAR = /[A-Za-z0-9_.-]/;
    function pathInTarget2(dec, p) {
      let from = 0, i;
      while ((i = dec.indexOf(p, from)) !== -1) {
        if (i === 0 || !PATH_CHAR.test(dec[i - 1]))
          return true;
        from = i + 1;
      }
      return false;
    }
    module2.exports = { PRESETS: PRESETS2, PRISM_LANG: PRISM_LANG2, JETBRAINS_PRODUCTS: JETBRAINS_PRODUCTS2, DEFAULT_SETTINGS: DEFAULT_SETTINGS2, LANGUAGES_TEMPLATE: LANGUAGES_TEMPLATE2, parseSkip: parseSkip2, underSkip: underSkip2, pathInTarget: pathInTarget2 };
  }
});

// src/gitignore.js
var require_gitignore = __commonJS({
  "src/gitignore.js"(exports2, module2) {
    "use strict";
    var RE_SPECIAL = new Set(".^$+{}()|\\");
    function globToRegex(glob) {
      let re = "";
      for (let i = 0; i < glob.length; i++) {
        const c = glob[i];
        if (c === "*") {
          if (glob[i + 1] === "*") {
            i++;
            if (glob[i + 1] === "/") {
              re += "(?:.*/)?";
              i++;
            } else
              re += ".*";
          } else {
            re += "[^/]*";
          }
        } else if (c === "?") {
          re += "[^/]";
        } else if (c === "[") {
          let cls = "[";
          i++;
          if (glob[i] === "!") {
            cls += "^";
            i++;
          }
          while (i < glob.length && glob[i] !== "]") {
            cls += glob[i] === "\\" ? "\\\\" : glob[i];
            i++;
          }
          re += cls + "]";
        } else {
          re += RE_SPECIAL.has(c) ? "\\" + c : c;
        }
      }
      return re;
    }
    function compileLine(raw, base) {
      let line = raw.replace(/\r$/, "").replace(/\s+$/, "");
      if (!line || line[0] === "#")
        return null;
      let negate = false;
      if (line[0] === "!") {
        negate = true;
        line = line.slice(1);
      }
      if (line[0] === "\\" && (line[1] === "#" || line[1] === "!"))
        line = line.slice(1);
      let dirOnly = false;
      if (line.endsWith("/")) {
        dirOnly = true;
        line = line.slice(0, -1);
      }
      if (!line)
        return null;
      const hadLeading = line[0] === "/";
      const core = hadLeading ? line.slice(1) : line;
      const anchored = hadLeading || core.includes("/");
      const body = globToRegex(core);
      const prefix = anchored ? "^" : "^(?:.*/)?";
      return { negate, dirOnly, base, re: new RegExp(prefix + body + "$") };
    }
    function compileGitignore2(text, base) {
      const rules = [];
      for (const raw of String(text || "").split("\n")) {
        const rule = compileLine(raw, base);
        if (rule)
          rules.push(rule);
      }
      return rules;
    }
    function relToBase(rel, base) {
      if (!base)
        return rel;
      if (rel === base)
        return "";
      return rel.startsWith(base + "/") ? rel.slice(base.length + 1) : null;
    }
    function isIgnored2(rules, rel, isDir) {
      let ignored = false;
      for (const rule of rules) {
        if (rule.dirOnly && !isDir)
          continue;
        const sub = relToBase(rel, rule.base);
        if (sub === null || sub === "")
          continue;
        if (rule.re.test(sub))
          ignored = !rule.negate;
      }
      return ignored;
    }
    module2.exports = { compileGitignore: compileGitignore2, isIgnored: isIgnored2 };
  }
});

// src/shared/fs-watch.js
var require_fs_watch = __commonJS({
  "src/shared/fs-watch.js"(exports2, module2) {
    "use strict";
    var nodeFs = require("fs");
    var nodePath2 = require("path");
    var toPosix = (s) => String(s || "").split("\\").join("/");
    var joinRel = (rel, name) => name ? rel ? rel + "/" + toPosix(name) : toPosix(name) : rel;
    function watchTree2(roots, opts = {}) {
      const { onEvent = () => {
      }, onUnsupported, shouldDescend = () => true, fsImpl = nodeFs } = opts;
      const watchers = [];
      const watched = /* @__PURE__ */ new Set();
      let noted = false;
      const noteDegraded = () => {
        if (!noted) {
          noted = true;
          if (onUnsupported)
            onUnsupported();
        }
      };
      const arm = (dir, cb) => {
        try {
          watchers.push(fsImpl.watch(dir, cb));
          return true;
        } catch (e) {
          if (e && (e.code === "ENOSPC" || e.code === "EMFILE"))
            noteDegraded();
          return false;
        }
      };
      const onDirEvent = (dir, rel, _evt, filename) => {
        const childRel = joinRel(rel, filename);
        onEvent(childRel, filename ? toPosix(filename) : "");
        if (filename) {
          const abs = nodePath2.join(dir, String(filename));
          let st;
          try {
            st = fsImpl.statSync(abs);
          } catch (e) {
            st = null;
          }
          if (st && st.isDirectory())
            watchSubtree(abs, childRel);
        }
      };
      const watchSubtree = (dir, rel) => {
        if (watched.has(dir) || !shouldDescend(rel))
          return;
        watched.add(dir);
        arm(dir, (evt, filename) => onDirEvent(dir, rel, evt, filename));
        let entries;
        try {
          entries = fsImpl.readdirSync(dir, { withFileTypes: true });
        } catch (e) {
          return;
        }
        for (const e of entries)
          if (e.isDirectory())
            watchSubtree(nodePath2.join(dir, e.name), joinRel(rel, e.name));
      };
      for (const { dir, rel } of roots) {
        if (!fsImpl.existsSync(dir))
          continue;
        try {
          watchers.push(fsImpl.watch(dir, { recursive: true }, (_evt, filename) => onEvent(joinRel(rel, filename), filename ? toPosix(filename) : "")));
        } catch (e) {
          if (e && e.code === "ERR_FEATURE_UNAVAILABLE_ON_PLATFORM") {
            noteDegraded();
            watchSubtree(dir, rel);
          }
        }
      }
      return {
        close() {
          for (const w of watchers) {
            try {
              w.close();
            } catch (e) {
            }
          }
          watchers.length = 0;
          watched.clear();
        }
      };
    }
    module2.exports = { watchTree: watchTree2, joinRel };
  }
});

// src/shared/binding.js
var require_binding = __commonJS({
  "src/shared/binding.js"(exports2, module2) {
    "use strict";
    var ANCHOR_LIST = [
      { token: "sym", field: "sym", owner: "code" },
      { token: "kind", field: "kind", owner: "code" },
      { token: "cite", field: "cite", owner: "reference" },
      { token: "sec", field: "sec", owner: "reference" },
      // A hash is base36 already, so it is the one value written through unescaped.
      { token: "line", field: "hash", owner: "code", raw: true }
    ];
    var ANCHORS2 = {};
    var FIELDS = [];
    var OWNERS = {};
    for (const a of ANCHOR_LIST) {
      ANCHORS2[a.token] = a.field;
      FIELDS.push(a.field);
      (OWNERS[a.owner] = OWNERS[a.owner] || []).push(a.field);
    }
    var TOKEN2 = new RegExp("^(" + ANCHOR_LIST.map((a) => a.token).join("|") + "):(.+)$");
    function ownerOf(binding) {
      if (!binding)
        return null;
      const claimed = Object.keys(OWNERS).filter((owner) => OWNERS[owner].some((anchor) => binding[anchor]));
      return claimed.length === 1 ? claimed[0] : null;
    }
    var bindingOwner2 = (title) => ownerOf(parseBinding2(title));
    var ownsBinding = (title, owner) => bindingOwner2(title) === owner;
    var LINE_RE2 = /:(\d+)(?=\D*$)/;
    var PAGE_RE = /#page=(\d+)/i;
    var encodeValue = (v) => String(v).replace(/[%"()\s]/g, (c) => "%" + c.charCodeAt(0).toString(16).toUpperCase().padStart(2, "0"));
    var decodeValue = (v) => v.replace(/%([0-9A-Fa-f]{2})/g, (_, h) => String.fromCharCode(parseInt(h, 16)));
    function hashLine2(text) {
      let h = 2166136261;
      const s = String(text || "").trim();
      for (let i = 0; i < s.length; i++) {
        h ^= s.charCodeAt(i);
        h = Math.imul(h, 16777619) >>> 0;
      }
      return h.toString(36);
    }
    function parseBinding2(title) {
      const s = String(title || "").trim();
      if (!s)
        return null;
      const b = {};
      for (const f of FIELDS)
        b[f] = "";
      for (const word of s.split(/\s+/)) {
        const m = TOKEN2.exec(word);
        if (!m)
          return null;
        b[ANCHORS2[m[1]]] = decodeValue(m[2]);
      }
      return FIELDS.some((f) => b[f]) ? b : null;
    }
    function formatBinding2(b) {
      const parts = [];
      for (const a of ANCHOR_LIST) {
        const v = b[a.field];
        if (v)
          parts.push(a.token + ":" + (a.raw ? v : encodeValue(v)));
      }
      return parts.join(" ");
    }
    function bindStateFrom2(hits, stored) {
      if (hits.includes(stored))
        return null;
      if (!hits.length)
        return { state: "broken" };
      const line = hits.reduce((a, n) => Math.abs(n - stored) < Math.abs(a - stored) ? n : a);
      return { state: "stale", line };
    }
    module2.exports = { LINE_RE: LINE_RE2, PAGE_RE, ANCHORS: ANCHORS2, OWNERS, hashLine: hashLine2, parseBinding: parseBinding2, formatBinding: formatBinding2, bindStateFrom: bindStateFrom2, ownerOf, bindingOwner: bindingOwner2, ownsBinding };
  }
});

// src/shared/root-token.js
var require_root_token = __commonJS({
  "src/shared/root-token.js"(exports2, module2) {
    "use strict";
    var OWNER_TOKENS = { code: "code-root", reference: "ref-root" };
    var LEGACY_TOKEN = "root";
    var tokenRe = (name) => new RegExp("\\{" + name + "\\}|%7B" + name + "%7D", "gi");
    function rootTokenIn(url) {
      const s = String(url == null ? "" : url);
      for (const owner of Object.keys(OWNER_TOKENS)) {
        if (tokenRe(OWNER_TOKENS[owner]).test(s))
          return owner;
      }
      return tokenRe(LEGACY_TOKEN).test(s) ? "legacy" : null;
    }
    function ownsRootToken2(url, owner, claimLegacy) {
      const found = rootTokenIn(url);
      if (found === owner)
        return true;
      return found === "legacy" && !!claimLegacy;
    }
    function fillRoot(url, { owner, root, claimLegacy = false } = {}) {
      const s = String(url == null ? "" : url);
      if (!owner || !OWNER_TOKENS[owner])
        return s;
      let out = s.replace(tokenRe(OWNER_TOKENS[owner]), root);
      if (claimLegacy)
        out = out.replace(tokenRe(LEGACY_TOKEN), root);
      return out;
    }
    function namespaceRoot2(url, owner) {
      const s = String(url == null ? "" : url);
      if (!owner || !OWNER_TOKENS[owner])
        return s;
      if (rootTokenIn(s) !== "legacy")
        return s;
      return s.replace(tokenRe(LEGACY_TOKEN), "{" + OWNER_TOKENS[owner] + "}");
    }
    module2.exports = { OWNER_TOKENS, LEGACY_TOKEN, rootTokenIn, ownsRootToken: ownsRootToken2, fillRoot, namespaceRoot: namespaceRoot2 };
  }
});

// src/shared/menu.js
var require_menu = __commonJS({
  "src/shared/menu.js"(exports2, module2) {
    "use strict";
    var obsidian = require("obsidian");
    var submenuSupport = null;
    function supportsSubmenu() {
      if (submenuSupport !== null)
        return submenuSupport;
      submenuSupport = false;
      try {
        const probe = new obsidian.Menu();
        probe.addItem((item) => {
          submenuSupport = typeof item.setSubmenu === "function";
        });
      } catch (e) {
        submenuSupport = false;
      }
      return submenuSupport;
    }
    function menuSection2(menu, label, grouped, icon) {
      if (!grouped)
        return menu;
      if (!supportsSubmenu()) {
        return {
          addItem(cb) {
            return menu.addItem((item) => {
              const setTitle = item.setTitle.bind(item);
              item.setTitle = (title) => setTitle(`${label}: ${title}`);
              cb(item);
            });
          },
          addSeparator() {
            return menu.addSeparator();
          }
        };
      }
      let sub = null;
      const ensure = () => {
        if (!sub) {
          menu.addItem((item) => {
            item.setTitle(label);
            if (icon)
              item.setIcon(icon);
            sub = item.setSubmenu();
          });
        }
        return sub;
      };
      return {
        addItem(cb) {
          return ensure().addItem(cb);
        },
        addSeparator() {
          return sub ? sub.addSeparator() : null;
        }
      };
    }
    var STORE = "__linkerMenuSections";
    function sharedSection(menu, key, label, icon) {
      if (!supportsSubmenu())
        return menuSection2(menu, label, true);
      let store = menu[STORE];
      if (!store) {
        store = {};
        try {
          Object.defineProperty(menu, STORE, { value: store, enumerable: false, configurable: true });
        } catch (e) {
          return menuSection2(menu, label, true, icon);
        }
      }
      if (!store[key]) {
        menu.addItem((item) => {
          item.setTitle(label);
          if (icon)
            item.setIcon(icon);
          store[key] = item.setSubmenu();
        });
      }
      return store[key];
    }
    module2.exports = { menuSection: menuSection2, sharedSection, supportsSubmenu };
  }
});

// src/shared/discover.js
var require_discover = __commonJS({
  "src/shared/discover.js"(exports2, module2) {
    "use strict";
    var LINKER_API = 1;
    function discoverLinkers(app, opts) {
      const minVersion = opts && opts.minVersion || LINKER_API;
      const found = [];
      const plugins = app && app.plugins && app.plugins.plugins;
      if (!plugins)
        return found;
      for (const id of Object.keys(plugins)) {
        const plugin = plugins[id];
        const provider = plugin && plugin.api && plugin.api.linker;
        if (!provider || typeof provider.id !== "string")
          continue;
        if (!(provider.apiVersion >= minVersion))
          continue;
        found.push(provider);
      }
      return found;
    }
    function outranks(a, b) {
      if (a.precedence !== b.precedence)
        return (a.precedence || 0) > (b.precedence || 0);
      return String(a.id) < String(b.id);
    }
    function drawsHere(peer, where) {
      if (typeof peer.drawsIn !== "function")
        return true;
      const w = where || {};
      try {
        return peer.drawsIn(w.path, w.surface) !== false;
      } catch (e) {
        return true;
      }
    }
    function foreignRanges(app, self, text, where) {
      const ranges = [];
      for (const peer of discoverLinkers(app)) {
        if (peer.id === self.id || !outranks(peer, self))
          continue;
        if (typeof peer.matches !== "function" || !drawsHere(peer, where))
          continue;
        let matches;
        try {
          matches = peer.matches(text) || [];
        } catch (e) {
          matches = [];
        }
        for (const m of matches) {
          if (m && typeof m.start === "number" && typeof m.end === "number")
            ranges.push([m.start, m.end]);
        }
      }
      return ranges.sort((a, b) => a[0] - b[0]);
    }
    function overlaps(ranges, s, e) {
      for (const [rs, re] of ranges) {
        if (rs >= e)
          break;
        if (re > s)
          return true;
      }
      return false;
    }
    function ownedMatches(app, self, text, matches, where) {
      if (!matches.length)
        return matches;
      const foreign = foreignRanges(app, self, text, where);
      if (!foreign.length)
        return matches;
      return matches.filter((m) => !overlaps(foreign, m.start, m.end));
    }
    function yieldedCandidates(app, self, text, where) {
      const out = [];
      for (const peer of discoverLinkers(app)) {
        if (peer.id === self.id || outranks(peer, self))
          continue;
        if (typeof peer.matches !== "function" || !drawsHere(peer, where))
          continue;
        let matches;
        try {
          matches = peer.matches(text) || [];
        } catch (e) {
          matches = [];
        }
        for (const m of matches) {
          if (!m || typeof m.start !== "number" || typeof m.end !== "number")
            continue;
          out.push({
            start: m.start,
            end: m.end,
            label: m.label || m.target || "",
            target: m.target,
            // The id survives a round trip through a DOM attribute; the opener is looked up
            // again at click time.
            id: peer.id,
            source: peer.displayName || peer.id,
            // How this row reads in an ambiguity list, asked of its owner and only when a list is
            // actually drawn — every span on screen produces candidates, few are ever looked at.
            describe: (display) => {
              if (typeof peer.describe !== "function")
                return null;
              try {
                return peer.describe(m.target, display);
              } catch (e) {
                return null;
              }
            },
            open: (sourcePath, newTab) => {
              if (typeof peer.open === "function")
                peer.open(m.target, sourcePath, newTab);
            },
            hover: (event, targetEl, sourcePath, hoverParent) => {
              if (typeof peer.hover === "function")
                peer.hover(m.target, event, targetEl, sourcePath, hoverParent);
            }
          });
        }
      }
      return out;
    }
    function candidatesFor(candidates, s, e) {
      return candidates.filter((c) => c.start < e && c.end > s);
    }
    function peerSuggestions(app, self, query, sourcePath) {
      const out = [];
      for (const peer of discoverLinkers(app)) {
        if (peer.id === self.id || typeof peer.suggest !== "function")
          continue;
        let items;
        try {
          items = peer.suggest(String(query || ""), sourcePath) || [];
        } catch (e) {
          items = [];
        }
        for (const it of items) {
          if (!it || typeof it.label !== "string")
            continue;
          out.push({
            label: it.label,
            note: it.note || "",
            target: it.target,
            // null means "keep what the reader typed"; only the peer knows whether its
            // candidate matched an inflection or completed a prefix.
            display: it.display == null ? null : it.display,
            id: peer.id,
            source: peer.displayName || peer.id,
            precedence: peer.precedence || 0,
            // Answered by the row's owner, including whether to compose a link at all. A peer
            // that predates `insertFor` has only `linkFor`, which always links — the right
            // reading for a plugin with no plain-text mode to consult.
            insert: (display, inTable) => {
              if (typeof peer.insertFor === "function")
                return peer.insertFor(it.target, display, inTable);
              return typeof peer.linkFor === "function" ? peer.linkFor(it.target, display, inTable) : null;
            }
          });
        }
      }
      return out;
    }
    function peersOffering(app, self, kind, text) {
      const out = [];
      for (const peer of discoverLinkers(app)) {
        if (peer.id === self.id || typeof peer.offers !== "function")
          continue;
        let yes;
        try {
          yes = peer.offers(kind, text);
        } catch (e) {
          yes = false;
        }
        if (yes)
          out.push(peer);
      }
      return out;
    }
    function siblingLinkers(app, self) {
      return discoverLinkers(app).filter((p) => p.id !== self.id);
    }
    module2.exports = { LINKER_API, discoverLinkers, outranks, drawsHere, foreignRanges, overlaps, ownedMatches, yieldedCandidates, candidatesFor, peerSuggestions, peersOffering, siblingLinkers };
  }
});

// src/shared/locales/common.js
var require_common = __commonJS({
  "src/shared/locales/common.js"(exports2, module2) {
    "use strict";
    var en = {
      "modal.andMore": "\u2026and {n} more",
      "btn.apply": "Apply",
      "btn.cancel": "Cancel",
      "btn.close": "Close",
      "label.thisNote": "This note",
      "modal.update.summary": "{links} change(s) across {files} note(s). Uncheck any change to skip it, or a note to skip all of its changes.",
      "modal.update.upToDate": "Everything is up to date \u2014 nothing to update.",
      "notice.updateSkipped": "({n} note(s) skipped \u2014 changed since the preview)",
      "set.heading.maintenance": "Maintenance",
      "set.rebuild.button": "Rebuild",
      "set.precedence.name": "Priority among linker plugins",
      "set.precedence.desc": "A word or link several linkers claim goes to the one highest in this list. You can only move this plugin \u2014 move the others from their own settings.",
      "set.precedence.other": "Moved from its own settings",
      "set.precedence.up": "Move up",
      "set.precedence.down": "Move down"
    };
    var ru = {
      "modal.andMore": "\u2026\u0438 \u0435\u0449\u0451 {n}",
      "btn.apply": "\u041F\u0440\u0438\u043C\u0435\u043D\u0438\u0442\u044C",
      "btn.cancel": "\u041E\u0442\u043C\u0435\u043D\u0430",
      "btn.close": "\u0417\u0430\u043A\u0440\u044B\u0442\u044C",
      "label.thisNote": "\u042D\u0442\u0430 \u0437\u0430\u043C\u0435\u0442\u043A\u0430",
      "modal.update.summary": "\u041F\u0440\u0430\u0432\u043E\u043A \u2014 {links} \u0432 \u0437\u0430\u043C\u0435\u0442\u043A\u0430\u0445: {files}. \u0421\u043D\u0438\u043C\u0438\u0442\u0435 \u0433\u0430\u043B\u043E\u0447\u043A\u0443 \u0441 \u043F\u0440\u0430\u0432\u043A\u0438, \u0447\u0442\u043E\u0431\u044B \u043F\u0440\u043E\u043F\u0443\u0441\u0442\u0438\u0442\u044C \u0435\u0451, \u0438\u043B\u0438 \u0441 \u0437\u0430\u043C\u0435\u0442\u043A\u0438 \u2014 \u0447\u0442\u043E\u0431\u044B \u043F\u0440\u043E\u043F\u0443\u0441\u0442\u0438\u0442\u044C \u0432\u0441\u0435 \u0435\u0451 \u043F\u0440\u0430\u0432\u043A\u0438.",
      "modal.update.upToDate": "\u0412\u0441\u0451 \u0430\u043A\u0442\u0443\u0430\u043B\u044C\u043D\u043E \u2014 \u043E\u0431\u043D\u043E\u0432\u043B\u044F\u0442\u044C \u043D\u0435\u0447\u0435\u0433\u043E.",
      "notice.updateSkipped": "(\u043F\u0440\u043E\u043F\u0443\u0449\u0435\u043D\u043E \u0437\u0430\u043C\u0435\u0442\u043E\u043A \u2014 {n}: \u0438\u0437\u043C\u0435\u043D\u0438\u043B\u0438\u0441\u044C \u043F\u043E\u0441\u043B\u0435 \u043F\u0440\u0435\u0434\u043F\u0440\u043E\u0441\u043C\u043E\u0442\u0440\u0430)",
      "set.heading.maintenance": "\u041E\u0431\u0441\u043B\u0443\u0436\u0438\u0432\u0430\u043D\u0438\u0435",
      "set.rebuild.button": "\u041F\u0435\u0440\u0435\u0441\u0442\u0440\u043E\u0438\u0442\u044C",
      "set.precedence.name": "\u041F\u0440\u0438\u043E\u0440\u0438\u0442\u0435\u0442 \u0441\u0440\u0435\u0434\u0438 \u043F\u043B\u0430\u0433\u0438\u043D\u043E\u0432-\u043B\u0438\u043D\u043A\u0435\u0440\u043E\u0432",
      "set.precedence.desc": "\u0421\u043B\u043E\u0432\u043E \u0438\u043B\u0438 \u0441\u0441\u044B\u043B\u043A\u0443, \u043D\u0430 \u043A\u043E\u0442\u043E\u0440\u044B\u0435 \u043F\u0440\u0435\u0442\u0435\u043D\u0434\u0443\u044E\u0442 \u043D\u0435\u0441\u043A\u043E\u043B\u044C\u043A\u043E \u043B\u0438\u043D\u043A\u0435\u0440\u043E\u0432, \u0437\u0430\u0431\u0438\u0440\u0430\u0435\u0442 \u0442\u043E\u0442, \u043A\u0442\u043E \u0432\u044B\u0448\u0435 \u0432 \u0441\u043F\u0438\u0441\u043A\u0435. \u041E\u0442\u0441\u044E\u0434\u0430 \u0434\u0432\u0438\u0433\u0430\u0435\u0442\u0441\u044F \u0442\u043E\u043B\u044C\u043A\u043E \u044D\u0442\u043E\u0442 \u043F\u043B\u0430\u0433\u0438\u043D \u2014 \u043E\u0441\u0442\u0430\u043B\u044C\u043D\u044B\u0435 \u0438\u0437 \u0441\u0432\u043E\u0438\u0445 \u043D\u0430\u0441\u0442\u0440\u043E\u0435\u043A.",
      "set.precedence.other": "\u0414\u0432\u0438\u0433\u0430\u0435\u0442\u0441\u044F \u0438\u0437 \u0441\u0432\u043E\u0438\u0445 \u043D\u0430\u0441\u0442\u0440\u043E\u0435\u043A",
      "set.precedence.up": "\u0412\u044B\u0448\u0435",
      "set.precedence.down": "\u041D\u0438\u0436\u0435"
    };
    var de = {
      "modal.andMore": "\u2026und {n} weitere",
      "btn.apply": "Anwenden",
      "btn.cancel": "Abbrechen",
      "set.heading.maintenance": "Wartung",
      "set.rebuild.button": "Neu aufbauen"
    };
    var es = {
      "modal.andMore": "\u2026y {n} m\xE1s",
      "btn.apply": "Aplicar",
      "btn.cancel": "Cancelar",
      "set.heading.maintenance": "Mantenimiento",
      "set.rebuild.button": "Reconstruir"
    };
    var fr = {
      "modal.andMore": "\u2026et {n} de plus",
      "btn.apply": "Appliquer",
      "btn.cancel": "Annuler",
      "set.heading.maintenance": "Maintenance",
      "set.rebuild.button": "Reconstruire"
    };
    var uk = {
      "modal.andMore": "\u2026\u0442\u0430 \u0449\u0435 {n}",
      "btn.apply": "\u0417\u0430\u0441\u0442\u043E\u0441\u0443\u0432\u0430\u0442\u0438",
      "btn.cancel": "\u0421\u043A\u0430\u0441\u0443\u0432\u0430\u0442\u0438",
      "set.heading.maintenance": "\u041E\u0431\u0441\u043B\u0443\u0433\u043E\u0432\u0443\u0432\u0430\u043D\u043D\u044F",
      "set.rebuild.button": "\u041F\u0435\u0440\u0435\u0431\u0443\u0434\u0443\u0432\u0430\u0442\u0438"
    };
    module2.exports = { en, ru, de, es, fr, uk };
  }
});

// src/shared/locales/prose.js
var require_prose = __commonJS({
  "src/shared/locales/prose.js"(exports2, module2) {
    "use strict";
    var en = {
      "noun.file": "file",
      "noun.folder": "folder",
      "scope.first": "first",
      "scope.all": "all",
      "menu.linkThisWord": "Link \u201C{display}\u201D",
      "menu.linkHere": "Link \u201C{display}\u201D here",
      "menu.linkDisplayTo": 'Link "{display}" to\u2026',
      "menu.linkScopeTo": 'Link {scope} "{display}" to\u2026',
      "menu.openThisWord": "Open \u201C{display}\u201D",
      "modal.choose.title": "Which one?",
      "set.heading.scope": "Scope",
      "set.heading.matching": "Matching",
      "set.languages.name": "Languages",
      "set.languages.show": "Show languages",
      "set.languages.hide": "Hide languages",
      "set.lang.higher": "Higher priority",
      "set.lang.lower": "Lower priority",
      "set.linkFirstOnly.name": "Link first occurrence only",
      "set.heading.highlighting": "Highlighting",
      "set.highlightInReading.name": "Highlight in Reading view",
      "set.editingHighlight.onSave": "On save",
      "set.skipHeadings.name": "Skip headings",
      "set.statusBar.name": "Status bar count",
      "set.heading.autocomplete": "Autocomplete",
      "set.linkSuggest.name": "Suggest links while typing",
      "set.suggestMinChars.desc": "How many characters to type before suggestions appear.",
      "set.suggestSkipAfter.name": "Skip after characters",
      "set.suggestPlainText.name": "Insert plain text",
      "set.suggestPlainText.desc": "Suggestions complete the word without turning it into a link.",
      "set.heading.contextMenu": "Context menu",
      // The shared submenu the exclusion items collect into, and their wording inside it, where
      // the parent already names the word.
      "exclude.group": "Exclude \u201C{value}\u201D",
      "exclude.addShort": "Add to {noun}",
      "exclude.removeShort": "Remove from {noun}",
      "label.selection": "Selection",
      "modal.leftAsText": "(left as text)",
      "modal.skipOption": "skip",
      "modal.materialize.summary": "Reviewing {files} file(s), {replacements} replacement(s).",
      "modal.unlink.summary": "Reviewing {files} file(s), {links} link(s).",
      "modal.choose.body": "This word has more than one match.",
      "notice.noActiveNote": "No active note.",
      "notice.noSelection": "Nothing selected.",
      "notice.scopeSkipped": " Skipped {n} note(s) changed since the preview.",
      "set.editingHighlight.live": "Live",
      "set.editingHighlight.name": "Highlight in the editor",
      "set.lang.invalid": "Invalid: {error}",
      "set.languages.desc": "{enabled} of {total} enabled",
      "set.matchMode.name": "Match mode",
      "set.matchMode.exact": "Exact (case-insensitive)",
      "set.matchMode.endingStrip": "Light ending strip",
      "set.matchMode.stemmer": "Stemmer (best across forms)",
      "kind.heading": "Heading",
      "kind.term": "Term",
      "kind.viaAlias": "via alias \u201C{form}\u201D",
      "set.smartCase.name": "Smart case for acronyms",
      "set.smartCase.desc": "Match mostly-uppercase terms (like \u201CIT\u201D or \u201CNASA\u201D) case-sensitively, so they don\u2019t link ordinary words.",
      "set.scopeMode.name": "Where to link",
      "set.scopeMode.vault": "The whole vault",
      "set.scopeMode.folders": "Only chosen folders",
      "set.suggestMinChars.name": "Minimum typed length",
      "set.statusBarIncludeLinks.name": "Count existing links too",
      "set.folderList.add": "Add path\u2026",
      "set.folderList.addAria": "Add",
      "plural.alias": { one: "{n} alias", other: "{n} aliases" }
    };
    var ru = {
      "noun.file": "\u0444\u0430\u0439\u043B",
      "noun.folder": "\u043F\u0430\u043F\u043A\u0443",
      "scope.first": "\u043F\u0435\u0440\u0432\u043E\u0435",
      "scope.all": "\u0432\u0441\u0435",
      "menu.linkThisWord": "\u0421\u0432\u044F\u0437\u0430\u0442\u044C \xAB{display}\xBB",
      "menu.linkHere": "\u0421\u0432\u044F\u0437\u0430\u0442\u044C \xAB{display}\xBB \u0437\u0434\u0435\u0441\u044C",
      "menu.linkDisplayTo": "\u0421\u0432\u044F\u0437\u0430\u0442\u044C \xAB{display}\xBB \u0441\u2026",
      "menu.linkScopeTo": "\u0421\u0432\u044F\u0437\u0430\u0442\u044C {scope} \xAB{display}\xBB \u0441\u2026",
      "menu.openThisWord": "\u041E\u0442\u043A\u0440\u044B\u0442\u044C \xAB{display}\xBB",
      "modal.choose.title": "\u041A\u0430\u043A\u043E\u0435 \u0438\u0437 \u0441\u043E\u0432\u043F\u0430\u0434\u0435\u043D\u0438\u0439?",
      "set.heading.scope": "\u041E\u0431\u043B\u0430\u0441\u0442\u044C",
      "set.heading.matching": "\u0421\u043E\u043F\u043E\u0441\u0442\u0430\u0432\u043B\u0435\u043D\u0438\u0435",
      "set.languages.name": "\u042F\u0437\u044B\u043A\u0438",
      "set.languages.show": "\u041F\u043E\u043A\u0430\u0437\u0430\u0442\u044C \u044F\u0437\u044B\u043A\u0438",
      "set.languages.hide": "\u0421\u043A\u0440\u044B\u0442\u044C \u044F\u0437\u044B\u043A\u0438",
      "set.lang.higher": "\u0412\u044B\u0448\u0435 \u043F\u0440\u0438\u043E\u0440\u0438\u0442\u0435\u0442",
      "set.lang.lower": "\u041D\u0438\u0436\u0435 \u043F\u0440\u0438\u043E\u0440\u0438\u0442\u0435\u0442",
      "set.linkFirstOnly.name": "\u0421\u0432\u044F\u0437\u044B\u0432\u0430\u0442\u044C \u0442\u043E\u043B\u044C\u043A\u043E \u043F\u0435\u0440\u0432\u043E\u0435 \u0432\u0445\u043E\u0436\u0434\u0435\u043D\u0438\u0435",
      "set.heading.highlighting": "\u041F\u043E\u0434\u0441\u0432\u0435\u0442\u043A\u0430",
      "set.highlightInReading.name": "\u041F\u043E\u0434\u0441\u0432\u0435\u0442\u043A\u0430 \u0432 \u0440\u0435\u0436\u0438\u043C\u0435 \u0447\u0442\u0435\u043D\u0438\u044F",
      "set.editingHighlight.onSave": "\u041F\u0440\u0438 \u0441\u043E\u0445\u0440\u0430\u043D\u0435\u043D\u0438\u0438",
      "set.skipHeadings.name": "\u041F\u0440\u043E\u043F\u0443\u0441\u043A\u0430\u0442\u044C \u0437\u0430\u0433\u043E\u043B\u043E\u0432\u043A\u0438",
      "set.statusBar.name": "\u0421\u0447\u0451\u0442\u0447\u0438\u043A \u0432 \u0441\u0442\u0440\u043E\u043A\u0435 \u0441\u043E\u0441\u0442\u043E\u044F\u043D\u0438\u044F",
      "set.heading.autocomplete": "\u0410\u0432\u0442\u043E\u0434\u043E\u043F\u043E\u043B\u043D\u0435\u043D\u0438\u0435",
      "set.linkSuggest.name": "\u041F\u043E\u0434\u0441\u043A\u0430\u0437\u044B\u0432\u0430\u0442\u044C \u0441\u0441\u044B\u043B\u043A\u0438 \u043F\u0440\u0438 \u043D\u0430\u0431\u043E\u0440\u0435",
      "set.suggestMinChars.desc": "\u0421\u043A\u043E\u043B\u044C\u043A\u043E \u0441\u0438\u043C\u0432\u043E\u043B\u043E\u0432 \u043D\u0430\u0431\u0440\u0430\u0442\u044C, \u043F\u0440\u0435\u0436\u0434\u0435 \u0447\u0435\u043C \u043F\u043E\u044F\u0432\u044F\u0442\u0441\u044F \u043F\u043E\u0434\u0441\u043A\u0430\u0437\u043A\u0438.",
      "set.suggestSkipAfter.name": "\u041F\u0440\u043E\u043F\u0443\u0441\u043A\u0430\u0442\u044C \u043F\u043E\u0441\u043B\u0435 \u0441\u0438\u043C\u0432\u043E\u043B\u043E\u0432",
      "set.suggestPlainText.name": "\u0412\u0441\u0442\u0430\u0432\u043B\u044F\u0442\u044C \u043F\u0440\u043E\u0441\u0442\u043E\u0439 \u0442\u0435\u043A\u0441\u0442",
      "set.suggestPlainText.desc": "\u041F\u043E\u0434\u0441\u043A\u0430\u0437\u043A\u0430 \u0434\u043E\u043F\u0438\u0441\u044B\u0432\u0430\u0435\u0442 \u0441\u043B\u043E\u0432\u043E, \u043D\u0435 \u043F\u0440\u0435\u0432\u0440\u0430\u0449\u0430\u044F \u0435\u0433\u043E \u0432 \u0441\u0441\u044B\u043B\u043A\u0443.",
      "set.heading.contextMenu": "\u041A\u043E\u043D\u0442\u0435\u043A\u0441\u0442\u043D\u043E\u0435 \u043C\u0435\u043D\u044E",
      "exclude.group": "\u0418\u0441\u043A\u043B\u044E\u0447\u0438\u0442\u044C \xAB{value}\xBB",
      "exclude.addShort": "\u0414\u043E\u0431\u0430\u0432\u0438\u0442\u044C \u0432 {noun}",
      "exclude.removeShort": "\u0423\u0431\u0440\u0430\u0442\u044C \u0438\u0437 {noun}",
      "label.selection": "\u0412\u044B\u0434\u0435\u043B\u0435\u043D\u0438\u0435",
      "modal.leftAsText": "(\u043E\u0441\u0442\u0430\u0432\u043B\u0435\u043D\u043E \u0442\u0435\u043A\u0441\u0442\u043E\u043C)",
      "modal.skipOption": "\u043F\u0440\u043E\u043F\u0443\u0441\u0442\u0438\u0442\u044C",
      "modal.materialize.summary": "\u041F\u0440\u043E\u0432\u0435\u0440\u043A\u0430: \u0444\u0430\u0439\u043B\u043E\u0432 \u2014 {files}, \u0437\u0430\u043C\u0435\u043D \u2014 {replacements}.",
      "modal.unlink.summary": "\u041F\u0440\u043E\u0432\u0435\u0440\u043A\u0430: \u0444\u0430\u0439\u043B\u043E\u0432 \u2014 {files}, \u0441\u0441\u044B\u043B\u043E\u043A \u2014 {links}.",
      "modal.choose.body": "\u0423 \u044D\u0442\u043E\u0433\u043E \u0441\u043B\u043E\u0432\u0430 \u043D\u0435\u0441\u043A\u043E\u043B\u044C\u043A\u043E \u0441\u043E\u0432\u043F\u0430\u0434\u0435\u043D\u0438\u0439.",
      "notice.noActiveNote": "\u041D\u0435\u0442 \u0430\u043A\u0442\u0438\u0432\u043D\u043E\u0439 \u0437\u0430\u043C\u0435\u0442\u043A\u0438.",
      "notice.noSelection": "\u041D\u0438\u0447\u0435\u0433\u043E \u043D\u0435 \u0432\u044B\u0434\u0435\u043B\u0435\u043D\u043E.",
      "notice.scopeSkipped": " \u041F\u0440\u043E\u043F\u0443\u0449\u0435\u043D\u043E \u0437\u0430\u043C\u0435\u0442\u043E\u043A, \u0438\u0437\u043C\u0435\u043D\u0451\u043D\u043D\u044B\u0445 \u043F\u043E\u0441\u043B\u0435 \u043F\u0440\u0435\u0432\u044C\u044E: {n}.",
      "set.editingHighlight.live": "\u041D\u0430 \u043B\u0435\u0442\u0443",
      "set.editingHighlight.name": "\u041F\u043E\u0434\u0441\u0432\u0435\u0442\u043A\u0430 \u0432 \u0440\u0435\u0434\u0430\u043A\u0442\u043E\u0440\u0435",
      "set.lang.invalid": "\u041E\u0448\u0438\u0431\u043A\u0430: {error}",
      "set.languages.desc": "\u0412\u043A\u043B\u044E\u0447\u0435\u043D\u043E {enabled} \u0438\u0437 {total}",
      "set.matchMode.name": "\u0420\u0435\u0436\u0438\u043C \u0441\u043E\u043F\u043E\u0441\u0442\u0430\u0432\u043B\u0435\u043D\u0438\u044F",
      "set.matchMode.exact": "\u0422\u043E\u0447\u043D\u043E\u0435 (\u0431\u0435\u0437 \u0443\u0447\u0451\u0442\u0430 \u0440\u0435\u0433\u0438\u0441\u0442\u0440\u0430)",
      "set.matchMode.endingStrip": "\u041B\u0451\u0433\u043A\u043E\u0435 \u043E\u0442\u0441\u0435\u0447\u0435\u043D\u0438\u0435 \u043E\u043A\u043E\u043D\u0447\u0430\u043D\u0438\u0439",
      "set.matchMode.stemmer": "\u0421\u0442\u0435\u043C\u043C\u0435\u0440 (\u043B\u0443\u0447\u0448\u0435 \u0434\u043B\u044F \u0432\u0441\u0435\u0445 \u0444\u043E\u0440\u043C)",
      "kind.heading": "\u0417\u0430\u0433\u043E\u043B\u043E\u0432\u043E\u043A",
      "kind.term": "\u0422\u0435\u0440\u043C\u0438\u043D",
      "kind.viaAlias": "\u043F\u043E \u0430\u043B\u0438\u0430\u0441\u0443 \xAB{form}\xBB",
      "set.smartCase.name": "\u0423\u043C\u043D\u044B\u0439 \u0440\u0435\u0433\u0438\u0441\u0442\u0440 \u0434\u043B\u044F \u0430\u0431\u0431\u0440\u0435\u0432\u0438\u0430\u0442\u0443\u0440",
      "set.smartCase.desc": "\u0422\u0435\u0440\u043C\u0438\u043D\u044B \u0438\u0437 \u0437\u0430\u0433\u043B\u0430\u0432\u043D\u044B\u0445 \u0431\u0443\u043A\u0432 (\u043D\u0430\u043F\u0440\u0438\u043C\u0435\u0440 \xABIT\xBB \u0438\u043B\u0438 \xABNASA\xBB) \u0441\u043E\u043F\u043E\u0441\u0442\u0430\u0432\u043B\u044F\u044E\u0442\u0441\u044F \u0441 \u0443\u0447\u0451\u0442\u043E\u043C \u0440\u0435\u0433\u0438\u0441\u0442\u0440\u0430, \u0447\u0442\u043E\u0431\u044B \u043D\u0435 \u0446\u0435\u043F\u043B\u044F\u0442\u044C \u043E\u0431\u044B\u0447\u043D\u044B\u0435 \u0441\u043B\u043E\u0432\u0430.",
      "set.scopeMode.name": "\u0413\u0434\u0435 \u0441\u0432\u044F\u0437\u044B\u0432\u0430\u0442\u044C",
      "set.scopeMode.vault": "\u0412\u0441\u0451 \u0445\u0440\u0430\u043D\u0438\u043B\u0438\u0449\u0435",
      "set.scopeMode.folders": "\u0422\u043E\u043B\u044C\u043A\u043E \u0432\u044B\u0431\u0440\u0430\u043D\u043D\u044B\u0435 \u043F\u0430\u043F\u043A\u0438",
      "set.suggestMinChars.name": "\u041C\u0438\u043D\u0438\u043C\u0443\u043C \u0441\u0438\u043C\u0432\u043E\u043B\u043E\u0432",
      "set.statusBarIncludeLinks.name": "\u0421\u0447\u0438\u0442\u0430\u0442\u044C \u0438 \u0443\u0436\u0435 \u0441\u0432\u044F\u0437\u0430\u043D\u043D\u044B\u0435",
      "set.folderList.add": "\u0414\u043E\u0431\u0430\u0432\u0438\u0442\u044C \u043F\u0443\u0442\u044C\u2026",
      "set.folderList.addAria": "\u0414\u043E\u0431\u0430\u0432\u0438\u0442\u044C",
      "plural.alias": { one: "{n} \u043F\u0441\u0435\u0432\u0434\u043E\u043D\u0438\u043C", few: "{n} \u043F\u0441\u0435\u0432\u0434\u043E\u043D\u0438\u043C\u0430", many: "{n} \u043F\u0441\u0435\u0432\u0434\u043E\u043D\u0438\u043C\u043E\u0432", other: "{n} \u043F\u0441\u0435\u0432\u0434\u043E\u043D\u0438\u043C\u043E\u0432" }
    };
    var de = {
      "noun.file": "Datei",
      "noun.folder": "Ordner",
      "scope.first": "erstes",
      "scope.all": "alle",
      "menu.linkDisplayTo": "\u201E{display}\u201C verlinken mit\u2026",
      "menu.linkScopeTo": "{scope} \u201E{display}\u201C verlinken mit\u2026",
      "modal.choose.title": "Begriff w\xE4hlen",
      "set.heading.scope": "Bereich",
      "set.heading.matching": "Abgleich",
      "set.languages.name": "Sprachen",
      "set.languages.show": "Sprachen anzeigen",
      "set.languages.hide": "Sprachen ausblenden",
      "set.lang.higher": "H\xF6here Priorit\xE4t",
      "set.lang.lower": "Niedrigere Priorit\xE4t",
      "set.linkFirstOnly.name": "Nur erstes Vorkommen verlinken",
      "set.heading.highlighting": "Hervorhebung",
      "set.highlightInReading.name": "In der Leseansicht hervorheben",
      "set.editingHighlight.onSave": "Beim Speichern",
      "set.skipHeadings.name": "\xDCberschriften \xFCberspringen",
      "set.statusBar.name": "Z\xE4hler in der Statusleiste",
      "set.heading.autocomplete": "Autovervollst\xE4ndigung",
      "set.linkSuggest.name": "Links w\xE4hrend der Eingabe vorschlagen",
      "set.suggestMinChars.desc": "Wie viele Zeichen einzugeben sind, bevor Vorschl\xE4ge erscheinen.",
      "set.suggestSkipAfter.name": "Nach Zeichen \xFCberspringen",
      "set.suggestPlainText.name": "Reinen Text einf\xFCgen",
      "set.suggestPlainText.desc": "Vorschl\xE4ge vervollst\xE4ndigen das Wort, ohne daraus einen Link zu machen.",
      "set.heading.contextMenu": "Kontextmen\xFC",
      "label.selection": "Auswahl",
      "modal.leftAsText": "\u2014 als Text belassen \u2014",
      "modal.skipOption": "(\xFCberspringen \u2014 als Text belassen)",
      "modal.materialize.summary": "Dateien: {files}, Ersetzungen: {replacements}",
      "modal.unlink.summary": "Dateien: {files}, zu entfernende Links: {links}",
      "modal.choose.body": "Dieses Wort passt zu mehr als einem Begriff \u2014 eines w\xE4hlen:",
      "notice.noActiveNote": "Keine aktive Notiz",
      "notice.noSelection": "Keine Auswahl",
      "notice.scopeSkipped": ", {n} \xFCbersprungen (seit der Vorschau ge\xE4ndert)",
      "set.editingHighlight.live": "Live (w\xE4hrend der Eingabe)",
      "set.editingHighlight.name": "Beim Bearbeiten hervorheben",
      "set.lang.invalid": "Ung\xFCltiges Modul: {error}",
      "set.languages.desc": "Mitgelieferte Morphologie-Module \u2014 {enabled} von {total} aktiviert",
      "set.matchMode.name": "Morphologie",
      "set.matchMode.exact": "Exakter Treffer",
      "set.matchMode.endingStrip": "Endungen abschneiden",
      "set.matchMode.stemmer": "Stemmer (empfohlen)",
      "kind.heading": "\xDCberschrift",
      "kind.term": "Begriff",
      "kind.viaAlias": "\xFCber Alias \u201E{form}\u201C",
      "set.smartCase.name": "Schreibweise von Abk\xFCrzungen beachten",
      "set.smartCase.desc": "\xDCberwiegend gro\xDFgeschriebene Begriffe (etwa \u201EIT\u201C oder \u201ENASA\u201C) werden nur bei gleicher Schreibweise verkn\xFCpft, damit sie keine gew\xF6hnlichen W\xF6rter erfassen.",
      "set.scopeMode.name": "Verlinkungsbereich",
      "set.scopeMode.vault": "\xDCberall",
      "set.scopeMode.folders": "Nur aufgef\xFChrte Pfade",
      "set.suggestMinChars.name": "Mindestanzahl Zeichen",
      "set.statusBarIncludeLinks.name": "Direkte Links z\xE4hlen",
      "plural.alias": { one: "{n} Alias", other: "{n} Aliasse" }
    };
    var es = {
      "noun.file": "archivo",
      "noun.folder": "carpeta",
      "scope.first": "la primera",
      "scope.all": "todas",
      "menu.linkDisplayTo": "Enlazar \xAB{display}\xBB con\u2026",
      "menu.linkScopeTo": "Enlazar {scope} \xAB{display}\xBB con\u2026",
      "modal.choose.title": "Elegir un t\xE9rmino",
      "set.heading.scope": "\xC1mbito",
      "set.heading.matching": "Coincidencia",
      "set.languages.name": "Idiomas",
      "set.languages.show": "Mostrar idiomas",
      "set.languages.hide": "Ocultar idiomas",
      "set.lang.higher": "Mayor prioridad",
      "set.lang.lower": "Menor prioridad",
      "set.linkFirstOnly.name": "Enlazar solo la primera aparici\xF3n",
      "set.heading.highlighting": "Resaltado",
      "set.highlightInReading.name": "Resaltar en vista de lectura",
      "set.editingHighlight.onSave": "Al guardar",
      "set.skipHeadings.name": "Omitir encabezados",
      "set.statusBar.name": "Contador en la barra de estado",
      "set.heading.autocomplete": "Autocompletado",
      "set.linkSuggest.name": "Sugerir enlaces al escribir",
      "set.suggestMinChars.desc": "Cu\xE1ntos caracteres escribir antes de que aparezcan las sugerencias.",
      "set.suggestSkipAfter.name": "Omitir tras caracteres",
      "set.suggestPlainText.name": "Insertar texto sin enlace",
      "set.suggestPlainText.desc": "Las sugerencias completan la palabra sin convertirla en un enlace.",
      "set.heading.contextMenu": "Men\xFA contextual",
      "label.selection": "selecci\xF3n",
      "modal.leftAsText": "\u2014 dejado como texto \u2014",
      "modal.skipOption": "(omitir \u2014 dejar como texto)",
      "modal.materialize.summary": "Archivos: {files}, reemplazos: {replacements}",
      "modal.unlink.summary": "Archivos: {files}, enlaces a eliminar: {links}",
      "modal.choose.body": "Esta palabra coincide con m\xE1s de un t\xE9rmino \u2014 elige uno:",
      "notice.noActiveNote": "No hay nota activa",
      "notice.noSelection": "No hay selecci\xF3n",
      "notice.scopeSkipped": ", {n} omitido(s) (cambiado desde la vista previa)",
      "set.editingHighlight.live": "En vivo (mientras escribes)",
      "set.editingHighlight.name": "Resaltar al editar",
      "set.lang.invalid": "M\xF3dulo no v\xE1lido: {error}",
      "set.languages.desc": "M\xF3dulos de morfolog\xEDa incluidos \u2014 {enabled} de {total} activados",
      "set.matchMode.name": "Morfolog\xEDa",
      "set.matchMode.exact": "Coincidencia exacta",
      "set.matchMode.endingStrip": "Quitar terminaciones",
      "set.matchMode.stemmer": "Lematizador (recomendado)",
      "kind.heading": "Encabezado",
      "kind.term": "T\xE9rmino",
      "kind.viaAlias": "por el alias \xAB{form}\xBB",
      "set.smartCase.name": "Distinguir may\xFAsculas en siglas",
      "set.smartCase.desc": "Los t\xE9rminos escritos casi todo en may\xFAsculas (como \xABIT\xBB o \xABNASA\xBB) solo coinciden con esa misma graf\xEDa, para que no enlacen palabras corrientes.",
      "set.scopeMode.name": "\xC1mbito de enlazado",
      "set.scopeMode.vault": "En todas partes",
      "set.scopeMode.folders": "Solo rutas indicadas",
      "set.suggestMinChars.name": "Caracteres m\xEDnimos",
      "set.statusBarIncludeLinks.name": "Contar enlaces directos",
      "plural.alias": { one: "{n} alias", other: "{n} alias" }
    };
    var fr = {
      "noun.file": "fichier",
      "noun.folder": "dossier",
      "scope.first": "la premi\xE8re",
      "scope.all": "toutes",
      "menu.linkDisplayTo": "Lier \xAB {display} \xBB \xE0\u2026",
      "menu.linkScopeTo": "Lier {scope} \xAB {display} \xBB \xE0\u2026",
      "modal.choose.title": "Choisir un terme",
      "set.heading.scope": "Port\xE9e",
      "set.heading.matching": "Correspondance",
      "set.languages.name": "Langues",
      "set.languages.show": "Afficher les langues",
      "set.languages.hide": "Masquer les langues",
      "set.lang.higher": "Priorit\xE9 plus haute",
      "set.lang.lower": "Priorit\xE9 plus basse",
      "set.linkFirstOnly.name": "Lier seulement la premi\xE8re occurrence",
      "set.heading.highlighting": "Surlignage",
      "set.highlightInReading.name": "Surligner en mode lecture",
      "set.editingHighlight.onSave": "\xC0 l\u2019enregistrement",
      "set.skipHeadings.name": "Ignorer les titres",
      "set.statusBar.name": "Compteur dans la barre d\u2019\xE9tat",
      "set.heading.autocomplete": "Autocompl\xE9tion",
      "set.linkSuggest.name": "Sugg\xE9rer des liens pendant la saisie",
      "set.suggestMinChars.desc": "Combien de caract\xE8res saisir avant que les suggestions apparaissent.",
      "set.suggestSkipAfter.name": "Ignorer apr\xE8s caract\xE8res",
      "set.suggestPlainText.name": "Ins\xE9rer du texte simple",
      "set.suggestPlainText.desc": "Les suggestions compl\xE8tent le mot sans en faire un lien.",
      "set.heading.contextMenu": "Menu contextuel",
      "label.selection": "s\xE9lection",
      "modal.leftAsText": "\u2014 laiss\xE9 en texte \u2014",
      "modal.skipOption": "(ignorer \u2014 laisser en texte)",
      "modal.materialize.summary": "Fichiers : {files}, remplacements : {replacements}",
      "modal.unlink.summary": "Fichiers : {files}, liens \xE0 supprimer : {links}",
      "modal.choose.body": "Ce mot correspond \xE0 plus d\u2019un terme \u2014 choisissez-en un :",
      "notice.noActiveNote": "Aucune note active",
      "notice.noSelection": "Aucune s\xE9lection",
      "notice.scopeSkipped": ", {n} ignor\xE9(s) (modifi\xE9 depuis l\u2019aper\xE7u)",
      "set.editingHighlight.live": "En direct (pendant la saisie)",
      "set.editingHighlight.name": "Surligner pendant l\u2019\xE9dition",
      "set.lang.invalid": "Module non valide : {error}",
      "set.languages.desc": "Modules de morphologie inclus \u2014 {enabled} sur {total} activ\xE9s",
      "set.matchMode.name": "Morphologie",
      "set.matchMode.exact": "Correspondance exacte",
      "set.matchMode.endingStrip": "Suppression des terminaisons",
      "set.matchMode.stemmer": "Racinisation (recommand\xE9)",
      "kind.heading": "Titre",
      "kind.term": "Terme",
      "kind.viaAlias": "via l\u2019alias \xAB {form} \xBB",
      "set.smartCase.name": "Respecter la casse des sigles",
      "set.smartCase.desc": "Les termes \xE9crits en majuscules (comme \xAB IT \xBB ou \xAB NASA \xBB) ne correspondent qu\u2019\xE0 la m\xEAme graphie, afin de ne pas lier des mots ordinaires.",
      "set.scopeMode.name": "Port\xE9e du liage",
      "set.scopeMode.vault": "Partout",
      "set.scopeMode.folders": "Chemins list\xE9s seulement",
      "set.suggestMinChars.name": "Caract\xE8res minimum",
      "set.statusBarIncludeLinks.name": "Compter les liens directs",
      "plural.alias": { one: "{n} alias", other: "{n} alias" }
    };
    var uk = {
      "noun.file": "\u0444\u0430\u0439\u043B",
      "noun.folder": "\u0442\u0435\u043A\u0443",
      "scope.first": "\u043F\u0435\u0440\u0448\u0435",
      "scope.all": "\u0443\u0441\u0456",
      "menu.linkDisplayTo": "\u0417\u0432\u2019\u044F\u0437\u0430\u0442\u0438 \xAB{display}\xBB \u0437\u2026",
      "menu.linkScopeTo": "\u0417\u0432\u2019\u044F\u0437\u0430\u0442\u0438 {scope} \xAB{display}\xBB \u0437\u2026",
      "modal.choose.title": "\u0412\u0438\u0431\u0435\u0440\u0456\u0442\u044C \u0442\u0435\u0440\u043C\u0456\u043D",
      "set.heading.scope": "\u041E\u0431\u043B\u0430\u0441\u0442\u044C",
      "set.heading.matching": "\u0417\u0456\u0441\u0442\u0430\u0432\u043B\u0435\u043D\u043D\u044F",
      "set.languages.name": "\u041C\u043E\u0432\u0438",
      "set.languages.show": "\u041F\u043E\u043A\u0430\u0437\u0430\u0442\u0438 \u043C\u043E\u0432\u0438",
      "set.languages.hide": "\u0421\u0445\u043E\u0432\u0430\u0442\u0438 \u043C\u043E\u0432\u0438",
      "set.lang.higher": "\u0412\u0438\u0449\u0438\u0439 \u043F\u0440\u0456\u043E\u0440\u0438\u0442\u0435\u0442",
      "set.lang.lower": "\u041D\u0438\u0436\u0447\u0438\u0439 \u043F\u0440\u0456\u043E\u0440\u0438\u0442\u0435\u0442",
      "set.linkFirstOnly.name": "\u0417\u0432\u2019\u044F\u0437\u0443\u0432\u0430\u0442\u0438 \u043B\u0438\u0448\u0435 \u043F\u0435\u0440\u0448\u0435 \u0432\u0445\u043E\u0434\u0436\u0435\u043D\u043D\u044F",
      "set.heading.highlighting": "\u041F\u0456\u0434\u0441\u0432\u0456\u0447\u0443\u0432\u0430\u043D\u043D\u044F",
      "set.highlightInReading.name": "\u041F\u0456\u0434\u0441\u0432\u0456\u0447\u0443\u0432\u0430\u0442\u0438 \u0432 \u0440\u0435\u0436\u0438\u043C\u0456 \u0447\u0438\u0442\u0430\u043D\u043D\u044F",
      "set.editingHighlight.onSave": "\u041F\u0456\u0434 \u0447\u0430\u0441 \u0437\u0431\u0435\u0440\u0435\u0436\u0435\u043D\u043D\u044F",
      "set.skipHeadings.name": "\u041F\u0440\u043E\u043F\u0443\u0441\u043A\u0430\u0442\u0438 \u0437\u0430\u0433\u043E\u043B\u043E\u0432\u043A\u0438",
      "set.statusBar.name": "\u041B\u0456\u0447\u0438\u043B\u044C\u043D\u0438\u043A \u0443 \u0440\u044F\u0434\u043A\u0443 \u0441\u0442\u0430\u043D\u0443",
      "set.heading.autocomplete": "\u0410\u0432\u0442\u043E\u0434\u043E\u043F\u043E\u0432\u043D\u0435\u043D\u043D\u044F",
      "set.linkSuggest.name": "\u041F\u0440\u043E\u043F\u043E\u043D\u0443\u0432\u0430\u0442\u0438 \u043F\u043E\u0441\u0438\u043B\u0430\u043D\u043D\u044F \u043F\u0456\u0434 \u0447\u0430\u0441 \u043D\u0430\u0431\u043E\u0440\u0443",
      "set.suggestMinChars.desc": "\u0421\u043A\u0456\u043B\u044C\u043A\u0438 \u0441\u0438\u043C\u0432\u043E\u043B\u0456\u0432 \u043D\u0430\u0431\u0440\u0430\u0442\u0438, \u043F\u0435\u0440\u0448 \u043D\u0456\u0436 \u0437\u2019\u044F\u0432\u043B\u044F\u0442\u044C\u0441\u044F \u043F\u0456\u0434\u043A\u0430\u0437\u043A\u0438.",
      "set.suggestSkipAfter.name": "\u041F\u0440\u043E\u043F\u0443\u0441\u043A\u0430\u0442\u0438 \u043F\u0456\u0441\u043B\u044F \u0441\u0438\u043C\u0432\u043E\u043B\u0456\u0432",
      "set.suggestPlainText.name": "\u0412\u0441\u0442\u0430\u0432\u043B\u044F\u0442\u0438 \u043F\u0440\u043E\u0441\u0442\u0438\u0439 \u0442\u0435\u043A\u0441\u0442",
      "set.suggestPlainText.desc": "\u041F\u0456\u0434\u043A\u0430\u0437\u043A\u0430 \u0434\u043E\u043F\u0438\u0441\u0443\u0454 \u0441\u043B\u043E\u0432\u043E, \u043D\u0435 \u043F\u0435\u0440\u0435\u0442\u0432\u043E\u0440\u044E\u044E\u0447\u0438 \u0439\u043E\u0433\u043E \u043D\u0430 \u043F\u043E\u0441\u0438\u043B\u0430\u043D\u043D\u044F.",
      "set.heading.contextMenu": "\u041A\u043E\u043D\u0442\u0435\u043A\u0441\u0442\u043D\u0435 \u043C\u0435\u043D\u044E",
      "label.selection": "\u0432\u0438\u0434\u0456\u043B\u0435\u043D\u043D\u044F",
      "modal.leftAsText": "\u2014 \u0437\u0430\u043B\u0438\u0448\u0435\u043D\u043E \u0442\u0435\u043A\u0441\u0442\u043E\u043C \u2014",
      "modal.skipOption": "(\u043F\u0440\u043E\u043F\u0443\u0441\u0442\u0438\u0442\u0438 \u2014 \u0437\u0430\u043B\u0438\u0448\u0438\u0442\u0438 \u0442\u0435\u043A\u0441\u0442\u043E\u043C)",
      "modal.materialize.summary": "\u0424\u0430\u0439\u043B\u0456\u0432: {files}, \u0437\u0430\u043C\u0456\u043D: {replacements}",
      "modal.unlink.summary": "\u0424\u0430\u0439\u043B\u0456\u0432: {files}, \u043F\u043E\u0441\u0438\u043B\u0430\u043D\u044C \u0434\u043E \u0432\u0438\u0434\u0430\u043B\u0435\u043D\u043D\u044F: {links}",
      "modal.choose.body": "\u0426\u0435 \u0441\u043B\u043E\u0432\u043E \u0437\u0431\u0456\u0433\u0430\u0454\u0442\u044C\u0441\u044F \u0437 \u043A\u0456\u043B\u044C\u043A\u043E\u043C\u0430 \u0442\u0435\u0440\u043C\u0456\u043D\u0430\u043C\u0438 \u2014 \u0432\u0438\u0431\u0435\u0440\u0456\u0442\u044C \u043E\u0434\u0438\u043D:",
      "notice.noActiveNote": "\u041D\u0435\u043C\u0430\u0454 \u0430\u043A\u0442\u0438\u0432\u043D\u043E\u0457 \u043D\u043E\u0442\u0430\u0442\u043A\u0438",
      "notice.noSelection": "\u041D\u0435\u043C\u0430\u0454 \u0432\u0438\u0434\u0456\u043B\u0435\u043D\u043D\u044F",
      "notice.scopeSkipped": ", \u043F\u0440\u043E\u043F\u0443\u0449\u0435\u043D\u043E: {n} (\u0437\u043C\u0456\u043D\u0435\u043D\u043E \u043F\u0456\u0441\u043B\u044F \u043F\u043E\u043F\u0435\u0440\u0435\u0434\u043D\u044C\u043E\u0433\u043E \u043F\u0435\u0440\u0435\u0433\u043B\u044F\u0434\u0443)",
      "set.editingHighlight.live": "\u041D\u0430 \u043B\u044C\u043E\u0442\u0443 (\u043F\u0456\u0434 \u0447\u0430\u0441 \u043D\u0430\u0431\u043E\u0440\u0443)",
      "set.editingHighlight.name": "\u041F\u0456\u0434\u0441\u0432\u0456\u0447\u0443\u0432\u0430\u0442\u0438 \u043F\u0456\u0434 \u0447\u0430\u0441 \u0440\u0435\u0434\u0430\u0433\u0443\u0432\u0430\u043D\u043D\u044F",
      "set.lang.invalid": "\u041D\u0435\u0434\u043E\u043F\u0443\u0441\u0442\u0438\u043C\u0438\u0439 \u043C\u043E\u0434\u0443\u043B\u044C: {error}",
      "set.languages.desc": "\u0412\u0431\u0443\u0434\u043E\u0432\u0430\u043D\u0456 \u043C\u043E\u0434\u0443\u043B\u0456 \u043C\u043E\u0440\u0444\u043E\u043B\u043E\u0433\u0456\u0457 \u2014 \u0443\u0432\u0456\u043C\u043A\u043D\u0435\u043D\u043E {enabled} \u0437 {total}",
      "set.matchMode.name": "\u041C\u043E\u0440\u0444\u043E\u043B\u043E\u0433\u0456\u044F",
      "set.matchMode.exact": "\u0422\u043E\u0447\u043D\u0438\u0439 \u0437\u0431\u0456\u0433",
      "set.matchMode.endingStrip": "\u0412\u0456\u0434\u0441\u0456\u043A\u0430\u043D\u043D\u044F \u0437\u0430\u043A\u0456\u043D\u0447\u0435\u043D\u044C",
      "set.matchMode.stemmer": "\u0421\u0442\u0435\u043C\u0435\u0440 (\u0440\u0435\u043A\u043E\u043C\u0435\u043D\u0434\u043E\u0432\u0430\u043D\u043E)",
      "kind.heading": "\u0417\u0430\u0433\u043E\u043B\u043E\u0432\u043E\u043A",
      "kind.term": "\u0422\u0435\u0440\u043C\u0456\u043D",
      "kind.viaAlias": "\u0437\u0430 \u0430\u043B\u0456\u0430\u0441\u043E\u043C \xAB{form}\xBB",
      "set.smartCase.name": "\u0420\u043E\u0437\u0443\u043C\u043D\u0438\u0439 \u0440\u0435\u0433\u0456\u0441\u0442\u0440 \u0434\u043B\u044F \u0430\u0431\u0440\u0435\u0432\u0456\u0430\u0442\u0443\u0440",
      "set.smartCase.desc": "\u0422\u0435\u0440\u043C\u0456\u043D\u0438 \u0437 \u0432\u0435\u043B\u0438\u043A\u0438\u0445 \u043B\u0456\u0442\u0435\u0440 (\u043D\u0430\u043F\u0440\u0438\u043A\u043B\u0430\u0434 \xABIT\xBB \u0430\u0431\u043E \xABNASA\xBB) \u0437\u0456\u0441\u0442\u0430\u0432\u043B\u044F\u044E\u0442\u044C\u0441\u044F \u0437 \u0443\u0440\u0430\u0445\u0443\u0432\u0430\u043D\u043D\u044F\u043C \u0440\u0435\u0433\u0456\u0441\u0442\u0440\u0443, \u0449\u043E\u0431 \u043D\u0435 \u0447\u0456\u043F\u043B\u044F\u0442\u0438 \u0437\u0432\u0438\u0447\u0430\u0439\u043D\u0456 \u0441\u043B\u043E\u0432\u0430.",
      "set.scopeMode.name": "\u041E\u0431\u043B\u0430\u0441\u0442\u044C \u0437\u0432\u2019\u044F\u0437\u0443\u0432\u0430\u043D\u043D\u044F",
      "set.scopeMode.vault": "\u0423\u0441\u044E\u0434\u0438",
      "set.scopeMode.folders": "\u041B\u0438\u0448\u0435 \u0432\u043A\u0430\u0437\u0430\u043D\u0456 \u0448\u043B\u044F\u0445\u0438",
      "set.suggestMinChars.name": "\u041C\u0456\u043D\u0456\u043C\u0443\u043C \u0441\u0438\u043C\u0432\u043E\u043B\u0456\u0432",
      "set.statusBarIncludeLinks.name": "\u0420\u0430\u0445\u0443\u0432\u0430\u0442\u0438 \u043F\u0440\u044F\u043C\u0456 \u043F\u043E\u0441\u0438\u043B\u0430\u043D\u043D\u044F",
      "plural.alias": { one: "{n} \u043F\u0441\u0435\u0432\u0434\u043E\u043D\u0456\u043C", few: "{n} \u043F\u0441\u0435\u0432\u0434\u043E\u043D\u0456\u043C\u0438", many: "{n} \u043F\u0441\u0435\u0432\u0434\u043E\u043D\u0456\u043C\u0456\u0432", other: "{n} \u043F\u0441\u0435\u0432\u0434\u043E\u043D\u0456\u043C\u0456\u0432" }
    };
    module2.exports = { en, ru, de, es, fr, uk };
  }
});

// src/shared/locales/sigil.js
var require_sigil = __commonJS({
  "src/shared/locales/sigil.js"(exports2, module2) {
    "use strict";
    var en = {
      "menu.convert": "Find and convert to link",
      "menu.convert.group": "Find and convert to link",
      "menu.open.group": "Find and open",
      "embed.menu.refresh": "Refresh embed",
      "embed.tool.more": "More actions",
      "embed.tool.open": "Open",
      "embed.tool.refresh": "Refresh",
      "modal.embedPlaceholder": "Choose an embed format\u2026",
      "set.heading.suggestions": "Suggestions & links",
      "set.heading.hover": "Hover preview",
      "set.heading.links": "Links",
      "set.codeRoot.desc": "Base folder the scan paths are relative to. Empty = the folder containing this vault.",
      "set.scanFolders.name": "Scan folders",
      "set.folderList.add": "Add folder\u2026",
      "set.folderList.remove": "Remove",
      "set.folderList.addAria": "Add",
      "set.skipFolders.name": "Skip folders",
      "set.trigger.name": "Trigger",
      "set.preset.file": "file://",
      "set.preset.ask": "Always ask",
      "set.editors.count": "{n} added",
      "set.editors.collapse": "Collapse",
      "set.editors.expand": "Expand",
      "set.editors.namePlaceholder": "Name",
      "set.editors.remove": "Remove",
      "set.minChars.name": "Min characters",
      "set.minChars.desc": "How many characters to type before suggestions appear.",
      "set.maxResults.name": "Max results",
      "set.maxResults.desc": "Most suggestions to show at once.",
      "set.autoRefresh.name": "Auto-refresh index",
      "set.autoRefresh.unsupported": "Recursive folder watching isn\u2019t supported on this platform (Linux); rebuild manually instead.",
      "set.contextMenu.name": "Editor context menu",
      "set.markStaleLinks.name": "Mark stale links",
      "set.info.unknownRoot": "(unknown)",
      "plural.entry": { one: "{n} entry", other: "{n} entries" },
      "plural.key": { one: "{n} key", other: "{n} keys" },
      "plural.note": { one: "{n} note", other: "{n} notes" },
      "plural.staleLink": { one: "{n} stale link", other: "{n} stale links" },
      "plural.brokenLink": { one: "{n} broken link", other: "{n} broken links" }
    };
    var ru = {
      "menu.convert": "\u041D\u0430\u0439\u0442\u0438 \u0438 \u043F\u0440\u0435\u0432\u0440\u0430\u0442\u0438\u0442\u044C \u0432 \u0441\u0441\u044B\u043B\u043A\u0443",
      "menu.convert.group": "\u041D\u0430\u0439\u0442\u0438 \u0438 \u043F\u0440\u0435\u0432\u0440\u0430\u0442\u0438\u0442\u044C \u0432 \u0441\u0441\u044B\u043B\u043A\u0443",
      "menu.open.group": "\u041D\u0430\u0439\u0442\u0438 \u0438 \u043E\u0442\u043A\u0440\u044B\u0442\u044C",
      "embed.menu.refresh": "\u041E\u0431\u043D\u043E\u0432\u0438\u0442\u044C embed",
      "embed.tool.more": "\u0415\u0449\u0451 \u0434\u0435\u0439\u0441\u0442\u0432\u0438\u044F",
      "embed.tool.open": "\u041E\u0442\u043A\u0440\u044B\u0442\u044C",
      "embed.tool.refresh": "\u041E\u0431\u043D\u043E\u0432\u0438\u0442\u044C",
      "modal.embedPlaceholder": "\u0412\u044B\u0431\u0435\u0440\u0438\u0442\u0435 \u0444\u043E\u0440\u043C\u0430\u0442 embed\u2026",
      "set.heading.suggestions": "\u041F\u043E\u0434\u0441\u043A\u0430\u0437\u043A\u0438 \u0438 \u0441\u0441\u044B\u043B\u043A\u0438",
      "set.heading.hover": "\u041F\u0440\u0435\u0432\u044C\u044E \u043F\u0440\u0438 \u043D\u0430\u0432\u0435\u0434\u0435\u043D\u0438\u0438",
      "set.heading.links": "\u0421\u0441\u044B\u043B\u043A\u0438",
      "set.codeRoot.desc": "\u0411\u0430\u0437\u043E\u0432\u0430\u044F \u043F\u0430\u043F\u043A\u0430, \u043E\u0442\u043D\u043E\u0441\u0438\u0442\u0435\u043B\u044C\u043D\u043E \u043A\u043E\u0442\u043E\u0440\u043E\u0439 \u0437\u0430\u0434\u0430\u044E\u0442\u0441\u044F \u043F\u0443\u0442\u0438 \u0441\u043A\u0430\u043D\u0438\u0440\u043E\u0432\u0430\u043D\u0438\u044F. \u041F\u0443\u0441\u0442\u043E = \u043F\u0430\u043F\u043A\u0430, \u0441\u043E\u0434\u0435\u0440\u0436\u0430\u0449\u0430\u044F \u044D\u0442\u043E \u0445\u0440\u0430\u043D\u0438\u043B\u0438\u0449\u0435.",
      "set.scanFolders.name": "\u041F\u0430\u043F\u043A\u0438 \u0441\u043A\u0430\u043D\u0438\u0440\u043E\u0432\u0430\u043D\u0438\u044F",
      "set.folderList.add": "\u0414\u043E\u0431\u0430\u0432\u0438\u0442\u044C \u043F\u0430\u043F\u043A\u0443\u2026",
      "set.folderList.remove": "\u0423\u0434\u0430\u043B\u0438\u0442\u044C",
      "set.folderList.addAria": "\u0414\u043E\u0431\u0430\u0432\u0438\u0442\u044C",
      "set.skipFolders.name": "\u041F\u0440\u043E\u043F\u0443\u0441\u043A\u0430\u0435\u043C\u044B\u0435 \u043F\u0430\u043F\u043A\u0438",
      "set.trigger.name": "\u0422\u0440\u0438\u0433\u0433\u0435\u0440",
      "set.preset.file": "file://",
      "set.preset.ask": "\u0412\u0441\u0435\u0433\u0434\u0430 \u0441\u043F\u0440\u0430\u0448\u0438\u0432\u0430\u0442\u044C",
      "set.editors.count": "\u0434\u043E\u0431\u0430\u0432\u043B\u0435\u043D\u043E: {n}",
      "set.editors.collapse": "\u0421\u0432\u0435\u0440\u043D\u0443\u0442\u044C",
      "set.editors.expand": "\u0420\u0430\u0437\u0432\u0435\u0440\u043D\u0443\u0442\u044C",
      "set.editors.namePlaceholder": "\u041D\u0430\u0437\u0432\u0430\u043D\u0438\u0435",
      "set.editors.remove": "\u0423\u0434\u0430\u043B\u0438\u0442\u044C",
      "set.minChars.name": "\u041C\u0438\u043D\u0438\u043C\u0443\u043C \u0441\u0438\u043C\u0432\u043E\u043B\u043E\u0432",
      "set.minChars.desc": "\u0421\u043A\u043E\u043B\u044C\u043A\u043E \u0441\u0438\u043C\u0432\u043E\u043B\u043E\u0432 \u0432\u0432\u0435\u0441\u0442\u0438, \u043F\u0440\u0435\u0436\u0434\u0435 \u0447\u0435\u043C \u043F\u043E\u044F\u0432\u044F\u0442\u0441\u044F \u043F\u043E\u0434\u0441\u043A\u0430\u0437\u043A\u0438.",
      "set.maxResults.name": "\u041C\u0430\u043A\u0441\u0438\u043C\u0443\u043C \u0440\u0435\u0437\u0443\u043B\u044C\u0442\u0430\u0442\u043E\u0432",
      "set.maxResults.desc": "\u0421\u043A\u043E\u043B\u044C\u043A\u043E \u043F\u043E\u0434\u0441\u043A\u0430\u0437\u043E\u043A \u043F\u043E\u043A\u0430\u0437\u044B\u0432\u0430\u0442\u044C \u043E\u0434\u043D\u043E\u0432\u0440\u0435\u043C\u0435\u043D\u043D\u043E.",
      "set.autoRefresh.name": "\u0410\u0432\u0442\u043E\u043E\u0431\u043D\u043E\u0432\u043B\u0435\u043D\u0438\u0435 \u0438\u043D\u0434\u0435\u043A\u0441\u0430",
      "set.autoRefresh.unsupported": "\u0420\u0435\u043A\u0443\u0440\u0441\u0438\u0432\u043D\u043E\u0435 \u0441\u043B\u0435\u0436\u0435\u043D\u0438\u0435 \u0437\u0430 \u043F\u0430\u043F\u043A\u0430\u043C\u0438 \u043D\u0435 \u043F\u043E\u0434\u0434\u0435\u0440\u0436\u0438\u0432\u0430\u0435\u0442\u0441\u044F \u043D\u0430 \u044D\u0442\u043E\u0439 \u043F\u043B\u0430\u0442\u0444\u043E\u0440\u043C\u0435 (Linux); \u043F\u0435\u0440\u0435\u0441\u0442\u0440\u0430\u0438\u0432\u0430\u0439\u0442\u0435 \u0432\u0440\u0443\u0447\u043D\u0443\u044E.",
      "set.contextMenu.name": "\u041A\u043E\u043D\u0442\u0435\u043A\u0441\u0442\u043D\u043E\u0435 \u043C\u0435\u043D\u044E \u0440\u0435\u0434\u0430\u043A\u0442\u043E\u0440\u0430",
      "set.markStaleLinks.name": "\u041E\u0442\u043C\u0435\u0447\u0430\u0442\u044C \u0443\u0441\u0442\u0430\u0440\u0435\u0432\u0448\u0438\u0435 \u0441\u0441\u044B\u043B\u043A\u0438",
      "set.info.unknownRoot": "(\u043D\u0435\u0438\u0437\u0432\u0435\u0441\u0442\u043D\u043E)",
      "plural.entry": { one: "{n} \u0437\u0430\u043F\u0438\u0441\u044C", few: "{n} \u0437\u0430\u043F\u0438\u0441\u0438", many: "{n} \u0437\u0430\u043F\u0438\u0441\u0435\u0439", other: "{n} \u0437\u0430\u043F\u0438\u0441\u0435\u0439" },
      "plural.key": { one: "{n} \u043A\u043B\u044E\u0447", few: "{n} \u043A\u043B\u044E\u0447\u0430", many: "{n} \u043A\u043B\u044E\u0447\u0435\u0439", other: "{n} \u043A\u043B\u044E\u0447\u0435\u0439" },
      "plural.note": { one: "{n} \u0437\u0430\u043C\u0435\u0442\u043A\u0435", few: "{n} \u0437\u0430\u043C\u0435\u0442\u043A\u0430\u0445", many: "{n} \u0437\u0430\u043C\u0435\u0442\u043A\u0430\u0445", other: "{n} \u0437\u0430\u043C\u0435\u0442\u043A\u0430\u0445" },
      "plural.staleLink": { one: "{n} \u0443\u0441\u0442\u0430\u0440\u0435\u0432\u0448\u0430\u044F \u0441\u0441\u044B\u043B\u043A\u0430", few: "{n} \u0443\u0441\u0442\u0430\u0440\u0435\u0432\u0448\u0438\u0435 \u0441\u0441\u044B\u043B\u043A\u0438", many: "{n} \u0443\u0441\u0442\u0430\u0440\u0435\u0432\u0448\u0438\u0445 \u0441\u0441\u044B\u043B\u043E\u043A", other: "{n} \u0443\u0441\u0442\u0430\u0440\u0435\u0432\u0448\u0438\u0445 \u0441\u0441\u044B\u043B\u043E\u043A" },
      "plural.brokenLink": { one: "{n} \u0431\u0438\u0442\u0430\u044F \u0441\u0441\u044B\u043B\u043A\u0430", few: "{n} \u0431\u0438\u0442\u044B\u0435 \u0441\u0441\u044B\u043B\u043A\u0438", many: "{n} \u0431\u0438\u0442\u044B\u0445 \u0441\u0441\u044B\u043B\u043E\u043A", other: "{n} \u0431\u0438\u0442\u044B\u0445 \u0441\u0441\u044B\u043B\u043E\u043A" }
    };
    module2.exports = { en, ru };
  }
});

// src/shared/i18n.js
var require_i18n = __commonJS({
  "src/shared/i18n.js"(exports2, module2) {
    "use strict";
    var LOCALES = { en: {} };
    var dict = LOCALES.en;
    var pluralRules = new Intl.PluralRules("en");
    function initI18n2(locales) {
      LOCALES = locales;
      const sys = (window.localStorage.getItem("language") || "").split("-")[0].toLowerCase();
      const locale = LOCALES[sys] ? sys : "en";
      dict = LOCALES[locale];
      try {
        pluralRules = new Intl.PluralRules(locale);
      } catch (e) {
        pluralRules = new Intl.PluralRules("en");
      }
    }
    function interpolate(str, vars) {
      if (!vars)
        return str;
      return str.replace(/\{(\w+)\}/g, (m, k) => k in vars ? String(vars[k]) : m);
    }
    function t2(key, vars) {
      let entry = dict[key];
      if (entry === void 0)
        entry = LOCALES.en[key];
      if (entry === void 0)
        return key;
      return interpolate(entry, vars);
    }
    function plural2(noun, n) {
      const forms = dict["plural." + noun] || LOCALES.en["plural." + noun];
      if (!forms)
        return n + " " + noun;
      let cat;
      try {
        cat = pluralRules.select(n);
      } catch (e) {
        cat = "other";
      }
      const tpl = forms[cat] != null ? forms[cat] : forms.other != null ? forms.other : Object.values(forms)[0];
      return interpolate(tpl, { n });
    }
    var FAMILY = {
      common: require_common(),
      prose: require_prose(),
      sigil: require_sigil()
    };
    function withFamily2(kind, pluginLocales) {
      const common = FAMILY.common;
      const pair = FAMILY[kind] || {};
      const out = {};
      for (const lang of Object.keys(pluginLocales)) {
        out[lang] = Object.assign({}, common[lang], pair[lang], pluginLocales[lang]);
      }
      return out;
    }
    module2.exports = { initI18n: initI18n2, t: t2, plural: plural2, withFamily: withFamily2 };
  }
});

// src/shared/menu-verbs.js
var require_menu_verbs = __commonJS({
  "src/shared/menu-verbs.js"(exports2, module2) {
    "use strict";
    var { sharedSection, menuSection: menuSection2 } = require_menu();
    var { peersOffering } = require_discover();
    var { t: t2 } = require_i18n();
    var VERBS = {
      convert: { label: "menu.convert.group", icon: "link" },
      open: { label: "menu.open.group", icon: "file-search" },
      exclude: { label: "exclude.group", icon: "ban" }
    };
    var MenuBuilder = class {
      constructor(plugin, menu) {
        this.plugin = plugin;
        this.menu = menu;
        this.entries = [];
      }
      // Untagged: written where it stands, exactly as Obsidian's own Menu would.
      addItem(cb) {
        this.entries.push({ cb });
        return this;
      }
      addSeparator() {
        this.entries.push({ separator: true });
        return this;
      }
      // Tagged. `cb(item, grouped)` is told whether it ended up in a submenu, since the wording
      // differs: inside one, the parent already names the object.
      tagged(verb, opts, cb) {
        if (!VERBS[verb])
          throw new Error("unknown menu verb: " + verb);
        this.entries.push({ cb, verb, value: opts && opts.value });
        return this;
      }
      // A submenu of this plugin's own — the several ways to link one word, say. Unlike a verb it
      // is never shared, and it is built even for a single item because the items only read as a
      // set. Takes items the way a menu does.
      section(label, icon) {
        const entry = { section: { label, icon }, children: [] };
        this.entries.push(entry);
        const child = {
          addItem(cb) {
            entry.children.push({ cb });
            return child;
          },
          addSeparator() {
            entry.children.push({ separator: true });
            return child;
          }
        };
        return child;
      }
      // Verb -> the object it acts on, for those that earned a submenu. All items of one verb in
      // one menu act on the same object, so the first one's value names the group.
      groupedVerbs() {
        const counts = /* @__PURE__ */ new Map();
        for (const e of this.entries) {
          if (!e.verb)
            continue;
          const seen = counts.get(e.verb) || { count: 0, value: e.value };
          seen.count++;
          counts.set(e.verb, seen);
        }
        const provider = this.plugin.api && this.plugin.api.linker;
        const grouped = /* @__PURE__ */ new Map();
        for (const [verb, { count, value }] of counts) {
          const peers = provider ? peersOffering(this.plugin.app, provider, verb, value).length : 0;
          if (count + peers > 1)
            grouped.set(verb, value);
        }
        return grouped;
      }
      // menuSection builds the group on its first item, so an empty one leaves no trace, and it
      // falls back to prefixed titles where the app has no submenus.
      writeSection(entry) {
        if (!entry.children.length)
          return;
        const sub = menuSection2(this.menu, entry.section.label, true, entry.section.icon);
        for (const child of entry.children) {
          if (child.separator)
            sub.addSeparator();
          else
            sub.addItem((item) => child.cb(item, true));
        }
      }
      sectionFor(verb, value) {
        const spec = VERBS[verb];
        const label = t2(spec.label, value == null ? void 0 : { value });
        return sharedSection(this.menu, "linker:" + verb, label, spec.icon);
      }
      // Replayed in declaration order, so a verb's submenu appears where its first item would
      // have. Anything else keeps its place.
      flush() {
        const grouped = this.groupedVerbs();
        const sections = /* @__PURE__ */ new Map();
        for (const e of this.entries) {
          if (e.separator) {
            this.menu.addSeparator();
            continue;
          }
          if (e.section) {
            this.writeSection(e);
            continue;
          }
          if (!e.verb || !grouped.has(e.verb)) {
            this.menu.addItem((item) => e.cb(item, false));
            continue;
          }
          if (!sections.has(e.verb))
            sections.set(e.verb, this.sectionFor(e.verb, grouped.get(e.verb)));
          sections.get(e.verb).addItem((item) => e.cb(item, true));
        }
      }
    };
    function buildMenu2(plugin, menu, fn) {
      const builder = new MenuBuilder(plugin, menu);
      fn(builder);
      builder.flush();
    }
    module2.exports = { VERBS, MenuBuilder, buildMenu: buildMenu2 };
  }
});

// src/shared/link-owner.js
var require_link_owner = __commonJS({
  "src/shared/link-owner.js"(exports2, module2) {
    "use strict";
    var { outranks, discoverLinkers } = require_discover();
    var RANK = { binding: 2, index: 1 };
    function linkOwner(app, target, title) {
      let best = null;
      let bestRank = 0;
      for (const peer of discoverLinkers(app)) {
        if (typeof peer.claim !== "function")
          continue;
        let claim;
        try {
          claim = peer.claim(target, title);
        } catch (e) {
          claim = null;
        }
        const rank = RANK[claim] || 0;
        if (!rank)
          continue;
        if (rank > bestRank || rank === bestRank && best && outranks(peer, best)) {
          best = peer;
          bestRank = rank;
        }
      }
      return best;
    }
    function ownsLink2(app, self, target, title) {
      const owner = linkOwner(app, target, title);
      return !!owner && owner.id === self.id;
    }
    module2.exports = { linkOwner, ownsLink: ownsLink2, RANK };
  }
});

// src/git.js
var require_git = __commonJS({
  "src/git.js"(exports2, module2) {
    "use strict";
    var fs2 = require("fs");
    var nodePath2 = require("path");
    function resolveGit2(absFile) {
      return repoFrom(nodePath2.dirname(absFile));
    }
    function resolveGitDir2(dir) {
      return repoFrom(dir);
    }
    function repoFrom(startDir) {
      const found = findGitDir(startDir);
      if (!found)
        return null;
      const head = readHead(found.gitDir);
      if (!head)
        return null;
      const remote = readRemote(found.gitDir);
      if (!remote)
        return null;
      return { remote, sha: head.sha, branch: head.branch, repoRoot: found.repoRoot };
    }
    function findGitDir(startDir) {
      let dir = startDir;
      for (; ; ) {
        const dotGit = nodePath2.join(dir, ".git");
        let st;
        try {
          st = fs2.statSync(dotGit);
        } catch (e) {
          st = null;
        }
        if (st && st.isDirectory())
          return { repoRoot: dir, gitDir: dotGit };
        if (st) {
          const m = readText(dotGit).match(/^gitdir:\s*(.+)$/m);
          if (m) {
            const p = m[1].trim();
            return { repoRoot: dir, gitDir: nodePath2.isAbsolute(p) ? p : nodePath2.resolve(dir, p) };
          }
        }
        const parent = nodePath2.dirname(dir);
        if (parent === dir)
          return null;
        dir = parent;
      }
    }
    function readHead(gitDir) {
      const head = readText(nodePath2.join(gitDir, "HEAD")).trim();
      const ref = head.match(/^ref:\s*(.+)$/);
      if (!ref)
        return /^[0-9a-f]{40}$/i.test(head) ? { sha: head, branch: null } : null;
      const refName = ref[1].trim();
      const sha = readRef(gitDir, refName);
      if (!sha)
        return null;
      return { sha, branch: refName.startsWith("refs/heads/") ? refName.slice("refs/heads/".length) : null };
    }
    function readRef(gitDir, refName) {
      const dirs = [gitDir];
      const common = readText(nodePath2.join(gitDir, "commondir")).trim();
      if (common)
        dirs.push(nodePath2.resolve(gitDir, common));
      for (const d of dirs) {
        const loose = readText(nodePath2.join(d, refName)).trim();
        if (/^[0-9a-f]{40}$/i.test(loose))
          return loose;
        for (const line of readText(nodePath2.join(d, "packed-refs")).split("\n")) {
          const m = line.match(/^([0-9a-f]{40})\s+(.+)$/);
          if (m && m[2].trim() === refName)
            return m[1];
        }
      }
      return null;
    }
    function readRemote(gitDir) {
      const config = readText(nodePath2.join(gitDir, "config"));
      let section = "", origin = "", fallback = "";
      for (const raw of config.split("\n")) {
        const line = raw.trim();
        const sec = line.match(/^\[(.+?)\]$/);
        if (sec) {
          section = sec[1].trim();
          continue;
        }
        const kv = line.match(/^url\s*=\s*(.+)$/);
        if (!kv || !/^remote\b/.test(section))
          continue;
        if (/^remote\s+"origin"$/.test(section))
          origin = kv[1].trim();
        else if (!fallback)
          fallback = kv[1].trim();
      }
      return normalizeRemote(origin || fallback);
    }
    function normalizeRemote(url) {
      let s = (url || "").trim();
      if (!s)
        return null;
      const scp = s.match(/^[^/@]+@([^:]+):(.+)$/);
      if (scp)
        s = "https://" + scp[1] + "/" + scp[2];
      else
        s = s.replace(/^(?:ssh|git|http):\/\//i, "https://");
      s = s.replace(/^(https:\/\/)[^/@]+@/i, "$1");
      s = s.replace(/\.git$/i, "").replace(/\/+$/, "");
      return /^https:\/\/[^/]+\/.+/.test(s) ? s : null;
    }
    function readText(path) {
      try {
        return fs2.readFileSync(path, "utf8");
      } catch (e) {
        return "";
      }
    }
    module2.exports = { resolveGit: resolveGit2, resolveGitDir: resolveGitDir2, normalizeRemote };
  }
});

// languages/csharp.json
var require_csharp = __commonJS({
  "languages/csharp.json"(exports2, module2) {
    module2.exports = {
      id: "csharp",
      name: "C#",
      extensions: [".cs"],
      patterns: [
        {
          re: "^\\s*(?:\\[[^\\]]*\\]\\s*)*(?:(?:public|internal|private|protected|static|sealed|abstract|partial|readonly|unsafe|new|ref)\\s+)*(class|struct|interface|enum|record)\\s+([A-Za-z_][A-Za-z0-9_]*)",
          kindGroup: 1,
          nameGroup: 2
        },
        {
          re: "^\\s*(?:\\[[^\\]]*\\]\\s*)*(?:(?:public|private|protected|internal|static|virtual|override|abstract|sealed|async|extern|unsafe|new|partial|readonly|volatile|required|file)\\s+)*(?!(?:public|private|protected|internal|static|virtual|override|abstract|sealed|async|extern|unsafe|new|partial|readonly|volatile|required|file|const|if|else|for|foreach|while|do|switch|case|catch|try|finally|return|throw|yield|await|using|lock|fixed|checked|unchecked|goto|break|continue|in|is|as|class|struct|interface|enum|record|namespace|delegate|event|where|get|set|add|remove|when|select|from|orderby|group|let|var|typeof|nameof|sizeof|default|stackalloc)\\b)[A-Za-z_][\\w.]*(?:<(?:[^<>()]|<[^<>()]*>)*>)?(?:\\[\\s*,*\\s*\\])?\\??\\s+([A-Za-z_]\\w*)\\s*(?:<(?:[^<>()]|<[^<>()]*>)*>)?\\s*\\(",
          kind: "method",
          nameGroup: 1
        },
        {
          re: "^\\s*(?:\\[[^\\]]*\\]\\s*)*(?:(?:public|private|protected|internal|static|virtual|override|abstract|sealed|async|extern|unsafe|new|partial|readonly|volatile|required|file)\\s+)*(?!(?:public|private|protected|internal|static|virtual|override|abstract|sealed|async|extern|unsafe|new|partial|readonly|volatile|required|file|const|if|else|for|foreach|while|do|switch|case|catch|try|finally|return|throw|yield|await|using|lock|fixed|checked|unchecked|goto|break|continue|in|is|as|class|struct|interface|enum|record|namespace|delegate|event|where|get|set|add|remove|when|select|from|orderby|group|let|var|typeof|nameof|sizeof|default|stackalloc)\\b)[A-Za-z_][\\w.]*(?:<(?:[^<>()]|<[^<>()]*>)*>)?(?:\\[\\s*,*\\s*\\])?\\??\\s+([A-Za-z_]\\w*)\\s*(?:\\{|=>)",
          kind: "property",
          nameGroup: 1
        }
      ]
    };
  }
});

// languages/typescript.json
var require_typescript = __commonJS({
  "languages/typescript.json"(exports2, module2) {
    module2.exports = {
      id: "typescript",
      name: "TypeScript",
      extensions: [".ts", ".tsx"],
      patterns: [
        {
          re: "^\\s*(?:export\\s+)?(?:default\\s+)?(?:abstract\\s+)?(class|interface|enum|type)\\s+([A-Za-z_$][\\w$]*)",
          kindGroup: 1,
          nameGroup: 2
        },
        {
          re: "^\\s*(?:export\\s+)?(?:default\\s+)?(?:async\\s+)?function\\s+([A-Za-z_$][\\w$]*)",
          kind: "function",
          nameGroup: 1
        },
        {
          re: "^\\s*(?:export\\s+)?(?:default\\s+)?(?:const|let|var)\\s+([A-Za-z_$][\\w$]*)\\s*(?::\\s*[^=;]+)?=\\s*(?:async\\s+)?(?:function\\b|(?:<[^>]*>\\s*)?\\(?[A-Za-z_$)][^=;]*=>)",
          kind: "function",
          nameGroup: 1
        }
      ]
    };
  }
});

// languages/javascript.json
var require_javascript = __commonJS({
  "languages/javascript.json"(exports2, module2) {
    module2.exports = {
      id: "javascript",
      name: "JavaScript",
      extensions: [".js", ".jsx", ".mjs", ".cjs"],
      patterns: [
        {
          re: "^\\s*(?:export\\s+)?(?:default\\s+)?class\\s+([A-Za-z_$][\\w$]*)",
          kind: "class",
          nameGroup: 1
        },
        {
          re: "^\\s*(?:export\\s+)?(?:default\\s+)?(?:async\\s+)?function\\s+([A-Za-z_$][\\w$]*)",
          kind: "function",
          nameGroup: 1
        },
        {
          re: "^\\s*(?:export\\s+)?(?:default\\s+)?(?:const|let|var)\\s+([A-Za-z_$][\\w$]*)\\s*=\\s*(?:async\\s+)?(?:function\\b|\\(?[A-Za-z_$)][^=;]*=>)",
          kind: "function",
          nameGroup: 1
        }
      ]
    };
  }
});

// languages/python.json
var require_python = __commonJS({
  "languages/python.json"(exports2, module2) {
    module2.exports = {
      id: "python",
      name: "Python",
      extensions: [".py"],
      patterns: [
        { re: "^\\s*class\\s+([A-Za-z_]\\w*)", kind: "class", nameGroup: 1 },
        { re: "^\\s*def\\s+([A-Za-z_]\\w*)", kind: "def", nameGroup: 1 }
      ]
    };
  }
});

// languages/java.json
var require_java = __commonJS({
  "languages/java.json"(exports2, module2) {
    module2.exports = {
      id: "java",
      name: "Java",
      extensions: [".java"],
      patterns: [
        {
          re: "^\\s*(?:@[A-Za-z_][\\w.]*(?:\\([^)]*\\))?\\s+)*(?:(?:public|protected|private|abstract|final|static|sealed|non-sealed|strictfp)\\s+)*(class|interface|enum|record)\\s+([A-Za-z_$][\\w$]*)",
          kindGroup: 1,
          nameGroup: 2
        },
        {
          re: "^\\s*(?:@[A-Za-z_][\\w.]*(?:\\([^)]*\\))?\\s+)*(?:(?:public|private|protected|static|final|abstract|synchronized|native|strictfp|default)\\s+)*(?:<(?:[^<>()]|<[^<>()]*>)*>\\s*)?(?!(?:public|private|protected|static|final|abstract|synchronized|native|strictfp|default|if|else|for|while|do|switch|case|catch|try|finally|return|throw|new|instanceof|class|interface|enum|record|extends|implements|super|this|assert|yield|break|continue|import|package)\\b)[A-Za-z_][\\w.]*(?:<(?:[^<>()]|<[^<>()]*>)*>)?(?:\\[\\s*\\])*\\s+([A-Za-z_]\\w*)\\s*\\(",
          kind: "method",
          nameGroup: 1
        }
      ]
    };
  }
});

// languages/cpp.json
var require_cpp = __commonJS({
  "languages/cpp.json"(exports2, module2) {
    module2.exports = {
      id: "cpp",
      name: "C / C++",
      extensions: [".c", ".h", ".hpp", ".hh", ".cpp", ".cc", ".cxx"],
      patterns: [
        {
          re: "^\\s*(?:template\\s*<[^>]*>\\s*)?(class|struct|enum)\\s+([A-Za-z_]\\w*)",
          kindGroup: 1,
          nameGroup: 2
        },
        {
          re: "^\\s*(?:(?:static|inline|virtual|explicit|friend|constexpr|consteval|constinit|extern|const|volatile|register|mutable|thread_local)\\s+)*(?!(?:static|inline|virtual|explicit|friend|constexpr|consteval|constinit|extern|const|volatile|register|mutable|thread_local|if|else|for|while|do|switch|case|catch|return|throw|new|delete|sizeof|typedef|using|namespace|template|class|struct|union|enum|public|private|protected|goto|break|continue|static_assert|decltype|co_return|co_await|co_yield)\\b)(?:(?:unsigned|signed|long|short|const|volatile|struct|enum|union)\\s+)*[A-Za-z_]\\w*(?:\\s*::\\s*[A-Za-z_]\\w*)*(?:<(?:[^<>()]|<[^<>()]*>)*>)?(?:\\s*[*&]+|\\s+)\\s*(?:[A-Za-z_]\\w*\\s*::\\s*)*(~?[A-Za-z_]\\w*)\\s*\\(",
          kind: "function",
          nameGroup: 1
        }
      ]
    };
  }
});

// languages/php.json
var require_php = __commonJS({
  "languages/php.json"(exports2, module2) {
    module2.exports = {
      id: "php",
      name: "PHP",
      extensions: [".php"],
      patterns: [
        {
          re: "^\\s*(?:(?:abstract|final|readonly)\\s+)*(class|interface|trait|enum)\\s+([A-Za-z_]\\w*)",
          kindGroup: 1,
          nameGroup: 2
        },
        {
          re: "^\\s*(?:(?:public|protected|private|static|abstract|final)\\s+)*function\\s+&?\\s*([A-Za-z_]\\w*)",
          kind: "function",
          nameGroup: 1
        }
      ]
    };
  }
});

// languages/go.json
var require_go = __commonJS({
  "languages/go.json"(exports2, module2) {
    module2.exports = {
      id: "go",
      name: "Go",
      extensions: [".go"],
      patterns: [
        { re: "^\\s*type\\s+([A-Za-z_]\\w*)\\s+(?:struct|interface)", kind: "type", nameGroup: 1 },
        { re: "^\\s*func\\s+(?:\\([^)]*\\)\\s*)?([A-Za-z_]\\w*)", kind: "func", nameGroup: 1 }
      ]
    };
  }
});

// languages/rust.json
var require_rust = __commonJS({
  "languages/rust.json"(exports2, module2) {
    module2.exports = {
      id: "rust",
      name: "Rust",
      extensions: [".rs"],
      patterns: [
        {
          re: "^\\s*(?:pub(?:\\([^)]*\\))?\\s+)?(struct|enum|trait|type|union)\\s+([A-Za-z_]\\w*)",
          kindGroup: 1,
          nameGroup: 2
        },
        {
          re: '^\\s*(?:pub(?:\\([^)]*\\))?\\s+)?(?:const\\s+|async\\s+|unsafe\\s+|extern\\s+(?:"[^"]*"\\s+)?)*fn\\s+([A-Za-z_]\\w*)',
          kind: "fn",
          nameGroup: 1
        }
      ]
    };
  }
});

// src/builtin-languages.js
var require_builtin_languages = __commonJS({
  "src/builtin-languages.js"(exports2, module2) {
    "use strict";
    var BUILTIN_LANGUAGES2 = [
      require_csharp(),
      require_typescript(),
      require_javascript(),
      require_python(),
      require_java(),
      require_cpp(),
      require_php(),
      require_go(),
      require_rust()
    ];
    module2.exports = { BUILTIN_LANGUAGES: BUILTIN_LANGUAGES2 };
  }
});

// src/shared/deeplink/suggest.js
var require_suggest = __commonJS({
  "src/shared/deeplink/suggest.js"(exports2, module2) {
    "use strict";
    var { EditorSuggest, prepareFuzzySearch } = require("obsidian");
    var { isProtected, inTableCell: inTableCell2 } = require_markdown();
    function createSigilSuggest(config) {
      const { cls, kindText } = config;
      const prepare = config.prepare || (() => () => true);
      return class SigilSuggest extends EditorSuggest {
        constructor(app, plugin) {
          super(app);
          this.plugin = plugin;
        }
        onTrigger(cursor, editor) {
          const s = this.plugin.settings;
          const before = editor.getLine(cursor.line).slice(0, cursor.ch);
          const i = before.lastIndexOf(s.trigger);
          if (i === -1)
            return null;
          const query = before.slice(i + s.trigger.length);
          if (!/^[\w.:]*$/.test(query))
            return null;
          if (query.length < Math.max(0, s.minChars))
            return null;
          const off = editor.posToOffset(cursor);
          if (isProtected(editor.getValue(), off))
            return null;
          return { start: { line: cursor.line, ch: i }, end: cursor, query };
        }
        getSuggestions(ctx) {
          const idx = this.plugin.index;
          if (!idx || !idx.length)
            return [];
          const max = this.plugin.settings.maxResults;
          const f = this.plugin.parseQuery(ctx.query);
          const allowed = prepare(this.plugin);
          const pass = (e) => allowed(e) && this.plugin.entryPassesFilter(e, f);
          const against = this.plugin.matchTextFor ? (e) => this.plugin.matchTextFor(e, f) : (e) => e.name;
          if (!f.name) {
            const out = [];
            for (const e of idx) {
              if (!pass(e))
                continue;
              out.push(e);
              if (out.length >= max)
                break;
            }
            return out;
          }
          const match = prepareFuzzySearch(f.name);
          const scored = [];
          for (const e of idx) {
            if (!pass(e))
              continue;
            const r = match(against(e));
            if (r)
              scored.push({ e, score: r.score });
          }
          scored.sort((a, b) => b.score - a.score || a.e.name.localeCompare(b.e.name));
          return scored.slice(0, max).map((s) => s.e);
        }
        renderSuggestion(e, el) {
          el.addClass(`${cls}-suggestion`);
          el.createSpan({ cls: `${cls}-name`, text: e.name });
          el.createSpan({ cls: `${cls}-kind`, text: kindText(e) });
          el.createSpan({ cls: `${cls}-path`, text: e.path });
        }
        selectSuggestion(e) {
          const ctx = this.context;
          if (!ctx)
            return;
          const inTable = inTableCell2(ctx.editor.getValue(), ctx.editor.posToOffset(ctx.start));
          const insert = (template) => {
            const link = this.plugin.buildLink(e, inTable, template);
            ctx.editor.replaceRange(link, ctx.start, ctx.end);
            const pos = ctx.editor.posToOffset(ctx.start) + link.length;
            ctx.editor.setCursor(ctx.editor.offsetToPos(pos));
          };
          this.plugin.withFormat(this.plugin.settings.askOnInsert, insert);
        }
      };
    }
    module2.exports = { createSigilSuggest };
  }
});

// src/suggest.js
var require_suggest2 = __commonJS({
  "src/suggest.js"(exports2, module2) {
    "use strict";
    var { createSigilSuggest } = require_suggest();
    var CodeIndexSuggest2 = createSigilSuggest({
      cls: "code-linker",
      prepare: (plugin) => {
        const hidden = new Set(plugin.settings.disabledKinds || []);
        return (e) => !hidden.has(e.lang + ":" + e.kind);
      },
      kindText: (e) => e.kind
    });
    module2.exports = { CodeIndexSuggest: CodeIndexSuggest2 };
  }
});

// src/shared/facets.js
var require_facets = __commonJS({
  "src/shared/facets.js"(exports2, module2) {
    "use strict";
    var { ANCHORS: ANCHORS2 } = require_binding();
    var VALUE2 = "value";
    var TOKEN2 = "token";
    var byName = (facets2, name) => facets2.find((f) => f.name === name) || null;
    function parseQuery(raw, facets2) {
      const values = {};
      let field = null;
      const parts = String(raw == null ? "" : raw).split(":");
      let i = 0;
      for (; i < parts.length - 1; i++) {
        const named = facets2.find((f) => f.typed === TOKEN2 && f.name === parts[i]);
        if (named) {
          field = named.name;
          i += 1;
          break;
        }
        let hit = null;
        for (const f of facets2) {
          if (f.typed !== VALUE2)
            continue;
          const v = f.resolve(parts[i]);
          if (v != null) {
            hit = { name: f.name, value: v };
            break;
          }
        }
        if (!hit)
          break;
        values[hit.name] = hit.value;
      }
      return { values, field, name: parts.slice(i).join(":") };
    }
    function passes(entry, parsed, facets2) {
      for (const name of Object.keys(parsed.values)) {
        const f = byName(facets2, name);
        if (f && f.of(entry) !== parsed.values[name])
          return false;
      }
      if (parsed.field) {
        const f = byName(facets2, parsed.field);
        if (f && !f.of(entry))
          return false;
      }
      return true;
    }
    function matchText(entry, parsed, facets2) {
      const f = parsed.field ? byName(facets2, parsed.field) : null;
      return f ? f.of(entry) : entry.name;
    }
    function bindingFrom(entry, facets2) {
      const b = {};
      for (const f of facets2) {
        if (!f.anchor || !f.of)
          continue;
        const v = f.of(entry);
        if (v)
          b[ANCHORS2[f.anchor]] = v;
      }
      return b;
    }
    function entriesFor(plugin, parsed, facets2) {
      if (!parsed.field)
        return plugin.entriesByName(parsed.name);
      const want = String(parsed.name || "").toLowerCase();
      if (!want)
        return [];
      return plugin.index.filter((e) => String(matchText(e, parsed, facets2) || "").toLowerCase() === want);
    }
    module2.exports = { VALUE: VALUE2, TOKEN: TOKEN2, parseQuery, passes, matchText, bindingFrom, entriesFor };
  }
});

// src/render.js
var require_render = __commonJS({
  "src/render.js"(exports2, module2) {
    "use strict";
    var fs2 = require("fs");
    var readline2 = require("readline");
    var { loadPrism } = require("obsidian");
    var MAX_LINE = 400;
    var PRISM_MAX_LINES = 5e3;
    function readLines(absPath, from, to) {
      return new Promise((resolve) => {
        from = Math.max(1, from);
        const lines = [];
        let i = 0;
        let binary = false;
        let stream;
        try {
          stream = fs2.createReadStream(absPath, { encoding: "utf8" });
        } catch (e) {
          resolve(null);
          return;
        }
        const rl = readline2.createInterface({ input: stream, crlfDelay: Infinity });
        const stop = () => {
          try {
            rl.close();
          } catch (e) {
          }
          stream.destroy();
        };
        rl.on("line", (text) => {
          i++;
          if (i < from)
            return;
          if (i > to) {
            stop();
            return;
          }
          if (/[\x00-\x08\x0E-\x1F]/.test(text)) {
            binary = true;
            stop();
            return;
          }
          lines.push(text.length > MAX_LINE ? text.slice(0, MAX_LINE) + "\u2026" : text);
        });
        rl.on("close", () => resolve(binary || !lines.length ? null : { startLine: from, lines }));
        rl.on("error", () => resolve(null));
        stream.on("error", () => resolve(null));
      });
    }
    function renderTokens(parent, tokens) {
      for (const tok of tokens) {
        if (typeof tok === "string") {
          parent.appendText(tok);
          continue;
        }
        const aliases = Array.isArray(tok.alias) ? tok.alias.join(" ") : tok.alias || "";
        const span = parent.createSpan({ cls: ("token " + tok.type + " " + aliases).trim() });
        if (typeof tok.content === "string")
          span.setText(tok.content);
        else
          renderTokens(span, Array.isArray(tok.content) ? tok.content : [tok.content]);
      }
    }
    var prismPromise = null;
    function ensurePrism() {
      if (!prismPromise)
        prismPromise = loadPrism().catch(() => null);
      return prismPromise;
    }
    function prismGrammar(P, prismId) {
      if (!P || !P.languages)
        return null;
      return prismId && P.languages[prismId] || P.languages.clike || null;
    }
    async function renderCode(parent, text, prismId) {
      const P = text.split("\n").length <= PRISM_MAX_LINES ? await ensurePrism() : null;
      const grammar = prismGrammar(P, prismId);
      const pre = parent.createEl("pre");
      const code = pre.createEl("code");
      if (grammar)
        renderTokens(code, P.tokenize(text, grammar));
      else
        code.setText(text);
    }
    module2.exports = { readLines, renderCode };
  }
});

// src/shared/popover.js
var require_popover = __commonJS({
  "src/shared/popover.js"(exports2, module2) {
    "use strict";
    var SHOW_DELAY = 200;
    var HIDE_GRACE = 250;
    var EDGE_PAD = 12;
    var Popover = class {
      constructor(opts) {
        this.cls = opts.cls;
        this.hiddenCls = opts.hiddenCls;
        this.showDelay = opts.showDelay == null ? SHOW_DELAY : opts.showDelay;
        this.hideGrace = opts.hideGrace == null ? HIDE_GRACE : opts.hideGrace;
        this.onHide = opts.onHide || null;
        this.onDestroy = opts.onDestroy || null;
        this.keepAlive = opts.keepAlive || null;
        this.el = null;
        this.timer = null;
        this.hideTimer = null;
        this.key = "";
        this.pendingKey = "";
        this.token = 0;
      }
      ensureEl() {
        if (!this.el) {
          this.el = document.body.createDiv({ cls: `${this.cls} ${this.hiddenCls}` });
          this.el.addEventListener("mouseenter", () => this.cancelHide());
          this.el.addEventListener("mouseleave", () => this.leave());
        }
        return this.el;
      }
      isVisible() {
        return !!this.el && !this.el.classList.contains(this.hiddenCls);
      }
      contains(node) {
        return !!this.el && !!node && this.el.contains(node);
      }
      cancelHide() {
        clearTimeout(this.hideTimer);
        this.hideTimer = null;
      }
      // Re-asking for what is already up, or already on its way, changes nothing — otherwise
      // every mouse move would restart the timer.
      schedule(key, x, y, build) {
        this.cancelHide();
        if (key === this.key && this.isVisible())
          return;
        if (key === this.pendingKey)
          return;
        this.pendingKey = key;
        clearTimeout(this.timer);
        this.timer = setTimeout(() => {
          this.pendingKey = "";
          this.show(key, x, y, build);
        }, this.showDelay);
      }
      leave() {
        if (this.hideTimer)
          return;
        this.hideTimer = setTimeout(() => {
          this.hideTimer = null;
          if (this.keepAlive && this.keepAlive()) {
            this.leave();
            return;
          }
          this.hide();
        }, this.hideGrace);
      }
      async show(key, x, y, build) {
        const token = ++this.token;
        const ctx = { isCurrent: () => token === this.token };
        const el = this.ensureEl();
        el.empty();
        const after = await build(el, ctx);
        if (after === false || !ctx.isCurrent())
          return;
        this.key = key;
        el.style.visibility = "hidden";
        el.style.left = "-9999px";
        el.style.top = "0px";
        el.removeClass(this.hiddenCls);
        if (typeof after === "function")
          after();
        const r = el.getBoundingClientRect();
        let left = x + EDGE_PAD;
        let top = y + EDGE_PAD;
        if (left + r.width > window.innerWidth - EDGE_PAD)
          left = Math.max(EDGE_PAD, x - EDGE_PAD - r.width);
        if (top + r.height > window.innerHeight - EDGE_PAD)
          top = Math.max(EDGE_PAD, y - EDGE_PAD - r.height);
        el.style.left = left + "px";
        el.style.top = top + "px";
        el.style.visibility = "visible";
      }
      hide() {
        clearTimeout(this.timer);
        clearTimeout(this.hideTimer);
        this.hideTimer = null;
        this.pendingKey = "";
        this.key = "";
        this.token++;
        if (this.onHide)
          this.onHide();
        if (this.el) {
          this.el.addClass(this.hiddenCls);
          this.el.empty();
        }
      }
      destroy() {
        clearTimeout(this.timer);
        clearTimeout(this.hideTimer);
        this.token++;
        if (this.onDestroy)
          this.onDestroy();
        if (this.el) {
          this.el.remove();
          this.el = null;
        }
      }
    };
    module2.exports = { Popover, SHOW_DELAY, HIDE_GRACE };
  }
});

// src/hover.js
var require_hover = __commonJS({
  "src/hover.js"(exports2, module2) {
    "use strict";
    var nodePath2 = require("path");
    var { readLines, renderCode } = require_render();
    var { Popover } = require_popover();
    var keyOf = (e) => e.path + ":" + e.line;
    var HoverPreview2 = class {
      constructor(plugin) {
        this.plugin = plugin;
        this.pop = new Popover({ cls: "code-linker-hover code-linker-code", hiddenCls: "code-linker-hidden" });
      }
      // Read from onHoverMove to tell "nothing scheduled" from "waiting to show".
      get pendingKey() {
        return this.pop.pendingKey;
      }
      isVisible() {
        return this.pop.isVisible();
      }
      contains(node) {
        return this.pop.contains(node);
      }
      cancelHide() {
        this.pop.cancelHide();
      }
      leave() {
        this.pop.leave();
      }
      hide() {
        this.pop.hide();
      }
      destroy() {
        this.pop.destroy();
      }
      schedule(entry, x, y) {
        this.pop.schedule(keyOf(entry), x, y, (el, ctx) => this.build(entry, el, ctx));
      }
      async build(entry, el, ctx) {
        const s = this.plugin.settings;
        const root = this.plugin.codeRoot();
        const abs = root ? nodePath2.join(root, entry.path) : entry.path;
        const line = entry.line || 1;
        const before = s.hoverBefore < 0 ? Infinity : Math.max(0, s.hoverBefore | 0);
        const after = s.hoverAfter < 0 ? Infinity : Math.max(0, s.hoverAfter | 0);
        const snippet = await readLines(abs, line - before, line + after);
        if (!snippet || !ctx.isCurrent())
          return false;
        el.createDiv({ cls: "code-linker-hover-header", text: keyOf(entry) });
        const body = el.createDiv({ cls: "code-linker-hover-body" });
        const idx = Math.min(Math.max(0, line - snippet.startLine), snippet.lines.length - 1);
        const band = body.createDiv({ cls: "code-linker-hover-band" });
        band.style.top = "calc(var(--cl-lh) * " + idx + ")";
        await renderCode(body, snippet.lines.join("\n"), this.plugin.prismIdFor(entry.lang));
        if (!ctx.isCurrent())
          return false;
        return () => {
          body.scrollTop = Math.max(0, band.offsetTop - (body.clientHeight - band.offsetHeight) / 2);
        };
      }
    };
    module2.exports = { HoverPreview: HoverPreview2 };
  }
});

// src/shared/embed-frame.js
var require_embed_frame = __commonJS({
  "src/shared/embed-frame.js"(exports2, module2) {
    "use strict";
    var obsidian = require("obsidian");
    var { t: t2 } = require_i18n();
    function parseSpec2(source, keys) {
      const spec = { target: "" };
      for (const k of keys)
        spec[k] = "";
      const re = new RegExp("^(" + keys.join("|") + ")\\s*:\\s*(.*)$", "i");
      for (const raw of String(source == null ? "" : source).split("\n")) {
        const line = raw.trim();
        if (!line)
          continue;
        const m = re.exec(line);
        if (m)
          spec[m[1].toLowerCase()] = m[2].trim();
        else if (!spec.target)
          spec.target = line;
      }
      return spec;
    }
    function setSpecLine(body, key, value) {
      const re = new RegExp("^\\s*" + key + "\\s*:", "i");
      const at = body.findIndex((l) => re.test(l));
      if (!value)
        return body.filter((l) => !re.test(l));
      if (at < 0)
        return [...body, key + ": " + value];
      const out = body.slice();
      out[at] = key + ": " + value;
      return out;
    }
    async function writeEmbedBody(app, sourcePath, info, body) {
      const view = app.workspace.getActiveViewOfType(obsidian.MarkdownView);
      const editor = view && view.file && view.file.path === sourcePath ? view.editor : null;
      if (editor) {
        editor.replaceRange(body.join("\n") + "\n", { line: info.lineStart + 1, ch: 0 }, { line: info.lineEnd, ch: 0 });
        return true;
      }
      const file = app.vault.getAbstractFileByPath(sourcePath);
      if (!file)
        return false;
      let moved = false;
      await app.vault.process(file, (data) => {
        const lines = data.split("\n");
        const here = lines.slice(info.lineStart, info.lineEnd + 1).join("\n");
        if (here !== info.text.split("\n").slice(info.lineStart, info.lineEnd + 1).join("\n")) {
          moved = true;
          return data;
        }
        lines.splice(info.lineStart + 1, info.lineEnd - info.lineStart - 1, ...body);
        return lines.join("\n");
      });
      return !moved;
    }
    var inEditor = (el) => !!(el && el.closest && el.closest(".markdown-source-view"));
    function toolButton(parent, cls, icon, label, onClick) {
      const b = parent.createEl("button", {
        cls: "clickable-icon " + cls + "-embed-button",
        attr: { type: "button", "aria-label": label, title: label }
      });
      if (icon && typeof obsidian.setIcon === "function")
        obsidian.setIcon(b, icon);
      b.addEventListener("click", (evt) => {
        evt.preventDefault();
        evt.stopPropagation();
        onClick(evt);
      });
      return b;
    }
    var EmbedFrame = class extends obsidian.MarkdownRenderChild {
      constructor(containerEl, plugin, spec, ctx, cls) {
        super(containerEl);
        this.plugin = plugin;
        this.spec = spec;
        this.ctx = ctx;
        this.cls = cls;
        this.renderId = 0;
        this.lastSig = null;
      }
      // --- what a plugin fills in ---------------------------------------------------------------
      resolve() {
        return { error: "embed-frame: resolve() not implemented" };
      }
      // Same string means nothing changed and the render is skipped; null means never skip.
      sig() {
        return null;
      }
      headerText() {
        return "";
      }
      async renderBody() {
        return false;
      }
      tools() {
      }
      menuItems() {
      }
      unreadable() {
        return "";
      }
      release() {
      }
      // --- the shell ----------------------------------------------------------------------------
      onload() {
        this.containerEl.addEventListener("contextmenu", (evt) => this.onContextMenu(evt));
        this.render();
        this.unsub = this.plugin.onIndexChange(() => this.render());
      }
      onunload() {
        if (this.unsub)
          this.unsub();
        this.release();
      }
      open() {
        const entry = this.res && this.res.entry;
        if (!entry)
          return;
        this.plugin.withFormat(this.plugin.settings.askOnInsert, (tpl) => this.plugin.openEntry(entry, tpl));
      }
      menu() {
        const menu = new obsidian.Menu();
        if (this.res.entry)
          menu.addItem((i) => i.setTitle(t2("embed.menu.open")).setIcon("go-to-file").onClick(() => this.open()));
        menu.addItem((i) => i.setTitle(t2("embed.menu.refresh")).setIcon("refresh-cw").onClick(() => this.refresh()));
        this.menuItems(menu, this.res);
        return menu;
      }
      onContextMenu(evt) {
        if (!this.res)
          return;
        evt.preventDefault();
        evt.stopPropagation();
        this.menu().showAtMouseEvent(evt);
      }
      refresh() {
        return this.render(true);
      }
      editable() {
        return inEditor(this.containerEl);
      }
      notice(text) {
        this.release();
        this.chrome = null;
        this.containerEl.empty();
        this.containerEl.createDiv({ cls: this.cls + "-embed-error", text });
      }
      button(parent, icon, label, onClick) {
        return toolButton(parent, this.cls, icon, label, onClick);
      }
      // Built once and kept: a plugin holding state in its own controls loses it to a rebuild.
      frame() {
        if (this.chrome && this.chrome.body.parentElement === this.containerEl)
          return this.chrome;
        const el = this.containerEl;
        el.empty();
        el.addClass(this.cls + "-embed");
        const header = el.createDiv({ cls: this.cls + "-embed-header" });
        const title = header.createSpan({ cls: this.cls + "-embed-title mod-clickable" });
        title.addEventListener("click", () => this.open());
        const bar = header.createDiv({ cls: this.cls + "-embed-tools" });
        const own = bar.createDiv({ cls: this.cls + "-embed-group" });
        const common = bar.createDiv({ cls: this.cls + "-embed-group" });
        this.button(common, "external-link", t2("embed.tool.open"), () => this.open());
        this.button(common, "refresh-cw", t2("embed.tool.refresh"), () => this.refresh());
        this.button(common, "more-horizontal", t2("embed.tool.more"), (evt) => this.menu().showAtMouseEvent(evt));
        const body = el.createDiv({ cls: this.cls + "-embed-body" });
        this.chrome = { header, title, tools: own, body };
        return this.chrome;
      }
      async render(force) {
        const token = ++this.renderId;
        const res = this.resolve();
        this.res = res;
        const sig = res.error ? "err:" + res.error : this.sig(res);
        if (!force && sig !== null && sig === this.lastSig)
          return;
        this.lastSig = sig;
        if (res.error) {
          this.notice(res.error);
          return;
        }
        const chrome = this.frame();
        chrome.title.setText(this.headerText(res));
        this.tools(chrome.tools, res);
        const drew = await this.renderBody(chrome.body, res, () => token === this.renderId);
        if (token !== this.renderId)
          return;
        if (!drew) {
          this.notice(this.unreadable(res));
          this.lastSig = null;
        }
      }
      setHeader(text) {
        if (this.chrome)
          this.chrome.title.setText(text);
      }
      // `edit(body)` gets the block body without its fences, and returns null to write nothing.
      async writeBody(edit) {
        const info = this.ctx && this.ctx.getSectionInfo && this.ctx.getSectionInfo(this.containerEl);
        if (!info)
          return false;
        const next = edit(info.text.split("\n").slice(info.lineStart + 1, info.lineEnd));
        if (!next)
          return false;
        return writeEmbedBody(this.plugin.app, this.ctx.sourcePath, info, next);
      }
    };
    module2.exports = { EmbedFrame, parseSpec: parseSpec2, setSpecLine, writeEmbedBody, toolButton, inEditor };
  }
});

// src/embed.js
var require_embed = __commonJS({
  "src/embed.js"(exports2, module2) {
    "use strict";
    var { Notice: Notice2 } = require("obsidian");
    var nodePath2 = require("path");
    var { readLines, renderCode } = require_render();
    var { parseBinding: parseBinding2 } = require_binding();
    var frame = require_embed_frame();
    var { t: t2, plural: plural2 } = require_i18n();
    var EMBED_LANG = "code-link";
    var MAX_EMBED_LINES = 400;
    var MORE_STEP = 10;
    var SPEC_KEYS = ["context", "lines", "title", "bind", "numbers"];
    var parseSpec2 = (source) => frame.parseSpec(source, SPEC_KEYS);
    var numbered = (spec) => !/^(off|no|false|hide|none)$/i.test((spec.numbers || "").trim());
    var baseName = (p) => nodePath2.basename(p).replace(/\.[^.]+$/, "");
    var intOr = (v, def) => {
      const n = parseInt(v, 10);
      return Number.isFinite(n) ? n : def;
    };
    function splitRange(v) {
      const m = /^(\d+)(?:\s*-\s*(\d+))?$/.exec((v || "").trim());
      if (!m)
        return null;
      const a = parseInt(m[1], 10);
      const b = m[2] ? parseInt(m[2], 10) : a;
      return { from: Math.min(a, b), to: Math.max(a, b) };
    }
    function splitPathRange2(t3) {
      const m = /^(.+?):(\d+)(?:-(\d+))?$/.exec(t3);
      if (!m)
        return null;
      const from = parseInt(m[2], 10);
      const to = m[3] ? parseInt(m[3], 10) : from;
      return { path: m[1], from: Math.min(from, to), to: Math.max(from, to), single: !m[3] };
    }
    var looksLikePath = (s) => s.includes("/") || s.includes("\\") || /\.[a-z0-9]+$/i.test(s);
    function langForPath(plugin, relPath) {
      const ext = nodePath2.extname(relPath).toLowerCase();
      const lang = plugin.languages.find((l) => l.extensions.includes(ext));
      return lang ? lang.id : "";
    }
    function resolvePath2(plugin, relPath) {
      const norm = relPath.split("\\").join("/").replace(/^\.?\//, "");
      const hit = plugin.lookup(norm)[0];
      return hit ? hit.path : norm;
    }
    function build(plugin, relPath, langId, from, to, targetLine, name) {
      const root = plugin.codeRoot();
      const absPath = root ? nodePath2.join(root, relPath) : relPath;
      const requestedTo = to;
      to = Math.min(to, from + MAX_EMBED_LINES - 1);
      return {
        absPath,
        relPath,
        from,
        to,
        targetLine,
        truncated: to < requestedTo,
        prismId: langId ? plugin.prismIdFor(langId) : "",
        entry: { name: name || baseName(relPath), path: relPath, line: targetLine || from }
      };
    }
    function fromPath(plugin, spec, relPath, from, to, targetLine) {
      relPath = resolvePath2(plugin, relPath);
      const ctx = intOr(spec.context, 0);
      const lr = splitRange(spec.lines);
      if (lr) {
        from = lr.from;
        to = lr.to;
        targetLine = null;
      }
      if (from == null) {
        from = 1;
        to = MAX_EMBED_LINES;
      }
      from = Math.max(1, from - ctx);
      to = to + ctx;
      return build(plugin, relPath, langForPath(plugin, relPath), from, to, targetLine, null);
    }
    function withDrift(plugin, spec, res, pinnedLine) {
      const b = parseBinding2(spec.bind);
      if (b && res.relPath && !spec.lines)
        res.drift = plugin.bindState(res.relPath, b, pinnedLine);
      return res;
    }
    function resolve(plugin, spec) {
      const target = spec.target;
      if (!target)
        return { error: t2("embed.empty") };
      const pr = splitPathRange2(target);
      if (pr)
        return withDrift(plugin, spec, fromPath(plugin, spec, pr.path, pr.from, pr.to, pr.single ? pr.from : null), pr.from);
      if (looksLikePath(target))
        return fromPath(plugin, spec, target, null, null, null);
      const f = plugin.parseQuery(target);
      const matches = plugin.entriesForQuery(f).filter((m) => plugin.entryPassesFilter(m, f));
      if (!matches.length)
        return { error: t2("embed.notFound", { query: target }) };
      const paths = new Set(matches.map((m) => m.path));
      if (paths.size > 1)
        return { error: t2("embed.ambiguous", { n: paths.size, query: target }) };
      const e = matches.find((m) => m.kind !== "file") || matches[0];
      const ctx = intOr(spec.context, 0);
      const lr = splitRange(spec.lines);
      const from = Math.max(1, (lr ? lr.from : e.line) - ctx);
      const to = (lr ? lr.to : e.line) + ctx;
      return build(plugin, e.path, e.lang, from, to, lr ? null : e.line, e.name);
    }
    var CodeEmbed = class extends frame.EmbedFrame {
      constructor(containerEl, plugin, spec, ctx) {
        super(containerEl, plugin, spec, ctx, "code-linker");
        containerEl.addClass("code-linker-code");
        this.above = 0;
        this.below = 0;
        this.wrapped = false;
      }
      resolve() {
        const res = resolve(this.plugin, this.spec);
        if (res.error || !(this.above || this.below))
          return res;
        res.from = Math.max(1, res.from - this.above);
        const to = res.to + this.below;
        res.to = Math.min(to, res.from + MAX_EMBED_LINES - 1);
        res.truncated = res.truncated || res.to < to;
        return res;
      }
      refresh() {
        this.above = 0;
        this.below = 0;
        return this.render(true);
      }
      // Without an mtime there is nothing to compare a rebuild against, so nothing is skipped.
      sig(res) {
        const cached = res.relPath && this.plugin.fileCache.get(res.relPath);
        const mtime = cached ? cached.mtimeMs : null;
        if (mtime == null)
          return null;
        const drift = res.drift ? res.drift.state + (res.drift.line || "") : "";
        return res.absPath + "|" + res.from + "|" + res.to + "|" + res.targetLine + "|" + mtime + "|" + drift;
      }
      headerText(res) {
        return this.spec.title || res.relPath;
      }
      unreadable(res) {
        return t2("embed.unreadable", { path: res.relPath });
      }
      tools(row) {
        row.empty();
        const wrap = this.button(row, "wrap-text", t2("embed.tool.wrap"), () => this.toggleWrap(wrap));
        wrap.toggleClass("is-active", this.wrapped);
        this.button(row, "copy", t2("embed.tool.copy"), () => this.copy());
      }
      toggleWrap(button) {
        this.wrapped = !this.wrapped;
        button.toggleClass("is-active", this.wrapped);
        this.chrome.body.toggleClass("is-wrapped", this.wrapped);
        this.measureWrap();
      }
      measureWrap() {
        const code = this.chrome && this.chrome.body.querySelector(".code-linker-embed-code");
        const pre = code && code.querySelector("pre");
        if (!pre)
          return;
        const lh = parseFloat(getComputedStyle(pre).lineHeight);
        const rows = this.lineCount || 0;
        code.toggleClass("has-wrapped-lines", !!(lh > 0 && rows && pre.scrollHeight > lh * rows + 1));
      }
      // Offered only where there is file left, and for as much of it as there is.
      strip(body, side, n) {
        if (n < 1)
          return;
        const label = plural2("embedMore", n);
        const button = this.button(body, side === "above" ? "chevron-up" : "chevron-down", label, () => {
          this[side] += n;
          this.render(true);
        });
        button.addClass("code-linker-embed-more");
        button.createSpan({ text: label });
      }
      copy() {
        if (!this.text || !navigator.clipboard)
          return;
        navigator.clipboard.writeText(this.text).then(() => new Notice2(t2("notice.snippetCopied")), () => {
        });
      }
      async renderBody(body, res, isCurrent) {
        const read = await readLines(res.absPath, res.from, res.to + MORE_STEP) || await readLines(res.absPath, res.from, res.to);
        if (!isCurrent())
          return true;
        if (!read)
          return false;
        const start = read.startLine;
        const snippet = { lines: read.lines.slice(0, res.to - res.from + 1) };
        const below = read.lines.length - snippet.lines.length;
        const end = start + snippet.lines.length - 1;
        this.setHeader(this.spec.title || res.relPath + ":" + (start === end ? start : start + "-" + end));
        for (const state of ["stale", "broken"]) {
          this.chrome.header.toggleClass("code-linker-embed-" + state, !!res.drift && res.drift.state === state);
        }
        body.empty();
        body.toggleClass("is-wrapped", this.wrapped);
        const room = MAX_EMBED_LINES - (res.to - res.from + 1);
        this.strip(body, "above", Math.min(MORE_STEP, start - 1, room));
        const code = body.createDiv({ cls: "code-linker-embed-code" });
        const marked = res.targetLine != null ? res.targetLine - start : -1;
        if (marked >= 0 && marked < snippet.lines.length) {
          const band = code.createDiv({ cls: "code-linker-embed-band" });
          band.style.top = "calc(var(--cl-lh) * " + marked + ")";
        }
        if (numbered(this.spec)) {
          const gutter = code.createDiv({ cls: "code-linker-embed-numbers" });
          snippet.lines.forEach((_, i) => gutter.createDiv({
            cls: i === marked ? "code-linker-embed-marked" : "",
            text: String(start + i)
          }));
        }
        this.text = snippet.lines.join("\n");
        this.lineCount = snippet.lines.length;
        await renderCode(code, this.text, res.prismId);
        this.strip(body, "below", Math.min(below, room));
        this.measureWrap();
        this.notes(res);
        return true;
      }
      notes(res) {
        for (const note of Array.from(this.containerEl.querySelectorAll(".code-linker-embed-note")))
          note.remove();
        if (res.drift) {
          this.containerEl.createDiv({
            cls: "code-linker-embed-note code-linker-embed-" + res.drift.state,
            text: res.drift.state === "stale" ? t2("embed.stale", { line: res.drift.line }) : t2("embed.broken")
          });
        }
        if (res.truncated)
          this.containerEl.createDiv({ cls: "code-linker-embed-note", text: t2("embed.truncated", { max: MAX_EMBED_LINES }) });
      }
      menuItems(menu, res) {
        if (!this.editable())
          return;
        if (res.drift && res.drift.state === "stale") {
          menu.addItem((i) => i.setTitle(t2("menu.fixLink")).setIcon("wrench").onClick(() => this.fix()));
        }
        const p = this.plugin;
        const site = p.embedSite(this.spec);
        p.addPinItems(menu, (a) => p.pinOption(site, this.spec.bind, a), (a) => this.pin(a));
        if (parseBinding2(this.spec.bind)) {
          menu.addItem((i) => i.setTitle(t2("menu.unpin")).setIcon("pin-off").onClick(() => this.setBind("")));
        }
      }
      pin(anchor) {
        const o = this.plugin.pinOption(this.plugin.embedSite(this.spec), this.spec.bind, anchor);
        if (!o) {
          new Notice2(t2("notice.cantBind"));
          return;
        }
        this.setBind(o.title);
      }
      // Bring this embed's frozen line up to date — the fence-body twin of a link's Fix.
      async fix() {
        let fixed = false;
        const ok = await this.writeBody((body) => {
          const d = this.plugin.embedDrift(body);
          if (!d || d.state !== "stale")
            return null;
          fixed = true;
          return d.out;
        });
        if (!fixed) {
          new Notice2(t2("notice.linksUpdated", { n: 0 }));
          return;
        }
        new Notice2(ok ? t2("notice.linksUpdated", { n: 1 }) : t2("notice.embedMoved"));
      }
      async setBind(title) {
        const ok = await this.writeBody((body) => frame.setSpecLine(body, "bind", title));
        if (!ok) {
          new Notice2(t2("notice.embedMoved"));
          return;
        }
        new Notice2(title ? t2("notice.bound", { line: this.res.from }) : t2("notice.unbound"));
      }
    };
    function registerEmbed2(plugin) {
      plugin.registerMarkdownCodeBlockProcessor(EMBED_LANG, (source, el, ctx) => {
        ctx.addChild(new CodeEmbed(el, plugin, parseSpec2(source), ctx));
      });
    }
    module2.exports = { registerEmbed: registerEmbed2, parseSpec: parseSpec2, splitPathRange: splitPathRange2, resolvePath: resolvePath2, numbered };
  }
});

// src/shared/actualize.js
var require_actualize = __commonJS({
  "src/shared/actualize.js"(exports2, module2) {
    "use strict";
    var { Notice: Notice2, MarkdownView: MarkdownView2 } = require("obsidian");
    var { ViewPlugin, Decoration } = require("@codemirror/view");
    var { RangeSetBuilder, StateEffect } = require("@codemirror/state");
    var { syntaxTree } = require("@codemirror/language");
    var { linkRegex: linkRegex2 } = require_markdown();
    var { t: t2 } = require_i18n();
    var SKIP_NODE = /code|comment|frontmatter/i;
    var refreshEffect = StateEffect.define();
    function refreshStaleLinks(app) {
      app.workspace.iterateAllLeaves((leaf) => {
        const cm = leaf.view && leaf.view.editor && leaf.view.editor.cm;
        if (cm)
          cm.dispatch({ effects: refreshEffect.of(null) });
      });
    }
    function staleLinksExtension(plugin, classes) {
      const marks = {
        stale: Decoration.mark({ class: classes.stale }),
        broken: Decoration.mark({ class: classes.broken })
      };
      const build = (view) => {
        const builder = new RangeSetBuilder();
        if (plugin.settings.markStaleLinks) {
          const tree = syntaxTree(view.state);
          for (const { from, to } of view.visibleRanges) {
            const text = view.state.doc.sliceString(from, to);
            const re = linkRegex2();
            let m;
            while (m = re.exec(text)) {
              const start = from + m.index;
              const end = start + m[0].length;
              let inCodeNode = false;
              tree.iterate({ from: start, to: end, enter: (n) => {
                if (SKIP_NODE.test(n.type.name))
                  inCodeNode = true;
              } });
              const state = inCodeNode ? null : plugin.linkState(m[2]);
              if (state)
                builder.add(start, end, marks[state]);
            }
          }
        }
        return builder.finish();
      };
      return ViewPlugin.fromClass(
        class {
          constructor(view) {
            this.decorations = build(view);
          }
          update(u) {
            const refresh = u.transactions.some((tr) => tr.effects.some((e) => e.is(refreshEffect)));
            if (u.docChanged || u.viewportChanged || refresh)
              this.decorations = build(u.view);
          }
        },
        { decorations: (v) => v.decorations }
      );
    }
    async function processNote(plugin, file, transform) {
      let count = 0;
      await plugin.app.vault.process(file, (data) => {
        const out = transform(plugin, data);
        count = out.count;
        return count ? out.text : data;
      });
      return count;
    }
    async function rewriteActiveNote(plugin, transform, noticeKey) {
      const view = plugin.app.workspace.getActiveViewOfType(MarkdownView2);
      const editor = view && view.editor;
      if (editor) {
        const { text, count } = transform(plugin, editor.getValue());
        if (count) {
          const cur = editor.getCursor();
          editor.setValue(text);
          editor.setCursor(cur);
        }
        new Notice2(t2(noticeKey, { n: count }));
        return;
      }
      const file = plugin.app.workspace.getActiveFile();
      if (!file) {
        new Notice2(t2(noticeKey, { n: 0 }));
        return;
      }
      new Notice2(t2(noticeKey, { n: await processNote(plugin, file, transform) }));
    }
    async function rewriteVault(plugin, transform, noticeKey) {
      let files = 0, total = 0;
      for (const f of plugin.app.vault.getMarkdownFiles()) {
        const count = await processNote(plugin, f, transform);
        if (count) {
          files++;
          total += count;
        }
      }
      new Notice2(t2(noticeKey, { n: total, files }));
    }
    module2.exports = { SKIP_NODE, refreshEffect, refreshStaleLinks, staleLinksExtension, rewriteActiveNote, rewriteVault };
  }
});

// src/shared/update-preview.js
var require_update_preview = __commonJS({
  "src/shared/update-preview.js"(exports2, module2) {
    "use strict";
    var { Notice: Notice2, Modal, MarkdownView: MarkdownView2 } = require("obsidian");
    var { t: t2 } = require_i18n();
    var MAX_ROWS = 50;
    var UpdatePreviewModal = class extends Modal {
      constructor(app, entries, onApply, prefix) {
        super(app);
        this.entries = entries;
        this.onApply = onApply;
        this.prefix = prefix;
        for (const e of entries)
          for (const c of e.changes)
            c.selected = true;
      }
      cls(suffix) {
        return suffix ? this.prefix + "-" + suffix : this.prefix;
      }
      onOpen() {
        const { contentEl } = this;
        contentEl.addClass(this.cls());
        contentEl.createEl("h3", { text: t2("modal.update.title") });
        const changed = this.entries.filter((e) => e.changes.length);
        const total = changed.reduce((n, e) => n + e.changes.length, 0);
        const brokenTotal = this.entries.reduce((n, e) => n + e.broken.length, 0);
        if (!total && !brokenTotal) {
          contentEl.createEl("p", { cls: this.cls("empty"), text: t2("modal.update.upToDate") });
        } else {
          if (total)
            contentEl.createEl("p", { text: t2("modal.update.summary", { links: total, files: changed.length }) });
          if (brokenTotal)
            contentEl.createEl("p", { cls: this.cls("attention"), text: t2("modal.update.attention", { n: brokenTotal }) });
          this.entries.forEach((e) => this.renderEntry(contentEl, e));
        }
        const bar = contentEl.createDiv({ cls: this.cls("buttons") });
        if (total) {
          bar.createEl("button", { text: t2("btn.apply"), cls: "mod-cta" }).onclick = async () => {
            this.close();
            await this.onApply(this.entries);
          };
          bar.createEl("button", { text: t2("btn.cancel") }).onclick = () => this.close();
        } else {
          bar.createEl("button", { text: t2("btn.close"), cls: "mod-cta" }).onclick = () => this.close();
        }
      }
      renderEntry(contentEl, e) {
        if (!e.changes.length && !e.broken.length)
          return;
        const head = contentEl.createDiv({ cls: this.cls("file") });
        if (e.changes.length) {
          const rowBoxes = [];
          const label = head.createEl("label", { cls: this.cls("check") });
          const master = label.createEl("input", { type: "checkbox" });
          master.checked = true;
          master.onchange = () => {
            e.changes.forEach((c, i) => {
              c.selected = master.checked;
              if (rowBoxes[i])
                rowBoxes[i].checked = master.checked;
            });
            master.indeterminate = false;
          };
          label.createSpan({ text: e.label });
          const syncMaster = () => {
            const on = e.changes.filter((c) => c.selected).length;
            master.checked = on > 0;
            master.indeterminate = on > 0 && on < e.changes.length;
          };
          const table = contentEl.createEl("table", { cls: this.cls("table") });
          e.changes.slice(0, MAX_ROWS).forEach((c) => {
            const tr = table.createEl("tr");
            const cb = tr.createEl("td", { cls: this.cls("pick") }).createEl("input", { type: "checkbox" });
            cb.checked = c.selected;
            cb.onchange = () => {
              c.selected = cb.checked;
              syncMaster();
            };
            rowBoxes.push(cb);
            tr.createEl("td", { text: c.label });
            if (c.toPath) {
              tr.addClass(this.cls("moved"));
              tr.createEl("td", { cls: this.cls("move"), text: c.fromPath + ":" + c.from + " \u2192 " + c.toPath + ":" + c.to });
            } else {
              tr.createEl("td", { cls: this.cls("move"), text: c.from + " \u2192 " + c.to });
            }
          });
          if (e.changes.length > MAX_ROWS)
            contentEl.createEl("div", { cls: this.cls("more"), text: t2("modal.andMore", { n: e.changes.length - MAX_ROWS }) });
        } else {
          head.setText(e.label);
        }
        e.broken.forEach((label) => contentEl.createDiv({ cls: this.cls("broken"), text: t2("modal.update.brokenRow", { label }) }));
      }
      onClose() {
        this.contentEl.empty();
      }
    };
    async function applyUpdates(plugin, entries, rewrite) {
      let files = 0, total = 0, skipped = 0;
      for (const e of entries) {
        const keys = new Set(e.changes.filter((c) => c.selected).map((c) => c.key));
        if (!keys.size)
          continue;
        if (e.editor) {
          if (e.editor.getValue() !== e.original) {
            skipped++;
            continue;
          }
          const { newText, count } = rewrite(plugin, e.original, keys);
          const cur = e.editor.getCursor();
          e.editor.setValue(newText);
          e.editor.setCursor(cur);
          files++;
          total += count;
        } else {
          let count = 0;
          await plugin.app.vault.process(e.file, (data) => {
            if (data !== e.original)
              return data;
            const out = rewrite(plugin, data, keys);
            count = out.count;
            return out.newText;
          });
          if (count) {
            files++;
            total += count;
          } else
            skipped++;
        }
      }
      let msg = t2("notice.linksUpdatedVault", { n: total, files });
      if (skipped)
        msg += " " + t2("notice.updateSkipped", { n: skipped });
      new Notice2(msg);
    }
    function openUpdatePreview(plugin, entries, rewrite, prefix) {
      new UpdatePreviewModal(plugin.app, entries, (chosen) => applyUpdates(plugin, chosen, rewrite), prefix).open();
    }
    async function updateInActiveNote(plugin, rewrite, prefix) {
      const view = plugin.app.workspace.getActiveViewOfType(MarkdownView2);
      const editor = view && view.editor;
      const file = plugin.app.workspace.getActiveFile();
      if (editor) {
        const original2 = editor.getValue();
        const c2 = rewrite(plugin, original2, null);
        openUpdatePreview(plugin, [{ editor, label: file && file.path || t2("label.thisNote"), original: original2, changes: c2.changes, broken: c2.broken }], rewrite, prefix);
        return;
      }
      if (!file) {
        new Notice2(t2("notice.linksUpdated", { n: 0 }));
        return;
      }
      const original = await plugin.app.vault.read(file);
      const c = rewrite(plugin, original, null);
      openUpdatePreview(plugin, [{ file, label: file.path, original, changes: c.changes, broken: c.broken }], rewrite, prefix);
    }
    async function scanVault(plugin, rewrite) {
      const entries = [];
      for (const f of plugin.app.vault.getMarkdownFiles()) {
        const original = await plugin.app.vault.read(f);
        const c = rewrite(plugin, original, null);
        if (c.changes.length || c.broken.length)
          entries.push({ file: f, label: f.path, original, changes: c.changes, broken: c.broken });
      }
      return entries;
    }
    async function updateInVault(plugin, rewrite, prefix) {
      openUpdatePreview(plugin, await scanVault(plugin, rewrite), rewrite, prefix);
    }
    module2.exports = { UpdatePreviewModal, applyUpdates, openUpdatePreview, updateInActiveNote, updateInVault, scanVault };
  }
});

// src/actualize.js
var require_actualize2 = __commonJS({
  "src/actualize.js"(exports2, module2) {
    "use strict";
    var { splitTarget: splitTarget2, withTitle: withTitle2, rewriteLinks, rewriteFences } = require_markdown();
    var { LINE_RE: LINE_RE2, parseBinding: parseBinding2, ownsBinding } = require_binding();
    var shared = require_actualize();
    var OWNER2 = "code";
    var { parseSpec: parseSpec2 } = require_embed();
    var { setSpecLine } = require_embed_frame();
    var preview = require_update_preview();
    var { t: t2 } = require_i18n();
    var PREVIEW_CLASS = "code-linker-preview";
    var EMBED_LANG = "code-link";
    var rewriteUpdates = (plugin, text, selected) => {
      const lineOf = (t3) => {
        const m = LINE_RE2.exec(t3);
        return m ? m[1] : "";
      };
      const collect = selected == null;
      const changes = [];
      const broken = [];
      let key = 0;
      const links = rewriteLinks(text, (name, target) => {
        const r = bindStateOf(plugin, target);
        if (r && r.state === "stale") {
          const k = key++;
          const { url, title } = splitTarget2(target);
          if (collect) {
            const row = { key: k, label: name, from: lineOf(url), to: String(r.line) };
            if (r.move) {
              row.fromPath = r.move.from;
              row.toPath = r.move.to;
            }
            changes.push(row);
          }
          if (!collect && !selected.has(k))
            return null;
          const fixedUrl = r.url != null ? r.url : url.replace(LINE_RE2, ":" + r.line);
          return "[" + name + "](" + withTitle2(fixedUrl, title) + ")";
        }
        if (collect && r && r.state === "broken")
          broken.push(name);
        return null;
      });
      const embeds = rewriteFences(links.text, EMBED_LANG, (body) => {
        const d = plugin.embedDrift(body);
        if (!d)
          return null;
        if (d.state === "broken") {
          if (collect)
            broken.push(d.path);
          return null;
        }
        const k = key++;
        if (collect)
          changes.push({ key: k, label: d.path, from: d.from, to: d.to });
        if (!collect && !selected.has(k))
          return null;
        return d.out;
      });
      return { newText: embeds.text, count: links.count + embeds.count, changes, broken };
    };
    var pinLinksInText = (anchors) => (plugin, text) => {
      const links = rewriteLinks(text, (name, target) => {
        const { url, title } = splitTarget2(target);
        if (title)
          return null;
        const bind = plugin.buildPinTitle(plugin.linkSite(target), anchors);
        return bind ? "[" + name + "](" + withTitle2(url, bind) + ")" : null;
      });
      const embeds = rewriteFences(links.text, EMBED_LANG, (body) => {
        const spec = parseSpec2(body.join("\n"));
        if (spec.bind)
          return null;
        const bind = plugin.buildPinTitle(plugin.embedSite(spec), anchors);
        return bind ? setSpecLine(body, "bind", bind) : null;
      });
      return { text: embeds.text, count: links.count + embeds.count };
    };
    var { refreshStaleLinks } = shared;
    var staleLinksExtension = (plugin) => shared.staleLinksExtension(plugin, { stale: "code-linker-stale", broken: "code-linker-broken" });
    function bindStateOf(plugin, target) {
      const { url, title } = splitTarget2(target);
      const m = url && LINE_RE2.exec(url);
      const b = ownsBinding(title, OWNER2) ? parseBinding2(title) : null;
      return m && b ? plugin.urlBindState(url, b, parseInt(m[1], 10)) : null;
    }
    var methods = {
      linkState(target) {
        const r = bindStateOf(this, target);
        return r ? r.state : null;
      },
      isLinkStale(target) {
        return this.linkState(target) === "stale";
      },
      // The link target with its line corrected, or null when there's nothing to fix. Shared
      // by the note/vault commands and the right-click fix.
      actualizedTarget(target) {
        const r = bindStateOf(this, target);
        if (!r || r.state !== "stale")
          return null;
        const { url, title } = splitTarget2(target);
        return withTitle2(r.url != null ? r.url : url.replace(LINE_RE2, ":" + r.line), title);
      },
      rewriteActiveNote(transform, noticeKey) {
        return shared.rewriteActiveNote(this, transform, noticeKey);
      },
      rewriteVault(transform, noticeKey) {
        return shared.rewriteVault(this, transform, noticeKey);
      },
      updateLinksInActiveNote() {
        return preview.updateInActiveNote(this, rewriteUpdates, PREVIEW_CLASS);
      },
      updateLinksInVault() {
        return preview.updateInVault(this, rewriteUpdates, PREVIEW_CLASS);
      },
      pinLinksInActiveNote(anchors) {
        return this.rewriteActiveNote(pinLinksInText(anchors), "notice.linksPinned");
      },
      pinLinksInVault(anchors) {
        return this.rewriteVault(pinLinksInText(anchors), "notice.linksPinnedVault");
      }
    };
    module2.exports = { methods, staleLinksExtension, refreshStaleLinks, rewriteUpdates };
  }
});

// src/modal.js
var require_modal = __commonJS({
  "src/modal.js"(exports2, module2) {
    "use strict";
    var { FuzzySuggestModal, Modal, Setting } = require("obsidian");
    var { t: t2 } = require_i18n();
    var CodeLinkModal2 = class extends FuzzySuggestModal {
      constructor(app, plugin, opts) {
        super(app);
        this.plugin = plugin;
        this.onChoose = opts && opts.onChoose || (() => {
        });
        this.initialQuery = opts && opts.query || "";
        this.setPlaceholder(t2("modal.searchPlaceholder"));
      }
      onOpen() {
        super.onOpen();
        if (this.initialQuery) {
          this.inputEl.value = this.initialQuery;
          this.inputEl.dispatchEvent(new Event("input"));
        }
      }
      getItems() {
        const hidden = new Set(this.plugin.settings.disabledKinds || []);
        return this.plugin.index.filter((e) => !hidden.has(e.lang + ":" + e.kind));
      }
      // Path keeps same-named entries distinct in the modal's own fuzzy search.
      getItemText(e) {
        return `${e.name}  ${e.kind}  ${e.path}`;
      }
      onChooseItem(e) {
        this.onChoose(e);
      }
    };
    var PresetPickerModal2 = class extends FuzzySuggestModal {
      constructor(app, items, onChoose, placeholder) {
        super(app);
        this.items = items;
        this.onChoose = onChoose;
        if (placeholder)
          this.setPlaceholder(placeholder);
      }
      getItems() {
        return this.items;
      }
      getItemText(p) {
        return p.label;
      }
      onChooseItem(p) {
        this.onChoose(p);
      }
    };
    var LinePromptModal2 = class extends Modal {
      constructor(app, line, onSubmit) {
        super(app);
        this.line = String(line);
        this.onSubmit = onSubmit;
      }
      onOpen() {
        this.titleEl.setText(t2("modal.linePrompt"));
        new Setting(this.contentEl).addText((c) => {
          c.setValue(this.line).onChange((v) => {
            this.line = v;
          });
          c.inputEl.type = "number";
          c.inputEl.min = "1";
          c.inputEl.focus();
          c.inputEl.select();
          c.inputEl.addEventListener("keydown", (e) => {
            if (e.key === "Enter")
              this.submit();
          });
        });
        new Setting(this.contentEl).addButton((b) => b.setButtonText(t2("modal.lineSubmit")).setCta().onClick(() => this.submit()));
      }
      submit() {
        const n = parseInt(this.line, 10);
        if (!(n >= 1))
          return;
        this.close();
        this.onSubmit(n);
      }
      onClose() {
        this.contentEl.empty();
      }
    };
    var PinAnchorModal2 = class extends Modal {
      constructor(app, onSubmit) {
        super(app);
        this.onSubmit = onSubmit;
        this.anchors = { sym: true, kind: false, line: true };
      }
      onOpen() {
        this.titleEl.setText(t2("modal.pinAnchors"));
        this.contentEl.createEl("p", { cls: "setting-item-description", text: t2("modal.pinAnchorsDesc") });
        for (const a of ["sym", "kind", "line"]) {
          new Setting(this.contentEl).setName(t2("modal.pinAnchor." + a)).addToggle((c) => c.setValue(this.anchors[a]).onChange((v) => {
            this.anchors[a] = v;
          }));
        }
        new Setting(this.contentEl).addButton((b) => b.setButtonText(t2("modal.pinAnchorsSubmit")).setCta().onClick(() => this.submit()));
      }
      submit() {
        if (!this.anchors.sym && !this.anchors.kind && !this.anchors.line)
          return;
        this.close();
        this.onSubmit(this.anchors);
      }
      onClose() {
        this.contentEl.empty();
      }
    };
    module2.exports = { CodeLinkModal: CodeLinkModal2, PresetPickerModal: PresetPickerModal2, LinePromptModal: LinePromptModal2, PinAnchorModal: PinAnchorModal2 };
  }
});

// src/index-view.js
var require_index_view = __commonJS({
  "src/index-view.js"(exports2, module2) {
    "use strict";
    var { ItemView, Notice: Notice2 } = require("obsidian");
    var { t: t2, plural: plural2 } = require_i18n();
    var { scanVault } = require_update_preview();
    var { rewriteUpdates } = require_actualize2();
    var INDEX_VIEW_TYPE2 = "code-index";
    var CodeIndexView2 = class extends ItemView {
      constructor(leaf, plugin) {
        super(leaf);
        this.plugin = plugin;
        this.query = "";
        this.openLangs = /* @__PURE__ */ new Set();
        this.notes = null;
      }
      getViewType() {
        return INDEX_VIEW_TYPE2;
      }
      getDisplayText() {
        return t2("view.index.title");
      }
      getIcon() {
        return "file-code";
      }
      async onOpen() {
        this.contentEl.addClass("code-linker-index");
        this.unsubscribe = this.plugin.onIndexChange(() => this.render());
        this.render();
      }
      async onClose() {
        if (this.unsubscribe)
          this.unsubscribe();
      }
      // A pane that cannot draw itself must say so. Obsidian swallows a throw out of onOpen and
      // leaves the leaf blank, which reads as "the panel found nothing" rather than "it broke".
      render() {
        const root = this.contentEl;
        root.empty();
        try {
          this.renderSearch(root);
          this.renderIndex(root);
          this.renderLinks(root);
        } catch (e) {
          console.error("Code Linker: the index panel failed to draw", e);
          root.createDiv({ cls: "code-linker-index-empty is-error", text: t2("view.index.failed", { error: String(e && e.message || e) }) });
        }
      }
      head(el, label, count) {
        const h = el.createDiv({ cls: "code-linker-index-head" });
        h.createSpan({ text: count == null ? label : `${label} (${count})` });
        return h;
      }
      renderSearch(root) {
        const bar = root.createDiv({ cls: "code-linker-index-bar" });
        const input = bar.createEl("input", { type: "search", placeholder: t2("view.index.search") });
        input.value = this.query;
        input.oninput = () => {
          this.query = input.value;
          this.renderMatches();
        };
        bar.createEl("button", { text: t2("view.index.rebuild") }).onclick = () => this.plugin.rebuildIndex(true);
        this.matchesEl = root.createDiv();
        this.renderMatches();
      }
      // Matching is by name, not by the inline filter grammar: a panel is for looking, and the
      // trigger in a note is where a query belongs.
      renderMatches() {
        if (!this.matchesEl)
          return;
        const el = this.matchesEl;
        el.empty();
        const q = this.query.trim().toLowerCase();
        if (!q)
          return;
        const hits = this.plugin.index.filter((e) => e.name.toLowerCase().includes(q)).slice(0, 50);
        this.head(el, t2("view.index.matches"), hits.length);
        if (!hits.length) {
          el.createDiv({ cls: "code-linker-index-empty", text: t2("view.index.noMatches") });
          return;
        }
        for (const e of hits)
          this.entryRow(el, e);
      }
      entryRow(el, e) {
        const row = el.createDiv({ cls: "code-linker-index-row" });
        const name = row.createSpan({ cls: "code-linker-index-name is-link", text: e.name });
        name.onclick = () => this.plugin.withFormat(this.plugin.settings.askOnInsert, (tpl) => this.plugin.openEntry(e, tpl));
        row.createSpan({ cls: "code-linker-index-kind", text: e.kind });
        row.createSpan({ cls: "code-linker-index-path", text: e.path });
        const copy = row.createSpan({ cls: "code-linker-index-act is-link", text: t2("view.index.copy") });
        copy.onclick = () => this.plugin.withFormat(this.plugin.settings.askOnInsert, (tpl) => this.plugin.copyLink(e, tpl));
      }
      // Languages, and the kinds inside each. Counting is over the whole index rather than the
      // enabled kinds: what was scanned is the question here, not what a query would offer.
      renderIndex(root) {
        const el = root.createDiv();
        const byLang = /* @__PURE__ */ new Map();
        for (const e of this.plugin.index) {
          const kinds = byLang.get(e.lang) || /* @__PURE__ */ new Map();
          kinds.set(e.kind, (kinds.get(e.kind) || 0) + 1);
          byLang.set(e.lang, kinds);
        }
        this.head(el, t2("view.index.index"), this.plugin.index.length);
        if (!byLang.size) {
          el.createDiv({ cls: "code-linker-index-empty", text: t2("view.index.empty") });
          return;
        }
        const langs = [...byLang.keys()].sort();
        for (const lang of langs) {
          const kinds = byLang.get(lang);
          const total = [...kinds.values()].reduce((a, b) => a + b, 0);
          const open = this.openLangs.has(lang);
          const row = el.createDiv({ cls: "code-linker-index-row is-toggle" });
          row.createSpan({ cls: "code-linker-index-caret", text: open ? "\u25BE" : "\u25B8" });
          row.createSpan({ cls: "code-linker-index-name", text: this.languageName(lang) });
          row.createSpan({ cls: "code-linker-index-count", text: String(total) });
          row.onclick = () => {
            if (open)
              this.openLangs.delete(lang);
            else
              this.openLangs.add(lang);
            this.render();
          };
          if (!open)
            continue;
          for (const kind of [...kinds.keys()].sort()) {
            const sub = el.createDiv({ cls: "code-linker-index-row is-sub" });
            sub.createSpan({ cls: "code-linker-index-name", text: kind });
            sub.createSpan({ cls: "code-linker-index-count", text: String(kinds.get(kind)) });
          }
        }
      }
      renderLinks(root) {
        const el = root.createDiv();
        const h = this.head(el, t2("view.index.links"), this.notes ? this.notes.length : null);
        h.createEl("button", { text: t2("view.index.scan") }).onclick = () => this.scan();
        if (!this.notes) {
          el.createDiv({ cls: "code-linker-index-empty", text: t2("view.index.notScanned") });
          return;
        }
        if (!this.notes.length) {
          el.createDiv({ cls: "code-linker-index-empty", text: t2("view.index.allWell") });
          return;
        }
        const stale = this.notes.reduce((n, x) => n + x.changes.length, 0);
        const broken = this.notes.reduce((n, x) => n + x.broken.length, 0);
        const sum = el.createDiv({ cls: "code-linker-index-summary" });
        sum.createSpan({ text: t2("view.index.found", { stale: plural2("staleLink", stale), broken: plural2("brokenLink", broken) }) });
        if (stale) {
          sum.createEl("button", { text: t2("view.index.fixAll"), cls: "mod-cta" }).onclick = () => this.plugin.updateLinksInVault();
        }
        for (const n of this.notes) {
          const row = el.createDiv({ cls: "code-linker-index-row" });
          const name = row.createSpan({ cls: "code-linker-index-name is-link", text: n.label });
          name.onclick = () => this.app.workspace.openLinkText(n.file.path, "", false);
          if (n.changes.length)
            row.createSpan({ cls: "code-linker-index-count", text: plural2("staleLink", n.changes.length) });
          if (n.broken.length)
            row.createSpan({ cls: "code-linker-index-count is-broken", text: plural2("brokenLink", n.broken.length) });
        }
      }
      // A language the index carries may have been switched off since; its id is still better than
      // nothing, so it stands in rather than the row vanishing.
      languageName(id) {
        const l = (this.plugin.languages || []).find((x) => x.id === id);
        return l && l.name || id;
      }
      // The walk reads every note, so one unreadable or concurrently deleted file must not leave
      // the button doing nothing and a rejection in the console. A failed scan stays "not scanned"
      // rather than empty: an empty result reads as "every link lands", which it did not prove.
      async scan() {
        try {
          this.notes = await scanVault(this.plugin, rewriteUpdates);
        } catch (e) {
          this.notes = null;
          new Notice2(t2("view.index.scanFailed"));
        }
        this.render();
      }
    };
    module2.exports = { CodeIndexView: CodeIndexView2, INDEX_VIEW_TYPE: INDEX_VIEW_TYPE2 };
  }
});

// src/shared/suggest-base.js
var require_suggest_base = __commonJS({
  "src/shared/suggest-base.js"(exports2, module2) {
    "use strict";
    var { AbstractInputSuggest } = require("obsidian");
    var PathSuggestBase = class extends AbstractInputSuggest {
      constructor(app, inputEl, onSelect) {
        super(app, inputEl);
        this.app = app;
        this.inputEl = inputEl;
        this.onSelect = onSelect;
      }
      // A vault completer deals in TFile/TFolder, a disk one in plain paths.
      pathOf(item) {
        return typeof item === "string" ? item : item.path;
      }
      match(items, query, limit) {
        const q = String(query == null ? "" : query).replace(/\\/g, "/").toLowerCase();
        const hit = items.filter((i) => this.pathOf(i).toLowerCase().includes(q));
        return limit ? hit.slice(0, limit) : hit;
      }
      renderSuggestion(item, el) {
        el.setText(this.pathOf(item) || "/");
      }
      // onSelect clears the box instead of keeping the pick: the folder-list editor adds it as a
      // row rather than binding the input to one value.
      selectSuggestion(item) {
        const path = this.pathOf(item);
        if (this.onSelect) {
          this.onSelect(path);
          this.setValue("");
          this.close();
          return;
        }
        this.setValue(path);
        this.inputEl.trigger("input");
        this.close();
      }
    };
    var suggestAvailable = () => typeof AbstractInputSuggest === "function";
    var SUGGEST_LIMIT = 50;
    module2.exports = { PathSuggestBase, suggestAvailable, SUGGEST_LIMIT };
  }
});

// src/shared/deeplink/disk-suggest.js
var require_disk_suggest = __commonJS({
  "src/shared/deeplink/disk-suggest.js"(exports2, module2) {
    "use strict";
    var fs2 = require("fs");
    var nodePath2 = require("path");
    var { PathSuggestBase, suggestAvailable, SUGGEST_LIMIT } = require_suggest_base();
    var DiskPathSuggest = class extends PathSuggestBase {
      constructor(app, inputEl, opts) {
        const o = opts || {};
        super(app, inputEl, o.onSelect);
        this.getRoot = o.getRoot;
        this.getSeed = o.getSeed;
        this.exts = o.exts && o.exts.length ? new Set(o.exts.map((e) => e.toLowerCase())) : null;
      }
      entries(dir) {
        try {
          return fs2.readdirSync(dir, { withFileTypes: true }).filter((e) => e.isDirectory()).map((e) => e.name);
        } catch (e) {
          return [];
        }
      }
      // Every wanted file under `base`, root-relative. Walked once per completer and kept: the
      // filtering runs per keystroke, and a document library is too big to re-read that often.
      files(base) {
        if (this.cache && this.cacheBase === base)
          return this.cache;
        const out = [];
        const walk = (dir, rel) => {
          let items = [];
          try {
            items = fs2.readdirSync(dir, { withFileTypes: true });
          } catch (e) {
            return;
          }
          for (const e of items) {
            if (e.name[0] === ".")
              continue;
            const r = rel ? rel + "/" + e.name : e.name;
            if (e.isDirectory())
              walk(nodePath2.join(dir, e.name), r);
            else if (this.exts.has(nodePath2.extname(e.name).toLowerCase()))
              out.push(r);
          }
        };
        walk(base, "");
        this.cacheBase = base;
        this.cache = out.sort();
        return this.cache;
      }
      getSuggestions(query) {
        const base = this.getRoot ? this.getRoot() : "";
        if (this.exts)
          return this.match(this.files(base), query, SUGGEST_LIMIT);
        const q = String(query == null ? "" : query).replace(/\\/g, "/");
        const slash = q.lastIndexOf("/");
        const partial = (slash === -1 ? q : q.slice(slash + 1)).toLowerCase();
        const head = slash === -1 ? "" : q.slice(0, slash);
        let scanDir, prefix;
        if (base) {
          scanDir = nodePath2.join(base, head);
          prefix = head;
        } else if (slash === -1) {
          scanDir = this.getSeed ? this.getSeed() : "";
          prefix = scanDir;
        } else {
          scanDir = head.endsWith(":") ? head + "/" : head;
          prefix = head;
        }
        if (!scanDir)
          return [];
        const stem = prefix.replace(/\/+$/, "");
        return this.entries(scanDir).filter((name) => name.toLowerCase().includes(partial)).map((name) => stem ? stem + "/" + name : name).sort().slice(0, SUGGEST_LIMIT);
      }
    };
    module2.exports = { DiskPathSuggest, suggestAvailable };
  }
});

// src/shared/folder-list.js
var require_folder_list = __commonJS({
  "src/shared/folder-list.js"(exports2, module2) {
    "use strict";
    var { Setting, setIcon } = require("obsidian");
    function renderFolderList(containerEl, opts) {
      const cls = opts.cls;
      const norm = opts.normalize || ((x) => x.trim());
      const read = () => (opts.get() || "").split("\n").map((x) => x.trim()).filter(Boolean);
      new Setting(containerEl).setName(opts.name).setDesc(opts.desc);
      const rowsEl = containerEl.createDiv({ cls: `${cls}-folder-rows` });
      const addEl = containerEl.createDiv({ cls: `${cls}-folder-add` });
      const commit = async (next) => {
        const seen = /* @__PURE__ */ new Set();
        const clean = [];
        for (const p of next) {
          const n = norm(p);
          if (n && !seen.has(n)) {
            seen.add(n);
            clean.push(n);
          }
        }
        await opts.set(clean.join("\n"));
        draw();
      };
      const draw = () => {
        rowsEl.empty();
        read().forEach((path, i) => {
          const row = new Setting(rowsEl).setName(path);
          row.settingEl.addClass(`${cls}-folder-row`);
          row.addExtraButton((b) => b.setIcon("x").setTooltip(opts.removeLabel || "").onClick(() => {
            const next = read();
            next.splice(i, 1);
            commit(next);
          }));
        });
      };
      const input = addEl.createEl("input", { type: "text", cls: `${cls}-folder-input`, attr: { placeholder: opts.placeholder || "" } });
      const addBtn = addEl.createEl("button", { cls: `${cls}-folder-addbtn`, attr: { "aria-label": opts.addLabel || "" } });
      setIcon(addBtn, "plus");
      const add = (raw) => {
        if (norm(raw))
          commit([...read(), raw]);
        input.value = "";
        input.focus();
      };
      if (opts.attachSuggest)
        opts.attachSuggest(input, add);
      addBtn.addEventListener("click", () => add(input.value));
      input.addEventListener("keydown", (e) => {
        if (e.key === "Enter") {
          e.preventDefault();
          add(input.value);
        }
      });
      draw();
    }
    module2.exports = { renderFolderList };
  }
});

// src/shared/settings-redraw.js
var require_settings_redraw = __commonJS({
  "src/shared/settings-redraw.js"(exports2, module2) {
    "use strict";
    function redraw(tab, draw) {
      const el = tab && tab.containerEl;
      const top = el ? el.scrollTop || 0 : 0;
      draw();
      if (el && top)
        el.scrollTop = top;
    }
    module2.exports = { redraw };
  }
});

// src/shared/precedence.js
var require_precedence = __commonJS({
  "src/shared/precedence.js"(exports2, module2) {
    "use strict";
    var { discoverLinkers, outranks, siblingLinkers } = require_discover();
    var { t: t2 } = require_i18n();
    var STEP = 10;
    function rankedLinkers(app) {
      return discoverLinkers(app).slice().sort((a, b) => {
        if (outranks(a, b))
          return -1;
        if (outranks(b, a))
          return 1;
        return 0;
      });
    }
    function indexForPrecedence(others, self, value) {
      const hypothetical = { precedence: value, id: self.id };
      return others.filter((o) => outranks(o, hypothetical)).length;
    }
    function precedenceForIndex(app, self, index) {
      const others = rankedLinkers(app).filter((p) => p.id !== self.id);
      if (!others.length)
        return self.precedence || 0;
      const at = Math.max(0, Math.min(index, others.length));
      const values = others.map((p) => p.precedence || 0);
      const candidates = [values[0] + STEP, values[values.length - 1] - STEP];
      for (let i = 1; i < values.length; i++) {
        if (values[i - 1] !== values[i])
          candidates.push((values[i - 1] + values[i]) / 2);
      }
      for (const v of values)
        candidates.push(v);
      const from = currentIndex(app, self);
      const wanted = Math.sign(at - from);
      let best = null;
      let bestLanded = null;
      for (const v of candidates) {
        const landed = indexForPrecedence(others, self, v);
        if (landed === at)
          return v;
        if (Math.sign(landed - from) !== wanted)
          continue;
        if (best === null || Math.abs(landed - at) < Math.abs(bestLanded - at)) {
          best = v;
          bestLanded = landed;
        }
      }
      return best === null ? self.precedence || 0 : best;
    }
    function currentIndex(app, self) {
      return rankedLinkers(app).findIndex((p) => p.id === self.id);
    }
    function renderPrecedence(containerEl, opts) {
      const { app, provider, Setting, name, desc, save } = opts;
      if (!provider || !siblingLinkers(app, provider).length)
        return;
      new Setting(containerEl).setName(name).setDesc(desc);
      const cls = opts.cls || "linker";
      const list = containerEl.createDiv({ cls: `${cls}-precedence-list` });
      const draw = () => {
        list.empty();
        const ranked = rankedLinkers(app);
        ranked.forEach((p, i) => {
          const mine = p.id === provider.id;
          const row = new Setting(list).setName(`${i + 1}. ${p.displayName || p.id}`);
          if (!mine) {
            row.setDesc(opts.otherDesc || "");
            return;
          }
          row.settingEl.addClass(`${cls}-precedence-self`);
          row.addExtraButton((b) => b.setIcon("arrow-up").setTooltip(opts.upTooltip || "").setDisabled(i === 0).onClick(async () => {
            await save(precedenceForIndex(app, provider, i - 1));
            refresh();
          }));
          row.addExtraButton((b) => b.setIcon("arrow-down").setTooltip(opts.downTooltip || "").setDisabled(i === ranked.length - 1).onClick(async () => {
            await save(precedenceForIndex(app, provider, i + 1));
            refresh();
          }));
        });
      };
      const refresh = () => {
        for (const p of siblingLinkers(app, provider)) {
          if (typeof p.refresh === "function") {
            try {
              p.refresh();
            } catch (e) {
            }
          }
        }
        draw();
      };
      draw();
    }
    function renderPrecedenceSetting(containerEl, opts) {
      renderPrecedence(containerEl, {
        app: opts.app,
        provider: opts.provider,
        Setting: opts.Setting,
        cls: opts.cls,
        name: t2("set.precedence.name"),
        desc: t2("set.precedence.desc"),
        otherDesc: t2("set.precedence.other"),
        upTooltip: t2("set.precedence.up"),
        downTooltip: t2("set.precedence.down"),
        save: opts.save
      });
    }
    module2.exports = { STEP, rankedLinkers, precedenceForIndex, currentIndex, renderPrecedence, renderPrecedenceSetting };
  }
});

// src/settings-tab.js
var require_settings_tab = __commonJS({
  "src/settings-tab.js"(exports2, module2) {
    "use strict";
    var { PluginSettingTab, Setting } = require("obsidian");
    var { PRESETS: PRESETS2, JETBRAINS_PRODUCTS: JETBRAINS_PRODUCTS2 } = require_constants();
    var { DiskPathSuggest, suggestAvailable } = require_disk_suggest();
    var { renderFolderList } = require_folder_list();
    var { t: t2, plural: plural2 } = require_i18n();
    var { redraw } = require_settings_redraw();
    var { renderPrecedenceSetting: precedenceSetting } = require_precedence();
    var normFolder = (p) => p.replace(/\\/g, "/").replace(/\/+$/, "").trim();
    var CodeLinkerSettingTab2 = class extends PluginSettingTab {
      constructor(app, plugin) {
        super(app, plugin);
        this.plugin = plugin;
        this.expanded = /* @__PURE__ */ new Set();
      }
      // The dropdown key for the active preset: 'ask' in always-ask mode, a built-in
      // preset, or 'u:<i>' for a user editor. Migration guarantees a template match.
      selectedEditor() {
        if (this.plugin.settings.askOnInsert)
          return "ask";
        const p = this.plugin.editorPresets().find((x) => x.template === this.plugin.settings.uriTemplate);
        return p ? p.key : "file";
      }
      // Whether the selected default's template uses a product placeholder (→ show the IDE dropdown).
      selectedUsesProduct() {
        const p = this.plugin.editorPresets().find((x) => x.key === this.selectedEditor());
        return !!p && this.plugin.usesProduct(p.template);
      }
      // Chevron toggle shared by the foldable sections (languages, presets, editors).
      foldButton(setting, open, onToggle) {
        setting.addExtraButton((b) => b.setIcon(open ? "chevron-up" : "chevron-down").setTooltip(open ? t2("set.editors.collapse") : t2("set.editors.expand")).onClick(onToggle));
      }
      // Update one editor's dropdown label as its name is typed, sparing a full re-render.
      refreshPresetOption(dropdown, i, name) {
        if (!dropdown)
          return;
        const opt = Array.from(dropdown.selectEl.options).find((o) => o.value === "u:" + i);
        if (opt)
          opt.text = name || `Editor ${i + 1}`;
      }
      // The kinds a language contributes to the index, each with a searchable toggle.
      renderSearchableKinds(lang) {
        const { containerEl } = this;
        const s = this.plugin.settings;
        const counts = /* @__PURE__ */ new Map();
        for (const e of this.plugin.index) {
          if (e.lang === lang.id)
            counts.set(e.kind, (counts.get(e.kind) || 0) + 1);
        }
        if (!counts.size) {
          containerEl.createEl("div", { cls: "setting-item-description code-linker-kind-row", text: t2("set.kind.rebuildHint") });
          return;
        }
        const hidden = new Set(s.disabledKinds || []);
        for (const kind of [...counts.keys()].sort()) {
          const key = lang.id + ":" + kind;
          const row = new Setting(containerEl).setName(kind).setDesc(t2("set.kind.count", { n: counts.get(kind) })).addToggle((c) => c.setValue(!hidden.has(key)).onChange(async (v) => {
            const set = new Set(s.disabledKinds || []);
            if (v)
              set.delete(key);
            else
              set.add(key);
            s.disabledKinds = [...set];
            await this.plugin.saveSettings();
          }));
          row.settingEl.addClass("code-linker-kind-row");
        }
      }
      // Every fold and toggle redraws the whole pane; the reader keeps their place (shared/settings-redraw).
      display() {
        redraw(this, () => this.draw());
      }
      draw() {
        const { containerEl } = this;
        containerEl.empty();
        const s = this.plugin.settings;
        const save = async (rebuild) => {
          await this.plugin.saveSettings();
          if (rebuild)
            await this.plugin.rebuildIndex(false);
        };
        const wide = (c) => {
          c.inputEl.addClass("code-linker-input");
          return c;
        };
        new Setting(containerEl).setName(t2("set.heading.index")).setHeading();
        new Setting(containerEl).setName(t2("set.codeRoot.name")).setDesc(t2("set.codeRoot.desc")).addText((c) => {
          wide(c).setPlaceholder(this.plugin.codeRoot()).setValue(s.codeRoot).onChange(async (v) => {
            s.codeRoot = v.trim();
            await save(false);
          });
          if (suggestAvailable())
            new DiskPathSuggest(this.app, c.inputEl, { getSeed: () => this.plugin.codeRoot() });
        });
        const folderList = (name, desc, key) => renderFolderList(containerEl, {
          cls: "code-linker",
          name,
          desc,
          get: () => s[key],
          set: async (v) => {
            s[key] = v;
            await save(false);
          },
          normalize: normFolder,
          attachSuggest: suggestAvailable() ? (inputEl, onPick) => new DiskPathSuggest(this.app, inputEl, { getRoot: () => this.plugin.codeRoot(), onSelect: onPick }) : null,
          placeholder: t2("set.folderList.add"),
          removeLabel: t2("set.folderList.remove"),
          addLabel: t2("set.folderList.addAria")
        });
        folderList(t2("set.scanFolders.name"), t2("set.scanFolders.desc"), "scanRoots");
        const missing = this.plugin.scanRootStatus().filter((x) => !x.exists).map((x) => x.rel);
        if (missing.length) {
          containerEl.createEl("div", { cls: "code-linker-note is-error", text: t2("set.scanFolders.notFound", { folders: missing.join(", ") }) });
        }
        folderList(t2("set.skipFolders.name"), t2("set.skipFolders.desc"), "skipDirs");
        if (this.plugin.hasGitignore) {
          new Setting(containerEl).setName(t2("set.gitignore.name")).setDesc(t2("set.gitignore.desc")).addToggle((c) => c.setValue(s.useGitignore).onChange(async (v) => {
            s.useGitignore = v;
            await save(false);
            this.plugin.rebuildIndex(false);
          }));
        }
        new Setting(containerEl).setName(t2("set.maxFileSize.name")).setDesc(t2("set.maxFileSize.desc")).addText((c) => {
          c.inputEl.type = "number";
          c.setValue(String(s.maxFileSizeKb)).onChange(async (v) => {
            const n = parseInt(v, 10);
            s.maxFileSizeKb = Number.isFinite(n) && n >= 0 ? n : 2048;
            await save(false);
          });
          c.inputEl.addEventListener("blur", () => this.plugin.rebuildIndex(false));
        });
        new Setting(containerEl).setName(t2("set.autoRefresh.name")).setDesc(t2("set.autoRefresh.desc")).addToggle((c) => c.setValue(s.autoRefresh).onChange(async (v) => {
          s.autoRefresh = v;
          await save(false);
          if (v)
            this.plugin.startWatchers();
          else
            this.plugin.stopWatchers();
        }));
        if (s.autoRefresh && this.plugin.watchUnsupported) {
          const warn = new Setting(containerEl).setDesc(t2("set.autoRefresh.unsupported"));
          warn.settingEl.addClass("mod-warning");
        }
        const root = this.plugin.codeRoot() || t2("set.info.unknownRoot");
        containerEl.createEl("div", { cls: "code-linker-note", text: t2("set.info", { root, entries: plural2("entry", this.plugin.index.length) }) });
        if (this.showLanguages === void 0)
          this.showLanguages = false;
        const enabled = new Set(s.enabledLanguages || []);
        const enabledCount = this.plugin.languages.filter((l) => enabled.has(l.id)).length;
        const langHeading = new Setting(containerEl).setName(t2("set.heading.languages")).setDesc(t2("set.languages.desc", { enabled: enabledCount, total: this.plugin.languages.length })).setHeading();
        this.foldButton(langHeading, this.showLanguages, () => {
          this.showLanguages = !this.showLanguages;
          this.display();
        });
        if (this.showLanguages) {
          for (const lang of this.plugin.languages) {
            const on = enabled.has(lang.id);
            const open = this.expanded.has(lang.id);
            const ext = lang.extensions.join(" ") || t2("set.lang.noExtensions");
            const setting = new Setting(containerEl).setName(lang.name).setDesc(t2("set.lang.meta", { id: lang.id, ext }));
            if (on) {
              setting.addExtraButton((b) => b.setIcon(open ? "chevron-up" : "chevron-down").setTooltip(open ? t2("set.lang.hideEntities") : t2("set.lang.showEntities")).onClick(() => {
                if (open)
                  this.expanded.delete(lang.id);
                else
                  this.expanded.add(lang.id);
                this.display();
              }));
            } else {
              this.expanded.delete(lang.id);
            }
            setting.addToggle((c) => c.setValue(on).onChange(async (v) => {
              const set = new Set(s.enabledLanguages || []);
              if (v)
                set.add(lang.id);
              else
                set.delete(lang.id);
              s.enabledLanguages = [...set];
              await save(true);
              this.display();
            }));
            if (on && open)
              this.renderSearchableKinds(lang);
          }
        }
        for (const bad of this.plugin.languageErrors || []) {
          const row = new Setting(containerEl).setName(bad.id).setDesc(t2("set.lang.invalid", { error: bad.error }));
          row.settingEl.addClass("mod-warning");
        }
        new Setting(containerEl).setName(t2("set.heading.customLanguages")).setDesc(t2("set.customLanguages.desc")).setHeading();
        const langPath = this.plugin.languagesFilePath();
        const langFile = langPath ? this.app.vault.getAbstractFileByPath(langPath) : null;
        const langSetting = new Setting(containerEl).setName(t2("set.languagesFile.name")).setDesc(t2("set.languagesFile.desc")).addText((c) => {
          c.setValue(s.languagesFile).onChange(async (v) => {
            s.languagesFile = v.trim();
            await save(false);
          });
          c.inputEl.addEventListener("blur", () => this.display());
        });
        if (langFile) {
          langSetting.addExtraButton((b) => b.setIcon("pencil").setTooltip(t2("set.languagesFile.open")).onClick(() => this.plugin.openLanguagesFile()));
        } else {
          langSetting.addButton((b) => b.setButtonText(t2("set.languagesFile.create")).setCta().onClick(async () => {
            await this.plugin.createLanguagesFile();
            this.display();
          }));
        }
        new Setting(containerEl).setName(t2("set.reloadLanguages.name")).setDesc(t2("set.reloadLanguages.desc")).addButton((b) => b.setButtonText(t2("set.reloadLanguages.button")).setCta().onClick(async () => {
          await this.plugin.loadLanguagesFile();
          await this.plugin.rebuildIndex(true);
          this.display();
        }));
        new Setting(containerEl).setName(t2("set.heading.suggestions")).setHeading();
        new Setting(containerEl).setName(t2("set.trigger.name")).setDesc(t2("set.trigger.desc")).addText((c) => c.setValue(s.trigger).onChange(async (v) => {
          s.trigger = v || "@@";
          await save(false);
        }));
        new Setting(containerEl).setName(t2("set.minChars.name")).setDesc(t2("set.minChars.desc")).addText((c) => {
          c.inputEl.type = "number";
          c.inputEl.min = "0";
          c.setValue(String(s.minChars)).onChange(async (v) => {
            const n = parseInt(v, 10);
            s.minChars = Number.isFinite(n) && n >= 0 ? n : 1;
            await save(false);
          });
        });
        new Setting(containerEl).setName(t2("set.maxResults.name")).setDesc(t2("set.maxResults.desc")).addText((c) => {
          c.inputEl.type = "number";
          c.inputEl.min = "1";
          c.setValue(String(s.maxResults)).onChange(async (v) => {
            const n = parseInt(v, 10);
            s.maxResults = Number.isFinite(n) && n > 0 ? n : 12;
            await save(false);
          });
        });
        let presetDropdown;
        new Setting(containerEl).setName(t2("set.editorPreset.name")).setDesc(t2("set.editorPreset.desc")).addDropdown((d) => {
          presetDropdown = d;
          for (const p of this.plugin.editorPresets())
            d.addOption(p.key, p.label);
          d.addOption("ask", t2("set.preset.ask"));
          d.setValue(this.selectedEditor()).onChange(async (v) => {
            const hadProduct = this.selectedUsesProduct();
            s.askOnInsert = v === "ask";
            if (!s.askOnInsert) {
              const p = this.plugin.editorPresets().find((x) => x.key === v);
              if (p)
                s.uriTemplate = p.template;
            }
            await save(false);
            if (hadProduct !== this.selectedUsesProduct())
              this.display();
          });
        });
        if (this.selectedUsesProduct()) {
          new Setting(containerEl).setName(t2("set.jetbrainsProduct.name")).setDesc(t2("set.jetbrainsProduct.desc")).addDropdown((d) => {
            for (const [code, label] of JETBRAINS_PRODUCTS2)
              d.addOption(code, label);
            d.addOption("ask", t2("set.preset.ask"));
            d.setValue(s.jetbrainsProduct).onChange(async (v) => {
              s.jetbrainsProduct = v;
              await save(false);
            });
          });
        }
        if (this.showPresets === void 0)
          this.showPresets = false;
        const builtins = this.plugin.editorPresets().filter((p) => p.builtin);
        const hiddenPresets = new Set(s.hiddenPresets || []);
        const presetHeading = new Setting(containerEl).setName(t2("set.shownPresets.name")).setDesc(t2("set.shownPresets.count", { shown: builtins.length - hiddenPresets.size, total: builtins.length }));
        this.foldButton(presetHeading, this.showPresets, () => {
          this.showPresets = !this.showPresets;
          this.display();
        });
        if (this.showPresets) {
          containerEl.createEl("div", { cls: "code-linker-note", text: t2("set.shownPresets.desc") });
          for (const p of builtins) {
            const row = new Setting(containerEl).setName(p.label).addToggle((c) => c.setValue(!hiddenPresets.has(p.key)).onChange(async (v) => {
              const set = new Set(s.hiddenPresets || []);
              if (v)
                set.delete(p.key);
              else
                set.add(p.key);
              s.hiddenPresets = [...set];
              await save(false);
            }));
            row.settingEl.addClass("code-linker-kind-row");
          }
        }
        if (this.showEditors === void 0)
          this.showEditors = false;
        const editors = s.editors || [];
        const editorsHeading = new Setting(containerEl).setName(t2("set.editors.name")).setDesc(t2("set.editors.count", { n: editors.length }));
        this.foldButton(editorsHeading, this.showEditors, () => {
          this.showEditors = !this.showEditors;
          this.display();
        });
        if (this.showEditors) {
          editors.forEach((ed, i) => {
            const row = new Setting(containerEl).addText((c) => {
              c.inputEl.addClass("code-linker-editor-name");
              c.setPlaceholder(t2("set.editors.namePlaceholder")).setValue(ed.name).onChange(async (v) => {
                ed.name = v;
                this.refreshPresetOption(presetDropdown, i, v);
                await save(false);
              });
            }).addText((c) => {
              c.inputEl.addClass("code-linker-editor-tpl");
              c.setPlaceholder("cursor://file/{abs}:{line}").setValue(ed.template).onChange(async (v) => {
                if (s.uriTemplate === ed.template)
                  s.uriTemplate = v;
                ed.template = v;
                await save(false);
              });
            }).addExtraButton((b) => b.setIcon("trash").setTooltip(t2("set.editors.remove")).onClick(async () => {
              if (s.uriTemplate === ed.template)
                s.uriTemplate = PRESETS2.file;
              editors.splice(i, 1);
              await save(false);
              this.display();
            }));
            row.settingEl.addClass("code-linker-editor-row");
          });
          new Setting(containerEl).setDesc(t2("set.editors.desc")).addButton((b) => b.setButtonText(t2("set.editors.add")).setCta().onClick(async () => {
            editors.push({ name: "", template: "" });
            s.editors = editors;
            await save(false);
            this.display();
          }));
        }
        new Setting(containerEl).setName(t2("set.statusBar.name")).setDesc(t2("set.statusBar.desc")).addToggle((c) => c.setValue(s.showStatusBar).onChange(async (v) => {
          s.showStatusBar = v;
          await save(false);
        }));
        new Setting(containerEl).setName(t2("set.ribbon.name")).setDesc(t2("set.ribbon.desc")).addToggle((c) => c.setValue(s.showRibbonIcon).onChange(async (v) => {
          s.showRibbonIcon = v;
          await save(false);
          this.plugin.applyRibbonIcon();
        }));
        new Setting(containerEl).setName(t2("set.contextMenu.name")).setDesc(t2("set.contextMenu.desc")).addToggle((c) => c.setValue(s.contextMenu).onChange(async (v) => {
          s.contextMenu = v;
          await save(false);
        }));
        new Setting(containerEl).setName(t2("set.heading.hover")).setHeading();
        new Setting(containerEl).setName(t2("set.hoverPreview.name")).setDesc(t2("set.hoverPreview.desc")).addToggle((c) => c.setValue(s.hoverPreview).onChange(async (v) => {
          s.hoverPreview = v;
          await save(false);
        }));
        new Setting(containerEl).setName(t2("set.hoverBefore.name")).setDesc(t2("set.hoverBefore.desc")).addText((c) => {
          c.inputEl.type = "number";
          c.inputEl.min = "-1";
          c.setValue(String(s.hoverBefore)).onChange(async (v) => {
            const n = parseInt(v, 10);
            s.hoverBefore = Number.isFinite(n) ? Math.max(-1, n) : 3;
            await save(false);
          });
        });
        new Setting(containerEl).setName(t2("set.hoverAfter.name")).setDesc(t2("set.hoverAfter.desc")).addText((c) => {
          c.inputEl.type = "number";
          c.inputEl.min = "-1";
          c.setValue(String(s.hoverAfter)).onChange(async (v) => {
            const n = parseInt(v, 10);
            s.hoverAfter = Number.isFinite(n) ? Math.max(-1, n) : 20;
            await save(false);
          });
        });
        new Setting(containerEl).setName(t2("set.heading.links")).setHeading();
        new Setting(containerEl).setName(t2("set.markStaleLinks.name")).setDesc(t2("set.markStaleLinks.desc")).addToggle((c) => c.setValue(s.markStaleLinks).onChange(async (v) => {
          s.markStaleLinks = v;
          await save(false);
        }));
        new Setting(containerEl).setName(t2("set.heading.maintenance")).setHeading();
        precedenceSetting(containerEl, {
          app: this.app,
          provider: this.plugin.api && this.plugin.api.linker,
          Setting,
          cls: "code-linker",
          save: async (value) => {
            s.linkPrecedence = value;
            await save(false);
          }
        });
        new Setting(containerEl).setName(t2("set.rebuild.name")).setDesc(t2("set.rebuild.desc")).addButton((b) => b.setButtonText(t2("set.rebuild.button")).onClick(() => this.plugin.rebuildIndex(true).then(() => this.display())));
      }
    };
    module2.exports = { CodeLinkerSettingTab: CodeLinkerSettingTab2 };
  }
});

// src/api.js
var require_api = __commonJS({
  "src/api.js"(exports2, module2) {
    "use strict";
    var { LINKER_API } = require_discover();
    var { splitTarget: splitTarget2 } = require_markdown();
    var { bindingOwner: bindingOwner2, ownsBinding } = require_binding();
    var OWNER2 = "code";
    var pick = (e) => ({ name: e.name, kind: e.kind, lang: e.lang, path: e.path, line: e.line });
    module2.exports = {
      buildApi() {
        const plugin = this;
        return {
          version: this.manifest.version,
          codeRoot: () => this.codeRoot(),
          // Every indexed entry: { name, kind, lang, path, line }.
          getEntries: () => this.index.map(pick),
          // One row per indexed file: { name, path, lang, entries }.
          getFiles: () => this.apiFiles(),
          // Totals: { files, entries, byLang, byKind }.
          getStats: () => this.apiStats(),
          // Enabled languages: { id, name, extensions }.
          getLanguages: () => this.apiLanguages(),
          // Entries matching a name or path tail (the same lookup the commands use).
          find: (text) => this.lookup(String(text || "")).map(pick),
          // Render helpers: a portable markdown link, or a ready-to-open absolute URI.
          linkFor: (entry) => this.buildLink(entry),
          uriFor: (entry) => this.fillRoot(this.buildUri(entry)),
          // Subscribe to index rebuilds; returns an unsubscribe function.
          onChange: (cb) => this.onIndexChange(cb),
          // The provider contract the sibling linkers read (consumed in shared/discover.js and
          // shared/link-owner.js).
          linker: {
            apiVersion: LINKER_API,
            id: "code-linker",
            displayName: "Code Linker",
            kind: "sigil",
            get precedence() {
              return plugin.settings.linkPrecedence;
            },
            claim: (target, title) => {
              const split = splitTarget2(String(target || ""));
              const ttl = title ? String(title) : split.title;
              if (ownsBinding(ttl, OWNER2))
                return "binding";
              if (bindingOwner2(ttl))
                return null;
              return split.url && plugin.targetIndexedFile(plugin.decodeTarget(split.url)) ? "index" : null;
            },
            // Both selection actions search on click, so the answer doesn't depend on the text —
            // only on whether our context menu is switched on at all.
            offers: (kind) => (kind === "convert" || kind === "open") && !!plugin.settings.contextMenu
          }
        };
      },
      apiFiles() {
        const out = [];
        for (const v of this.fileCache.values()) {
          const f = v.entries[0];
          if (f)
            out.push({ name: f.name, path: f.path, lang: f.lang, entries: v.entries.length });
        }
        out.sort((a, b) => a.path.localeCompare(b.path));
        return out;
      },
      apiStats() {
        const byLang = {}, byKind = {};
        for (const e of this.index) {
          byLang[e.lang] = (byLang[e.lang] || 0) + 1;
          byKind[e.kind] = (byKind[e.kind] || 0) + 1;
        }
        return { files: this.fileCache.size, entries: this.index.length, byLang, byKind };
      },
      apiLanguages() {
        const enabled = new Set(this.settings.enabledLanguages || []);
        return this.languages.filter((l) => enabled.has(l.id)).map((l) => ({ id: l.id, name: l.name, extensions: l.extensions.slice() }));
      }
    };
  }
});

// src/shared/index-events.js
var require_index_events = __commonJS({
  "src/shared/index-events.js"(exports2, module2) {
    "use strict";
    module2.exports = {
      // Returns an unsubscribe function.
      onIndexChange(cb) {
        if (typeof cb !== "function")
          return () => {
          };
        if (!this._indexListeners)
          this._indexListeners = /* @__PURE__ */ new Set();
        this._indexListeners.add(cb);
        return () => this._indexListeners.delete(cb);
      },
      notifyIndexChange() {
        for (const cb of this._indexListeners || []) {
          try {
            cb();
          } catch (e) {
            console.error(`${this.manifest.id}: index listener failed`, e);
          }
        }
      }
    };
  }
});

// src/locales/en.js
var require_en = __commonJS({
  "src/locales/en.js"(exports2, module2) {
    "use strict";
    module2.exports = {
      // Commands
      "cmd.rebuildIndex": "Rebuild code index",
      "cmd.openIndex": "Open the code index panel",
      "ribbon.tooltip": "Code index",
      "view.index.title": "Code index",
      "view.index.search": "Find a symbol\u2026",
      "view.index.rebuild": "Rebuild",
      "view.index.matches": "Matches",
      "view.index.noMatches": "Nothing in the index answers to that.",
      "view.index.copy": "copy",
      "view.index.index": "Indexed",
      "view.index.empty": "The index is empty \u2014 check the code root and the scan folders.",
      "view.index.links": "Links in the vault",
      "view.index.scan": "Scan",
      "view.index.notScanned": "Scanning reads every note, so it runs when you ask.",
      "view.index.allWell": "Every code link still lands where it points.",
      "view.index.found": "{stale}, {broken}",
      "view.index.fixAll": "Fix all\u2026",
      "view.index.failed": "The panel could not draw itself: {error}",
      "view.index.scanFailed": "Could not read every note \u2014 the scan stopped.",
      "set.ribbon.name": "Ribbon icon",
      "set.ribbon.desc": "Show a ribbon button that opens the code index panel.",
      "cmd.insertLink": "Insert code link",
      "cmd.insertLinkAs": "Insert code link as\u2026",
      "cmd.switchPreset": "Switch editor preset",
      "cmd.openFile": "Open code file",
      "cmd.copyLink": "Copy code link",
      "cmd.convertSelection": "Convert selection to code link",
      "cmd.openSelection": "Find and open code",
      "cmd.insertLineLink": "Insert code link to a line",
      "cmd.insertEmbed": "Insert code embed",
      "cmd.pin.sym": "Pin code link to its symbol",
      "cmd.pin.kind": "Pin code link to its kind",
      "cmd.pin.line": "Pin code link to its exact line",
      "cmd.pinLinksNote": "Pin unpinned code links and embeds in this note",
      "cmd.pinLinksVault": "Pin unpinned code links and embeds in the whole vault",
      "cmd.updateLinksNote": "Update code links in this note",
      "cmd.updateLinksVault": "Update code links in the whole vault",
      // Editor context menu
      // Selection actions. `.solo` is the flat wording used when no sibling linker offers the
      // same verb; `.group` labels the shared submenu when one does, and `.item` names our
      // destination inside it. The `.group` wording must match the sibling's word for word —
      // whichever plugin is called first creates the group and its label is the one shown.
      "menu.convert.solo": "Find and convert to code link",
      "menu.convert.item": "Code",
      "menu.open.solo": "Find and open code",
      "menu.open.item": "Code",
      "menu.copyLink": "Copy code link",
      "menu.fixLink": "Update this code link",
      "menu.pin": "Pin this code link",
      "menu.pin.sym": "Pin to symbol \u201C{value}\u201D",
      "menu.pin.kind": "Pin to kind \u201C{value}\u201D",
      "menu.pin.line": "Pin to this exact line ({value})",
      "menu.unpin": "Unpin this code link",
      // Notices
      "notice.noCodeRoot": "Code Linker: could not determine code root",
      "notice.noLanguages": "Code Linker: no languages enabled",
      "notice.scanFailed": "Code Linker: scan failed \u2014 {error}",
      "notice.indexed": "Code Linker: {entries} indexed",
      "notice.missingFolders": "Code Linker: scan folder not found \u2014 {folders}",
      "notice.copied": "Code Linker: link copied",
      "notice.bound": "Code Linker: link pinned to line {line}",
      "notice.unbound": "Code Linker: link unpinned \u2014 it is no longer tracked",
      "notice.cantBind": "Code Linker: can't pin \u2014 the link doesn't point at a line of an indexed file",
      "notice.embedMoved": "Code Linker: the note changed since this embed was drawn \u2014 nothing was written; refresh it and try again",
      "notice.noGit": "Code Linker: no git repository (with a remote) found for this file",
      "notice.editorSet": "Code Linker: links now open in {name}",
      "notice.noSelection": "Code Linker: select a name or path first",
      "notice.noMatch": "Code Linker: no code entry matches \u201C{query}\u201D",
      "notice.watchUnsupported": "Code Linker: auto-refresh is unavailable on this platform \u2014 rebuild manually",
      "notice.linksPinned": "Code Linker: {n} link(s) and embed(s) pinned",
      "notice.linksPinnedVault": "Code Linker: {n} link(s) and embed(s) pinned across {files} note(s)",
      "notice.noDeclHere": "Code Linker: nothing is declared on that line \u2014 pin it to the line instead",
      "notice.linksUpdated": "Code Linker: {n} link(s) updated",
      "notice.linksUpdatedVault": "Code Linker: {n} link(s) updated across {files} note(s)",
      "notice.langFileNoPath": "Code Linker: set a languages file path first",
      "notice.langFileExists": "Code Linker: the languages file already exists",
      "notice.langFileCreated": "Code Linker: created {path}",
      "notice.langFileError": "Code Linker: could not create the file \u2014 {error}",
      // Inline embeds
      "embed.empty": "Code Linker: empty embed \u2014 give a symbol name or a path:line",
      "embed.fmt.file": "Whole file",
      "embed.fmt.symbol": "Symbol \u2014 tracks the declaration as code moves",
      "embed.fmt.line": "Declaration line ({line})",
      "embed.fmt.range": "Line range ({from}-{to}, edit to taste)",
      "embed.stale": "Code Linker: the pinned code moved to line {line} \u2014 run \u201CUpdate code links in this note\u201D",
      "embed.broken": "Code Linker: the pinned code is gone \u2014 renamed, removed, or the line was rewritten",
      "embed.menu.open": "Open code file",
      "embed.notFound": "Code Linker: no code entry matches \u201C{query}\u201D",
      "embed.ambiguous": "Code Linker: {n} entries match \u201C{query}\u201D \u2014 add a language/kind filter (e.g. py:) or a path to pick one",
      "embed.unreadable": "Code Linker: can\u2019t read {path}",
      "plural.embedMore": { one: "Show 1 more line", other: "Show {n} more lines" },
      "embed.tool.wrap": "Wrap long lines",
      "embed.tool.copy": "Copy snippet",
      "notice.snippetCopied": "Code Linker: snippet copied",
      "embed.truncated": "Code Linker: showing the first {max} lines",
      // Status bar
      "status.indexing": "Code Linker: indexing\u2026 {n}",
      "status.editor": "Code link: {name}",
      "status.editorTooltip": "Code Linker: click to switch the editor links open in",
      // Command-palette modal
      "modal.searchPlaceholder": "Search code files and types\u2026",
      "modal.linePrompt": "Which line?",
      "modal.lineSubmit": "Insert link",
      "modal.switchPlaceholder": "Choose the editor links open in\u2026",
      "modal.formatPlaceholder": "Choose an editor format for this link\u2026",
      "modal.productPlaceholder": "Choose a JetBrains IDE\u2026",
      "modal.pinAnchors": "Pin to\u2026",
      "modal.pinAnchorsDesc": "What each link and embed is pinned to. Anchors combine: symbol + line tracks the exact declaration and won\u2019t silently repin to a same-named one.",
      "modal.pinAnchor.sym": "Symbol name",
      "modal.pinAnchor.kind": "Kind (class, method\u2026)",
      "modal.pinAnchor.line": "Exact line text",
      "modal.pinAnchorsSubmit": "Pin",
      "modal.update.title": "Update code links",
      "modal.update.attention": "{n} link(s) need attention: their code is gone (renamed or removed), so there\u2019s no line to fix.",
      "modal.update.brokenRow": "{label} \u2014 no fix (renamed or removed)",
      // Settings — headings
      "set.heading.index": "Code index",
      "set.heading.languages": "Languages",
      "set.heading.customLanguages": "Custom languages",
      // Settings — code index
      "set.codeRoot.name": "Code root",
      "set.scanFolders.desc": "Folders scanned for source files, relative to the code root. Leave empty to scan the whole code root.",
      "set.scanFolders.notFound": "\u26A0 Not found under the code root \u2014 {folders}",
      "set.maxFileSize.name": "Max file size (KB)",
      "set.maxFileSize.desc": "Files larger than this are indexed by name only, not parsed for declarations. 0 = no limit.",
      "set.skipFolders.desc": "A bare name (node_modules) is skipped at any depth; a path with a slash (src/generated) skips only that folder, relative to the code root.",
      "set.gitignore.name": "Respect .gitignore",
      "set.gitignore.desc": "Also skip paths a .gitignore excludes. Files are read from the scan root down (a .gitignore above it is not consulted); negation (!), directory-only (build/) and the *, ?, ** wildcards are honoured.",
      "set.rebuild.name": "Rebuild code index",
      "set.rebuild.desc": "Re-scan the source folders now.",
      // Settings — languages
      "set.languages.desc": "Which languages are scanned \u2014 {enabled} of {total} enabled. Expand an enabled language to pick which of its entity kinds are searchable.",
      "set.lang.meta": "id: {id} \xB7 {ext}",
      "set.lang.noExtensions": "(no extensions)",
      "set.lang.showEntities": "Show entities",
      "set.lang.hideEntities": "Hide entities",
      "set.lang.invalid": "Invalid: {error}",
      "set.kind.count": "{n} in index",
      "set.kind.rebuildHint": "Rebuild the index to choose which of its entities are searchable.",
      // Settings — custom languages
      "set.customLanguages.desc": "Add your own languages, or override a built-in, from a JSON file in your vault. Set a path below and press Create to write a starter template, edit it, then save \u2014 it reloads on save. An entry whose id matches a built-in replaces it; a new id appears as a new language above.",
      "set.languagesFile.name": "Languages file",
      "set.languagesFile.desc": "Path to the JSON file, relative to your vault root.",
      "set.languagesFile.create": "Create file",
      "set.languagesFile.open": "Open the languages file",
      "set.reloadLanguages.name": "Reload languages file",
      "set.reloadLanguages.desc": "Re-reads the file and rebuilds. Also happens automatically when you save the file.",
      "set.reloadLanguages.button": "Reload & rebuild",
      // Settings — suggestions & links
      "set.trigger.desc": "Type this to start a code suggestion.",
      "set.editorPreset.name": "Editor link preset",
      "set.editorPreset.desc": "Which editor the inserted links open in. Add your own under \u201CYour editors\u201D below.",
      "set.preset.vscode": "VS Code",
      "set.preset.jetbrains": "JetBrains",
      "set.preset.github": "GitHub permalink",
      "set.preset.gitlab": "GitLab permalink",
      "set.jetbrainsProduct.name": "JetBrains IDE",
      "set.jetbrainsProduct.desc": "Which JetBrains IDE the links open in.",
      "set.shownPresets.name": "Shown in the picker",
      "set.shownPresets.count": "{shown} of {total} shown",
      "set.shownPresets.desc": "Which built-in presets appear in the pickers. Your own editors always appear.",
      "set.editors.name": "Your editors",
      "set.editors.desc": "Named presets for the dropdown above. Placeholders: {abs} {path} {line} {name} {project} {jetbrainsProduct} {root} {gitRemote} {gitSha} {gitBranch}.",
      "set.editors.add": "+ Add editor",
      "set.statusBar.name": "Show editor in status bar",
      "set.statusBar.desc": "Show the active editor preset in the status bar; click it to switch without opening settings.",
      "set.autoRefresh.desc": "Watch the scan folders and rebuild the index when source files change.",
      "set.contextMenu.desc": "Add \u201CFind and convert to link\u201D and \u201CFind and open code\u201D to the editor right-click menu \u2014 plus \u201CCopy code link\u201D when you right-click a code link.",
      "set.hoverPreview.name": "Code preview on hover",
      "set.hoverPreview.desc": "Preview the file around a code link\u2019s line when you hover it. In live preview, hold Ctrl/Cmd; in reading view a plain hover is enough.",
      "set.hoverBefore.name": "Preview lines before",
      "set.hoverBefore.desc": "How many lines to show above the target line. -1 = no limit (to the start of the file).",
      "set.hoverAfter.name": "Preview lines after",
      "set.hoverAfter.desc": "How many lines to show below the target line. -1 = no limit (to the end of the file).",
      "set.markStaleLinks.desc": "Underline code links whose stored line has drifted from the declaration (warning colour) or whose symbol is gone \u2014 renamed or removed (error colour). Run \u201CUpdate code links\u2026\u201D to fix drifted ones.",
      "set.info": "Code root: {root} \xB7 {entries} indexed"
    };
  }
});

// src/locales/ru.js
var require_ru = __commonJS({
  "src/locales/ru.js"(exports2, module2) {
    "use strict";
    module2.exports = {
      // Commands
      "cmd.rebuildIndex": "\u041F\u0435\u0440\u0435\u0441\u0442\u0440\u043E\u0438\u0442\u044C \u0438\u043D\u0434\u0435\u043A\u0441 \u043A\u043E\u0434\u0430",
      "cmd.openIndex": "\u041E\u0442\u043A\u0440\u044B\u0442\u044C \u043F\u0430\u043D\u0435\u043B\u044C \u0438\u043D\u0434\u0435\u043A\u0441\u0430 \u043A\u043E\u0434\u0430",
      "ribbon.tooltip": "\u0418\u043D\u0434\u0435\u043A\u0441 \u043A\u043E\u0434\u0430",
      "view.index.title": "\u0418\u043D\u0434\u0435\u043A\u0441 \u043A\u043E\u0434\u0430",
      "view.index.search": "\u041D\u0430\u0439\u0442\u0438 \u0441\u0438\u043C\u0432\u043E\u043B\u2026",
      "view.index.rebuild": "\u041F\u0435\u0440\u0435\u0441\u0442\u0440\u043E\u0438\u0442\u044C",
      "view.index.matches": "\u041D\u0430\u0439\u0434\u0435\u043D\u043E",
      "view.index.noMatches": "\u0412 \u0438\u043D\u0434\u0435\u043A\u0441\u0435 \u043D\u0438\u0447\u0435\u0433\u043E \u0442\u0430\u043A\u043E\u0433\u043E \u043D\u0435\u0442.",
      "view.index.copy": "\u0441\u043A\u043E\u043F\u0438\u0440\u043E\u0432\u0430\u0442\u044C",
      "view.index.index": "\u0412 \u0438\u043D\u0434\u0435\u043A\u0441\u0435",
      "view.index.empty": "\u0418\u043D\u0434\u0435\u043A\u0441 \u043F\u0443\u0441\u0442 \u2014 \u043F\u0440\u043E\u0432\u0435\u0440\u044C\u0442\u0435 \u043A\u043E\u0440\u0435\u043D\u044C \u043A\u043E\u0434\u0430 \u0438 \u043F\u0430\u043F\u043A\u0438 \u0441\u043A\u0430\u043D\u0438\u0440\u043E\u0432\u0430\u043D\u0438\u044F.",
      "view.index.links": "\u0421\u0441\u044B\u043B\u043A\u0438 \u0432 \u0445\u0440\u0430\u043D\u0438\u043B\u0438\u0449\u0435",
      "view.index.scan": "\u041F\u0440\u043E\u0432\u0435\u0440\u0438\u0442\u044C",
      "view.index.notScanned": "\u041F\u0440\u043E\u0432\u0435\u0440\u043A\u0430 \u0447\u0438\u0442\u0430\u0435\u0442 \u0432\u0441\u0435 \u0437\u0430\u043C\u0435\u0442\u043A\u0438, \u043F\u043E\u044D\u0442\u043E\u043C\u0443 \u0437\u0430\u043F\u0443\u0441\u043A\u0430\u0435\u0442\u0441\u044F \u043F\u043E \u0442\u0440\u0435\u0431\u043E\u0432\u0430\u043D\u0438\u044E.",
      "view.index.allWell": "\u0412\u0441\u0435 \u0441\u0441\u044B\u043B\u043A\u0438 \u043D\u0430 \u043A\u043E\u0434 \u0432\u0435\u0434\u0443\u0442 \u0442\u0443\u0434\u0430, \u043A\u0443\u0434\u0430 \u0443\u043A\u0430\u0437\u044B\u0432\u0430\u044E\u0442.",
      "view.index.found": "{stale}, {broken}",
      "view.index.fixAll": "\u0418\u0441\u043F\u0440\u0430\u0432\u0438\u0442\u044C \u0432\u0441\u0451\u2026",
      "view.index.failed": "\u041F\u0430\u043D\u0435\u043B\u044C \u043D\u0435 \u0441\u043C\u043E\u0433\u043B\u0430 \u043E\u0442\u0440\u0438\u0441\u043E\u0432\u0430\u0442\u044C\u0441\u044F: {error}",
      "view.index.scanFailed": "\u041D\u0435 \u0443\u0434\u0430\u043B\u043E\u0441\u044C \u043F\u0440\u043E\u0447\u0438\u0442\u0430\u0442\u044C \u0432\u0441\u0435 \u0437\u0430\u043C\u0435\u0442\u043A\u0438 \u2014 \u043F\u0440\u043E\u0432\u0435\u0440\u043A\u0430 \u043F\u0440\u0435\u0440\u0432\u0430\u043D\u0430.",
      "set.ribbon.name": "\u0418\u043A\u043E\u043D\u043A\u0430 \u043D\u0430 \u043F\u0430\u043D\u0435\u043B\u0438",
      "set.ribbon.desc": "\u041F\u043E\u043A\u0430\u0437\u044B\u0432\u0430\u0442\u044C \u043A\u043D\u043E\u043F\u043A\u0443 \u0441\u043B\u0435\u0432\u0430, \u043E\u0442\u043A\u0440\u044B\u0432\u0430\u044E\u0449\u0443\u044E \u043F\u0430\u043D\u0435\u043B\u044C \u0438\u043D\u0434\u0435\u043A\u0441\u0430 \u043A\u043E\u0434\u0430.",
      "cmd.insertLink": "\u0412\u0441\u0442\u0430\u0432\u0438\u0442\u044C \u0441\u0441\u044B\u043B\u043A\u0443 \u043D\u0430 \u043A\u043E\u0434",
      "cmd.insertLinkAs": "\u0412\u0441\u0442\u0430\u0432\u0438\u0442\u044C \u0441\u0441\u044B\u043B\u043A\u0443 \u043D\u0430 \u043A\u043E\u0434 \u043A\u0430\u043A\u2026",
      "cmd.switchPreset": "\u0421\u043C\u0435\u043D\u0438\u0442\u044C \u043F\u0440\u0435\u0441\u0435\u0442 \u0440\u0435\u0434\u0430\u043A\u0442\u043E\u0440\u0430",
      "cmd.openFile": "\u041E\u0442\u043A\u0440\u044B\u0442\u044C \u0444\u0430\u0439\u043B \u043A\u043E\u0434\u0430",
      "cmd.copyLink": "\u0421\u043A\u043E\u043F\u0438\u0440\u043E\u0432\u0430\u0442\u044C \u0441\u0441\u044B\u043B\u043A\u0443 \u043D\u0430 \u043A\u043E\u0434",
      "cmd.convertSelection": "\u041F\u0440\u0435\u0432\u0440\u0430\u0442\u0438\u0442\u044C \u0432\u044B\u0434\u0435\u043B\u0435\u043D\u0438\u0435 \u0432 \u0441\u0441\u044B\u043B\u043A\u0443 \u043D\u0430 \u043A\u043E\u0434",
      "cmd.openSelection": "\u041D\u0430\u0439\u0442\u0438 \u0438 \u043E\u0442\u043A\u0440\u044B\u0442\u044C \u043A\u043E\u0434",
      "cmd.insertLineLink": "\u0412\u0441\u0442\u0430\u0432\u0438\u0442\u044C \u0441\u0441\u044B\u043B\u043A\u0443 \u043D\u0430 \u0441\u0442\u0440\u043E\u043A\u0443 \u043A\u043E\u0434\u0430",
      "cmd.insertEmbed": "\u0412\u0441\u0442\u0430\u0432\u0438\u0442\u044C embed \u043A\u043E\u0434\u0430",
      "cmd.pin.sym": "\u0417\u0430\u043A\u0440\u0435\u043F\u0438\u0442\u044C \u0441\u0441\u044B\u043B\u043A\u0443 \u0437\u0430 \u0435\u0451 \u0441\u0438\u043C\u0432\u043E\u043B\u043E\u043C",
      "cmd.pin.kind": "\u0417\u0430\u043A\u0440\u0435\u043F\u0438\u0442\u044C \u0441\u0441\u044B\u043B\u043A\u0443 \u0437\u0430 \u0435\u0451 \u0432\u0438\u0434\u043E\u043C",
      "cmd.pin.line": "\u0417\u0430\u043A\u0440\u0435\u043F\u0438\u0442\u044C \u0441\u0441\u044B\u043B\u043A\u0443 \u0437\u0430 \u0435\u0451 \u0441\u0442\u0440\u043E\u043A\u043E\u0439",
      "cmd.pinLinksNote": "\u0417\u0430\u043A\u0440\u0435\u043F\u0438\u0442\u044C \u043D\u0435\u0437\u0430\u043A\u0440\u0435\u043F\u043B\u0451\u043D\u043D\u044B\u0435 \u0441\u0441\u044B\u043B\u043A\u0438 \u043D\u0430 \u043A\u043E\u0434 \u0438 embed \u0432 \u044D\u0442\u043E\u0439 \u0437\u0430\u043C\u0435\u0442\u043A\u0435",
      "cmd.pinLinksVault": "\u0417\u0430\u043A\u0440\u0435\u043F\u0438\u0442\u044C \u043D\u0435\u0437\u0430\u043A\u0440\u0435\u043F\u043B\u0451\u043D\u043D\u044B\u0435 \u0441\u0441\u044B\u043B\u043A\u0438 \u043D\u0430 \u043A\u043E\u0434 \u0438 embed \u0432\u043E \u0432\u0441\u0451\u043C \u0445\u0440\u0430\u043D\u0438\u043B\u0438\u0449\u0435",
      "cmd.updateLinksNote": "\u0410\u043A\u0442\u0443\u0430\u043B\u0438\u0437\u0438\u0440\u043E\u0432\u0430\u0442\u044C \u0441\u0441\u044B\u043B\u043A\u0438 \u043D\u0430 \u043A\u043E\u0434 \u0432 \u044D\u0442\u043E\u0439 \u0437\u0430\u043C\u0435\u0442\u043A\u0435",
      "cmd.updateLinksVault": "\u0410\u043A\u0442\u0443\u0430\u043B\u0438\u0437\u0438\u0440\u043E\u0432\u0430\u0442\u044C \u0441\u0441\u044B\u043B\u043A\u0438 \u043D\u0430 \u043A\u043E\u0434 \u0432\u043E \u0432\u0441\u0451\u043C \u0445\u0440\u0430\u043D\u0438\u043B\u0438\u0449\u0435",
      // Editor context menu
      "menu.convert.solo": "\u041D\u0430\u0439\u0442\u0438 \u0438 \u043F\u0440\u0435\u0432\u0440\u0430\u0442\u0438\u0442\u044C \u0432 \u0441\u0441\u044B\u043B\u043A\u0443 \u043D\u0430 \u043A\u043E\u0434",
      "menu.convert.item": "\u041A\u043E\u0434",
      "menu.open.solo": "\u041D\u0430\u0439\u0442\u0438 \u0438 \u043E\u0442\u043A\u0440\u044B\u0442\u044C \u043A\u043E\u0434",
      "menu.open.item": "\u041A\u043E\u0434",
      "menu.copyLink": "\u0421\u043A\u043E\u043F\u0438\u0440\u043E\u0432\u0430\u0442\u044C \u0441\u0441\u044B\u043B\u043A\u0443 \u043D\u0430 \u043A\u043E\u0434",
      "menu.fixLink": "\u0410\u043A\u0442\u0443\u0430\u043B\u0438\u0437\u0438\u0440\u043E\u0432\u0430\u0442\u044C \u044D\u0442\u0443 \u0441\u0441\u044B\u043B\u043A\u0443 \u043D\u0430 \u043A\u043E\u0434",
      "menu.pin": "\u0417\u0430\u043A\u0440\u0435\u043F\u0438\u0442\u044C \u044D\u0442\u0443 \u0441\u0441\u044B\u043B\u043A\u0443",
      "menu.pin.sym": "\u0417\u0430\u043A\u0440\u0435\u043F\u0438\u0442\u044C \u0437\u0430 \u0441\u0438\u043C\u0432\u043E\u043B\u043E\u043C \xAB{value}\xBB",
      "menu.pin.kind": "\u0417\u0430\u043A\u0440\u0435\u043F\u0438\u0442\u044C \u0437\u0430 \u0432\u0438\u0434\u043E\u043C \xAB{value}\xBB",
      "menu.pin.line": "\u0417\u0430\u043A\u0440\u0435\u043F\u0438\u0442\u044C \u0437\u0430 \u044D\u0442\u043E\u0439 \u0441\u0442\u0440\u043E\u043A\u043E\u0439 ({value})",
      "menu.unpin": "\u041E\u0442\u043A\u0440\u0435\u043F\u0438\u0442\u044C \u044D\u0442\u0443 \u0441\u0441\u044B\u043B\u043A\u0443",
      // Notices
      "notice.noCodeRoot": "Code Linker: \u043D\u0435 \u0443\u0434\u0430\u043B\u043E\u0441\u044C \u043E\u043F\u0440\u0435\u0434\u0435\u043B\u0438\u0442\u044C \u043A\u043E\u0440\u0435\u043D\u044C \u043A\u043E\u0434\u0430",
      "notice.noLanguages": "Code Linker: \u043D\u0435 \u0432\u043A\u043B\u044E\u0447\u0451\u043D \u043D\u0438 \u043E\u0434\u0438\u043D \u044F\u0437\u044B\u043A",
      "notice.scanFailed": "Code Linker: \u0441\u043A\u0430\u043D\u0438\u0440\u043E\u0432\u0430\u043D\u0438\u0435 \u043D\u0435 \u0443\u0434\u0430\u043B\u043E\u0441\u044C \u2014 {error}",
      "notice.indexed": "Code Linker: \u043F\u0440\u043E\u0438\u043D\u0434\u0435\u043A\u0441\u0438\u0440\u043E\u0432\u0430\u043D\u043E {entries}",
      "notice.missingFolders": "Code Linker: \u043F\u0430\u043F\u043A\u0430 \u0441\u043A\u0430\u043D\u0438\u0440\u043E\u0432\u0430\u043D\u0438\u044F \u043D\u0435 \u043D\u0430\u0439\u0434\u0435\u043D\u0430 \u2014 {folders}",
      "notice.copied": "Code Linker: \u0441\u0441\u044B\u043B\u043A\u0430 \u0441\u043A\u043E\u043F\u0438\u0440\u043E\u0432\u0430\u043D\u0430",
      "notice.bound": "Code Linker: \u0441\u0441\u044B\u043B\u043A\u0430 \u0437\u0430\u043A\u0440\u0435\u043F\u043B\u0435\u043D\u0430 \u0437\u0430 \u0441\u0442\u0440\u043E\u043A\u043E\u0439 {line}",
      "notice.unbound": "Code Linker: \u0441\u0441\u044B\u043B\u043A\u0430 \u043E\u0442\u043A\u0440\u0435\u043F\u043B\u0435\u043D\u0430 \u2014 \u0431\u043E\u043B\u044C\u0448\u0435 \u043D\u0435 \u043E\u0442\u0441\u043B\u0435\u0436\u0438\u0432\u0430\u0435\u0442\u0441\u044F",
      "notice.cantBind": "Code Linker: \u043D\u0435 \u0437\u0430 \u0447\u0442\u043E \u0437\u0430\u043A\u0440\u0435\u043F\u0438\u0442\u044C \u2014 \u0441\u0441\u044B\u043B\u043A\u0430 \u043D\u0435 \u0432\u0435\u0434\u0451\u0442 \u043D\u0430 \u0441\u0442\u0440\u043E\u043A\u0443 \u043F\u0440\u043E\u0438\u043D\u0434\u0435\u043A\u0441\u0438\u0440\u043E\u0432\u0430\u043D\u043D\u043E\u0433\u043E \u0444\u0430\u0439\u043B\u0430",
      "notice.embedMoved": "Code Linker: \u0437\u0430\u043C\u0435\u0442\u043A\u0430 \u0438\u0437\u043C\u0435\u043D\u0438\u043B\u0430\u0441\u044C \u0441 \u043C\u043E\u043C\u0435\u043D\u0442\u0430 \u043E\u0442\u0440\u0438\u0441\u043E\u0432\u043A\u0438 \u0431\u043B\u043E\u043A\u0430 \u2014 \u043D\u0438\u0447\u0435\u0433\u043E \u043D\u0435 \u0437\u0430\u043F\u0438\u0441\u0430\u043D\u043E; \u043E\u0431\u043D\u043E\u0432\u0438\u0442\u0435 \u0435\u0433\u043E \u0438 \u043F\u043E\u0432\u0442\u043E\u0440\u0438\u0442\u0435",
      "notice.noGit": "Code Linker: \u0434\u043B\u044F \u044D\u0442\u043E\u0433\u043E \u0444\u0430\u0439\u043B\u0430 \u043D\u0435 \u043D\u0430\u0439\u0434\u0435\u043D git-\u0440\u0435\u043F\u043E\u0437\u0438\u0442\u043E\u0440\u0438\u0439 \u0441 remote",
      "notice.editorSet": "Code Linker: \u0441\u0441\u044B\u043B\u043A\u0438 \u0442\u0435\u043F\u0435\u0440\u044C \u043E\u0442\u043A\u0440\u044B\u0432\u0430\u044E\u0442\u0441\u044F \u0432 {name}",
      "notice.noSelection": "Code Linker: \u0441\u043D\u0430\u0447\u0430\u043B\u0430 \u0432\u044B\u0434\u0435\u043B\u0438\u0442\u0435 \u0438\u043C\u044F \u0438\u043B\u0438 \u043F\u0443\u0442\u044C",
      "notice.noMatch": "Code Linker: \u043D\u0435\u0442 \u0437\u0430\u043F\u0438\u0441\u0438 \u043A\u043E\u0434\u0430 \u0434\u043B\u044F \xAB{query}\xBB",
      "notice.watchUnsupported": "Code Linker: \u0430\u0432\u0442\u043E\u043E\u0431\u043D\u043E\u0432\u043B\u0435\u043D\u0438\u0435 \u043D\u0435\u0434\u043E\u0441\u0442\u0443\u043F\u043D\u043E \u043D\u0430 \u044D\u0442\u043E\u0439 \u043F\u043B\u0430\u0442\u0444\u043E\u0440\u043C\u0435 \u2014 \u043F\u0435\u0440\u0435\u0441\u0442\u0440\u0430\u0438\u0432\u0430\u0439\u0442\u0435 \u0432\u0440\u0443\u0447\u043D\u0443\u044E",
      "notice.linksPinned": "Code Linker: \u0437\u0430\u043A\u0440\u0435\u043F\u043B\u0435\u043D\u043E \u0441\u0441\u044B\u043B\u043E\u043A \u0438 embed \u2014 {n}",
      "notice.linksPinnedVault": "Code Linker: \u0437\u0430\u043A\u0440\u0435\u043F\u043B\u0435\u043D\u043E \u0441\u0441\u044B\u043B\u043E\u043A \u0438 embed \u2014 {n} \u0432 \u0437\u0430\u043C\u0435\u0442\u043A\u0430\u0445: {files}",
      "notice.noDeclHere": "Code Linker: \u043D\u0430 \u044D\u0442\u043E\u0439 \u0441\u0442\u0440\u043E\u043A\u0435 \u043D\u0438\u0447\u0435\u0433\u043E \u043D\u0435 \u043E\u0431\u044A\u044F\u0432\u043B\u0435\u043D\u043E \u2014 \u0437\u0430\u043A\u0440\u0435\u043F\u0438\u0442\u0435 \u0437\u0430 \u0441\u0442\u0440\u043E\u043A\u043E\u0439",
      "notice.linksUpdated": "Code Linker: \u043E\u0431\u043D\u043E\u0432\u043B\u0435\u043D\u043E \u0441\u0441\u044B\u043B\u043E\u043A \u2014 {n}",
      "notice.linksUpdatedVault": "Code Linker: \u043E\u0431\u043D\u043E\u0432\u043B\u0435\u043D\u043E \u0441\u0441\u044B\u043B\u043E\u043A \u2014 {n} \u0432 \u0437\u0430\u043C\u0435\u0442\u043A\u0430\u0445: {files}",
      "notice.langFileNoPath": "Code Linker: \u0441\u043D\u0430\u0447\u0430\u043B\u0430 \u0443\u043A\u0430\u0436\u0438\u0442\u0435 \u043F\u0443\u0442\u044C \u043A \u0444\u0430\u0439\u043B\u0443 \u044F\u0437\u044B\u043A\u043E\u0432",
      "notice.langFileExists": "Code Linker: \u0444\u0430\u0439\u043B \u044F\u0437\u044B\u043A\u043E\u0432 \u0443\u0436\u0435 \u0441\u0443\u0449\u0435\u0441\u0442\u0432\u0443\u0435\u0442",
      "notice.langFileCreated": "Code Linker: \u0441\u043E\u0437\u0434\u0430\u043D {path}",
      "notice.langFileError": "Code Linker: \u043D\u0435 \u0443\u0434\u0430\u043B\u043E\u0441\u044C \u0441\u043E\u0437\u0434\u0430\u0442\u044C \u0444\u0430\u0439\u043B \u2014 {error}",
      // Inline embeds
      "embed.empty": "Code Linker: \u043F\u0443\u0441\u0442\u043E\u0439 embed \u2014 \u0443\u043A\u0430\u0436\u0438\u0442\u0435 \u0438\u043C\u044F \u0441\u0438\u043C\u0432\u043E\u043B\u0430 \u0438\u043B\u0438 \u043F\u0443\u0442\u044C:\u0441\u0442\u0440\u043E\u043A\u0443",
      "embed.fmt.file": "\u0424\u0430\u0439\u043B \u0446\u0435\u043B\u0438\u043A\u043E\u043C",
      "embed.fmt.symbol": "\u0421\u0438\u043C\u0432\u043E\u043B \u2014 \u0441\u043B\u0435\u0434\u0443\u0435\u0442 \u0437\u0430 \u043E\u0431\u044A\u044F\u0432\u043B\u0435\u043D\u0438\u0435\u043C \u043F\u0440\u0438 \u0434\u0432\u0438\u0436\u0435\u043D\u0438\u0438 \u043A\u043E\u0434\u0430",
      "embed.fmt.line": "\u0421\u0442\u0440\u043E\u043A\u0430 \u043E\u0431\u044A\u044F\u0432\u043B\u0435\u043D\u0438\u044F ({line})",
      "embed.fmt.range": "\u0414\u0438\u0430\u043F\u0430\u0437\u043E\u043D \u0441\u0442\u0440\u043E\u043A ({from}-{to}, \u043F\u043E\u043F\u0440\u0430\u0432\u044C\u0442\u0435 \u043F\u043E \u0432\u043A\u0443\u0441\u0443)",
      "embed.stale": "Code Linker: \u0437\u0430\u043A\u0440\u0435\u043F\u043B\u0451\u043D\u043D\u044B\u0439 \u043A\u043E\u0434 \u0443\u0435\u0445\u0430\u043B \u043D\u0430 \u0441\u0442\u0440\u043E\u043A\u0443 {line} \u2014 \u0437\u0430\u043F\u0443\u0441\u0442\u0438\u0442\u0435 \xAB\u0410\u043A\u0442\u0443\u0430\u043B\u0438\u0437\u0438\u0440\u043E\u0432\u0430\u0442\u044C \u0441\u0441\u044B\u043B\u043A\u0438 \u0432 \u044D\u0442\u043E\u0439 \u0437\u0430\u043C\u0435\u0442\u043A\u0435\xBB",
      "embed.broken": "Code Linker: \u0437\u0430\u043A\u0440\u0435\u043F\u043B\u0451\u043D\u043D\u044B\u0439 \u043A\u043E\u0434 \u043F\u0440\u043E\u043F\u0430\u043B \u2014 \u043F\u0435\u0440\u0435\u0438\u043C\u0435\u043D\u043E\u0432\u0430\u043D, \u0443\u0434\u0430\u043B\u0451\u043D \u0438\u043B\u0438 \u0441\u0442\u0440\u043E\u043A\u0430 \u043F\u0435\u0440\u0435\u043F\u0438\u0441\u0430\u043D\u0430",
      "embed.menu.open": "\u041E\u0442\u043A\u0440\u044B\u0442\u044C \u0444\u0430\u0439\u043B \u043A\u043E\u0434\u0430",
      "embed.notFound": "Code Linker: \u043D\u0435\u0442 \u0437\u0430\u043F\u0438\u0441\u0438 \u043A\u043E\u0434\u0430 \u0434\u043B\u044F \xAB{query}\xBB",
      "embed.ambiguous": "Code Linker: \u043F\u043E\u0434 \xAB{query}\xBB \u043F\u043E\u0434\u0445\u043E\u0434\u0438\u0442 \u0437\u0430\u043F\u0438\u0441\u0435\u0439: {n} \u2014 \u0443\u0442\u043E\u0447\u043D\u0438\u0442\u0435 \u0444\u0438\u043B\u044C\u0442\u0440\u043E\u043C \u044F\u0437\u044B\u043A\u0430/\u0442\u0438\u043F\u0430 (\u043D\u0430\u043F\u0440. py:) \u0438\u043B\u0438 \u043F\u0443\u0442\u0451\u043C",
      "embed.unreadable": "Code Linker: \u043D\u0435 \u0443\u0434\u0430\u043B\u043E\u0441\u044C \u043F\u0440\u043E\u0447\u0438\u0442\u0430\u0442\u044C {path}",
      "plural.embedMore": { one: "\u041F\u043E\u043A\u0430\u0437\u0430\u0442\u044C \u0435\u0449\u0451 {n} \u0441\u0442\u0440\u043E\u043A\u0443", few: "\u041F\u043E\u043A\u0430\u0437\u0430\u0442\u044C \u0435\u0449\u0451 {n} \u0441\u0442\u0440\u043E\u043A\u0438", many: "\u041F\u043E\u043A\u0430\u0437\u0430\u0442\u044C \u0435\u0449\u0451 {n} \u0441\u0442\u0440\u043E\u043A", other: "\u041F\u043E\u043A\u0430\u0437\u0430\u0442\u044C \u0435\u0449\u0451 {n} \u0441\u0442\u0440\u043E\u043A\u0438" },
      "embed.tool.wrap": "\u041F\u0435\u0440\u0435\u043D\u043E\u0441\u0438\u0442\u044C \u0434\u043B\u0438\u043D\u043D\u044B\u0435 \u0441\u0442\u0440\u043E\u043A\u0438",
      "embed.tool.copy": "\u0421\u043A\u043E\u043F\u0438\u0440\u043E\u0432\u0430\u0442\u044C \u0441\u043D\u0438\u043F\u043F\u0435\u0442",
      "notice.snippetCopied": "Code Linker: \u0441\u043D\u0438\u043F\u043F\u0435\u0442 \u0441\u043A\u043E\u043F\u0438\u0440\u043E\u0432\u0430\u043D",
      "embed.truncated": "Code Linker: \u043F\u043E\u043A\u0430\u0437\u0430\u043D\u044B \u043F\u0435\u0440\u0432\u044B\u0435 {max} \u0441\u0442\u0440\u043E\u043A",
      // Status bar
      "status.indexing": "Code Linker: \u0438\u043D\u0434\u0435\u043A\u0441\u0438\u0440\u043E\u0432\u0430\u043D\u0438\u0435\u2026 {n}",
      "status.editor": "\u0421\u0441\u044B\u043B\u043A\u0430 \u043D\u0430 \u043A\u043E\u0434: {name}",
      "status.editorTooltip": "Code Linker: \u043A\u043B\u0438\u043A \u2014 \u0441\u043C\u0435\u043D\u0438\u0442\u044C \u0440\u0435\u0434\u0430\u043A\u0442\u043E\u0440, \u0432 \u043A\u043E\u0442\u043E\u0440\u043E\u043C \u043E\u0442\u043A\u0440\u044B\u0432\u0430\u044E\u0442\u0441\u044F \u0441\u0441\u044B\u043B\u043A\u0438",
      // Command-palette modal
      "modal.searchPlaceholder": "\u041F\u043E\u0438\u0441\u043A \u0444\u0430\u0439\u043B\u043E\u0432 \u0438 \u0442\u0438\u043F\u043E\u0432 \u043A\u043E\u0434\u0430\u2026",
      "modal.linePrompt": "\u041A\u0430\u043A\u0430\u044F \u0441\u0442\u0440\u043E\u043A\u0430?",
      "modal.lineSubmit": "\u0412\u0441\u0442\u0430\u0432\u0438\u0442\u044C \u0441\u0441\u044B\u043B\u043A\u0443",
      "modal.switchPlaceholder": "\u0412\u044B\u0431\u0435\u0440\u0438\u0442\u0435 \u0440\u0435\u0434\u0430\u043A\u0442\u043E\u0440, \u0432 \u043A\u043E\u0442\u043E\u0440\u043E\u043C \u043E\u0442\u043A\u0440\u044B\u0432\u0430\u044E\u0442\u0441\u044F \u0441\u0441\u044B\u043B\u043A\u0438\u2026",
      "modal.formatPlaceholder": "\u0412\u044B\u0431\u0435\u0440\u0438\u0442\u0435 \u0444\u043E\u0440\u043C\u0430\u0442 \u0440\u0435\u0434\u0430\u043A\u0442\u043E\u0440\u0430 \u0434\u043B\u044F \u044D\u0442\u043E\u0439 \u0441\u0441\u044B\u043B\u043A\u0438\u2026",
      "modal.productPlaceholder": "\u0412\u044B\u0431\u0435\u0440\u0438\u0442\u0435 IDE JetBrains\u2026",
      "modal.pinAnchors": "\u0417\u0430\u043A\u0440\u0435\u043F\u0438\u0442\u044C \u043A\u2026",
      "modal.pinAnchorsDesc": "\u041A \u0447\u0435\u043C\u0443 \u043F\u0440\u0438\u0432\u044F\u0437\u044B\u0432\u0430\u0442\u044C \u043A\u0430\u0436\u0434\u0443\u044E \u0441\u0441\u044B\u043B\u043A\u0443 \u0438 embed. \u042F\u043A\u043E\u0440\u044F \u0441\u043A\u043B\u0430\u0434\u044B\u0432\u0430\u044E\u0442\u0441\u044F: \u0441\u0438\u043C\u0432\u043E\u043B + \u0441\u0442\u0440\u043E\u043A\u0430 \u0434\u0435\u0440\u0436\u0430\u0442 \u0442\u043E\u0447\u043D\u043E\u0435 \u043E\u0431\u044A\u044F\u0432\u043B\u0435\u043D\u0438\u0435 \u0438 \u043D\u0435 \u043F\u0435\u0440\u0435\u043F\u0440\u0438\u0432\u044F\u0436\u0443\u0442\u0441\u044F \u043C\u043E\u043B\u0447\u0430 \u043A \u043E\u0434\u043D\u043E\u0438\u043C\u0451\u043D\u043D\u043E\u043C\u0443.",
      "modal.pinAnchor.sym": "\u0418\u043C\u044F \u0441\u0438\u043C\u0432\u043E\u043B\u0430",
      "modal.pinAnchor.kind": "\u0412\u0438\u0434 (\u043A\u043B\u0430\u0441\u0441, \u043C\u0435\u0442\u043E\u0434\u2026)",
      "modal.pinAnchor.line": "\u0422\u043E\u0447\u043D\u044B\u0439 \u0442\u0435\u043A\u0441\u0442 \u0441\u0442\u0440\u043E\u043A\u0438",
      "modal.pinAnchorsSubmit": "\u0417\u0430\u043A\u0440\u0435\u043F\u0438\u0442\u044C",
      "modal.update.title": "\u0410\u043A\u0442\u0443\u0430\u043B\u0438\u0437\u0438\u0440\u043E\u0432\u0430\u0442\u044C \u0441\u0441\u044B\u043B\u043A\u0438 \u043D\u0430 \u043A\u043E\u0434",
      "modal.update.attention": "\u0422\u0440\u0435\u0431\u0443\u044E\u0442 \u0432\u043D\u0438\u043C\u0430\u043D\u0438\u044F \u2014 {n}: \u0438\u0445 \u043A\u043E\u0434 \u043F\u0440\u043E\u043F\u0430\u043B (\u043F\u0435\u0440\u0435\u0438\u043C\u0435\u043D\u043E\u0432\u0430\u043D \u0438\u043B\u0438 \u0443\u0434\u0430\u043B\u0451\u043D), \u043F\u043E\u044D\u0442\u043E\u043C\u0443 \u0447\u0438\u043D\u0438\u0442\u044C \u043D\u0435\u0447\u0435\u0433\u043E.",
      "modal.update.brokenRow": "{label} \u2014 \u043D\u0435 \u043F\u043E\u0447\u0438\u043D\u0438\u0442\u044C (\u043F\u0435\u0440\u0435\u0438\u043C\u0435\u043D\u043E\u0432\u0430\u043D \u0438\u043B\u0438 \u0443\u0434\u0430\u043B\u0451\u043D)",
      // Settings — headings
      "set.heading.index": "\u0418\u043D\u0434\u0435\u043A\u0441 \u043A\u043E\u0434\u0430",
      "set.heading.languages": "\u042F\u0437\u044B\u043A\u0438",
      "set.heading.customLanguages": "\u0421\u0432\u043E\u0438 \u044F\u0437\u044B\u043A\u0438",
      // Settings — code index
      "set.codeRoot.name": "\u041A\u043E\u0440\u0435\u043D\u044C \u043A\u043E\u0434\u0430",
      "set.scanFolders.desc": "\u041F\u0430\u043F\u043A\u0438, \u0441\u043A\u0430\u043D\u0438\u0440\u0443\u0435\u043C\u044B\u0435 \u043D\u0430 \u0438\u0441\u0445\u043E\u0434\u043D\u044B\u0435 \u0444\u0430\u0439\u043B\u044B, \u043E\u0442\u043D\u043E\u0441\u0438\u0442\u0435\u043B\u044C\u043D\u043E \u043A\u043E\u0440\u043D\u044F \u043A\u043E\u0434\u0430. \u041E\u0441\u0442\u0430\u0432\u044C\u0442\u0435 \u043F\u0443\u0441\u0442\u044B\u043C, \u0447\u0442\u043E\u0431\u044B \u0441\u043A\u0430\u043D\u0438\u0440\u043E\u0432\u0430\u0442\u044C \u0432\u0435\u0441\u044C \u043A\u043E\u0440\u0435\u043D\u044C \u043A\u043E\u0434\u0430.",
      "set.scanFolders.notFound": "\u26A0 \u041D\u0435 \u043D\u0430\u0439\u0434\u0435\u043D\u043E \u0432 \u043A\u043E\u0440\u043D\u0435 \u043A\u043E\u0434\u0430 \u2014 {folders}",
      "set.maxFileSize.name": "\u041C\u0430\u043A\u0441. \u0440\u0430\u0437\u043C\u0435\u0440 \u0444\u0430\u0439\u043B\u0430 (\u041A\u0411)",
      "set.maxFileSize.desc": "\u0424\u0430\u0439\u043B\u044B \u043A\u0440\u0443\u043F\u043D\u0435\u0435 \u0438\u043D\u0434\u0435\u043A\u0441\u0438\u0440\u0443\u044E\u0442\u0441\u044F \u0442\u043E\u043B\u044C\u043A\u043E \u043F\u043E \u0438\u043C\u0435\u043D\u0438, \u0431\u0435\u0437 \u0440\u0430\u0437\u0431\u043E\u0440\u0430 \u043E\u0431\u044A\u044F\u0432\u043B\u0435\u043D\u0438\u0439. 0 = \u0431\u0435\u0437 \u043E\u0433\u0440\u0430\u043D\u0438\u0447\u0435\u043D\u0438\u044F.",
      "set.skipFolders.desc": "\u041F\u0440\u043E\u0441\u0442\u043E \u0438\u043C\u044F (node_modules) \u043F\u0440\u043E\u043F\u0443\u0441\u043A\u0430\u0435\u0442\u0441\u044F \u043D\u0430 \u043B\u044E\u0431\u043E\u0439 \u0433\u043B\u0443\u0431\u0438\u043D\u0435; \u043F\u0443\u0442\u044C \u0441\u043E \u0441\u043B\u044D\u0448\u0435\u043C (src/generated) \u043F\u0440\u043E\u043F\u0443\u0441\u043A\u0430\u0435\u0442 \u0442\u043E\u043B\u044C\u043A\u043E \u044D\u0442\u0443 \u043F\u0430\u043F\u043A\u0443 \u043E\u0442\u043D\u043E\u0441\u0438\u0442\u0435\u043B\u044C\u043D\u043E \u043A\u043E\u0440\u043D\u044F \u043A\u043E\u0434\u0430.",
      "set.gitignore.name": "\u0423\u0447\u0438\u0442\u044B\u0432\u0430\u0442\u044C .gitignore",
      "set.gitignore.desc": "\u041F\u0440\u043E\u043F\u0443\u0441\u043A\u0430\u0442\u044C \u0438 \u043F\u0443\u0442\u0438, \u0438\u0441\u043A\u043B\u044E\u0447\u0451\u043D\u043D\u044B\u0435 .gitignore. \u0424\u0430\u0439\u043B\u044B \u0447\u0438\u0442\u0430\u044E\u0442\u0441\u044F \u043E\u0442 \u043A\u043E\u0440\u043D\u044F \u0441\u043A\u0430\u043D\u0438\u0440\u043E\u0432\u0430\u043D\u0438\u044F \u0432\u043D\u0438\u0437 (.gitignore \u0432\u044B\u0448\u0435 \u043D\u0435 \u0443\u0447\u0438\u0442\u044B\u0432\u0430\u0435\u0442\u0441\u044F); \u043F\u043E\u0434\u0434\u0435\u0440\u0436\u0430\u043D\u044B \u043E\u0442\u0440\u0438\u0446\u0430\u043D\u0438\u0435 (!), \u0442\u043E\u043B\u044C\u043A\u043E-\u043A\u0430\u0442\u0430\u043B\u043E\u0433\u0438 (build/) \u0438 \u0448\u0430\u0431\u043B\u043E\u043D\u044B *, ?, **.",
      "set.rebuild.name": "\u041F\u0435\u0440\u0435\u0441\u0442\u0440\u043E\u0438\u0442\u044C \u0438\u043D\u0434\u0435\u043A\u0441 \u043A\u043E\u0434\u0430",
      "set.rebuild.desc": "\u041F\u0435\u0440\u0435\u0441\u043A\u0430\u043D\u0438\u0440\u043E\u0432\u0430\u0442\u044C \u0438\u0441\u0445\u043E\u0434\u043D\u044B\u0435 \u043F\u0430\u043F\u043A\u0438 \u0441\u0435\u0439\u0447\u0430\u0441.",
      // Settings — languages
      "set.languages.desc": "\u041A\u0430\u043A\u0438\u0435 \u044F\u0437\u044B\u043A\u0438 \u0441\u043A\u0430\u043D\u0438\u0440\u0443\u044E\u0442\u0441\u044F \u2014 \u0432\u043A\u043B\u044E\u0447\u0435\u043D\u043E {enabled} \u0438\u0437 {total}. \u0420\u0430\u0437\u0432\u0435\u0440\u043D\u0438\u0442\u0435 \u0432\u043A\u043B\u044E\u0447\u0451\u043D\u043D\u044B\u0439 \u044F\u0437\u044B\u043A, \u0447\u0442\u043E\u0431\u044B \u0432\u044B\u0431\u0440\u0430\u0442\u044C, \u043A\u0430\u043A\u0438\u0435 \u0432\u0438\u0434\u044B \u0441\u0443\u0449\u043D\u043E\u0441\u0442\u0435\u0439 \u0432 \u043D\u0451\u043C \u0434\u043E\u0441\u0442\u0443\u043F\u043D\u044B \u0434\u043B\u044F \u043F\u043E\u0438\u0441\u043A\u0430.",
      "set.lang.meta": "id: {id} \xB7 {ext}",
      "set.lang.noExtensions": "(\u0431\u0435\u0437 \u0440\u0430\u0441\u0448\u0438\u0440\u0435\u043D\u0438\u0439)",
      "set.lang.showEntities": "\u041F\u043E\u043A\u0430\u0437\u0430\u0442\u044C \u0441\u0443\u0449\u043D\u043E\u0441\u0442\u0438",
      "set.lang.hideEntities": "\u0421\u043A\u0440\u044B\u0442\u044C \u0441\u0443\u0449\u043D\u043E\u0441\u0442\u0438",
      "set.lang.invalid": "\u041D\u0435\u043A\u043E\u0440\u0440\u0435\u043A\u0442\u043D\u043E: {error}",
      "set.kind.count": "\u0432 \u0438\u043D\u0434\u0435\u043A\u0441\u0435: {n}",
      "set.kind.rebuildHint": "\u041F\u0435\u0440\u0435\u0441\u0442\u0440\u043E\u0439\u0442\u0435 \u0438\u043D\u0434\u0435\u043A\u0441, \u0447\u0442\u043E\u0431\u044B \u0432\u044B\u0431\u0440\u0430\u0442\u044C, \u043A\u0430\u043A\u0438\u0435 \u0435\u0433\u043E \u0441\u0443\u0449\u043D\u043E\u0441\u0442\u0438 \u0434\u043E\u0441\u0442\u0443\u043F\u043D\u044B \u0434\u043B\u044F \u043F\u043E\u0438\u0441\u043A\u0430.",
      // Settings — custom languages
      "set.customLanguages.desc": "\u0414\u043E\u0431\u0430\u0432\u044C\u0442\u0435 \u0441\u0432\u043E\u0438 \u044F\u0437\u044B\u043A\u0438 \u0438\u043B\u0438 \u043F\u0435\u0440\u0435\u043E\u043F\u0440\u0435\u0434\u0435\u043B\u0438\u0442\u0435 \u0432\u0441\u0442\u0440\u043E\u0435\u043D\u043D\u044B\u0439 \u0447\u0435\u0440\u0435\u0437 JSON-\u0444\u0430\u0439\u043B \u0432 \u0445\u0440\u0430\u043D\u0438\u043B\u0438\u0449\u0435. \u0423\u043A\u0430\u0436\u0438\u0442\u0435 \u043F\u0443\u0442\u044C \u043D\u0438\u0436\u0435 \u0438 \u043D\u0430\u0436\u043C\u0438\u0442\u0435 \xAB\u0421\u043E\u0437\u0434\u0430\u0442\u044C \u0444\u0430\u0439\u043B\xBB, \u0447\u0442\u043E\u0431\u044B \u0437\u0430\u043F\u0438\u0441\u0430\u0442\u044C \u0441\u0442\u0430\u0440\u0442\u043E\u0432\u044B\u0439 \u0448\u0430\u0431\u043B\u043E\u043D, \u043E\u0442\u0440\u0435\u0434\u0430\u043A\u0442\u0438\u0440\u0443\u0439\u0442\u0435 \u0438 \u0441\u043E\u0445\u0440\u0430\u043D\u0438\u0442\u0435 \u2014 \u043E\u043D \u043F\u0435\u0440\u0435\u0437\u0430\u0433\u0440\u0443\u0437\u0438\u0442\u0441\u044F \u043F\u0440\u0438 \u0441\u043E\u0445\u0440\u0430\u043D\u0435\u043D\u0438\u0438. \u0417\u0430\u043F\u0438\u0441\u044C \u0441 id \u0432\u0441\u0442\u0440\u043E\u0435\u043D\u043D\u043E\u0433\u043E \u044F\u0437\u044B\u043A\u0430 \u0437\u0430\u043C\u0435\u043D\u044F\u0435\u0442 \u0435\u0433\u043E; \u043D\u043E\u0432\u044B\u0439 id \u043F\u043E\u044F\u0432\u043B\u044F\u0435\u0442\u0441\u044F \u043A\u0430\u043A \u043D\u043E\u0432\u044B\u0439 \u044F\u0437\u044B\u043A \u0432\u044B\u0448\u0435.",
      "set.languagesFile.name": "\u0424\u0430\u0439\u043B \u044F\u0437\u044B\u043A\u043E\u0432",
      "set.languagesFile.desc": "\u041F\u0443\u0442\u044C \u043A JSON-\u0444\u0430\u0439\u043B\u0443 \u043E\u0442\u043D\u043E\u0441\u0438\u0442\u0435\u043B\u044C\u043D\u043E \u043A\u043E\u0440\u043D\u044F \u0445\u0440\u0430\u043D\u0438\u043B\u0438\u0449\u0430.",
      "set.languagesFile.create": "\u0421\u043E\u0437\u0434\u0430\u0442\u044C \u0444\u0430\u0439\u043B",
      "set.languagesFile.open": "\u041E\u0442\u043A\u0440\u044B\u0442\u044C \u0444\u0430\u0439\u043B \u044F\u0437\u044B\u043A\u043E\u0432",
      "set.reloadLanguages.name": "\u041F\u0435\u0440\u0435\u0437\u0430\u0433\u0440\u0443\u0437\u0438\u0442\u044C \u0444\u0430\u0439\u043B \u044F\u0437\u044B\u043A\u043E\u0432",
      "set.reloadLanguages.desc": "\u041F\u0435\u0440\u0435\u0447\u0438\u0442\u044B\u0432\u0430\u0435\u0442 \u0444\u0430\u0439\u043B \u0438 \u043F\u0435\u0440\u0435\u0441\u0442\u0440\u0430\u0438\u0432\u0430\u0435\u0442 \u0438\u043D\u0434\u0435\u043A\u0441. \u0422\u0430\u043A\u0436\u0435 \u043F\u0440\u043E\u0438\u0441\u0445\u043E\u0434\u0438\u0442 \u0430\u0432\u0442\u043E\u043C\u0430\u0442\u0438\u0447\u0435\u0441\u043A\u0438 \u043F\u0440\u0438 \u0441\u043E\u0445\u0440\u0430\u043D\u0435\u043D\u0438\u0438 \u0444\u0430\u0439\u043B\u0430.",
      "set.reloadLanguages.button": "\u041F\u0435\u0440\u0435\u0437\u0430\u0433\u0440\u0443\u0437\u0438\u0442\u044C \u0438 \u043F\u0435\u0440\u0435\u0441\u0442\u0440\u043E\u0438\u0442\u044C",
      // Settings — suggestions & links
      "set.trigger.desc": "\u0412\u0432\u0435\u0434\u0438\u0442\u0435 \u044D\u0442\u043E, \u0447\u0442\u043E\u0431\u044B \u043D\u0430\u0447\u0430\u0442\u044C \u043F\u043E\u0434\u0441\u043A\u0430\u0437\u043A\u0443 \u043F\u043E \u043A\u043E\u0434\u0443.",
      "set.editorPreset.name": "\u041F\u0440\u0435\u0441\u0435\u0442 \u0441\u0441\u044B\u043B\u043A\u0438 \u043D\u0430 \u0440\u0435\u0434\u0430\u043A\u0442\u043E\u0440",
      "set.editorPreset.desc": "\u0412 \u043A\u0430\u043A\u043E\u043C \u0440\u0435\u0434\u0430\u043A\u0442\u043E\u0440\u0435 \u043E\u0442\u043A\u0440\u044B\u0432\u0430\u044E\u0442\u0441\u044F \u0432\u0441\u0442\u0430\u0432\u043B\u0435\u043D\u043D\u044B\u0435 \u0441\u0441\u044B\u043B\u043A\u0438. \u0421\u0432\u043E\u0438 \u0434\u043E\u0431\u0430\u0432\u043B\u044F\u044E\u0442\u0441\u044F \u0432 \xAB\u0412\u0430\u0448\u0438 \u0440\u0435\u0434\u0430\u043A\u0442\u043E\u0440\u044B\xBB \u043D\u0438\u0436\u0435.",
      "set.preset.vscode": "VS Code",
      "set.preset.jetbrains": "JetBrains",
      "set.preset.github": "\u041F\u0435\u0440\u043C\u0430\u043B\u0438\u043D\u043A GitHub",
      "set.preset.gitlab": "\u041F\u0435\u0440\u043C\u0430\u043B\u0438\u043D\u043A GitLab",
      "set.jetbrainsProduct.name": "IDE JetBrains",
      "set.jetbrainsProduct.desc": "\u0412 \u043A\u0430\u043A\u043E\u0439 JetBrains IDE \u043E\u0442\u043A\u0440\u044B\u0432\u0430\u044E\u0442\u0441\u044F \u0441\u0441\u044B\u043B\u043A\u0438.",
      "set.shownPresets.name": "\u041F\u043E\u043A\u0430\u0437\u044B\u0432\u0430\u0442\u044C \u0432 \u0432\u044B\u0431\u043E\u0440\u0435",
      "set.shownPresets.count": "\u043F\u043E\u043A\u0430\u0437\u0430\u043D\u043E: {shown} \u0438\u0437 {total}",
      "set.shownPresets.desc": "\u041A\u0430\u043A\u0438\u0435 \u0432\u0441\u0442\u0440\u043E\u0435\u043D\u043D\u044B\u0435 \u043F\u0440\u0435\u0441\u0435\u0442\u044B \u043F\u043E\u043A\u0430\u0437\u044B\u0432\u0430\u044E\u0442\u0441\u044F \u0432 \u043F\u0438\u043A\u0435\u0440\u0430\u0445. \u0412\u0430\u0448\u0438 \u0440\u0435\u0434\u0430\u043A\u0442\u043E\u0440\u044B \u043F\u043E\u043A\u0430\u0437\u044B\u0432\u0430\u044E\u0442\u0441\u044F \u0432\u0441\u0435\u0433\u0434\u0430.",
      "set.editors.name": "\u0412\u0430\u0448\u0438 \u0440\u0435\u0434\u0430\u043A\u0442\u043E\u0440\u044B",
      "set.editors.desc": "\u0418\u043C\u0435\u043D\u043E\u0432\u0430\u043D\u043D\u044B\u0435 \u043F\u0440\u0435\u0441\u0435\u0442\u044B \u0434\u043B\u044F \u0441\u043F\u0438\u0441\u043A\u0430 \u0432\u044B\u0448\u0435. \u041F\u043B\u0435\u0439\u0441\u0445\u043E\u043B\u0434\u0435\u0440\u044B: {abs} {path} {line} {name} {project} {jetbrainsProduct} {root} {gitRemote} {gitSha} {gitBranch}.",
      "set.editors.add": "+ \u0414\u043E\u0431\u0430\u0432\u0438\u0442\u044C \u0440\u0435\u0434\u0430\u043A\u0442\u043E\u0440",
      "set.statusBar.name": "\u041F\u043E\u043A\u0430\u0437\u044B\u0432\u0430\u0442\u044C \u0440\u0435\u0434\u0430\u043A\u0442\u043E\u0440 \u0432 \u0441\u0442\u0430\u0442\u0443\u0441-\u0431\u0430\u0440\u0435",
      "set.statusBar.desc": "\u041F\u043E\u043A\u0430\u0437\u044B\u0432\u0430\u0442\u044C \u0430\u043A\u0442\u0438\u0432\u043D\u044B\u0439 \u043F\u0440\u0435\u0441\u0435\u0442 \u0440\u0435\u0434\u0430\u043A\u0442\u043E\u0440\u0430 \u0432 \u0441\u0442\u0430\u0442\u0443\u0441-\u0431\u0430\u0440\u0435; \u043A\u043B\u0438\u043A \u043F\u043E \u043D\u0435\u043C\u0443 \u043C\u0435\u043D\u044F\u0435\u0442 \u0440\u0435\u0434\u0430\u043A\u0442\u043E\u0440 \u0431\u0435\u0437 \u0432\u0445\u043E\u0434\u0430 \u0432 \u043D\u0430\u0441\u0442\u0440\u043E\u0439\u043A\u0438.",
      "set.autoRefresh.desc": "\u0421\u043B\u0435\u0434\u0438\u0442\u044C \u0437\u0430 \u043F\u0430\u043F\u043A\u0430\u043C\u0438 \u0441\u043A\u0430\u043D\u0438\u0440\u043E\u0432\u0430\u043D\u0438\u044F \u0438 \u043F\u0435\u0440\u0435\u0441\u0442\u0440\u0430\u0438\u0432\u0430\u0442\u044C \u0438\u043D\u0434\u0435\u043A\u0441 \u043F\u0440\u0438 \u0438\u0437\u043C\u0435\u043D\u0435\u043D\u0438\u0438 \u0438\u0441\u0445\u043E\u0434\u043D\u044B\u0445 \u0444\u0430\u0439\u043B\u043E\u0432.",
      "set.contextMenu.desc": "\u0414\u043E\u0431\u0430\u0432\u043B\u044F\u0442\u044C \xAB\u041D\u0430\u0439\u0442\u0438 \u0438 \u043F\u0440\u0435\u0432\u0440\u0430\u0442\u0438\u0442\u044C \u0432 \u0441\u0441\u044B\u043B\u043A\u0443\xBB \u0438 \xAB\u041D\u0430\u0439\u0442\u0438 \u0438 \u043E\u0442\u043A\u0440\u044B\u0442\u044C \u043A\u043E\u0434\xBB \u0432 \u043C\u0435\u043D\u044E \u043F\u043E \u043F\u0440\u0430\u0432\u043E\u043C\u0443 \u043A\u043B\u0438\u043A\u0443 \u2014 \u043F\u043B\u044E\u0441 \xAB\u0421\u043A\u043E\u043F\u0438\u0440\u043E\u0432\u0430\u0442\u044C \u0441\u0441\u044B\u043B\u043A\u0443 \u043D\u0430 \u043A\u043E\u0434\xBB \u043F\u0440\u0438 \u043A\u043B\u0438\u043A\u0435 \u043F\u043E \u0441\u0441\u044B\u043B\u043A\u0435 \u0432 \u043A\u043E\u0434.",
      "set.hoverPreview.name": "\u041F\u0440\u0435\u0432\u044C\u044E \u043A\u043E\u0434\u0430 \u043F\u0440\u0438 \u043D\u0430\u0432\u0435\u0434\u0435\u043D\u0438\u0438",
      "set.hoverPreview.desc": "\u041F\u043E\u043A\u0430\u0437\u044B\u0432\u0430\u0442\u044C \u0444\u0440\u0430\u0433\u043C\u0435\u043D\u0442 \u0444\u0430\u0439\u043B\u0430 \u0432\u043E\u043A\u0440\u0443\u0433 \u0441\u0442\u0440\u043E\u043A\u0438 \u0441\u0441\u044B\u043B\u043A\u0438 \u043F\u0440\u0438 \u043D\u0430\u0432\u0435\u0434\u0435\u043D\u0438\u0438. \u0412 \u0440\u0435\u0436\u0438\u043C\u0435 live preview \u0443\u0434\u0435\u0440\u0436\u0438\u0432\u0430\u0439\u0442\u0435 Ctrl/Cmd; \u0432 \u0440\u0435\u0436\u0438\u043C\u0435 \u0447\u0442\u0435\u043D\u0438\u044F \u0434\u043E\u0441\u0442\u0430\u0442\u043E\u0447\u043D\u043E \u043F\u0440\u043E\u0441\u0442\u043E\u0433\u043E \u043D\u0430\u0432\u0435\u0434\u0435\u043D\u0438\u044F.",
      "set.hoverBefore.name": "\u0421\u0442\u0440\u043E\u043A \u043F\u0440\u0435\u0432\u044C\u044E \u0434\u043E",
      "set.hoverBefore.desc": "\u0421\u043A\u043E\u043B\u044C\u043A\u043E \u0441\u0442\u0440\u043E\u043A \u043F\u043E\u043A\u0430\u0437\u044B\u0432\u0430\u0442\u044C \u043D\u0430\u0434 \u0446\u0435\u043B\u0435\u0432\u043E\u0439 \u0441\u0442\u0440\u043E\u043A\u043E\u0439. -1 = \u0431\u0435\u0437 \u043E\u0433\u0440\u0430\u043D\u0438\u0447\u0435\u043D\u0438\u044F (\u0434\u043E \u043D\u0430\u0447\u0430\u043B\u0430 \u0444\u0430\u0439\u043B\u0430).",
      "set.hoverAfter.name": "\u0421\u0442\u0440\u043E\u043A \u043F\u0440\u0435\u0432\u044C\u044E \u043F\u043E\u0441\u043B\u0435",
      "set.hoverAfter.desc": "\u0421\u043A\u043E\u043B\u044C\u043A\u043E \u0441\u0442\u0440\u043E\u043A \u043F\u043E\u043A\u0430\u0437\u044B\u0432\u0430\u0442\u044C \u043F\u043E\u0434 \u0446\u0435\u043B\u0435\u0432\u043E\u0439 \u0441\u0442\u0440\u043E\u043A\u043E\u0439. -1 = \u0431\u0435\u0437 \u043E\u0433\u0440\u0430\u043D\u0438\u0447\u0435\u043D\u0438\u044F (\u0434\u043E \u043A\u043E\u043D\u0446\u0430 \u0444\u0430\u0439\u043B\u0430).",
      "set.markStaleLinks.desc": "\u041F\u043E\u0434\u0447\u0451\u0440\u043A\u0438\u0432\u0430\u0442\u044C \u0441\u0441\u044B\u043B\u043A\u0438 \u043D\u0430 \u043A\u043E\u0434, \u0443 \u043A\u043E\u0442\u043E\u0440\u044B\u0445 \u0441\u043E\u0445\u0440\u0430\u043D\u0451\u043D\u043D\u0430\u044F \u0441\u0442\u0440\u043E\u043A\u0430 \u0443\u0435\u0445\u0430\u043B\u0430 \u043E\u0442 \u043E\u0431\u044A\u044F\u0432\u043B\u0435\u043D\u0438\u044F (\u0446\u0432\u0435\u0442 \u043F\u0440\u0435\u0434\u0443\u043F\u0440\u0435\u0436\u0434\u0435\u043D\u0438\u044F) \u0438\u043B\u0438 \u0441\u0438\u043C\u0432\u043E\u043B \u043F\u0440\u043E\u043F\u0430\u043B \u2014 \u043F\u0435\u0440\u0435\u0438\u043C\u0435\u043D\u043E\u0432\u0430\u043D \u0438\u043B\u0438 \u0443\u0434\u0430\u043B\u0451\u043D (\u0446\u0432\u0435\u0442 \u043E\u0448\u0438\u0431\u043A\u0438). \u0423\u0435\u0445\u0430\u0432\u0448\u0438\u0435 \u0447\u0438\u043D\u044F\u0442\u0441\u044F \u043A\u043E\u043C\u0430\u043D\u0434\u043E\u0439 \xAB\u0410\u043A\u0442\u0443\u0430\u043B\u0438\u0437\u0438\u0440\u043E\u0432\u0430\u0442\u044C \u0441\u0441\u044B\u043B\u043A\u0438\u2026\xBB.",
      "set.info": "\u041A\u043E\u0440\u0435\u043D\u044C \u043A\u043E\u0434\u0430: {root} \xB7 \u043F\u0440\u043E\u0438\u043D\u0434\u0435\u043A\u0441\u0438\u0440\u043E\u0432\u0430\u043D\u043E {entries}"
    };
  }
});

// src/main.js
var { Plugin, Notice, normalizePath, MarkdownView } = require("obsidian");
var { EditorView } = require("@codemirror/view");
var { Prec } = require("@codemirror/state");
var fs = require("fs");
var fsp = fs.promises;
var readline = require("readline");
var nodePath = require("path");
var { PRESETS, PRISM_LANG, JETBRAINS_PRODUCTS, DEFAULT_SETTINGS, LANGUAGES_TEMPLATE, parseSkip, underSkip, pathInTarget } = require_constants();
var { compileGitignore, isIgnored } = require_gitignore();
var { watchTree } = require_fs_watch();
var { splitLines, inTableCell, inCode, inLink, linkRegex, splitTarget, withTitle } = require_markdown();
var { LINE_RE, ANCHORS, hashLine, parseBinding, formatBinding, bindStateFrom, bindingOwner } = require_binding();
var { fillRoot: fillRootToken, ownsRootToken, namespaceRoot } = require_root_token();
var { menuSection } = require_menu();
var { buildMenu } = require_menu_verbs();
var { ownsLink } = require_link_owner();
var { resolveGit, resolveGitDir } = require_git();
var OWNER = "code";
var SIBLING_ID = "reference-linker";
var GIT_PLACEHOLDER = /{(?:gitRemote|gitSha|gitBranch)}/;
var LINE_TOKEN = /[^\w{}]*[A-Za-z]*\{line\}/;
var PRODUCT_PLACEHOLDER = /{(?:jetbrainsProduct|product)}/;
var MAX_PARSE_LINE_LENGTH = 2e3;
var { BUILTIN_LANGUAGES } = require_builtin_languages();
var { CodeIndexSuggest } = require_suggest2();
var facets = require_facets();
var { VALUE, TOKEN } = facets;
var { HoverPreview } = require_hover();
var { registerEmbed, parseSpec, splitPathRange, resolvePath } = require_embed();
var actualize = require_actualize2();
var { CodeLinkModal, PresetPickerModal, LinePromptModal, PinAnchorModal } = require_modal();
var { CodeIndexView, INDEX_VIEW_TYPE } = require_index_view();
var { CodeLinkerSettingTab } = require_settings_tab();
var { initI18n, withFamily, t, plural } = require_i18n();
var api = require_api();
var indexEvents = require_index_events();
var CodeLinkerPlugin = class extends Plugin {
  async onload() {
    initI18n(withFamily("sigil", { en: require_en(), ru: require_ru() }));
    this.settings = Object.assign({}, DEFAULT_SETTINGS, await this.loadData());
    this.setIndex([]);
    this.languages = [];
    this.languageErrors = [];
    this.customRaw = "";
    this.scanWatcher = null;
    this.fileCache = /* @__PURE__ */ new Map();
    this.lineMaps = /* @__PURE__ */ new Map();
    this.cacheSignature = "";
    this._indexListeners = /* @__PURE__ */ new Set();
    await this.loadLanguagesFile();
    this.migrateSettings();
    this.initPresetVisibility();
    await this.loadCache();
    this.hover = new HoverPreview(this);
    this.registerEditorSuggest(new CodeIndexSuggest(this.app, this));
    this.registerMarkdownPostProcessor((el) => this.resolveRootLinks(el));
    this.registerEditorExtension(
      Prec.highest(
        EditorView.domEventHandlers({
          mousedown: (evt, view) => this.onEditorLink(evt, view, false),
          click: (evt, view) => this.onEditorLink(evt, view, true),
          auxclick: (evt, view) => this.onEditorLink(evt, view, true)
        })
      )
    );
    registerEmbed(this);
    this.registerEditorExtension(actualize.staleLinksExtension(this));
    this.register(this.onIndexChange(() => this.refreshStale()));
    this.lastX = 0;
    this.lastY = 0;
    this.registerDomEvent(document, "mousemove", (evt) => this.onHoverMove(evt));
    this.registerDomEvent(document, "keydown", (evt) => {
      if (evt.key === "Control" || evt.key === "Meta")
        this.onHoverKey();
    });
    this.registerDomEvent(document, "scroll", (evt) => {
      if (!this.hover.contains(evt.target))
        this.hover.hide();
    }, { capture: true });
    this.registerDomEvent(window, "blur", () => this.hover.hide());
    this.registerDomEvent(document, "keyup", (evt) => {
      if (evt.key === "Escape")
        this.hover.hide();
    });
    this.addSettingTab(new CodeLinkerSettingTab(this.app, this));
    this.statusEl = this.addStatusBarItem();
    this.editorStatusEl = this.addStatusBarItem();
    this.editorStatusEl.addClass("mod-clickable");
    this.editorStatusEl.setAttribute("aria-label", t("status.editorTooltip"));
    this.registerDomEvent(this.editorStatusEl, "click", () => this.switchPreset());
    this.updateStatusBar();
    this.registerView(INDEX_VIEW_TYPE, (leaf) => new CodeIndexView(leaf, this));
    this.applyRibbonIcon();
    this.addCommand({ id: "open-code-index", name: t("cmd.openIndex"), callback: () => this.activateIndexView() });
    this.addCommand({ id: "rebuild-code-index", name: t("cmd.rebuildIndex"), callback: () => this.rebuildIndex(true) });
    this.addCommand({ id: "insert-code-link", name: t("cmd.insertLink"), editorCallback: (editor) => this.pickEntry((e) => this.withFormat(this.settings.askOnInsert, (tpl) => this.insertLink(editor, e, tpl))) });
    this.addCommand({ id: "insert-code-link-as", name: t("cmd.insertLinkAs"), editorCallback: (editor) => this.pickEntry((e) => this.withFormat(true, (tpl) => this.insertLink(editor, e, tpl))) });
    this.addCommand({ id: "switch-editor-preset", name: t("cmd.switchPreset"), callback: () => this.switchPreset() });
    this.addCommand({ id: "open-code-file", name: t("cmd.openFile"), callback: () => this.pickEntry((e) => this.withFormat(this.settings.askOnInsert, (tpl) => this.openEntry(e, tpl))) });
    this.addCommand({ id: "copy-code-link", name: t("cmd.copyLink"), callback: () => this.pickEntry((e) => this.withFormat(this.settings.askOnInsert, (tpl) => this.copyLink(e, tpl))) });
    this.addCommand({ id: "convert-selection-to-link", name: t("cmd.convertSelection"), editorCallback: (editor) => this.convertSelection(editor) });
    this.addCommand({ id: "open-selected-code", name: t("cmd.openSelection"), editorCallback: (editor) => this.openSelection(editor) });
    this.addCommand({ id: "insert-code-link-line", name: t("cmd.insertLineLink"), editorCallback: (editor) => this.withFormat(this.settings.askOnInsert, (tpl) => this.insertLineLink(editor, tpl)) });
    this.addLinkCommand("copy-code-link-at-cursor", t("menu.copyLink"), () => true, (editor, link) => this.copyLinkAtCursor(link));
    this.addLinkCommand("fix-code-link", t("menu.fixLink"), (link) => this.isLinkStale(link.target), (editor, link) => this.fixLinkAtCursor(editor, link));
    for (const anchor of ["sym", "kind", "line"]) {
      this.addLinkCommand(
        "pin-code-link-" + anchor,
        t("cmd.pin." + anchor),
        (link) => !!this.linkPinOption(link, anchor),
        (editor, link) => this.pinLink(editor, link, anchor)
      );
    }
    this.addLinkCommand("unpin-code-link", t("menu.unpin"), (link) => this.linkAtCursorBound(link), (editor, link) => this.unbindLink(editor, link));
    this.addCommand({ id: "pin-links-note", name: t("cmd.pinLinksNote"), callback: () => this.pickPinAnchors((a) => this.pinLinksInActiveNote(a)) });
    this.addCommand({ id: "pin-links-vault", name: t("cmd.pinLinksVault"), callback: () => this.pickPinAnchors((a) => this.pinLinksInVault(a)) });
    this.addCommand({ id: "insert-code-embed", name: t("cmd.insertEmbed"), editorCallback: (editor) => this.pickEntry((e) => this.insertEmbed(editor, e)) });
    this.addCommand({ id: "update-links-note", name: t("cmd.updateLinksNote"), callback: () => this.updateLinksInActiveNote() });
    this.addCommand({ id: "update-links-vault", name: t("cmd.updateLinksVault"), callback: () => this.updateLinksInVault() });
    this.registerEvent(
      this.app.workspace.on("editor-menu", (nativeMenu, editor) => buildMenu(this, nativeMenu, (menu) => {
        if (!this.settings.contextMenu)
          return;
        if (this.selectionTarget(editor, true)) {
          this.selectionItem(menu, "convert", "link", () => this.convertSelection(editor));
        }
        if (this.selectionTarget(editor, false)) {
          this.selectionItem(menu, "open", "file-search", () => this.openSelection(editor));
        }
        const link = this.codeLinkAtCursor(editor);
        if (link && this.ownsLinkAtCursor(link)) {
          menu.addItem((item) => item.setTitle(t("menu.copyLink")).setIcon("copy").onClick(() => this.copyLinkAtCursor(link)));
          if (this.isLinkStale(link.target)) {
            menu.addItem((item) => item.setTitle(t("menu.fixLink")).setIcon("wrench").onClick(() => this.fixLinkAtCursor(editor, link)));
          }
          this.addPinItems(menu, (a) => this.linkPinOption(link, a), (a) => this.pinLink(editor, link, a));
          if (this.linkAtCursorBound(link)) {
            menu.addItem((item) => item.setTitle(t("menu.unpin")).setIcon("pin-off").onClick(() => this.unbindLink(editor, link)));
          }
        }
      }))
    );
    this.registerEvent(
      this.app.vault.on("modify", async (f) => {
        if (f && f.path === this.languagesFilePath()) {
          await this.loadLanguagesFile();
          this.rebuildIndex(false);
        }
      })
    );
    this.app.workspace.onLayoutReady(() => this.rebuildIndex(false));
    this.api = this.buildApi();
  }
  onunload() {
    this.stopWatchers();
    clearTimeout(this.watchTimer);
    if (this.hover)
      this.hover.destroy();
  }
  migrateSettings() {
    if (this.settings.enabledLanguages == null) {
      this.settings.enabledLanguages = this.languages.map((l) => l.id);
    }
    this.settings.skipDirs = (this.settings.skipDirs || "").split(/[\n,]+/).map((s) => s.trim()).filter(Boolean).join("\n");
    if (this.settings.uriTemplate === "file:///{abs}")
      this.settings.uriTemplate = PRESETS.file;
    if (this.settings.uriTemplate === "jetbrains://{product}/navigate/reference?project={project}&path={path}:{line}") {
      this.settings.uriTemplate = PRESETS.jetbrains;
    }
    this.settings.uriTemplate = namespaceRoot(this.settings.uriTemplate, OWNER);
    for (const e of this.settings.editors || [])
      e.template = namespaceRoot(e.template, OWNER);
    const tpl = this.settings.uriTemplate;
    const editors = this.settings.editors || (this.settings.editors = []);
    const known = Object.values(PRESETS).includes(tpl) || editors.some((e) => e.template === tpl);
    if (!known)
      editors.push({ name: "Custom", template: tpl });
  }
  // Our own {code-root} is always ours to fill. A bare {root} predates the namespacing and
  // Reference Linker used to fill it too, so it takes a verdict — see legacyRootIsOurs.
  // The default claims it, which is what every call about our own links wants; only the
  // render path, where another plugin's links go past, asks first.
  fillRoot(v, claimLegacy = true) {
    const root = encodeURI(this.codeRoot().split(nodePath.sep).join("/"));
    return fillRootToken(v, { owner: OWNER, root, claimLegacy });
  }
  siblingLinkerInstalled() {
    const plugins = this.app.plugins && this.app.plugins.plugins;
    return !!(plugins && plugins[SIBLING_ID]);
  }
  // Whether a bare {root} in a rendered link is ours to resolve. The binding settles it
  // when there is one. Failing that, being the only linker installed makes every legacy
  // link ours, which keeps a solo vault behaving exactly as it always did. Otherwise the
  // link has to point at something inside our root to count as ours.
  legacyRootIsOurs(url, title) {
    const owner = bindingOwner(title);
    if (owner)
      return owner === OWNER;
    if (!this.siblingLinkerInstalled())
      return true;
    return !!this.targetIndexedFile(this.decodeTarget(url));
  }
  resolveRootLinks(el) {
    const links = el.querySelectorAll ? el.querySelectorAll("a") : [];
    for (const a of links) {
      const title = a.getAttribute("title") || "";
      for (const attr of ["href", "data-href"]) {
        const v = a.getAttribute(attr);
        if (!v)
          continue;
        const out = this.fillRoot(v, this.legacyRootIsOurs(v, title));
        if (out !== v)
          a.setAttribute(attr, out);
      }
    }
    this.markStaleAnchors(el);
  }
  // A rendered anchor back in raw [text](url "title") form: reading view parses the title
  // into its own attribute, while Live Preview only ever sees the raw line.
  anchorTarget(a) {
    const href = a.getAttribute("href") || a.getAttribute("data-href") || "";
    const title = a.getAttribute("title") || "";
    return withTitle(href, title);
  }
  // Toggle the drifted/broken-link underline on every rendered anchor in `el`. toggle (not
  // add) so re-running after an index rebuild also clears links that are now current.
  markStaleAnchors(el) {
    const links = el.querySelectorAll ? el.querySelectorAll("a") : [];
    for (const a of links) {
      const state = this.settings.markStaleLinks ? this.linkState(this.anchorTarget(a)) : null;
      a.classList.toggle("code-linker-stale", state === "stale");
      a.classList.toggle("code-linker-broken", state === "broken");
    }
  }
  // After an index rebuild, refresh stale marks in both render modes: the CM6 effect for
  // Live Preview, and a re-scan of rendered anchors for Reading view (its post-processor
  // doesn't re-run on its own).
  refreshStale() {
    actualize.refreshStaleLinks(this.app);
    this.app.workspace.iterateAllLeaves((leaf) => {
      const view = leaf.view;
      if (view && view.getViewType && view.getViewType() === "markdown" && view.containerEl) {
        this.markStaleAnchors(view.containerEl);
      }
    });
  }
  hoverEnabled() {
    return this.settings.hoverPreview;
  }
  // Pointer tracking that mirrors a real page preview. Rendered (Reading view) links
  // preview on plain hover; the editor (Live Preview) needs the modifier — same split
  // as native page preview. Idle in the editor (nothing shown, no modifier, not over a
  // rendered link) does no work beyond storing the position. While a preview is up it
  // follows the pointer so it stays until you leave the link (entering it keeps it).
  onHoverMove(evt) {
    this.lastX = evt.clientX;
    this.lastY = evt.clientY;
    if (!this.hoverEnabled())
      return;
    if (evt.buttons)
      return;
    const el = evt.target;
    if (this.hover.contains(el)) {
      this.hover.cancelHide();
      return;
    }
    const mod = evt.ctrlKey || evt.metaKey;
    const overAnchor = !!(el && el.closest && el.closest("a"));
    if (!this.hover.isVisible() && !this.hover.pendingKey && !mod && !overAnchor)
      return;
    const hit = this.entryAtPoint(el, evt.clientX, evt.clientY);
    if (hit && (!hit.requireMod || mod)) {
      this.hover.cancelHide();
      this.hover.schedule(hit.entry, evt.clientX, evt.clientY);
    } else if (this.hover.isVisible() || this.hover.pendingKey) {
      this.hover.leave();
    }
  }
  // Pressing the modifier while already hovering a link shows it — the other order
  // (modifier first, then move onto the link) is handled by onHoverMove.
  onHoverKey() {
    if (!this.hoverEnabled())
      return;
    const el = document.elementFromPoint(this.lastX, this.lastY);
    if (this.hover.contains(el))
      return;
    const hit = this.entryAtPoint(el, this.lastX, this.lastY);
    if (hit)
      this.hover.schedule(hit.entry, this.lastX, this.lastY);
  }
  // The code entry under a screen point as { entry, requireMod }, across both render
  // modes, or null. Reading view carries the URL on a rendered anchor and previews on
  // plain hover; Live Preview's CM6 link span has no href (recovered from the editor at
  // those coordinates) and requires the modifier, like a link in the editor natively.
  entryAtPoint(el, x, y) {
    if (!el || !el.closest)
      return null;
    const a = el.closest("a");
    if (a && !(a.classList && a.classList.contains("internal-link"))) {
      const entry = this.entryUnderPointer(this.anchorTarget(a));
      if (entry)
        return { entry, requireMod: false };
    }
    if (el.closest(".cm-link")) {
      const view = typeof EditorView.findFromDOM === "function" ? EditorView.findFromDOM(el) : this.activeCm();
      const ref = view && this.codeRefAt(view, x, y);
      if (ref) {
        const entry = this.entryUnderPointer(ref.target);
        if (entry)
          return { entry, requireMod: true };
      }
    }
    return null;
  }
  // The CM6 EditorView of the active Markdown editor, used as a fallback when
  // EditorView.findFromDOM isn't available to map a point to its editor.
  activeCm() {
    const mv = this.app.workspace.getActiveViewOfType(MarkdownView);
    return mv && mv.editor && mv.editor.cm;
  }
  // Resolve a hovered link's display name + target to an index entry, or null
  // (so non-code links — a wiki link, a web link, a custom Unity-scene link —
  // simply show nothing). The entry's relative path must appear in the target,
  // which every preset embeds via {path}/{abs}; that rejects unrelated links even
  // when their text matches a symbol name. Ties are broken by the line in the
  // target, preferring a declaration over the bare file entry.
  entryUnderPointer(target) {
    const { url } = splitTarget(target);
    if (!url)
      return null;
    const rel = this.targetIndexedFile(this.decodeTarget(url));
    const entries = rel ? (this.fileCache.get(rel) || { entries: [] }).entries : [];
    if (!entries.length)
      return null;
    const m = LINE_RE.exec(url);
    if (!m)
      return entries[0];
    const line = parseInt(m[1], 10);
    return entries.find((e) => e.line === line && e.kind !== "file") || { name: entries[0].name, path: rel, line, kind: "line", lang: entries[0].lang };
  }
  // CM6 link handler for Live Preview. Suppresses Obsidian's open of the literal
  // {root} URL; opens the resolved one on click/auxclick. Returns true when handled.
  onEditorLink(evt, view, open) {
    if (evt.button !== 0 && evt.button !== 1)
      return false;
    const uri = this.rootUriAt(evt, view);
    if (!uri)
      return false;
    evt.preventDefault();
    evt.stopPropagation();
    if (open)
      window.open(uri);
    return true;
  }
  // The markdown link at screen coords in Live Preview, as { name, target }. The
  // rendered span has no href, so map the coords to a document position and read it.
  codeRefAt(view, x, y) {
    if (typeof view.posAtCoords !== "function")
      return null;
    const offset = view.posAtCoords({ x, y });
    if (offset == null)
      return null;
    const line = view.state.doc.lineAt(offset);
    const ch = offset - line.from;
    const re = linkRegex();
    let m;
    while (m = re.exec(line.text)) {
      if (ch < m.index || ch > m.index + m[0].length)
        continue;
      return { name: m[1], target: m[2].trim() };
    }
    return null;
  }
  // The link under the click resolved, if the token it carries is ours — else null, so a
  // plain link falls through to Obsidian's own opener and the other linker's link falls
  // through to that plugin. Both register a highest-precedence handler, so each has to
  // claim only its own; otherwise the winner comes down to which plugin loaded first.
  rootUriAt(evt, view) {
    const el = evt.target;
    if (!el || !el.closest || !el.closest(".cm-link"))
      return null;
    const ref = this.codeRefAt(view, evt.clientX, evt.clientY);
    if (!ref)
      return null;
    const { url, title } = splitTarget(ref.target);
    const claimLegacy = this.legacyRootIsOurs(url, title);
    return ownsRootToken(url, OWNER, claimLegacy) ? this.fillRoot(url, claimLegacy) : null;
  }
  // Absolute base folder the scan paths are resolved against.
  codeRoot() {
    if (this.settings.codeRoot)
      return this.settings.codeRoot;
    const adapter = this.app.vault.adapter;
    const base = adapter && typeof adapter.getBasePath === "function" ? adapter.getBasePath() : "";
    return base ? nodePath.dirname(base) : "";
  }
  // Vault-relative, normalized path of the custom languages file (or "" if unset).
  languagesFilePath() {
    const raw = (this.settings.languagesFile || "").trim();
    return raw ? normalizePath(raw) : "";
  }
  cacheFilePath() {
    return normalizePath(`${this.manifest.dir}/index-cache.json`);
  }
  // A fingerprint of what the scan would produce: enabled languages, their
  // extensions and patterns. When it changes, the per-file entry cache is stale
  // even if file mtimes haven't moved (e.g. a regex was edited), so we drop it.
  indexSignature() {
    const enabled = new Set(this.settings.enabledLanguages || []);
    const parts = [];
    for (const lang of this.languages) {
      if (!enabled.has(lang.id))
        continue;
      const pats = lang.patterns.map((p) => [p.regex.source, p.regex.flags, p.kind, p.kindGroup, p.nameGroup]);
      parts.push([lang.id, lang.extensions, pats]);
    }
    return JSON.stringify([this.settings.maxFileSizeKb, parts]);
  }
  async loadCache() {
    try {
      const p = this.cacheFilePath();
      if (!await this.app.vault.adapter.exists(p))
        return;
      const data = JSON.parse(await this.app.vault.adapter.read(p));
      if (!data || data.version !== 1 || !data.files)
        return;
      this.cacheSignature = data.signature || "";
      this.fileCache = new Map(Object.entries(data.files));
      this.setIndex(this.flattenCache());
    } catch (e) {
    }
  }
  async saveCache() {
    try {
      const files = {};
      for (const [rel, v] of this.fileCache.entries())
        files[rel] = v;
      const data = { version: 1, signature: this.cacheSignature, files };
      await this.app.vault.adapter.write(this.cacheFilePath(), JSON.stringify(data));
    } catch (e) {
    }
  }
  flattenCache() {
    const out = [];
    for (const v of this.fileCache.values())
      for (const e of v.entries)
        out.push(e);
    out.sort((a, b) => a.name.localeCompare(b.name) || a.path.localeCompare(b.path));
    return out;
  }
  // Set the index and its name lookup together. byName groups entries by lowercased
  // name so resolving a link/symbol scans only the same-named entries, not the whole
  // index (the hot paths — hover, stale marks, embeds — call this per event).
  setIndex(entries) {
    this.index = entries;
    this.byName = /* @__PURE__ */ new Map();
    this.kinds = /* @__PURE__ */ new Set();
    for (const e of entries) {
      const k = e.name.toLowerCase();
      const a = this.byName.get(k);
      if (a)
        a.push(e);
      else
        this.byName.set(k, [e]);
      this.kinds.add(e.kind);
    }
  }
  // Index entries whose (lowercased) name equals `name` — the candidate set a bare
  // symbol resolves against.
  entriesByName(name) {
    return this.byName.get(String(name).toLowerCase()) || [];
  }
  // An inline filter token as a language id: its id, an extension without the dot
  // (`py` -> `.py`), or its lower-cased name. Custom languages match for free.
  resolveLangToken(token) {
    const tok = String(token || "").toLowerCase();
    const l = tok && this.languages.find((l2) => l2.id === tok || l2.name.toLowerCase() === tok || l2.extensions.includes("." + tok));
    return l ? l.id : null;
  }
  // Every way an entry can be addressed, built once: the suggest asks per entry over the whole
  // index. `sym:` is worth having despite matching what a bare name does, because it is the
  // only way to ask for a symbol whose own name is a language or kind token.
  // `pinFrom` reads an anchor's value off a spot in a file rather than off an index entry,
  // because that is what this plugin pins from: `store` goes into the title, `show` is what the
  // menu says it pinned to. Null when the anchor can't be met there.
  buildFacets() {
    const decl = (site) => this.declAtSite(site);
    return [
      { name: "lang", typed: VALUE, resolve: (t2) => this.resolveLangToken(t2), of: (e) => e.lang },
      {
        name: "kind",
        typed: VALUE,
        resolve: (t2) => this.kinds.has(t2) ? t2 : null,
        of: (e) => e.kind,
        anchor: "kind",
        pinFrom: (site) => {
          const d = decl(site);
          return d && d.kind ? { store: d.kind, show: d.kind } : null;
        }
      },
      {
        name: "sym",
        typed: TOKEN,
        of: (e) => e.name,
        anchor: "sym",
        pinFrom: (site) => {
          const d = decl(site);
          return d ? { store: d.name, show: d.name } : null;
        }
      },
      {
        name: "line",
        anchor: "line",
        // A blank line hashes to nothing the index keeps, so that pin is broken at birth.
        pinFrom: (site) => site.text.trim() ? { store: hashLine(site.text), show: String(site.line) } : null
      }
    ];
  }
  pinnable(anchor) {
    return this.facets().find((f) => f.anchor === anchor && f.pinFrom) || null;
  }
  facets() {
    if (!this.queryFacets)
      this.queryFacets = this.buildFacets();
    return this.queryFacets;
  }
  // The container is a suffix of the name rather than a prefix of the query, so it is read
  // here and not by the shared grammar: "Foo.bar" is bar declared beside Foo.
  parseQuery(raw) {
    const q = facets.parseQuery(raw, this.facets());
    const segs = q.name.split(".");
    q.name = segs[segs.length - 1];
    q.container = segs.length > 1 && segs[segs.length - 2] ? segs[segs.length - 2] : null;
    return q;
  }
  matchTextFor(e, f) {
    return facets.matchText(e, f, this.facets());
  }
  entriesForQuery(f) {
    return facets.entriesFor(this, f, this.facets());
  }
  // Whether an entry passes a parsed inline filter (the caller matches the name). A
  // container must be declared in the same file — its class name stands in for the path.
  entryPassesFilter(e, f) {
    if (!facets.passes(e, f, this.facets()))
      return false;
    if (f.container) {
      const v = this.fileCache.get(e.path);
      const lc = f.container.toLowerCase();
      if (!v || !v.entries.some((x) => x !== e && x.name.toLowerCase() === lc))
        return false;
    }
    return true;
  }
  // Decode a link target and return { dec, cand }: the decoded string and the entries
  // whose display name matches and whose path appears in it — the shared first step of
  // resolving a link. Callers apply their own tie-break (hover uses the stored line,
  // actualization must not).
  // A link url as a plain comparable path string: {root} filled in, percent-escapes
  // undone, backslashes normalised.
  decodeTarget(url) {
    let dec = this.fillRoot(url);
    try {
      dec = decodeURIComponent(dec);
    } catch (e) {
    }
    return dec.split("\\").join("/");
  }
  linkCandidates(name, target) {
    const dec = this.decodeTarget(target);
    const named = this.entriesByName(name).filter((e) => e.name === name && pathInTarget(dec, e.path));
    const bestLen = named.reduce((mx, e) => Math.max(mx, e.path.length), 0);
    const cand = named.filter((e) => e.path.length === bestLen);
    return { dec, cand };
  }
  // The longest indexed file path a link target points at, or null — lets linkState tell a
  // broken link (file indexed, symbol gone) from an unrelated one. Only runs for links that
  // don't resolve, so the file scan stays off the hot path.
  targetIndexedFile(dec) {
    let best = null;
    for (const rel of this.fileCache.keys()) {
      if ((!best || rel.length > best.length) && pathInTarget(dec, rel))
        best = rel;
    }
    return best;
  }
  // Line hashes for one file, as hash -> line numbers. Kept in memory only: it's derived
  // from the file, and only files carrying a line binding are ever read, so the on-disk
  // index cache stays as small as it is.
  lineMap(rel) {
    const abs = nodePath.join(this.codeRoot(), rel);
    let stat;
    try {
      stat = fs.statSync(abs);
    } catch (e) {
      return null;
    }
    const hit = this.lineMaps.get(rel);
    if (hit && hit.mtimeMs === stat.mtimeMs)
      return hit.map;
    let text;
    try {
      text = fs.readFileSync(abs, "utf8");
    } catch (e) {
      return null;
    }
    const map = /* @__PURE__ */ new Map();
    const lines = text.split("\n");
    for (let i = 0; i < lines.length; i++) {
      if (!lines[i].trim())
        continue;
      const h = hashLine(lines[i]);
      const a = map.get(h);
      if (a)
        a.push(i + 1);
      else
        map.set(h, [i + 1]);
    }
    this.lineMaps.set(rel, { mtimeMs: stat.mtimeMs, map });
    return map;
  }
  // The indexed entries of one file.
  entriesIn(rel) {
    return rel ? (this.fileCache.get(rel) || { entries: [] }).entries : [];
  }
  lineHitsIn(rel, hash) {
    const map = rel && this.lineMap(rel);
    return map && map.get(hash) || [];
  }
  // The lines of `rel` meeting every anchor of a binding — anchors are requirements, so
  // they intersect.
  bindingHitsIn(rel, b) {
    const sets = [];
    if (b.sym)
      sets.push(this.entriesIn(rel).filter((e) => e.name === b.sym).map((e) => e.line));
    if (b.kind)
      sets.push(this.entriesIn(rel).filter((e) => e.kind === b.kind).map((e) => e.line));
    if (b.hash)
      sets.push(this.lineHitsIn(rel, b.hash));
    if (!sets.length)
      return [];
    return [...new Set(sets.reduce((a, s) => a.filter((n) => s.includes(n))))];
  }
  // What a binding says about a spot in `rel`: null when it still sits on a match,
  // { state: 'stale', line } with where it moved to, or { state: 'broken' } when nothing
  // in the file meets it any more. Judges within one file the index knows; the caller
  // decides what an unknown file means.
  bindState(rel, b, storedLine) {
    return bindStateFrom(this.bindingHitsIn(rel, b), storedLine);
  }
  // What a link's binding says, as three states. Broken is reserved for a file the index
  // *has* whose binding is truly gone — never for a file it doesn't know (wrong code root,
  // an unindexed folder, a moved file). An unknown file is judged silently: stale if the
  // binding turns up elsewhere, else no verdict at all, so nothing is marked on a guess.
  urlBindState(url, b, storedLine) {
    const dec = this.decodeTarget(url);
    const rel = this.targetIndexedFile(dec);
    const here = rel ? this.bindState(rel, b, storedLine) : null;
    if (here && here.state === "stale")
      return here;
    if (here && here.state === "broken")
      return this.movedBindState(url, dec, b, rel, storedLine) || here;
    if (!rel)
      return this.movedBindState(url, dec, b, null, storedLine);
    return here;
  }
  // Where a link's code moved to, as a stale state carrying the rewritten url, or null when
  // there's no confident move. Reported only when fixable: the new file must satisfy the
  // binding and the old path must be locatable in the url to rewrite.
  movedBindState(url, dec, b, fromRel, storedLine) {
    const rel2 = this.moveTarget(dec, b, fromRel);
    if (!rel2)
      return null;
    const hits = this.bindingHitsIn(rel2, b);
    if (!hits.length)
      return null;
    const oldRel = this.urlPathAnchor(url, fromRel);
    if (oldRel == null)
      return null;
    const line = hits.reduce((a, n) => Math.abs(n - storedLine) < Math.abs(a - storedLine) ? n : a);
    const rewritten = url.split(oldRel).join(rel2).replace(LINE_RE, ":" + line);
    return { state: "stale", line, url: rewritten, move: { from: oldRel, to: rel2 } };
  }
  // The one indexed file a moved binding now lives in, or null when it's ambiguous or
  // unfound. Two signals, each for a different refactor: a unique declaration of the symbol
  // (the file was renamed) or a lone file with the same basename (the file was moved).
  moveTarget(dec, b, fromRel) {
    if (b.sym) {
      const e = this.uniqueSymbolEntry(b.sym);
      if (e && e.path !== fromRel && this.bindingHitsIn(e.path, b).length)
        return e.path;
    }
    const base = (dec.split("/").pop() || "").split(/[:#?]/)[0];
    if (base) {
      const cands = [];
      for (const rel of this.fileCache.keys()) {
        if (rel !== fromRel && rel.split("/").pop() === base && this.bindingHitsIn(rel, b).length)
          cands.push(rel);
      }
      if (cands.length === 1)
        return cands[0];
    }
    return null;
  }
  // The code-root-relative path as it sits verbatim in the url, so a move can swap just that
  // run: `fromRel` when the old file is still indexed, else the run after the {root}/ or
  // path= anchor. Git permalinks never reach here (their `#L` line dodges LINE_RE), so only
  // the `:line` presets need handling. Null when it can't be located — then the move is left
  // silent rather than half-rewritten.
  urlPathAnchor(url, fromRel) {
    if (fromRel && url.includes(fromRel))
      return fromRel;
    const m = /(?:\{root\}\/|path=)(.+?)(?::\d+)?$/.exec(url);
    return m && url.includes(m[1]) ? m[1] : null;
  }
  // The single entry a bare symbol resolves to (a declaration preferred over the file
  // entry), or null when the name spans several files (ambiguous) or is unknown.
  uniqueSymbolEntry(name) {
    const named = this.entriesByName(name);
    if (!named.length)
      return null;
    if (new Set(named.map((e) => e.path)).size > 1)
      return null;
    return named.find((e) => e.kind !== "file") || named[0];
  }
  // Extensions of currently enabled languages, used to filter watch events.
  watchedExts() {
    const enabled = new Set(this.settings.enabledLanguages || []);
    const exts = /* @__PURE__ */ new Set();
    for (const lang of this.languages) {
      if (enabled.has(lang.id))
        for (const e of lang.extensions)
          exts.add(e);
    }
    return exts;
  }
  startWatchers() {
    this.stopWatchers();
    this.watchUnsupported = false;
    if (!this.settings.autoRefresh)
      return;
    const root = this.codeRoot();
    if (!root)
      return;
    const roots = this.scanFolders().map((r) => ({ dir: nodePath.join(root, r), rel: String(r || "").split("\\").join("/").replace(/\/+$/, "") }));
    this.scanWatcher = watchTree(roots, {
      onEvent: (rel, filename) => this.onWatchEvent(rel, filename),
      // Recursive watching isn't available on Linux; the shared watcher falls back to
      // per-directory watches and tells us so, so the notice fires once.
      onUnsupported: () => {
        this.watchUnsupported = true;
        if (!this.watchUnsupportedNotified) {
          this.watchUnsupportedNotified = true;
          new Notice(t("notice.watchUnsupported"));
        }
      },
      // Keep the Linux fallback out of node_modules and the like — the same prune the scan makes.
      shouldDescend: (rel) => !underSkip(rel, parseSkip(this.settings.skipDirs))
    });
  }
  stopWatchers() {
    if (this.scanWatcher) {
      this.scanWatcher.close();
      this.scanWatcher = null;
    }
  }
  // Debounce a background rebuild on a scan-folder change. `rel` is the changed path relative
  // to the code root; skip-dir noise (node_modules) and files we don't index are dropped
  // cheaply before scheduling.
  onWatchEvent(rel, filename) {
    if (filename) {
      if (underSkip(rel, parseSkip(this.settings.skipDirs)))
        return;
      const ext = nodePath.extname(rel).toLowerCase();
      if (ext && !this.watchedExts().has(ext))
        return;
    }
    clearTimeout(this.watchTimer);
    this.watchTimer = setTimeout(() => this.rebuildIndex(false), 1500);
  }
  async loadLanguagesFile() {
    const path = this.languagesFilePath();
    this.customRaw = "";
    if (path) {
      try {
        if (await this.app.vault.adapter.exists(path)) {
          this.customRaw = await this.app.vault.adapter.read(path);
        }
      } catch (e) {
      }
    }
    this.compileLanguages();
  }
  // Write the starter languages file at the configured path (if it doesn't exist yet),
  // then load and index it. Backs the "Create file" button in settings.
  async createLanguagesFile() {
    const path = this.languagesFilePath();
    if (!path) {
      new Notice(t("notice.langFileNoPath"));
      return;
    }
    if (this.app.vault.getAbstractFileByPath(path)) {
      new Notice(t("notice.langFileExists"));
      return;
    }
    try {
      await this.app.vault.create(path, LANGUAGES_TEMPLATE);
    } catch (e) {
      new Notice(t("notice.langFileError", { error: e && e.message }));
      return;
    }
    await this.loadLanguagesFile();
    await this.rebuildIndex(false);
    new Notice(t("notice.langFileCreated", { path }));
  }
  // Open the languages file for editing. It's JSON, which Obsidian can't show in a leaf
  // (that opens a blank tab), so hand it to the OS default editor.
  openLanguagesFile() {
    const path = this.languagesFilePath();
    if (!path || !this.app.vault.getAbstractFileByPath(path))
      return;
    if (typeof this.app.openWithDefaultApp === "function") {
      this.app.openWithDefaultApp(path);
      return;
    }
    const adapter = this.app.vault.adapter;
    const base = adapter && typeof adapter.getBasePath === "function" ? adapter.getBasePath() : "";
    if (base)
      window.open("file:///" + encodeURI(nodePath.join(base, path).split(nodePath.sep).join("/")));
  }
  // Merge built-ins with the languages file, compile every regex.
  compileLanguages() {
    const merged = /* @__PURE__ */ new Map();
    for (const l of BUILTIN_LANGUAGES)
      merged.set(l.id, l);
    this.languageErrors = [];
    const raw = (this.customRaw || "").trim();
    if (raw) {
      let arr = null;
      try {
        arr = JSON.parse(raw);
      } catch (e) {
        this.languageErrors.push({ id: "(languages file)", error: "invalid JSON: " + e.message });
      }
      if (Array.isArray(arr)) {
        for (const def of arr) {
          if (!def || typeof def.id !== "string") {
            this.languageErrors.push({ id: def && def.id || "(unknown)", error: "missing string id" });
            continue;
          }
          merged.set(def.id, def);
        }
      } else if (arr != null) {
        this.languageErrors.push({ id: "(languages file)", error: "expected a JSON array" });
      }
    }
    const out = [];
    for (const def of merged.values()) {
      const extensions = Array.isArray(def.extensions) ? def.extensions.map((e) => String(e).toLowerCase()) : [];
      const patterns = [];
      for (const p of def.patterns || []) {
        try {
          patterns.push({
            regex: new RegExp(p.re, p.flags || ""),
            kind: p.kind,
            kindGroup: p.kindGroup,
            nameGroup: p.nameGroup
          });
        } catch (e) {
          this.languageErrors.push({ id: def.id, error: `bad regex: ${e.message}` });
        }
      }
      const prism = typeof def.prism === "string" ? def.prism.trim() : "";
      out.push({ id: def.id, name: def.name || def.id, extensions, patterns, prism });
    }
    this.languages = out;
  }
  // The Prism grammar id for a language id: a custom language's own `prism` field
  // wins, then the built-in mapping, then the id itself (so e.g. "rust" works when
  // Prism has it). hover.js falls back to plain text / c-like when it doesn't.
  prismIdFor(langId) {
    const lang = this.languages.find((l) => l.id === langId);
    if (lang && lang.prism)
      return lang.prism;
    return PRISM_LANG[langId] || langId;
  }
  // Empty the index (nothing to scan) and persist, telling whoever's listening.
  async resetIndex(noticeKey, notify) {
    this.setIndex([]);
    this.fileCache = /* @__PURE__ */ new Map();
    await this.saveCache();
    this.notifyIndexChange();
    if (notify)
      new Notice(t(noticeKey));
  }
  async rebuildIndex(notify) {
    this.stopWatchers();
    const root = this.codeRoot();
    if (!root) {
      if (notify)
        new Notice(t("notice.noCodeRoot"));
      return;
    }
    const roots = this.scanFolders();
    const enabled = new Set(this.settings.enabledLanguages || []);
    const byExt = /* @__PURE__ */ new Map();
    for (const lang of this.languages) {
      if (!enabled.has(lang.id))
        continue;
      for (const ext of lang.extensions) {
        if (!byExt.has(ext))
          byExt.set(ext, []);
        byExt.get(ext).push(lang);
      }
    }
    if (!byExt.size) {
      await this.resetIndex("notice.noLanguages", notify);
      return;
    }
    const signature = this.indexSignature();
    const old = signature === this.cacheSignature ? this.fileCache : /* @__PURE__ */ new Map();
    let seen = 0;
    const onFile = () => {
      if (++seen % 200 === 0)
        this.statusEl.setText(t("status.indexing", { n: seen }));
    };
    const scan = { root, byExt, skip: parseSkip(this.settings.skipDirs), old, next: /* @__PURE__ */ new Map(), onFile, gitignore: !!this.settings.useGitignore, ignores: [], sawGitignore: false };
    try {
      for (const r of roots) {
        await this.walk(nodePath.join(root, r), scan);
      }
    } catch (err) {
      this.statusEl.setText("");
      if (notify)
        new Notice(t("notice.scanFailed", { error: err && err.message }));
      return;
    }
    this.statusEl.setText("");
    this.fileCache = scan.next;
    this.cacheSignature = signature;
    this.hasGitignore = scan.sawGitignore;
    this.setIndex(this.flattenCache());
    await this.saveCache();
    this.notifyIndexChange();
    this.startWatchers();
    if (notify) {
      const missing = this.scanRootStatus().filter((st) => !st.exists).map((st) => st.rel);
      if (missing.length)
        new Notice(t("notice.missingFolders", { folders: missing.join(", ") }));
      else
        new Notice(t("notice.indexed", { entries: plural("entry", this.index.length) }));
    }
  }
  async walk(absDir, scan) {
    let items;
    try {
      items = await fsp.readdir(absDir, { withFileTypes: true });
    } catch (e) {
      return;
    }
    const mark = scan.ignores.length;
    if (items.some((it) => it.isFile() && it.name === ".gitignore")) {
      scan.sawGitignore = true;
      if (scan.gitignore) {
        let text = "";
        try {
          text = await fsp.readFile(nodePath.join(absDir, ".gitignore"), "utf8");
        } catch (e) {
        }
        const base = nodePath.relative(scan.root, absDir).split(nodePath.sep).join("/");
        for (const rule of compileGitignore(text, base))
          scan.ignores.push(rule);
      }
    }
    for (const it of items) {
      const abs = nodePath.join(absDir, it.name);
      const rel = nodePath.relative(scan.root, abs).split(nodePath.sep).join("/");
      if (it.isDirectory()) {
        if (underSkip(rel, scan.skip))
          continue;
        if (scan.gitignore && isIgnored(scan.ignores, rel, true))
          continue;
        await this.walk(abs, scan);
      } else if (it.isFile()) {
        if (scan.gitignore && isIgnored(scan.ignores, rel, false))
          continue;
        const langs = scan.byExt.get(nodePath.extname(it.name).toLowerCase());
        if (langs)
          await this.indexFile(abs, langs, scan);
      }
    }
    scan.ignores.length = mark;
  }
  async indexFile(abs, langs, scan) {
    const rel = nodePath.relative(scan.root, abs).split(nodePath.sep).join("/");
    let stat;
    try {
      stat = await fsp.stat(abs);
    } catch (e) {
      return;
    }
    if (scan.onFile)
      scan.onFile();
    const cached = scan.old.get(rel);
    if (cached && cached.mtimeMs === stat.mtimeMs) {
      scan.next.set(rel, cached);
      return;
    }
    const base = nodePath.basename(abs).replace(/\.[^.]+$/, "");
    const entries = [{ name: base, kind: "file", lang: langs[0].id, path: rel, line: 1 }];
    const maxBytes = Math.max(0, this.settings.maxFileSizeKb || 0) * 1024;
    if (!maxBytes || stat.size <= maxBytes) {
      try {
        await this.parseLines(abs, langs, rel, entries);
      } catch (e) {
      }
    }
    scan.next.set(rel, { mtimeMs: stat.mtimeMs, entries });
  }
  // Stream line by line so we never hold the whole file plus a lines[] array at
  // once; appends each declaration it finds to `entries`.
  parseLines(abs, langs, rel, entries) {
    return new Promise((resolve, reject) => {
      const stream = fs.createReadStream(abs, { encoding: "utf8" });
      const rl = readline.createInterface({ input: stream, crlfDelay: Infinity });
      let i = 0;
      rl.on("line", (line) => {
        i++;
        if (line.length > MAX_PARSE_LINE_LENGTH)
          return;
        for (const lang of langs) {
          for (const p of lang.patterns) {
            p.regex.lastIndex = 0;
            const m = p.regex.exec(line);
            if (!m)
              continue;
            let name, kind;
            if (p.kindGroup != null) {
              kind = m[p.kindGroup];
              name = m[p.nameGroup != null ? p.nameGroup : 2];
            } else {
              kind = p.kind || "type";
              name = m[p.nameGroup != null ? p.nameGroup : 1];
            }
            if (name)
              entries.push({ name, kind, lang: lang.id, path: rel, line: i });
          }
        }
      });
      rl.on("close", resolve);
      stream.on("error", reject);
    });
  }
  // An entry's absolute path on disk: the code root joined with its stored relative path.
  entryPath(e) {
    const root = this.codeRoot();
    return root ? nodePath.join(root, e.path) : e.path;
  }
  // {root} stays in the link for portability (resolved on render/click); call fillRoot()
  // when opening the URI directly. `template` overrides the default preset.
  buildUri(e, template) {
    let tpl = template || this.settings.uriTemplate;
    const absFs = this.entryPath(e);
    const absFwd = absFs.split(nodePath.sep).join("/");
    if (e.kind === "file")
      tpl = tpl.replace(LINE_TOKEN, "");
    const line = String(e.line || 1);
    const project = (e.path.split("/")[0] || "").trim();
    const jb = this.settings.jetbrainsProduct;
    const product = jb && jb !== "ask" ? jb : "idea";
    const git = GIT_PLACEHOLDER.test(tpl) ? resolveGit(absFs) : null;
    const relPath = git ? nodePath.relative(git.repoRoot, absFs).split(nodePath.sep).join("/") : e.path;
    const encPath = (p) => p.split("/").map(encodeURIComponent).join("/");
    return tpl.replace(/{abs}/g, encodeURI(absFwd)).replace(/{path}/g, encPath(relPath)).replace(/{line}/g, line).replace(/{name}/g, encodeURIComponent(e.name)).replace(/{project}/g, encodeURIComponent(project)).replace(/{(?:jetbrainsProduct|product)}/g, product).replace(/{gitRemote}/g, git ? git.remote : "").replace(/{gitSha}/g, git ? git.sha : "").replace(/{gitBranch}/g, git ? git.branch || git.sha : "");
  }
  // True (and warns) when a permalink preset has no git repo to fill {remote}/{sha}.
  gitTemplateBlocked(e, template) {
    if (!GIT_PLACEHOLDER.test(template || this.settings.uriTemplate))
      return false;
    if (resolveGit(this.entryPath(e)))
      return false;
    new Notice(t("notice.noGit"));
    return true;
  }
  // The markdown link to insert: a plain markdown link, nothing more. Tracking is opt-in
  // — pin the link when you want it, the same way an embed only tracks once you give it a
  // bind: line. Inside a table cell a literal pipe splits the row.
  buildLink(e, inTable, template) {
    const link = `[${e.name}](${this.buildUri(e, template)})`;
    return inTable ? link.replace(/\|/g, "\\|") : link;
  }
  pickEntry(onChoose, query) {
    new CodeLinkModal(this.app, this, { onChoose, query }).open();
  }
  pickPinAnchors(run) {
    new PinAnchorModal(this.app, run).open();
  }
  insertLink(editor, e, template) {
    if (this.gitTemplateBlocked(e, template))
      return;
    const inTable = inTableCell(editor.getValue(), editor.posToOffset(editor.getCursor("from")));
    editor.replaceSelection(this.buildLink(e, inTable, template));
  }
  // The ```code-link block bodies offered for an entry: a unique symbol embeds by name
  // (so it tracks the declaration as code moves), plus precise by-line and by-range forms.
  // A range shows a window of code; add a `context: N` line by hand to pad the others.
  embedFormats(e) {
    const line = e.line || 1;
    if (e.kind === "file")
      return [{ label: t("embed.fmt.file"), body: e.path }];
    const out = [];
    if (this.uniqueSymbolEntry(e.name))
      out.push({ label: t("embed.fmt.symbol"), body: e.name });
    out.push({ label: t("embed.fmt.line", { line }), body: e.path + ":" + line });
    out.push({ label: t("embed.fmt.range", { from: line, to: line + 10 }), body: e.path + ":" + line + "-" + (line + 10) });
    return out;
  }
  insertEmbed(editor, e) {
    const formats = this.embedFormats(e);
    new PresetPickerModal(this.app, formats, (f) => {
      editor.replaceSelection("```code-link\n" + f.body + "\n```\n");
    }, t("modal.embedPlaceholder")).open();
  }
  // The selectable presets — built-ins then the user's own — as { key, label, template },
  // where key is the value the settings dropdown stores ('u:<i>' for a user editor).
  editorPresets() {
    const out = [
      { key: "file", label: t("set.preset.file"), template: PRESETS.file, builtin: true },
      { key: "vscode", label: t("set.preset.vscode"), template: PRESETS.vscode, builtin: true },
      { key: "jetbrains", label: t("set.preset.jetbrains"), template: PRESETS.jetbrains, builtin: true },
      { key: "github", label: t("set.preset.github"), template: PRESETS.github, builtin: true },
      { key: "gitlab", label: t("set.preset.gitlab"), template: PRESETS.gitlab, builtin: true }
    ];
    (this.settings.editors || []).forEach((e, i) => out.push({ key: "u:" + i, label: e.name || `Editor ${i + 1}`, template: e.template, builtin: false }));
    return out;
  }
  // Presets offered in the pickers: the visible ones (hiding everything falls back to all),
  // most-recently-used first. Custom editors are always shown.
  visiblePresets() {
    const hidden = new Set(this.settings.hiddenPresets || []);
    const all = this.editorPresets();
    const shown = all.filter((p) => !hidden.has(p.key));
    const mru = this.settings.recentPresets || [];
    const rank = (p) => {
      const i = mru.indexOf(p.key);
      return i === -1 ? Infinity : i;
    };
    return (shown.length ? shown : all).map((p, i) => ({ p, i })).sort((a, b) => rank(a.p) - rank(b.p) || a.i - b.i).map((x) => x.p);
  }
  recordRecentPreset(key) {
    const mru = (this.settings.recentPresets || []).filter((k) => k !== key);
    mru.unshift(key);
    this.settings.recentPresets = mru.slice(0, 8);
    this.saveSettings();
  }
  // Runs once: GitHub/GitLab ship hidden and unhide only if the code root's remote is on
  // that host, so you don't scroll past a permalink preset for a service you don't use.
  initPresetVisibility() {
    if (this.settings.presetsInitialized)
      return;
    this.settings.presetsInitialized = true;
    const git = resolveGitDir(this.codeRoot());
    const host = git ? (git.remote.match(/^https:\/\/([^/]+)/) || [])[1] || "" : "";
    const hidden = new Set(this.settings.hiddenPresets || []);
    if (/github/i.test(host))
      hidden.delete("github");
    if (/gitlab/i.test(host))
      hidden.delete("gitlab");
    this.settings.hiddenPresets = [...hidden];
    this.saveSettings();
  }
  updateStatusBar() {
    const el = this.editorStatusEl;
    if (!el)
      return;
    if (!this.settings.showStatusBar) {
      el.hide();
      return;
    }
    const p = this.editorPresets().find((x) => x.template === this.settings.uriTemplate);
    const name = this.settings.askOnInsert ? t("set.preset.ask") : p ? p.label : this.settings.uriTemplate;
    el.show();
    el.setText(t("status.editor", { name }));
  }
  usesProduct(template) {
    return PRODUCT_PLACEHOLDER.test(template || "");
  }
  applyProduct(template, code) {
    return template.replace(/{(?:jetbrainsProduct|product)}/g, code);
  }
  productLabel(code) {
    if (code === "ask")
      return t("set.preset.ask");
    const p = JETBRAINS_PRODUCTS.find(([key]) => key === code);
    return p ? p[1] : code;
  }
  // Pick a JetBrains IDE, then done(code). `allowAsk` adds an "Always ask" choice, so a
  // fixed preset can be told to prompt for the IDE on every insert.
  pickProduct(allowAsk, done) {
    const items = JETBRAINS_PRODUCTS.map(([key, label]) => ({ key, label }));
    if (allowAsk)
      items.unshift({ key: "ask", label: t("set.preset.ask") });
    new PresetPickerModal(this.app, items, (p) => done(p.key), t("modal.productPlaceholder")).open();
  }
  // Pick a preset; one whose template has a product placeholder then picks the IDE. Calls
  // done(preset, code) — code is null without a product placeholder, else the IDE (or 'ask').
  pickPreset(items, placeholder, done, allowAsk) {
    new PresetPickerModal(this.app, items, (p) => {
      if (!this.usesProduct(p.template))
        return done(p, null);
      this.pickProduct(allowAsk, (code) => done(p, code));
    }, placeholder).open();
  }
  // Always-ask mode picks the format (and IDE) per insert; a fixed preset still prompts for
  // the IDE when the JetBrains-IDE setting is "Always ask".
  withFormat(ask, run) {
    if (ask) {
      this.pickPreset(this.visiblePresets(), t("modal.formatPlaceholder"), (p, code) => {
        this.recordRecentPreset(p.key);
        run(code ? this.applyProduct(p.template, code) : p.template);
      }, false);
      return;
    }
    const tpl = this.settings.uriTemplate;
    if (this.usesProduct(tpl) && this.settings.jetbrainsProduct === "ask") {
      this.pickProduct(false, (code) => run(this.applyProduct(tpl, code)));
      return;
    }
    run(void 0);
  }
  // Switch the default preset (or "Always ask") without opening settings; a product preset
  // also sets the JetBrains-IDE setting, which may itself be "Always ask".
  switchPreset() {
    const items = this.visiblePresets().concat({ key: "ask", label: t("set.preset.ask") });
    this.pickPreset(items, t("modal.switchPlaceholder"), async (p, code) => {
      this.settings.askOnInsert = p.key === "ask";
      if (p.key !== "ask") {
        this.settings.uriTemplate = p.template;
        if (code)
          this.settings.jetbrainsProduct = code;
        this.recordRecentPreset(p.key);
      }
      await this.saveSettings();
      new Notice(t("notice.editorSet", { name: code ? this.productLabel(code) : p.label }));
    }, true);
  }
  // Resolve {root} to the absolute code root: a copied link is usually pasted outside
  // the vault (a browser, a terminal), where the portable {root} token wouldn't resolve.
  // Inserted links keep {root} for note portability.
  async activateIndexView() {
    const { workspace } = this.app;
    let leaf = workspace.getLeavesOfType(INDEX_VIEW_TYPE)[0];
    if (!leaf) {
      leaf = workspace.getRightLeaf(false);
      if (!leaf)
        return;
      await leaf.setViewState({ type: INDEX_VIEW_TYPE, active: true });
    }
    workspace.revealLeaf(leaf);
  }
  applyRibbonIcon() {
    const want = this.settings.showRibbonIcon;
    if (want && !this.ribbonEl) {
      this.ribbonEl = this.addRibbonIcon("file-code", t("ribbon.tooltip"), () => this.activateIndexView());
    } else if (!want && this.ribbonEl) {
      this.ribbonEl.remove();
      this.ribbonEl = null;
    }
  }
  copyLink(e, template) {
    if (this.gitTemplateBlocked(e, template))
      return;
    navigator.clipboard.writeText(this.fillRoot(this.buildLink(e, false, template)));
    new Notice(t("notice.copied"));
  }
  // fillRoot resolves the portable {root} token, since there's no note to render it.
  openEntry(e, template) {
    window.open(this.fillRoot(this.buildUri(e, template)));
  }
  // Entries matched by name, or by path tail so a selected "Foo/Bar.cs" resolves too.
  lookup(text) {
    const q = text.trim();
    if (!q)
      return [];
    const lc = q.toLowerCase();
    const norm = lc.split("\\").join("/");
    const out = [];
    for (const e of this.index) {
      const p = e.path.toLowerCase();
      if (e.name.toLowerCase() === lc || p === norm || p.endsWith("/" + norm))
        out.push(e);
    }
    return out;
  }
  selectionOrWord(editor) {
    const sel = editor.getSelection();
    if (sel)
      return { text: sel, from: editor.getCursor("from"), to: editor.getCursor("to") };
    const cur = editor.getCursor();
    const line = editor.getLine(cur.line);
    const isWord = (ch) => ch && /[\w./\\-]/.test(ch);
    let s = cur.ch, en = cur.ch;
    while (s > 0 && isWord(line[s - 1]))
      s--;
    while (en < line.length && isWord(line[en]))
      en++;
    const text = line.slice(s, en);
    return text ? { text, from: { line: cur.line, ch: s }, to: { line: cur.line, ch: en } } : null;
  }
  // The selection/word to act on, or null when it makes no sense there. Never inside an
  // existing link (both actions). For `write` (convert-to-link) also never inside code or
  // frontmatter, where inserting a link would corrupt the sample; opening code from there
  // is harmless, so read-only actions are allowed.
  selectionTarget(editor, write) {
    const target = this.selectionOrWord(editor);
    if (!target)
      return null;
    const text = editor.getValue();
    const off = editor.posToOffset(target.from);
    if (inLink(text, off))
      return null;
    if (write && inCode(text, off))
      return null;
    return target;
  }
  // The markdown link spanning the editor cursor, as { name, target, line, from, to }
  // (character offsets within the line), or null. Right-click puts the cursor on the
  // click, so this reads the link that was clicked.
  codeLinkAtCursor(editor) {
    const cur = editor.getCursor();
    const line = editor.getLine(cur.line);
    const re = linkRegex();
    let m;
    while (m = re.exec(line)) {
      if (cur.ch >= m.index && cur.ch <= m.index + m[0].length) {
        return { name: m[1], target: m[2], line: cur.line, from: m.index, to: m.index + m[0].length };
      }
    }
    return null;
  }
  fixLinkAtCursor(editor, link) {
    const target = this.actualizedTarget(link.target);
    if (target == null) {
      new Notice(t("notice.linksUpdated", { n: 0 }));
      return;
    }
    editor.replaceRange("[" + link.name + "](" + target + ")", { line: link.line, ch: link.from }, { line: link.line, ch: link.to });
    new Notice(t("notice.linksUpdated", { n: 1 }));
  }
  // Whether a markdown link is one of ours rather than a wiki or web link: its url points at
  // an indexed file, or it carries one of our bindings. A moved file points nowhere indexed
  // but is still ours; a binding only uses our tokens, so it won't match a reader's tooltip.
  isCodeLink(target) {
    const { url, title } = splitTarget(target);
    return !!url && (!!parseBinding(title) || !!this.targetIndexedFile(this.decodeTarget(url)));
  }
  // A link's file and stored line as { rel, line, text }, or null when it doesn't point
  // into an indexed file or the line is past its end. `text` is that line's contents —
  // what a line binding hashes.
  linkSite(target) {
    const { url } = splitTarget(target);
    const m = url && LINE_RE.exec(url);
    if (!m)
      return null;
    const rel = this.targetIndexedFile(this.decodeTarget(url));
    const line = parseInt(m[1], 10);
    const text = rel && this.lineTextAt(rel, line);
    return text == null ? null : { rel, line, text };
  }
  // One line's text straight from disk, or null when the file or the line isn't there.
  lineTextAt(rel, line) {
    let text;
    try {
      text = fs.readFileSync(nodePath.join(this.codeRoot(), rel), "utf8");
    } catch (e) {
      return null;
    }
    const lines = text.split("\n");
    return line >= 1 && line <= lines.length ? lines[line - 1] : null;
  }
  // Where a ```code-link block's window has drifted, for the preview and the rewrite:
  // { state:'stale', path, from, to, out } with the body brought up to date, or
  // { state:'broken', path } when the binding is lost, or null when there's nothing to
  // judge or it's still current. Only the numbers move: the path is written the way the
  // reader wrote it (a tail like "http-client.ts" resolves fine), and a range keeps length.
  embedDrift(body) {
    const spec = parseSpec(body.join("\n"));
    const b = parseBinding(spec.bind);
    if (!b || spec.lines)
      return null;
    const pr = splitPathRange(spec.target);
    if (!pr)
      return null;
    const rel = resolvePath(this, pr.path);
    const d = this.bindState(rel, b, pr.from);
    if (!d)
      return null;
    if (d.state === "broken")
      return this.fileCache.has(rel) ? { state: "broken", path: pr.path } : null;
    const moved = pr.path + ":" + d.line + (pr.single ? "" : "-" + (pr.to + d.line - pr.from));
    const out = body.map((l) => l.trim() === spec.target ? l.replace(spec.target, moved) : l);
    return { state: "stale", path: pr.path, from: pr.from, to: d.line, out };
  }
  // What sits on a spot's line: a declaration, or the file's own entry at the top of the
  // file. The file entry counts — `sym:Player` is satisfied by Player.cs as much as by
  // class Player, so refusing to offer that pin would make the menu disagree with the marks.
  declAtSite(site) {
    const here = this.entriesIn(site.rel).filter((e) => e.line === site.line);
    return here.find((e) => e.kind !== "file") || here[0];
  }
  // What one pin would do: the title it'd produce and the value it pins to, for the menu
  // to show. Anchors add up rather than replace, so pinning symbol then kind narrows the
  // same spot. Null when there's nothing to pin to, or when it would change nothing.
  pinOption(site, current, anchor) {
    const f = site && this.pinnable(anchor);
    const got = f && f.pinFrom(site);
    if (!got)
      return null;
    const next = Object.assign({}, parseBinding(current));
    next[ANCHORS[anchor]] = got.store;
    const title = formatBinding(next);
    return title === (current || "") ? null : { title, value: got.show, site };
  }
  linkPinOption(link, anchor) {
    return this.pinOption(this.linkSite(link.target), splitTarget(link.target).title, anchor);
  }
  // A binding title for a bulk pin over `site`, from the chosen anchors. They intersect,
  // so symbol + line pins to the exact declaration and won't repin to a same-named one.
  // Null when an anchor can't be met: no declaration for sym/kind, or a blank line for
  // line — a blank line hashes to nothing the index keeps, so that pin is broken at birth.
  buildPinTitle(site, anchors) {
    if (!site)
      return null;
    const b = {};
    for (const f of this.facets()) {
      if (!f.pinFrom || !anchors[f.anchor])
        continue;
      const got = f.pinFrom(site);
      if (!got)
        return null;
      b[ANCHORS[f.anchor]] = got.store;
    }
    return Object.keys(b).length ? formatBinding(b) : null;
  }
  // The spot a ```code-link block's window is frozen at — the same shape linkSite gives,
  // so an embed pins through exactly the code a link does.
  embedSite(spec) {
    const pr = splitPathRange(spec.target);
    if (!pr || spec.lines)
      return null;
    const rel = resolvePath(this, pr.path);
    const text = this.lineTextAt(rel, pr.from);
    return text == null ? null : { rel, line: pr.from, text };
  }
  pinLink(editor, link, anchor) {
    const p = this.linkPinOption(link, anchor);
    if (!p) {
      new Notice(t("notice.cantBind"));
      return;
    }
    this.retitleLink(editor, link, p.title);
    new Notice(t("notice.bound", { line: p.site.line }));
  }
  // Drop a link's binding. Nothing tracks it, nothing marks it, nothing rewrites it — it
  // goes back to being an ordinary markdown link that happens to point at code.
  unbindLink(editor, link) {
    this.retitleLink(editor, link, "");
    new Notice(t("notice.unbound"));
  }
  linkAtCursorBound(link) {
    return !!parseBinding(splitTarget(link.target).title);
  }
  retitleLink(editor, link, title) {
    const { url } = splitTarget(link.target);
    const out = "[" + link.name + "](" + withTitle(url, title) + ")";
    editor.replaceRange(out, { line: link.line, ch: link.from }, { line: link.line, ch: link.to });
  }
  // One of the two selection verbs. The builder decides whether it ends up under the verb
  // or on its own; the wording follows, since inside the submenu the verb is already named.
  selectionItem(menu, kind, icon, run) {
    menu.tagged(kind, {}, (item, grouped) => item.setTitle(t("menu." + kind + (grouped ? ".item" : ".solo"))).setIcon(icon).onClick(run));
  }
  // Whether the link under the cursor is ours to act on. Recognising it isn't enough: the
  // reference linker recognises a file both indexes cover just as readily, and two Copy and
  // two Unpin items on one link tell the reader nothing about which is which.
  ownsLinkAtCursor(link) {
    if (!this.isCodeLink(link.target))
      return false;
    const provider = this.api && this.api.linker;
    if (!provider)
      return true;
    return ownsLink(this.app, provider, link.target);
  }
  // The pins, in a submenu: they're a set, and they'd crowd the menu otherwise. Each is
  // labelled with what it would pin to — "symbol" and "kind" mean nothing until you see
  // Player and class. menuSection handles the older builds where submenus don't exist.
  addPinItems(menu, option, run) {
    const opts = ["sym", "kind", "line"].map((a) => [a, option(a)]).filter(([, o]) => o);
    if (!opts.length)
      return;
    const group = menuSection(menu, t("menu.pin"), true);
    for (const [a, o] of opts) {
      group.addItem((i) => i.setTitle(t("menu.pin." + a, { value: o.value })).setIcon("pin").onClick(() => run(a)));
    }
  }
  // A right-click item on the code link under the cursor, mirrored into the palette so
  // every one of them is reachable without the mouse. `can` gates both.
  addLinkCommand(id, name, can, run) {
    this.addCommand({
      id,
      name,
      editorCheckCallback: (checking, editor) => {
        const link = this.codeLinkAtCursor(editor);
        if (!link || !this.ownsLinkAtCursor(link) || !can(link))
          return false;
        if (!checking)
          run(editor, link);
        return true;
      }
    });
  }
  // Insert a link to a chosen line of a chosen file — for pointing at something the index
  // has no name for. Like any insert it leaves the link unbound; pin it to track it.
  insertLineLink(editor, template) {
    this.pickEntry((e) => new LinePromptModal(this.app, e.line || 1, (line) => {
      const at = Object.assign({}, e, { line, kind: e.kind === "file" ? "line" : e.kind });
      const link = "[" + e.name + ":" + line + "](" + this.buildUri(at, template) + ")";
      const inTable = inTableCell(editor.getValue(), editor.posToOffset(editor.getCursor("from")));
      editor.replaceSelection(inTable ? link.replace(/\|/g, "\\|") : link);
    }).open());
  }
  // Copy the clicked link's own target ({root} filled in), keeping the scheme it was
  // saved with — unlike copyLink, which builds a fresh link from the default preset.
  copyLinkAtCursor(link) {
    navigator.clipboard.writeText(this.fillRoot(splitTarget(link.target).url));
    new Notice(t("notice.copied"));
  }
  // Run the selected (or under-cursor) token through the index: a single match runs
  // `action`, several open the picker, none notifies. `write` gates the protected-range
  // check (convert may not run in code; open may).
  resolveSelection(editor, action, write) {
    const target = this.selectionTarget(editor, write);
    if (!target) {
      new Notice(t("notice.noSelection"));
      return;
    }
    const matches = this.lookup(target.text);
    if (!matches.length) {
      new Notice(t("notice.noMatch", { query: target.text }));
      return;
    }
    const run = (e) => action(e, target);
    if (matches.length === 1)
      run(matches[0]);
    else
      this.pickEntry(run, target.text);
  }
  convertSelection(editor) {
    this.resolveSelection(editor, (e, target) => this.withFormat(this.settings.askOnInsert, (template) => {
      const inTable = inTableCell(editor.getValue(), editor.posToOffset(target.from));
      editor.replaceRange(this.buildLink(e, inTable, template), target.from, target.to);
    }), true);
  }
  openSelection(editor) {
    this.resolveSelection(editor, (e) => this.withFormat(this.settings.askOnInsert, (template) => this.openEntry(e, template)), false);
  }
  // Folders to scan, relative to the code root; empty means the whole code root.
  scanFolders() {
    const roots = splitLines(this.settings.scanRoots);
    return roots.length ? roots : ["."];
  }
  scanRootStatus() {
    const root = this.codeRoot();
    return this.scanFolders().map((rel) => ({
      rel,
      exists: !!root && fs.existsSync(nodePath.join(root, rel))
    }));
  }
  async saveSettings() {
    await this.saveData(this.settings);
    this.updateStatusBar();
  }
};
Object.assign(CodeLinkerPlugin.prototype, api, indexEvents);
Object.assign(CodeLinkerPlugin.prototype, actualize.methods);
module.exports = CodeLinkerPlugin;

/* nosourcemap */
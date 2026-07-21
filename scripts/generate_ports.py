#!/usr/bin/env python3
"""Generate application ports from dist/stargazing.json and vetted templates."""
from __future__ import annotations
import json, os, re, shutil, zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PALETTE_ROOT = Path(os.environ.get("STARGAZING_PALETTE_ROOT", ROOT.parent / "stargazing")).expanduser()
DATA = json.loads((PALETTE_ROOT / "dist/stargazing.json").read_text())
SPEC = json.loads((PALETTE_ROOT / "src/palette.json").read_text())
PORTS = ROOT / "ports"
TEMPLATES = ROOT / "templates"
STEPS = ["paper","50","100","150","200","300","400","500","600","700","800","850","900","950","black"]


def reset(path: Path):
    if path.exists(): shutil.rmtree(path)
    path.mkdir(parents=True)


def hexes(slug: str) -> dict[str,str]:
    return {k:v["hex"] for k,v in DATA["themes"][slug]["base"].items()}


def accents() -> dict[str,dict[str,str]]:
    return {n:{k:v["hex"] for k,v in shades.items()} for n,shades in DATA["accents"].items()}

A = accents()
REF = SPEC["baseReference"]


def replace_base(text: str, slug: str) -> str:
    values = hexes(slug)
    for key in STEPS:
        text = re.sub(re.escape(REF[key]), values[key], text, flags=re.I)
        text = re.sub(rf"(?<![0-9a-f]){re.escape(REF[key][1:])}(?![0-9a-f])", values[key][1:], text, flags=re.I)
    return text


def semantic(slug: str, mode: str) -> dict[str,str]:
    b = hexes(slug)
    if mode == "light":
        out = dict(bg=b["paper"], bg2=b["50"], ui=b["100"], ui2=b["150"], ui3=b["200"], tx3=b["300"], tx2=b["600"], tx=b["black"])
        level = "600"
    else:
        out = dict(bg=b["black"], bg2=b["950"], ui=b["900"], ui2=b["850"], ui3=b["800"], tx3=b["700"], tx2=b["500"], tx=b["200"])
        level = "400"
    out.update({n:A[n][level] for n in A})
    return out


def name(slug: str) -> str: return DATA["themes"][slug]["name"]


def write(path: Path, text: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.rstrip()+"\n")


def write_zip(path: Path, files: dict[str, bytes]):
    """Write a byte-for-byte stable archive with fixed metadata."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name in sorted(files):
            info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, files[name])


# Wallpaper HEIC files are binary artwork generated from the approved engraving,
# not palette templates. Preserve them while rebuilding every textual port.
wallpaper_files = {
    path.name: path.read_bytes()
    for path in (PORTS / "wallpaper").glob("*.heic")
} if (PORTS / "wallpaper").exists() else {}
reset(PORTS)
for filename, data in wallpaper_files.items():
    path = PORTS / "wallpaper" / filename
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)

for slug in DATA["themes"]:
    b = hexes(slug)
    for mode in ("light", "dark"):
        c = semantic(slug, mode)
        suffix = f"{slug}-{mode}"
        title = f"Stargazing {name(slug)} {mode.title()}"

        # Ghostty
        ansi = [b["900"], c["red"], c["green"], c["yellow"], c["blue"], c["magenta"], c["cyan"], b["100"] if mode=="light" else b["200"],
                b["600"] if mode=="light" else b["500"], A["red"]["400"], A["green"]["400"], A["yellow"]["400"], A["blue"]["400"], A["magenta"]["400"], A["cyan"]["400"], b["paper"] if mode=="light" else b["200"]]
        ghost = [f"# {title}",f"background = {c['bg']}",f"foreground = {c['tx']}",f"cursor-color = {c['tx']}",f"cursor-text = {c['bg']}",f"selection-background = {c['ui3']}",f"selection-foreground = {c['tx']}"] + [f"palette = {i}={v}" for i,v in enumerate(ansi)]
        write(PORTS/f"ghostty/{suffix}", "\n".join(ghost))

        # Template-derived ports
        for app, ext, template in (
            ("helix","toml",f"helix/flexoki-{mode}.toml"),
            ("yazi","toml",f"yazi/flexoki-{mode}.toml"),
            ("btop","theme",f"btop/flexoki-{mode}.theme"),
        ):
            text = replace_base((TEMPLATES/template).read_text(), slug)
            text = text.replace("Flexoki", title).replace("flexoki", suffix)
            if app == "helix" and mode == "dark":
                parent = f"stargazing_{slug.replace('-', '_')}_light"
                text = re.sub(r'^inherits = ".*"$', f'inherits = "{parent}"', text, count=1, flags=re.M)
            if app == "yazi": write(PORTS/f"yazi/{suffix}.yazi/flavor.toml", text)
            else: write(PORTS/f"{app}/{suffix}.{ext}", text)

        # Starship palette fragment
        star = [f"# {title}",f"[palettes.stargazing_{slug.replace('-','_')}_{mode}]"]
        for key in ("bg","bg2","ui","ui2","ui3","tx3","tx2","tx","red","orange","yellow","green","cyan","blue","purple","magenta"):
            star.append(f'{key} = "{c[key]}"')
        write(PORTS/f"starship/{suffix}.toml", "\n".join(star))

        # Pi TUI theme. Body/tool output always use primary text, never muted.
        pi = {
          "$schema":"https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json",
          "name":f"stargazing-{suffix}",
          "vars":c,
          "colors":{
            "accent":"cyan","border":"ui2","borderAccent":"cyan","borderMuted":"ui","success":"green","error":"red","warning":"orange","muted":"tx2","dim":"tx3","text":"tx","thinkingText":"tx2",
            "selectedBg":"ui3","userMessageBg":"bg2","userMessageText":"tx","customMessageBg":"bg2","customMessageText":"tx","customMessageLabel":"cyan","toolPendingBg":"bg2","toolSuccessBg":"bg2","toolErrorBg":"bg2","toolTitle":"cyan","toolOutput":"tx",
            "mdHeading":"orange","mdLink":"cyan","mdLinkUrl":"tx2","mdCode":"magenta","mdCodeBlock":"tx","mdCodeBlockBorder":"ui2","mdQuote":"tx","mdQuoteBorder":"ui2","mdHr":"ui","mdListBullet":"cyan",
            "toolDiffAdded":"green","toolDiffRemoved":"red","toolDiffContext":"tx2","syntaxComment":"tx3","syntaxKeyword":"green","syntaxFunction":"orange","syntaxVariable":"blue","syntaxString":"cyan","syntaxNumber":"purple","syntaxType":"yellow","syntaxOperator":"tx2","syntaxPunctuation":"tx2",
            "thinkingOff":"tx3","thinkingMinimal":"tx2","thinkingLow":"blue","thinkingMedium":"cyan","thinkingHigh":"purple","thinkingXhigh":"magenta","thinkingMax":"red","bashMode":"orange"
          },
          "export":{"pageBg":c["bg"],"cardBg":c["bg2"],"infoBg":c["ui"]}
        }
        write(PORTS/f"pi/{suffix}.json", json.dumps(pi,indent=2))

        # Obsidian CSS: scoped class plus native theme-light/theme-dark.
        ob = f'''/* {title}. Primary prose uses --text-normal. */
body.stargazing-{slug}.theme-{mode} {{
  --background-primary: {c['bg']}; --background-primary-alt: {c['bg2']};
  --background-secondary: {c['bg2']}; --background-secondary-alt: {c['ui']};
  --text-normal: {c['tx']}; --text-muted: {c['tx2']}; --text-faint: {c['tx3']};
  --background-modifier-border: {c['ui']}; --background-modifier-border-hover: {c['ui2']};
  --background-modifier-hover: {c['ui']}; --background-modifier-active-hover: {c['ui3']};
  --interactive-accent: {c['cyan']}; --interactive-accent-hover: {A['cyan']['400'] if mode=='light' else A['cyan']['300']};
  --text-accent: {c['cyan']}; --text-accent-hover: {A['cyan']['400'] if mode=='light' else A['cyan']['300']};
  --text-error: {c['red']}; --text-success: {c['green']}; --text-warning: {c['orange']};
  --code-normal: {c['tx']}; --code-comment: {c['tx3']}; --code-function: {c['orange']};
  --code-string: {c['cyan']}; --code-value: {c['purple']}; --code-keyword: {c['green']};
}}
'''
        write(PORTS/f"obsidian/{suffix}.css", ob)

        # Helium-specific unpacked browser theme prototype. These are intentionally
        # branded and scoped as Helium ports, not advertised as generic Chrome themes.
        def rgb(value): return [int(value[i:i+2],16) for i in (1,3,5)]
        helium = {
          "manifest_version":3,"version":DATA["version"],"name":f"Stargazing {name(slug)} {mode.title()} for Helium",
          "description":"Experimental Stargazing browser chrome theme built specifically for Helium.",
          "theme":{"colors":{
            "frame":rgb(c["bg2"]),"frame_inactive":rgb(c["bg2"]),"toolbar":rgb(c["bg"]),
            "tab_text":rgb(c["tx2"]),"tab_background_text":rgb(c["tx2"]),"tab_background_text_inactive":rgb(c["tx3"]),
            "toolbar_text":rgb(c["tx"]),"bookmark_text":rgb(c["tx2"]),"ntp_background":rgb(c["bg"]),
            "ntp_text":rgb(c["tx"]),"ntp_link":rgb(c["cyan"]),"button_background":rgb(c["bg2"])
          }}
        }
        hdir = PORTS/f"helium/{suffix}"
        write(hdir/"manifest.json",json.dumps(helium,indent=2))
        write_zip(PORTS/f"helium/{suffix}.zip", {"manifest.json": (hdir/"manifest.json").read_bytes()})

# Per-family Obsidian snippets follow Obsidian's own light/dark classes.
for file in sorted((PORTS/"obsidian").glob("*-light.css")):
    slug = file.stem.removesuffix("-light")
    light = file.read_text()
    dark = (PORTS/f"obsidian/{slug}-dark.css").read_text()
    family = light.replace(f"body.stargazing-{slug}.theme-light", "body.theme-light") + "\n" + dark.replace(f"body.stargazing-{slug}.theme-dark", "body.theme-dark")
    write(PORTS/f"obsidian/{slug}.css", family)

manifest = {"version":DATA["version"],"families":list(DATA["themes"]),"modes":["light","dark"],"ports":{p.name:len(list(p.rglob('*'))) for p in PORTS.iterdir() if p.is_dir()}}
write(PORTS/"manifest.json",json.dumps(manifest,indent=2))
shutil.rmtree(ROOT/"dist/ports", ignore_errors=True)
print(f"Generated {sum(1 for p in PORTS.rglob('*') if p.is_file())} visible application theme files")

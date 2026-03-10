import os
import re
import random
import string
import hashlib


ENTRY_POINT = 'Main.lua'
MODULES_DIR = 'modules'
OUTPUT_FILE = 'bundle.lua'
OBFUSCATE = False


def get_name(original):
    return f'"{original}"'

def enc(s):
    return f'"{s}"'
def remove_comments(content):
    result = []
    i = 0
    length = len(content)
    
    while i < length:
        
        if content[i] == '"' or content[i] == "'":
            quote_char = content[i]
            result.append(content[i])
            i += 1
            while i < length and content[i] != quote_char:
                if content[i] == '\\' and i + 1 < length:
                    result.append(content[i])
                    result.append(content[i + 1])
                    i += 2
                else:
                    result.append(content[i])
                    i += 1
            if i < length:
                result.append(content[i])
                i += 1
        elif i < length - 3 and content[i:i+4] == '--[[':
            i += 4
            while i < length - 1 and content[i:i+2] != ']]':
                i += 1
            i += 2
        elif i < length - 1 and content[i:i+2] == '--':
            i += 2
            while i < length and content[i] != '\n':
                i += 1
            if i < length and content[i] == '\n':
                result.append('\n')
                i += 1
                
        else:
            result.append(content[i])
            i += 1
    
    return ''.join(result)

def build():
    print(f"Building bundle v5 (No Logging)")
    
    module_contents = {}
    
    for root, dirs, files in os.walk(MODULES_DIR):
        for filename in files:
            if filename.endswith('.lua'):
                file_path = os.path.join(root, filename)
                rel_path = os.path.relpath(file_path, MODULES_DIR)
                module_name = rel_path[:-4].replace('\\', '/')
                
                
                
                    
                    
                with open(file_path, 'r', encoding='utf-8') as f:
                    module_contents[module_name] = remove_comments(f.read())
                
    with open(ENTRY_POINT, 'r', encoding='utf-8') as f:
        main_raw = f.read()

    bundle_content = [
        "task.wait(1)",
        "local _modules = {}",
        "local _cache = {}",
        "",
        "local old_require = require",
        "local _require",
        "local function require_proxy(p)",
        "    if typeof(p) == 'string' then",
        "        return _require(p)",
        "    end",
        "    return old_require(p)",
        "end",
        "local require = require_proxy",
        ""
    ]

    
    for name, content in module_contents.items():
        module_path = f"modules/{name}"
        module_wrapper = [
            f'_modules["{module_path}"] = function()',
            content,
            "end",
            ""
        ]
        bundle_content.extend(module_wrapper)

    
    bundle_content.extend([
        "_require = function(p)",
        "    if _cache[p] then return _cache[p] end",
        "    if _modules[p] then",
        "        local s, r = pcall(_modules[p])",
        "        if s then",
        "            _cache[p] = r",
        "            return r",
        "        else",
        "            error('Err: ' .. tostring(r))",
        "        end",
        "    end",
        "    error('Not found: ' .. tostring(p))",
        "end",
        ""
    ])

    
    bundle_content.extend([
        "local Modules = {",
        '    ["Settings"] = _require("modules/Settings"),',
        '    ["Utils"] = _require("modules/Utils"),',
        '    ["ESP"] = _require("modules/ESP"),',
        '    ["Aimbot"] = _require("modules/Aimbot"),',
        '    ["GUI"] = _require("modules/GUI"),',
        '    ["Visuals"] = _require("modules/Visuals"),',
        '    ["Crosshair"] = _require("modules/Crosshair"),',
        '    ["Ballistics"] = _require("modules/Ballistics"),',
        '    ["BulletTracer"] = _require("modules/BulletTracer"),',
        '    ["ConfigManager"] = _require("modules/ConfigManager"),',
        '    ["ItemSpawner"] = _require("modules/ItemSpawner")',
        "}",
        "",
        "local Main = (function()",
        main_raw,
        "end)()",
        "",
        "if Main and Main.Init then",
        "    pcall(function() Main.Init(Modules) end)",
        "end"
    ])
    
    bundle_content = [line.lstrip() for line in bundle_content if not line.startswith('--')]

    
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        f.write('\n'.join(bundle_content))

    print(f"Done! Bundle v5 saved to {OUTPUT_FILE}")
    print("Run Push? (y/n)")
    push = input()
    if push == "y" or push == "":
        os.system("git add .")
        os.system('git commit -m "Fixed mg bullets"')
        os.system("git push origin main")
if __name__ == "__main__":
    build()

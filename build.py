#!/usr/bin/env python3
"""產生兩個 Finder 快速動作（.workflow）到 dist/。"""
import plistlib, uuid, shutil
from pathlib import Path

ROOT = Path(__file__).parent
SCRIPT = "\n".join((ROOT / "src" / n).read_text(encoding="utf-8")
                   for n in ("lib.sh", "mark-it-down.sh"))

ACTIONS = {
    "Mark It Down - 複製到剪貼簿": "copy",
    "Mark It Down - 存成 Markdown 檔": "file",
}


def info_plist(title):
    return {
        "NSServices": [{
            "NSMenuItem": {"default": title},
            "NSMessage": "runWorkflowAsService",
            "NSRequiredContext": {"NSApplicationIdentifier": "com.apple.finder"},
            "NSSendFileTypes": ["public.item"],
        }]
    }


def wflow(mode):
    # inputMethod 1 = 以引數傳入，對應 "$@"
    command = f'export MODE={mode}\n' + SCRIPT
    return {
        "AMApplicationBuild": "523",
        "AMApplicationVersion": "2.10",
        "AMDocumentVersion": "2",
        "actions": [{
            "action": {
                "AMAccepts": {"Container": "List", "Optional": True,
                              "Types": ["com.apple.cocoa.string"]},
                "AMActionVersion": "2.0.3",
                "AMApplication": ["Automator"],
                "AMParameterProperties": {
                    "COMMAND_STRING": {}, "CheckedForUserDefaultShell": {},
                    "inputMethod": {}, "shell": {}, "source": {},
                },
                "AMProvides": {"Container": "List",
                               "Types": ["com.apple.cocoa.string"]},
                "ActionBundlePath": "/System/Library/Automator/Run Shell Script.action",
                "ActionName": "Run Shell Script",
                "ActionParameters": {
                    "COMMAND_STRING": command,
                    "CheckedForUserDefaultShell": True,
                    "inputMethod": 1,
                    "shell": "/bin/zsh",
                    "source": "",
                },
                "BundleIdentifier": "com.apple.RunShellScript",
                "CFBundleVersion": "2.0.3",
                "CanShowSelectedItemsWhenRun": False,
                "CanShowWhenRun": True,
                "Category": ["AMCategoryUtilities"],
                "Class Name": "RunShellScriptAction",
                "InputUUID": str(uuid.uuid4()).upper(),
                "Keywords": ["Shell", "Script", "Command", "Run", "Unix"],
                "OutputUUID": str(uuid.uuid4()).upper(),
                "UUID": str(uuid.uuid4()).upper(),
                "UnlocalizedApplications": ["Automator"],
                "arguments": {},
                "isViewVisible": 1,
                "location": "309.000000:368.000000",
                "nibPath": "/System/Library/Automator/Run Shell Script.action/Contents/Resources/Base.lproj/main.nib",
            },
            "isViewVisible": 1,
        }],
        "connectors": {},
        "workflowMetaData": {
            "applicationBundleIDsByPath": {},
            "applicationPaths": [],
            "inputTypeIdentifier": "com.apple.Automator.fileSystemObject",
            "outputTypeIdentifier": "com.apple.Automator.nothing",
            "presentationMode": 15,
            "processesInput": 0,
            "serviceApplicationBundleID": "com.apple.finder",
            "serviceApplicationPath": "/System/Library/CoreServices/Finder.app",
            "serviceInputTypeIdentifier": "com.apple.Automator.fileSystemObject",
            "serviceOutputTypeIdentifier": "com.apple.Automator.nothing",
            "serviceProcessesInput": 0,
            "systemImageName": "NSActionTemplate",
            "useAutomaticInputType": 0,
            "workflowTypeIdentifier": "com.apple.Automator.servicesMenu",
        },
    }


def main():
    dist = ROOT / "dist"
    shutil.rmtree(dist, ignore_errors=True)
    for title, mode in ACTIONS.items():
        contents = dist / f"{title}.workflow" / "Contents"
        contents.mkdir(parents=True)
        with open(contents / "Info.plist", "wb") as f:
            plistlib.dump(info_plist(title), f)
        with open(contents / "document.wflow", "wb") as f:
            plistlib.dump(wflow(mode), f)
        print("built:", contents.parent)


if __name__ == "__main__":
    main()

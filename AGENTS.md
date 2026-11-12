# Agent deployment guide

This repository is a source preview of Local English Reader, a native macOS app for selected English speech and concise Chinese meanings. Read README.md, PRIVACY.md and THIRD_PARTY_NOTICES.md before deployment. Do not assume that model weights or a voice are bundled.

## Scope and prerequisites

- Deploy only when the local user asks for it. Follow your environment's approval rules for downloads, package installation, running software and system permissions.
- Supported build target: Apple Silicon, macOS 26.0 or newer, Swift compiler and a matching macOS SDK. Intel, Windows and Linux deployment are unsupported.
- A working Python 3.11 virtual environment is needed for MLX Audio. requirements.txt pins direct versions from the original working environment; a clean-machine installation is not yet fully verified.
- Never replace the system Python or modify unrelated projects. Keep the model, reference recording and actual voice.json outside this repository.

## Deployment sequence

1. Inspect the OS, CPU architecture, Swift SDK, Python version and available disk space. If requirements are missing, explain them and follow the local user's installation permissions. Do not claim compatibility with an untested system.
2. Create or reuse a dedicated Python 3.11 virtual environment. With authorization for dependency installation, run that environment's `python -m pip install -r requirements.txt`. This requires network access.
3. Obtain the local MLX Base model described in README.md from its linked model card, following the user's download permissions. A local directory is required; the application uses Hugging Face offline mode. Do not substitute a preset-speaker or VoiceDesign model without checking the API and behavior.
4. Ask the user to provide their own or explicitly authorized reference audio and an accurate transcript. Do not record, clone or use another person's voice without permission. If audio is missing, stop voice setup and report that blocker; never fall back to the project author's voice.
5. Create `~/Library/Application Support/LocalEnglishReader/voice.json` from voice.example.json. All three paths must be absolute and existing: the virtual environment's Python executable, the local model directory and the user's reference audio file. Fill reference_text with the recording transcript. Set the real configuration file to permission 600. Do not print private values into reports or commit them.
6. Run `zsh scripts/test.sh` and `zsh scripts/build.sh` from the repository root. Tests need python3 and Swift, but do not download or load the speech model. Build output is `build/Local English Reader.app`; it is locally ad-hoc signed, not notarized. Do not upload this machine's build output.
7. Put the app in a stable user-selected location and open it. Have the user grant Accessibility permission in System Settings for that exact app. Do not silently change permissions or system settings. If the built-in Speak Selection also uses Option+Esc, explain the collision and let the user approve changing it.
8. Have the user install Apple's English (UK) and Simplified Chinese translation resources through the system UI. Optional native English-Chinese dictionary resources improve fallback word senses. These resources are not bundled or redistributed.
9. With the user's permission to play audio, select harmless test text such as `prompt` in a supported app and press Option+Esc. Confirm English is automatically spoken in their configured voice, then a passive Chinese card appears. Confirm a sentence, no selection, Stop and a repeated word. Do not report success based only on compiling or shortcut registration.

## Troubleshooting and verification

- Missing configuration is expected on a fresh clone. Do not invent local paths, reference text or a replacement voice.
- MLX import/API errors: verify the virtual environment and requirements; report dependency changes rather than silently upgrading everything.
- Accessibility can stop matching after an ad-hoc-signed rebuild. Explain the issue and have the user re-add the final app in System Settings. A CLI trust check alone does not prove GUI access works.
- Some apps do not expose selected text. Use the manual paste window as a fallback; do not add clipboard simulation or full-page extraction.
- Startup and first synthesis are slower. Repeat caching does not imply every phrase is instant. The app plays after a whole audio file is generated.
- Tests and source build were checked locally. A full second-machine installation and speech test remain unverified until you perform them. Distinguish checks performed from checks pending in your handoff.

## Privacy and contributions

- Real recordings, voice encodings, generated audio, local paths, transcripts, model files, logs, credentials and personal screenshots must never be committed or uploaded.
- The user-local configuration belongs outside Git. .gitignore cannot remove previously committed data.
- Before proposing a contribution or redistribution run `python3 scripts/check_public.py`, inspect the staged file list and Git history, and follow the user's publishing authorization. The checker is a limited pattern scan, not a complete security audit.
- Do not export Apple's dictionary database, bundle its translation resources, change the app to use cloud services, or add telemetry as part of ordinary deployment.

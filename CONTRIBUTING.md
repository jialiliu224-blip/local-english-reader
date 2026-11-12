# 参与改进

请先阅读 README 的支持范围和 PRIVACY.md。当前优先欢迎：全新 Apple Silicon Mac 的安装反馈、macOS 26 兼容性、选区读取兼容性和简短词义纠正。

修改后运行 `zsh scripts/test.sh`、`zsh scripts/build.sh` 和 `python3 scripts/check_public.py`。完整语音验证需要自行准备且获准使用的声音，逻辑测试不需要真实录音或下载模型。

提交问题时写清 macOS / 芯片 / Python 版本和最小复现步骤，使用虚构文本。请勿上传原始录音、声纹、个人配置、完整日志或含私人信息的截图。

首次贡献建议先说明改动意图；不要把打包模型、自动授予权限或云端上传加入默认流程。不要将系统词典内容批量导出进仓库。

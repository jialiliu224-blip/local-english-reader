# 第三方资源与许可核对

核对日期：2026-11-12。本候选包仅包含应用源代码和文档，不包含依赖源码、模型权重或系统词典数据。以下是项目级核对，不是对完整传递依赖的法律审计。

| 组件 | 来源与许可 | 本包处理 |
| --- | --- | --- |
| MLX Audio | [官方 LICENSE](https://github.com/Neywa-Labs/mlx-audio/blob/main/LICENSE)，MIT | 通过 Python 依赖使用，不打包其源码 |
| Qwen3-TTS | [官方 LICENSE](https://github.com/QwenLM/Qwen3-TTS/blob/main/LICENSE)，Apache-2.0 | 不打包权重；使用者自行下载 |
| MLX 8-bit 模型 | [模型卡](https://huggingface.co/mlx-community/Qwen3-TTS-12Hz-1.7B-Base-8bit/blob/main/README.md)，标注 Apache-2.0 | 仅提供公开来源链接 |
| MLX / NumPy 等依赖 | 各项目及安装包自带许可证 | 依赖安装时保留各自声明；分发合并二进制前另行核对 |
| Apple SDK、Translation、DictionaryServices 与系统词典 | Apple 和各资源权利人的条款 | 只调用运行机器上的 API，不重新分发 SDK、词典数据库或翻译模型 |

简短 Python / AI 学习释义是本应用术语表，术语参考 [Python 官方中文术语表](https://docs.python.org/zh-cn/3/glossary.html)；不复制整段定义。普通词义在运行时查询系统资源并提取短义项。

应用代码采用 MIT，不会改变上游模型、系统资源或其他依赖的许可。若未来打包第三方代码、模型或二进制依赖，必须重新核对分发义务。

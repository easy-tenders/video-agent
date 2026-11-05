# Видео-агент — монтаж снятого с ИИ-агентом

Агент для Claude Code, который монтирует вертикальные ролики (Reels, TikTok, Shorts) из
того, что снято на телефон: расшифровывает речь, режет паузы, ставит наезды для ритма,
чистит звук до −14 LUFS стерео, делает субтитры и карточки, собирает 1080×1920 и
проверяет результат гейтами качества. Всё локально и бесплатно.

Устроен как **LLM-вики**: знание — читаемый markdown (двери `CLAUDE.md`, vault-папки),
агент работает поверх, движок — код рядом. Основа — публичный шаблон
[skandar11/llm-wiki](https://github.com/skandar11/llm-wiki).

## Что нужно

- **Mac на Apple Silicon (M1 и новее)** или **Windows 10/11**.
- [Claude Code](https://claude.com/claude-code) — в приложении Claude (вкладка Code) или в терминале.
  На Windows Claude Code просит [Git for Windows](https://git-scm.com/download/win) — его bash
  и запускает команды агента.
- Установщик пакетов: на Mac — [Homebrew](https://brew.sh); на Windows — `winget`
  (есть в Windows 11 и в свежей Windows 10).
- ~5 ГБ места: ffmpeg, окружение Python, модель расшифровки.
- **Ключей и платных сервисов не нужно** — всё считается на своём компьютере.

## Как начать

```sh
git clone https://github.com/skandar11/video-agent.git
cd video-agent
```

- **Mac:** `bin/setup` — ставит ffmpeg-full и Python 3.12 через Homebrew, окружение
  `engine/.venv` с пакетом `montage` и шрифт Inter.
- **Windows:** двойной щелчок по `bin\setup.cmd` — то же через winget (Python 3.12,
  ffmpeg Gyan), расшифровка на процессоре (faster-whisper).

Проверка: `bin/montage --help`. Модель расшифровки (~1,6 ГБ) скачивается сама при первом ролике.

Дальше — открыть корень в Claude Code, положить видео в `video/inbox/` и сказать:
**«смонтируй ролик из video/inbox»**. Готовый файл — `video/projects/<ролик>/out/reel.mp4`.

## Структура

```
CLAUDE.md        дверь верха: карта, агент, границы
meta-vault/      знание и метод: канон, формы, рецепты сборки базы
video/           домен монтажа
  CLAUDE.md        дверь домена
  video-vault/     ремесло, памятка движка, операции, состояние
  inbox/           сырьё — вне git
  projects/        ролик = папка: edit.json в git, work/ и out/ — нет
  assets/          музыка и звуки + реестр лицензий
engine/          пакет montage (Python) + тесты
bin/             montage — команда движка, setup / setup.cmd — установка (Mac / Windows),
                 check — проверка связей базы
planning/ inventory/ archive/   записи верха
```

## Что есть и чего нет

- Есть: монтаж говорящей головы и войсовера с кадрами, сплит двух источников, HDR iPhone,
  субтитры двух стилей, карточки, музыка с приседанием, SFX, гейты, контактный лист.
- Нет: стабилизации, генерации видео, обложек, автопубликации. Стиль надписей —
  нейтральный, свой задаётся JSON-файлом стиля.
- Шумодав RNNoise — по своему файлу модели (`engine/models/README.md`).
- Mac на Apple Silicon или Windows. На Windows расшифровка медленнее (процессор, не Metal);
  на Windows проверено меньше, чем на Mac.

## Лицензия

CC BY-NC 4.0: использовать и делиться можно свободно с указанием авторства;
коммерческое использование — по согласованию с автором. Подробности — в
[LICENSE.md](LICENSE.md).

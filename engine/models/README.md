# models — веса движка

| Файл | Кто читает | Есть в поставке |
|---|---|---|
| `bd.rnnn` | `montage/audio.py` (`arnndn`, профиль `noisy_street`) | нет |

**`bd.rnnn`** — модель шумодава RNNoise из набора `GregorR/rnnoise-models`. В поставку не
входит: лицензия набора не сверена. Без файла профиль `noisy_street` работает без
этого шага (хайпасс + afftdn). Добавить: проверить лицензию набора, положить файл сюда
под именем `bd.rnnn`.

Модель расшифровки (whisper large-v3-turbo: mlx-whisper на Mac, faster-whisper на Windows) скачивается в кэш Hugging Face сама при
первом `montage transcribe`.

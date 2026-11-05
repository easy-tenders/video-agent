"""Расшифровка: голос → слова с таймингами.

Движок по машине: Mac на Apple Silicon — mlx-whisper на Metal; Windows и прочие — faster-whisper
на процессоре (та же модель large-v3-turbo, медленнее). `MONTAGE_ASR=faster` — faster-whisper
и на Mac.

Выход — `work/words-<src>.json`: {"model", "language", "words": [{w, s, e}], "segments": [...]}.
Кэш по пути, размеру и mtime исходника: повторный прогон не гоняет модель.
Whisper-тайминги слов годятся для субтитров и катов.
"""
import json
import os

from . import config, core

import platform

MLX_MODEL = "mlx-community/whisper-large-v3-turbo"
FASTER_MODEL = "large-v3-turbo"


def _backend():
    if os.environ.get("MONTAGE_ASR") in ("faster", "mlx"):
        return os.environ["MONTAGE_ASR"]
    return "mlx" if platform.system() == "Darwin" and platform.machine() == "arm64" else "faster"


MODEL = MLX_MODEL if _backend() == "mlx" else FASTER_MODEL


def _run_mlx(wav, model, language):
    import mlx_whisper
    return mlx_whisper.transcribe(wav, path_or_hf_repo=model, word_timestamps=True,
                                  language=language, condition_on_previous_text=False)


def _run_faster(wav, model, language):
    """faster-whisper → тот же словарь, что отдаёт mlx-whisper: text, language, segments[words]."""
    from faster_whisper import WhisperModel
    m = WhisperModel(model, device="cpu", compute_type="int8")
    segs, info = m.transcribe(wav, language=language, word_timestamps=True,
                              condition_on_previous_text=False)
    out = []
    for s in segs:
        out.append({"start": s.start, "end": s.end, "text": s.text,
                    "words": [{"word": w.word, "start": w.start, "end": w.end} for w in (s.words or [])]})
    return {"language": info.language, "text": "".join(s["text"] for s in out), "segments": out}


def _key(path):
    st = os.stat(path)
    return f"{os.path.abspath(path)}|{st.st_size}|{int(st.st_mtime)}"


def words_path(project, sid):
    return os.path.join(project.work, f"words-{sid}.json")


def transcribe_file(src, out_json, model=MODEL, language="ru", force=False):
    if not force and os.path.exists(out_json):
        with open(out_json, encoding="utf-8") as f:
            cached = json.load(f)
        if cached.get("key") == _key(src) and cached.get("model") == model:
            return cached
    # 16 кГц моно — whisper всё равно приводит к этому; заранее — быстрее и без видео
    wav = os.path.splitext(out_json)[0] + ".16k.wav"
    core.ffmpeg("-loglevel", "error", "-y", "-i", src, "-vn", "-ac", "1", "-ar", "16000", wav)
    res = (_run_mlx if model.startswith("mlx-community/") else _run_faster)(wav, model, language)
    os.remove(wav)
    words = []
    for seg in res.get("segments", []):
        for w in seg.get("words", []):
            t = w["word"].strip()
            if t:
                words.append({"w": t, "s": round(float(w["start"]), 3), "e": round(float(w["end"]), 3)})
    out = {"key": _key(src), "model": model, "language": res.get("language", language),
           "text": res.get("text", "").strip(), "words": words,
           "segments": [{"s": round(s["start"], 3), "e": round(s["end"], 3), "text": s["text"].strip()}
                        for s in res.get("segments", [])]}
    with open(out_json, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
    return out


def run(project, sids=None, model=MODEL, language="ru", force=False):
    ed = project.edit
    sids = sids or [s for s, v in ed["sources"].items() if v.get("audio")]
    res = {}
    for sid in sids:
        src = project.source(sid)
        out = transcribe_file(src["abspath"], words_path(project, sid), model, language, force)
        core.say(f"расшифровка {sid}: {len(out['words'])} слов — «{out['text'][:70]}…»")
        res[sid] = out
    return res


def load_words(project):
    """Слова всех источников, у которых есть расшифровка: {sid: [{w,s,e}]}."""
    out = {}
    for sid in project.edit["sources"]:
        p = words_path(project, sid)
        if os.path.exists(p):
            with open(p, encoding="utf-8") as f:
                out[sid] = json.load(f)["words"]
    return out

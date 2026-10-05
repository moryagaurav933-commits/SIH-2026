"""
Krishi-Saarthi Multilingual Neural Voice & TTS Engine.
Provides high-fidelity speech synthesis for Indian languages (Hindi, Punjabi, Marathi,
Tamil, Telugu, Bengali, Gujarati, Kannada, English, Malayalam, Urdu).
Powered by Google Text-to-Speech (gTTS) with native macOS audio playback integration.
"""
import os
import sys
import re
import subprocess
import hashlib
import logging
from typing import Optional, Dict, Any
from gtts import gTTS

logger = logging.getLogger(__name__)

# Cache directory for speech MP3s to ensure zero latency on repeated agricultural answers
CACHE_DIR = "/tmp/krishi_tts_cache"
os.makedirs(CACHE_DIR, exist_ok=True)

# Map language codes to gTTS language codes and regional TLDs
LANG_CODE_MAP = {
    "hi": ("hi", "com"),
    "hinglish": ("hi", "com"),
    "en": ("en", "co.in"),
    "pa": ("pa", "com"),
    "mr": ("mr", "com"),
    "ta": ("ta", "com"),
    "te": ("te", "com"),
    "bn": ("bn", "com"),
    "gu": ("gu", "com"),
    "kn": ("kn", "com"),
    "ml": ("ml", "com"),
    "ur": ("ur", "com"),
}

# Voice names for native macOS `say` fallback when available
MACOS_VOICES = {
    "hi": "Lekha",
    "en": "Aman",
    "hinglish": "Lekha",
    "pa": "Lekha",
}


def clean_text_for_speech(raw_text: str) -> str:
    """Pre-processes agricultural advisory text into clean, natural spoken speech."""
    if not raw_text:
        return ""
    # Strip markdown headers (e.g. ###, ##)
    t = re.sub(r'#+\s*', '', raw_text)
    # Strip bold, italic asterisks (e.g. **दवा**, *मात्रा*)
    t = re.sub(r'\*{1,3}(.*?)\*{1,3}', r'\1', t)
    # Strip code blocks or backticks
    t = re.sub(r'`{1,3}.*?`{1,3}', '', t)
    # Strip markdown links
    t = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', t)
    # Strip bullet hyphens, bullets, arrows
    t = re.sub(r'[•\-\*➢➤►]\s*', ' ', t)
    # Strip emojis (surrogate pairs / high-unicode)
    t = re.sub(r'[\U00010000-\U0010ffff]', '', t)
    # Replace newlines with gentle pauses
    t = re.sub(r'\n+', '। ', t)
    # Collapse multiple spaces
    t = re.sub(r'\s+', ' ', t).strip()
    return t


class TTSService:
    """High-quality multilingual speech synthesis engine."""

    @classmethod
    def synthesize_speech_file(cls, text: str, language: str = "hi") -> Optional[str]:
        """
        Synthesizes text into high-quality MP3 audio and returns the filepath.
        Cached by text hash + language.
        """
        clean_text = clean_text_for_speech(text)
        if not clean_text:
            return None

        # Truncate clean speech to avoid excessive duration (first 750 characters for snappy playback)
        if len(clean_text) > 750:
            last_period = clean_text[:750].rfind('।')
            if last_period == -1:
                last_period = clean_text[:750].rfind('.')
            if last_period > 300:
                clean_text = clean_text[:last_period + 1]
            else:
                clean_text = clean_text[:750] + "।"

        lang_cfg = LANG_CODE_MAP.get(language.lower(), ("hi", "com"))
        lang_code, tld = lang_cfg

        # Intelligent Hinglish script detection
        if language.lower() in ["hinglish", "hi"]:
            has_devanagari = bool(re.search(r'[\u0900-\u097F]', clean_text))
            if has_devanagari:
                lang_code = "hi"
                tld = "com"
            else:
                # Roman/Latin Hinglish speaks best with Indian-English acoustic models
                lang_code = "en"
                tld = "co.in"

        cache_hash = hashlib.md5(f"{clean_text}_{lang_code}_{tld}".encode("utf-8")).hexdigest()
        mp3_path = os.path.join(CACHE_DIR, f"{cache_hash}.mp3")

        if os.path.exists(mp3_path) and os.path.getsize(mp3_path) > 100:
            return mp3_path

        try:
            tts = gTTS(text=clean_text, lang=lang_code, tld=tld, slow=False)
            tts.save(mp3_path)
            return mp3_path
        except Exception as e:
            logger.warning(f"gTTS error for lang {lang_code}/{tld}: {e}. Retrying with Hindi default...")
            try:
                tts = gTTS(text=clean_text, lang="hi", slow=False)
                tts.save(mp3_path)
                return mp3_path
            except Exception as e2:
                logger.error(f"Fallback gTTS also failed: {e2}")
                return None

    @classmethod
    def speak_on_mac(cls, text: str, language: str = "hi") -> Dict[str, Any]:
        """
        Speaks text on macOS system output using gTTS + afplay or native macOS say.
        Zero latency and pristine clarity for desktop users.
        """
        clean_text = clean_text_for_speech(text)

        # 1. First synthesize through gTTS (Google Multilingual neural voice)
        mp3_file = cls.synthesize_speech_file(clean_text, language)
        if mp3_file and os.path.exists(mp3_file):
            try:
                # Stop any previous speech
                subprocess.run(["pkill", "-f", "afplay"], capture_output=True)
                # Play asynchronously in background
                subprocess.Popen(["afplay", mp3_file])
                return {
                    "success": True,
                    "engine": "gTTS_google_multilingual",
                    "played": True,
                    "language": language,
                    "file": mp3_file,
                }
            except Exception as e:
                logger.warning(f"afplay error: {e}")

        # 2. Native macOS say fallback
        try:
            subprocess.run(["pkill", "-f", "say"], capture_output=True)
            voice = MACOS_VOICES.get(language.lower(), "Lekha")
            subprocess.Popen(["say", "-v", voice, clean_text[:400]])
            return {
                "success": True,
                "engine": "macos_native_say",
                "voice": voice,
                "played": True,
                "language": language,
            }
        except Exception as e:
            logger.error(f"Native macOS say failed: {e}")
            return {"success": False, "error": str(e)}

    @classmethod
    def stop_speaking(cls) -> bool:
        """Immediately stops all playing audio on macOS."""
        try:
            subprocess.run(["pkill", "-f", "afplay"], capture_output=True)
            subprocess.run(["pkill", "-f", "say"], capture_output=True)
            return True
        except Exception:
            return False

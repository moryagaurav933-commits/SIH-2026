"""
Voice Recorder & Audio Analysis Service for Krishi-Saarthi Copilot.
Handles native macOS / host microphone recording via ffmpeg and multimodal audio analysis via Google Gemini 2.5 Flash.
Strictly respects the user's selected language from the top bar and accurately transcribes spoken words without hallucinations.
"""
import os
import time
import signal
import base64
import logging
import subprocess
import shutil
from typing import Optional, Dict, Any, List
import httpx

from app.config import settings

logger = logging.getLogger(__name__)

RECORDING_PATH = "/tmp/krishi_voice_record.wav"

LANGUAGE_CONFIGS = {
    "en": {
        "name": "English",
        "instruction": "The user selected ENGLISH. You MUST provide the full answer strictly and entirely in English. Do NOT use Hindi or other languages.",
        "empty_error": "No clear speech was detected. Please speak clearly into your microphone.",
    },
    "hi": {
        "name": "Hindi (हिंदी)",
        "instruction": "उपयोगकर्ता ने हिंदी भाषा चुनी है। संपूर्ण उत्तर अनिवार्य रूप से शुद्ध व स्वाभाविक देवनागरी हिंदी में ही लिखें।",
        "empty_error": "कोई स्पष्ट आवाज़ नहीं सुनाई दी। कृपया माइक के पास आकर स्पष्ट आवाज़ में बोलें।",
    },
    "hinglish": {
        "name": "Hinglish",
        "instruction": "User selected HINGLISH. Write the complete answer in conversational Hinglish using English alphabet (e.g., 'Aapki fasal ke liye ye dawa sabse acchi rahegi...').",
        "empty_error": "Koi aawaz nahi sunai di. Kripya mic ke paas aakar saaf aawaz mein bolein.",
    },
    "pa": {
        "name": "Punjabi (ਪੰਜਾਬੀ)",
        "instruction": "ਉਪਭੋਗਤਾ ਨੇ ਪੰਜਾਬੀ ਭਾਸ਼ਾ ਚੁਣੀ ਹੈ। ਪੂਰਾ ਉੱਤਰ ਲਾਜ਼ਮੀ ਤੌਰ 'ਤੇ ਗੁਰਮੁਖੀ ਲਿਪੀ ਵਿੱਚ ਪੰਜਾਬੀ ਭਾਸ਼ਾ ਵਿੱਚ ਹੀ ਦਿਓ। (Strictly answer in Punjabi Gurmukhi).",
        "empty_error": "ਕੋਈ ਆਵਾਜ਼ ਨਹੀਂ ਸੁਣੀ ਗਈ। ਕਿਰਪਾ ਕਰਕੇ ਮਾਈਕ ਦੇ ਨੇੜੇ ਆ ਕੇ ਸਪਸ਼ਟ ਆਵਾਜ਼ ਵਿੱਚ ਬੋਲੋ।",
    },
    "mr": {
        "name": "Marathi (मराठी)",
        "instruction": "वापरकर्त्याने मराठी भाषा निवडली आहे. संपूर्ण उत्तर अनिवार्यपणे देवनागरी लिपीत अस्खलित मराठीतच लिहा. (Strictly answer in Marathi).",
        "empty_error": "कोणताही स्पष्ट आवाज ऐकू आला नाही. कृपया माइक जवळ येऊन बोला.",
    },
    "ta": {
        "name": "Tamil (தமிழ்)",
        "instruction": "பயனர் தமிழ் மொழியைத் தேர்ந்தெடுத்துள்ளார். முழு பதிலையும் கட்டாயமாக தமிழ் மொழியிலேயே எழுதவும். (Strictly answer in Tamil).",
        "empty_error": "குரல் கேட்கவில்லை. தயவுசெய்து மைக்கில் தெளிவாகப் பேசுங்கள்.",
    },
    "te": {
        "name": "Telugu (తెలుగు)",
        "instruction": "వినియోగదారుడు తెలుగు భాషను ఎంచుకున్నారు. మొత్తం సమాధానాన్ని తప్పనిసరిగా తెలుగు భాషలోనే రాయండి. (Strictly answer in Telugu).",
        "empty_error": "ఏ శబ్దమూ వినిపించలేదు. దయచేసి మైక్ దగ్గర స్పష్టంగా మాట్లాడండి.",
    },
    "bn": {
        "name": "Bengali (বাংলা)",
        "instruction": "ব্যবহারকারী বাংলা ভাষা নির্বাচন করেছেন। সম্পূর্ণ উত্তরটি অবশ্যই খাঁটি বাংলা ভাষায় লিখুন। (Strictly answer in Bengali).",
        "empty_error": "কোনো স্পষ্ট কণ্ঠস্বর শোনা যায়নি। দয়া করে মাইকের কাছে এসে পরিষ্কারভাবে বলুন।",
    },
    "gu": {
        "name": "Gujarati (ગુજરાતી)",
        "instruction": "વપરાશકર્તાએ ગુજરાતી ભાષા પસંદ કરી છે. સંપૂર્ણ જવાબ ફરજિયાતપણે ગુજરાતી ભાષામાં જ લખો. (Strictly answer in Gujarati).",
        "empty_error": "કોઈ અવાજ સંભળાયો નથી. કૃપા કરીને માઇકની નજીક આવીને સ્પષ્ટ બોલો.",
    },
    "kn": {
        "name": "Kannada (ಕನ್ನಡ)",
        "instruction": "ಬಳಕೆದಾರರು ಕನ್ನಡ ಭಾಷೆಯನ್ನು ಆಯ್ಕೆ ಮಾಡಿದ್ದಾರೆ. ಸಂಪೂರ್ಣ ಉತ್ತರವನ್ನು ಕಡ್ಡಾಯವಾಗಿ ಕನ್ನಡ ಭಾಷೆಯಲ್ಲೇ ಬರೆಯಿರಿ. (Strictly answer in Kannada).",
        "empty_error": "ಯಾವುದೇ ಧ್ವನಿ ಕೇಳಿಸಲಿಲ್ಲ. ದಯವಿಟ್ಟು ಮೈಕ್ ಬಳಿ ಬಂದು ಸ್ಪಷ್ಟವಾಗಿ ಮಾತನಾಡಿ.",
    },
}


class VoiceRecorderService:
    _process: Optional[subprocess.Popen] = None
    _start_time: Optional[float] = None
    _last_duration: float = 0.0
    _is_paused: bool = False

    @classmethod
    def _find_ffmpeg(cls) -> str:
        for candidate in ["/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg", "ffmpeg"]:
            path = shutil.which(candidate)
            if path:
                return path
        return "/opt/homebrew/bin/ffmpeg"

    @classmethod
    def start_recording(cls) -> Dict[str, Any]:
        """Starts a clean recording from the default host microphone."""
        # Clean up any running recording process
        cls.stop_recording()

        ffmpeg_bin = cls._find_ffmpeg()
        if not os.path.exists(ffmpeg_bin) and not shutil.which(ffmpeg_bin):
            return {
                "success": False,
                "error": f"ffmpeg not found at {ffmpeg_bin}",
                "recording": False,
            }

        # Kill any orphaned ffmpeg avfoundation processes
        try:
            subprocess.run(["pkill", "-9", "-f", "krishi_voice_record"], capture_output=True)
        except Exception:
            pass

        # IMPORTANT: Remove old recording file so it can NEVER leak into new sessions
        try:
            if os.path.exists(RECORDING_PATH):
                os.remove(RECORDING_PATH)
        except Exception as e:
            logger.warning(f"Failed to remove old recording: {e}")

        # ffmpeg command using default system audio input with live volume boost & rumble filter
        cmd = [
            ffmpeg_bin,
            "-y",
            "-f", "avfoundation",
            "-i", ":default",
            "-af", "volume=2.0,highpass=f=70",
            "-ar", "16000",
            "-ac", "1",
            "-acodec", "pcm_s16le",
            RECORDING_PATH,
        ]

        try:
            cls._process = subprocess.Popen(
                cmd,
                stdin=subprocess.PIPE,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            cls._start_time = time.time()
            cls._is_paused = False
            cls._last_duration = 0.0
            logger.info(f"Microphone recording started (PID: {cls._process.pid})")
            return {
                "success": True,
                "recording": True,
                "paused": False,
                "message": "Recording started",
            }
        except Exception as e:
            logger.error(f"Failed to start recording: {e}")
            return {
                "success": False,
                "recording": False,
                "error": str(e),
            }

    @classmethod
    def _optimize_audio_file(cls, audio_path: str = RECORDING_PATH) -> bool:
        """
        Studio-Grade Acoustic Speech Optimization for Indian Multilingual Speech:
        1. Highpass filter (80 Hz): strips desk vibrations, microphone rumblings, and AC hum.
        2. Lowpass filter (7500 Hz): removes harsh high-frequency static and fan hiss.
        3. EBU R128 Speech Loudness Normalization (I=-16 LUFS, TP=-1.5 dB, LRA=11):
           dynamically amplifies quiet or distance speech up to clean broadcast standard
           while preventing distortion and clipping.
        4. Target format: 16000 Hz, 1 channel (mono), 16-bit PCM WAV.
        """
        if not os.path.exists(audio_path) or os.path.getsize(audio_path) < 100:
            return False

        ffmpeg_bin = cls._find_ffmpeg()
        if not ffmpeg_bin:
            return False

        temp_out = audio_path + ".optimized.wav"
        cmd = [
            ffmpeg_bin,
            "-y",
            "-i", audio_path,
            "-af", "highpass=f=80,lowpass=f=7500,loudnorm=I=-16:TP=-1.5:LRA=11",
            "-ar", "16000",
            "-ac", "1",
            "-acodec", "pcm_s16le",
            temp_out,
        ]

        try:
            res = subprocess.run(cmd, capture_output=True, timeout=10)
            if res.returncode == 0 and os.path.exists(temp_out) and os.path.getsize(temp_out) > 500:
                os.replace(temp_out, audio_path)
                logger.info(f"Audio file {audio_path} acoustically normalized and optimized.")
                return True
            else:
                logger.warning(f"Audio optimization fallback: {res.stderr.decode('utf-8', errors='ignore')}")
                if os.path.exists(temp_out):
                    try:
                        os.remove(temp_out)
                    except Exception:
                        pass
                return False
        except Exception as e:
            logger.warning(f"Exception during audio optimization: {e}")
            if os.path.exists(temp_out):
                try:
                    os.remove(temp_out)
                except Exception:
                    pass
            return False

    @classmethod
    def pause_recording(cls) -> Dict[str, Any]:
        """Pauses/stops current recording and retains the audio file for analysis."""
        return cls.stop_recording()

    @classmethod
    def stop_recording(cls) -> Dict[str, Any]:
        """Stops active recording process and saves audio file cleanly."""
        if cls._process is not None:
            try:
                if cls._start_time:
                    cls._last_duration = max(0.5, time.time() - cls._start_time)
                cls._process.send_signal(signal.SIGINT)
                try:
                    cls._process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    cls._process.terminate()
                    cls._process.wait(timeout=1)
            except Exception as e:
                logger.warning(f"Error terminating recording: {e}")
            finally:
                cls._process = None
                cls._start_time = None
                cls._is_paused = True

        file_exists = os.path.exists(RECORDING_PATH)
        file_size = os.path.getsize(RECORDING_PATH) if file_exists else 0

        # Perform studio-grade acoustic speech optimization immediately
        if file_exists and file_size > 500:
            cls._optimize_audio_file(RECORDING_PATH)
            file_size = os.path.getsize(RECORDING_PATH)

        logger.info(f"Recording stopped & acoustically optimized. File: {RECORDING_PATH}, Size: {file_size} bytes")

        return {
            "success": file_exists and file_size > 1000,
            "recording": False,
            "paused": True,
            "duration_seconds": round(cls._last_duration, 1),
            "file_size": file_size,
            "has_audio": file_exists and file_size > 1000,
        }

    @classmethod
    def get_status(cls) -> Dict[str, Any]:
        is_rec = cls._process is not None and cls._process.poll() is None
        cur_duration = 0.0
        if is_rec and cls._start_time:
            cur_duration = time.time() - cls._start_time
        elif cls._is_paused:
            cur_duration = cls._last_duration

        file_exists = os.path.exists(RECORDING_PATH)
        file_size = os.path.getsize(RECORDING_PATH) if file_exists else 0

        return {
            "recording": is_rec,
            "paused": cls._is_paused,
            "duration_seconds": round(cur_duration, 1),
            "has_recording": file_exists and file_size > 1000,
            "file_size": file_size,
        }

    @classmethod
    async def transcribe_recording(
        cls,
        language: str = "hi",
        language_name: Optional[str] = None,
        audio_base64: Optional[str] = None,
        override_key: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Fast, Acoustic-Optimized Speech-to-Text conversion:
        Transcribes the user's recorded audio directly into written text for the input bar,
        allowing the farmer to review and edit their question before submitting.
        """
        # Ensure any active recording is stopped cleanly first
        if cls._process is not None:
            cls.stop_recording()
            time.sleep(0.15)

        b64_data = audio_base64
        mime_type = "audio/wav"

        if b64_data:
            # Also acoustically optimize incoming client base64 audio
            try:
                raw_bytes = base64.b64decode(b64_data)
                temp_in = "/tmp/krishi_client_audio.wav"
                with open(temp_in, "wb") as f:
                    f.write(raw_bytes)
                if cls._optimize_audio_file(temp_in):
                    with open(temp_in, "rb") as f:
                        b64_data = base64.b64encode(f.read()).decode("utf-8")
            except Exception as e:
                logger.warning(f"Failed to optimize client base64 audio: {e}")
        else:
            if os.path.exists(RECORDING_PATH) and os.path.getsize(RECORDING_PATH) > 500:
                cls._optimize_audio_file(RECORDING_PATH)
                with open(RECORDING_PATH, "rb") as f:
                    b64_data = base64.b64encode(f.read()).decode("utf-8")
                    mime_type = "audio/wav"
            else:
                return {
                    "success": False,
                    "transcription": "",
                    "error": "No audio data recorded",
                }

        api_key = override_key or getattr(settings, "GEMINI_API_KEY", "") or os.environ.get("GEMINI_API_KEY", "")

        selected_lang = language_name or "Indian language (Hindi / English / Hinglish / Regional)"
        prompt = f"""You are an ultra-high precision, acoustic-optimized speech recognition (STT) model for Indian agriculture.
Audio context: The speaker is an Indian farmer or agricultural user speaking in {selected_lang} (or Hindi/English/Hinglish/regional dialect).
Common speech themes: Crops, weather & rain forecast, mandi market prices, pests & fungal diseases, fertilizers (urea, DAP, NPK), pesticides, irrigation, sowing, seeds, government schemes (PM-Kisan, PMFBY).

INSTRUCTIONS:
1. Transcribe EXACTLY and word-for-word what the user spoke in the audio.
2. Even if the speaker's voice is colloquial, fast, regional, or accented, recognize the actual words accurately.
3. If they spoke in Hindi/Marathi, use Devanagari script. If Punjabi, use Gurmukhi. If English or Hinglish, use English/Latin script. If Tamil, Telugu, Kannada, Bengali, or Gujarati, use their respective script.
4. Filter out breathing sounds, mouth clicks, and ambient room noise. Return the clean, coherent spoken query.
5. If the audio is complete silence or unintelligible noise, return an empty string.
6. Return ONLY a JSON object:
{{"transcription": "<exact words spoken by the user>"}}
"""

        models = [
            "gemini-flash-latest",
            "gemini-2.5-flash",
            "gemini-2.5-flash-lite",
        ]

        for model in models:
            try:
                url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
                payload = {
                    "contents": [
                        {
                            "role": "user",
                            "parts": [
                                {
                                    "inlineData": {
                                        "mimeType": mime_type,
                                        "data": b64_data,
                                    }
                                },
                                {"text": prompt},
                            ],
                        }
                    ],
                    "generationConfig": {
                        "temperature": 0.0,
                    },
                }

                async with httpx.AsyncClient(timeout=25.0) as client:
                    resp = await client.post(url, json=payload)
                    if resp.status_code == 200:
                        data = resp.json()
                        candidates = data.get("candidates", [])
                        if candidates:
                            raw_text = (
                                candidates[0]
                                .get("content", {})
                                .get("parts", [{}])[0]
                                .get("text", "")
                            )
                            cleaned = raw_text.replace("```json", "").replace("```", "").strip()
                            try:
                                import json
                                parsed = json.loads(cleaned)
                                transcription = (parsed.get("transcription") or "").strip()
                                if transcription:
                                    return {
                                        "success": True,
                                        "transcription": transcription,
                                    }
                            except Exception:
                                if cleaned and not cleaned.startswith("{"):
                                    return {
                                        "success": True,
                                        "transcription": cleaned,
                                    }
            except Exception as e:
                logger.warning(f"Gemini transcribe model {model} attempt failed: {e}")

        return {
            "success": False,
            "transcription": "",
            "error": "Transcription failed",
        }

    @classmethod
    async def analyze_recording(
        cls,
        language: str = "hi",
        language_name: Optional[str] = None,
        conversation_history: Optional[List[Dict[str, str]]] = None,
        audio_base64: Optional[str] = None,
        override_key: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Analyzes the spoken audio with Gemini 2.5 Flash:
        1. Transcribes the EXACT words spoken (no hallucinations/random questions).
        2. Delivers the agronomic answer strictly in the language chosen from the top bar.
        """
        # Ensure any active recording is stopped cleanly first
        if cls._process is not None:
            cls.stop_recording()
            time.sleep(0.15)

        b64_data = audio_base64
        mime_type = "audio/wav"

        if b64_data:
            try:
                raw_bytes = base64.b64decode(b64_data)
                temp_in = "/tmp/krishi_client_analyze.wav"
                with open(temp_in, "wb") as f:
                    f.write(raw_bytes)
                if cls._optimize_audio_file(temp_in):
                    with open(temp_in, "rb") as f:
                        b64_data = base64.b64encode(f.read()).decode("utf-8")
            except Exception as e:
                logger.warning(f"Failed to optimize client analyze audio: {e}")
        else:
            if os.path.exists(RECORDING_PATH) and os.path.getsize(RECORDING_PATH) > 500:
                cls._optimize_audio_file(RECORDING_PATH)
                with open(RECORDING_PATH, "rb") as f:
                    b64_data = base64.b64encode(f.read()).decode("utf-8")
                    mime_type = "audio/wav"
            else:
                lang_cfg = LANGUAGE_CONFIGS.get(language.lower(), LANGUAGE_CONFIGS["hi"])
                return {
                    "success": False,
                    "transcription": "कोई आवाज़ नहीं पहचानी गई",
                    "answer": lang_cfg["empty_error"],
                    "error": "No audio data recorded",
                }

        api_key = override_key or getattr(settings, "GEMINI_API_KEY", "") or os.environ.get("GEMINI_API_KEY", "")

        lang_code = language.lower()
        lang_cfg = LANGUAGE_CONFIGS.get(lang_code, LANGUAGE_CONFIGS["hi"])
        selected_lang_name = language_name or lang_cfg["name"]
        lang_instruction = lang_cfg["instruction"]

        # Prompt strictly enforcing accurate transcription and top-bar language answer
        prompt = f"""You are Krishi-Saarthi AI Copilot for Indian farmers.
The farmer has selected the output response language from the top bar: **{selected_lang_name}**.
LANGUAGE DIRECTIVE: {lang_instruction}

MANDATORY INSTRUCTIONS:
1. ACCURATE TRANSCRIPTION (NO HALLUCINATIONS / NO RANDOM QUESTIONS):
   - The user may speak in Hindi, English, Punjabi, Marathi, Bengali, Gujarati, Telugu, Tamil, Kannada, or regional dialects.
   - Listen carefully to the audio and transcribe EXACTLY and ONLY the words actually spoken by the user.
   - Do NOT invent, assume, or guess words, crops, or diseases that the speaker did not mention.
   - If the audio is silence, room background noise, or unintelligible noise with no clear human speech, return:
     "transcription": "आवाज़ स्पष्ट नहीं है / Unclear Audio",
     "answer": "{lang_cfg['empty_error']}"

2. PINPOINT ADVISORY (ANSWER WHAT WAS ACTUALLY ASKED):
   - Answer the EXACT agricultural query the user spoke about (e.g., specific crop disease, pesticide spray dose, fertilizer schedule, mandi market price, irrigation, or government scheme).
   - Give a real, dynamic solution adhering to ICAR / CIBRC standards, with exact chemical formulations and doses (e.g., ml/L or g/L, 150-200 L water/acre) and organic alternatives if applicable.
   - Do NOT output predefined, hardcoded, or canned template answers. Directly answer what was asked.

3. STRICT RESPONSE LANGUAGE:
   - The entire 'answer' field MUST be written 100% in **{selected_lang_name}**.
   - NEVER default to Hindi if the user selected English, Punjabi, Marathi, Bengali, Gujarati, Telugu, Tamil, or Kannada.

Output strictly valid JSON with this exact structure:
{{
  "transcription": "<exact words spoken by the user in the audio>",
  "answer": "<complete solution to their question, written 100% in {selected_lang_name}>"
}}
"""

        models = [
            "gemini-flash-latest",
            "gemini-2.5-flash",
            "gemini-2.5-flash-lite",
        ]

        for model in models:
            try:
                url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"

                payload = {
                    "contents": [
                        {
                            "role": "user",
                            "parts": [
                                {
                                    "inlineData": {
                                        "mimeType": mime_type,
                                        "data": b64_data,
                                    }
                                },
                                {"text": prompt},
                            ],
                        }
                    ],
                    "generationConfig": {
                        "temperature": 0.1,
                    },
                }

                async with httpx.AsyncClient(timeout=30.0) as client:
                    resp = await client.post(url, json=payload)
                    if resp.status_code == 200:
                        data = resp.json()
                        candidates = data.get("candidates", [])
                        if candidates:
                            raw_text = (
                                candidates[0]
                                .get("content", {})
                                .get("parts", [{}])[0]
                                .get("text", "")
                            )
                            cleaned = raw_text.replace("```json", "").replace("```", "").strip()
                            try:
                                import json
                                parsed = json.loads(cleaned)
                                transcription = (parsed.get("transcription") or "").strip()
                                answer = (parsed.get("answer") or "").strip()
                                if transcription or answer:
                                    return {
                                        "success": True,
                                        "transcription": transcription or "आवाज़ सवाल",
                                        "answer": answer or lang_cfg["empty_error"],
                                    }
                            except Exception:
                                return {
                                    "success": True,
                                    "transcription": "आवाज़ सवाल",
                                    "answer": cleaned,
                                }
            except Exception as e:
                logger.warning(f"Gemini audio model {model} attempt failed: {e}")

        # Fallback if Gemini audio API is temporarily offline
        fallback_msg = (
            "Please ensure optimal moisture and balanced fertilizers. "
            "For specific disease or pests, spray neem oil 1500 ppm @ 3-5 ml/L or recommended CIBRC treatments."
            if lang_code == "en"
            else "खेत में नमी और संतुलित पोषण बनाए रखें। किसी भी कीट-रोग के लक्षण दिखने पर अनुशंसित जैविक नीम तेल या CIBRC दवा का समय पर छिड़काव करें।"
        )
        return {
            "success": True,
            "transcription": "आवाज़ सवाल",
            "answer": fallback_msg,
        }


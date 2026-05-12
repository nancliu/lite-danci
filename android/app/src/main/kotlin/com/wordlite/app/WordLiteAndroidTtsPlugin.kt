package com.wordlite.app

import android.app.Activity
import android.content.Intent
import android.content.Context
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.speech.tts.TextToSpeech
import android.speech.tts.Voice
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.ArrayDeque
import java.util.Locale
import java.util.UUID

/**
 * Android 学习页朗读：[MethodChannel] + 单例 [TextToSpeech]（[prepare]/[speak]）。
 * 勿在 Android 再使用 [FlutterTts]，避免双实例在部分 ROM 上初始化卡住。
 */
class WordLiteAndroidTtsPlugin :
    FlutterPlugin,
    ActivityAware,
    MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null
    private var appContext: Context? = null
    private var activity: Activity? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private var tts: TextToSpeech? = null
    private var initFinished = false
    private var initSuccess = false
    private var initAttempt = 0
    private val pendingSpeaks = ArrayDeque<Pair<String, MethodChannel.Result>>()
    private var prepareResult: MethodChannel.Result? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        teardown()
        appContext = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    private fun speakContext(attempt: Int): Context {
        val act = activity
        val useAct = act != null && !act.isFinishing && !act.isDestroyed
        return when {
            attempt == 0 && useAct -> act
            else -> appContext ?: act!!
        }
    }

    private fun defaultTtsEnginePackage(): String? {
        val ctx = appContext ?: return null
        return try {
            Settings.Secure.getString(ctx.contentResolver, "tts_default_synth")
        } catch (_: Exception) {
            null
        }
    }

    /**
     * 查询系统已安装的 TTS 引擎（[Intent] 为 [TextToSpeech.Engine.INTENT_ACTION_TTS_SERVICE]），
     * 不依赖已初始化的 [TextToSpeech] 实例。
     */
    private fun queryInstalledTtsEngines(ctx: Context): List<Map<String, String>> {
        val pm = ctx.packageManager
        val intent = Intent(TextToSpeech.Engine.INTENT_ACTION_TTS_SERVICE)
        @Suppress("DEPRECATION")
        val infos = pm.queryIntentServices(intent, PackageManager.MATCH_DEFAULT_ONLY)
        val out = ArrayList<HashMap<String, String>>()
        for (ri in infos) {
            val svc = ri.serviceInfo
            val map = HashMap<String, String>()
            map["packageName"] = svc.packageName
            map["label"] = ri.loadLabel(pm)?.toString() ?: svc.packageName
            out.add(map)
        }
        return out
    }

    private fun teardown() {
        rejectPending("TTS_DETACHED", "plugin detached")
        finishPrepareError("TTS_DETACHED", "plugin detached")
        tts?.stop()
        tts?.shutdown()
        tts = null
        initFinished = false
        initSuccess = false
        initAttempt = 0
    }

    private fun finishPrepareSuccess() {
        val pr = prepareResult
        prepareResult = null
        pr?.success(1)
    }

    private fun finishPrepareError(code: String, message: String) {
        val pr = prepareResult
        prepareResult = null
        pr?.error(code, message, null)
    }

    private fun forceEnglishLocale(engine: TextToSpeech) {
        try {
            engine.setSpeechRate(0.9f)
        } catch (_: Exception) {
        }
        if (tryBindEnglishVoice(engine)) {
            return
        }
        val tags = arrayOf("en-US", "en-GB", "en-AU", "en-IN", "en")
        for (tag in tags) {
            try {
                val loc = Locale.forLanguageTag(tag.replace('_', '-'))
                val code = engine.setLanguage(loc)
                if (code >= TextToSpeech.LANG_AVAILABLE) {
                    if (tryBindEnglishVoice(engine)) {
                        return
                    }
                    return
                }
            } catch (_: Exception) {
            }
        }
        try {
            engine.setLanguage(Locale.US)
            tryBindEnglishVoice(engine)
        } catch (_: Exception) {
        }
    }

    private fun pickEnglishVoice(engine: TextToSpeech): Voice? {
        val voices =
            try {
                engine.voices
            } catch (_: Exception) {
                null
            } ?: return null
        val candidates =
            voices.filter { vo ->
                try {
                    vo.locale.language.equals("en", ignoreCase = true)
                } catch (_: Exception) {
                    false
                }
            }
        if (candidates.isEmpty()) {
            return null
        }
        val preferTags =
            listOf(
                "en-us",
                "en-gb",
                "en-au",
                "en-in",
                "en",
            )
        for (wanted in preferTags) {
            val hit =
                candidates.firstOrNull { vo ->
                    val t =
                        vo.locale
                            .toLanguageTag()
                            .replace('_', '-')
                            .lowercase(Locale.ROOT)
                    t == wanted || t.startsWith("$wanted-")
                }
            if (hit != null) {
                return hit
            }
        }
        return candidates.firstOrNull()
    }

    private fun tryBindEnglishVoice(engine: TextToSpeech): Boolean {
        val v = pickEnglishVoice(engine) ?: return false
        return try {
            engine.voice = v
            engine.setLanguage(v.locale)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun drainPending(engine: TextToSpeech) {
        while (true) {
            val pair = synchronized(pendingSpeaks) {
                if (pendingSpeaks.isEmpty()) {
                    null
                } else {
                    pendingSpeaks.removeFirst()
                }
            } ?: break
            runSpeak(engine, pair.first, pair.second)
        }
    }

    private fun rejectPending(code: String, message: String) {
        while (true) {
            val pair = synchronized(pendingSpeaks) {
                if (pendingSpeaks.isEmpty()) {
                    null
                } else {
                    pendingSpeaks.removeFirst()
                }
            } ?: break
            pair.second.error(code, message, null)
        }
    }

    private fun runSpeak(engine: TextToSpeech, text: String, result: MethodChannel.Result) {
        engine.stop()
        forceEnglishLocale(engine)
        val id = UUID.randomUUID().toString()
        val bundle = Bundle()
        val code = engine.speak(text, TextToSpeech.QUEUE_FLUSH, bundle, id)
        if (code == TextToSpeech.SUCCESS) {
            result.success(1)
        } else {
            result.success(0)
        }
    }

    private fun onTtsInitDone(status: Int) {
        initFinished = true
        initSuccess = status == TextToSpeech.SUCCESS
        val engine = tts
        if (initSuccess && engine != null) {
            forceEnglishLocale(engine)
            finishPrepareSuccess()
            drainPending(engine)
        } else {
            tts?.shutdown()
            tts = null
            if (initAttempt < MAX_INIT_ATTEMPTS) {
                initAttempt++
                initFinished = false
                val delayMs = 320L * initAttempt
                mainHandler.postDelayed({ beginTtsInit() }, delayMs)
            } else {
                rejectPending("TTS_INIT", "TextToSpeech init failed after retries, last status=$status")
                finishPrepareError("TTS_INIT", "TextToSpeech init failed after retries, last status=$status")
                initFinished = true
                initSuccess = false
                initAttempt = 0
            }
        }
    }

    private fun beginTtsInit() {
        if (tts != null) {
            return
        }
        initFinished = false
        initSuccess = false
        val ctx = speakContext(initAttempt)
        val enginePkg = if (initAttempt >= 2) defaultTtsEnginePackage() else null
        val listener = TextToSpeech.OnInitListener { status: Int -> onTtsInitDone(status) }
        tts = try {
            if (!enginePkg.isNullOrBlank()) {
                TextToSpeech(ctx, listener, enginePkg)
            } else {
                TextToSpeech(ctx, listener)
            }
        } catch (e: Exception) {
            onTtsInitDone(TextToSpeech.ERROR)
            return
        }
    }

    /** 尝试打开系统「文字转语音」或无障碍（内常有 TTS）页面；失败则打开总设置。 */
    private fun tryOpenSystemTtsSettings(act: Activity): Boolean {
        val intents =
            listOf(
                Intent("com.android.settings.TTS_SETTINGS"),
                Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS),
            )
        for (intent in intents) {
            try {
                act.startActivity(intent)
                return true
            } catch (_: Exception) {
            }
        }
        return try {
            act.startActivity(Intent(Settings.ACTION_SETTINGS))
            true
        } catch (_: Exception) {
            false
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "prepare" -> {
                if (initSuccess && tts != null) {
                    result.success(1)
                    return
                }
                if (prepareResult != null) {
                    result.error("TTS_BUSY", "prepare already in progress", null)
                    return
                }
                prepareResult = result
                if (tts == null) {
                    beginTtsInit()
                }
            }
            "speak" -> {
                val text = call.argument<String>("text") ?: ""
                if (text.isEmpty()) {
                    result.success(0)
                    return
                }
                if (!initFinished || !initSuccess || tts == null) {
                    if (tts == null) {
                        beginTtsInit()
                    }
                    synchronized(pendingSpeaks) {
                        pendingSpeaks.addLast(text to result)
                    }
                    return
                }
                val engine = tts
                if (engine == null) {
                    result.error("TTS_INIT", "engine not available", null)
                    return
                }
                runSpeak(engine, text, result)
            }
            "stop" -> {
                tts?.stop()
                result.success(null)
            }
            "openSystemTtsSettings" -> {
                val act = activity
                if (act == null || act.isFinishing || act.isDestroyed) {
                    result.success(false)
                    return
                }
                result.success(tryOpenSystemTtsSettings(act))
            }
            "getTtsEngines" -> {
                val ctx = appContext ?: activity
                if (ctx == null) {
                    result.success(emptyList<Any>())
                    return
                }
                result.success(queryInstalledTtsEngines(ctx))
            }
            "getDefaultTtsEnginePackage" -> {
                result.success(defaultTtsEnginePackage())
            }
            else -> result.notImplemented()
        }
    }

    companion object {
        private const val CHANNEL = "com.wordlite.app/android_tts"
        private const val MAX_INIT_ATTEMPTS = 4
    }
}

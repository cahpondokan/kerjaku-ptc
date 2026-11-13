package com.niam.ayani.kerjakuptc

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Paint
import androidx.core.content.FileProvider
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.UUID
import java.util.concurrent.Executors
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.roundToInt

class DutyScannerBridge(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "com.niam.ayani.kerjakuptc/duty_scan")
    private val worker = Executors.newSingleThreadExecutor()
    private var pendingScan: MethodChannel.Result? = null
    private val requestCode = 1301
    private val scanCache get() = File(activity.cacheDir, "duty_scanner").apply { mkdirs() }

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "scan" -> scan(call, result)
                "crop" -> worker.execute {
                    try {
                        val bytes = crop(call)
                        activity.runOnUiThread { result.success(bytes) }
                    } catch (error: Exception) {
                        activity.runOnUiThread { result.error("CROP_FAILED", error.message ?: "Potongan tidak valid.", null) }
                    }
                }
                "discard" -> {
                    for (path in call.argument<List<String>>("paths").orEmpty()) {
                        val file = File(path).canonicalFile
                        if (file.parentFile == scanCache.canonicalFile) file.delete()
                    }
                    result.success(null)
                }
                "sharePacket" -> {
                    try { sharePacket(call.argument<String>("path").orEmpty()); result.success(true) }
                    catch (error: Exception) { result.error("WHATSAPP_UNAVAILABLE", error.message ?: "WhatsApp belum dapat dibuka.", null) }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun scan(call: MethodCall, result: MethodChannel.Result) {
        if (pendingScan != null) {
            result.error("SCANNER_BUSY", "Pemindai masih terbuka.", null)
            return
        }
        pendingScan = result
        // BASE provides scanning, crop and rotation without content-cleanup tools.
        val options = GmsDocumentScannerOptions.Builder()
            .setGalleryImportAllowed(true)
            .setPageLimit((call.argument<Int>("limit") ?: 10).coerceIn(1, 10))
            .setResultFormats(GmsDocumentScannerOptions.RESULT_FORMAT_JPEG)
            .setScannerMode(GmsDocumentScannerOptions.SCANNER_MODE_BASE)
            .build()
        GmsDocumentScanning.getClient(options).getStartScanIntent(activity)
            .addOnSuccessListener { sender ->
                try {
                    @Suppress("DEPRECATION")
                    activity.startIntentSenderForResult(sender, requestCode, null, 0, 0, 0)
                } catch (error: Exception) { failScan(error) }
            }
            .addOnFailureListener { failScan(it) }
    }

    private fun failScan(error: Exception) {
        pendingScan?.error("SCANNER_UNAVAILABLE",
            "Pemindai belum siap. Pada pemakaian pertama, aktifkan internet untuk mengunduh komponen pemindai dan pastikan Google Play services tersedia. Coba lagi.", error.message)
        pendingScan = null
    }

    fun onActivityResult(code: Int, resultCode: Int, data: Intent?): Boolean {
        if (code != requestCode) return false
        val result = pendingScan ?: return true
        pendingScan = null
        if (resultCode != Activity.RESULT_OK) { result.success(null); return true }
        val pages = GmsDocumentScanningResult.fromActivityResultIntent(data)?.pages.orEmpty()
        if (pages.isEmpty()) { result.success(null); return true }
        worker.execute {
            val files = mutableListOf<File>()
            try {
                for (page in pages) {
                    val file = File(scanCache, "${UUID.randomUUID()}.jpg")
                    files.add(file)
                    activity.contentResolver.openInputStream(page.imageUri)?.use { input ->
                        file.outputStream().use { output -> input.copyTo(output) }
                    } ?: error("Hasil scan tidak dapat dibaca.")
                    require(file.length() in 1..20L * 1024 * 1024) { "Hasil scan melebihi 20 MB per halaman." }
                }
                activity.runOnUiThread { result.success(files.map { it.absolutePath }) }
            } catch (error: Exception) {
                files.forEach { it.delete() }
                activity.runOnUiThread { result.error("SCAN_READ_FAILED", error.message ?: "Hasil scan tidak dapat dibaca.", null) }
            }
        }
        return true
    }

    private fun crop(call: MethodCall): ByteArray {
        val bytes = call.argument<ByteArray>("bytes") ?: error("Gambar tidak tersedia.")
        require(bytes.size <= 20 * 1024 * 1024) { "Gambar terlalu besar." }
        val points = call.argument<List<Double>>("corners") ?: error("Titik potongan tidak tersedia.")
        require(points.size == 8 && points.all { it.isFinite() && it in 0.0..1.0 }) { "Titik potongan tidak valid." }
        // Enforce clockwise convex corners: TL, TR, BR, BL. Reject crossing handles.
        for (i in 0..3) {
            val a = i * 2; val b = ((i + 1) % 4) * 2; val c = ((i + 2) % 4) * 2
            val cross = (points[b] - points[a]) * (points[c+1] - points[b+1]) -
                (points[b+1] - points[a+1]) * (points[c] - points[b])
            require(cross > 0.0001) { "Sudut potongan saling berpotongan atau terlalu sempit." }
        }
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
        require(bounds.outWidth > 0 && bounds.outHeight > 0) { "Gambar tidak dapat dibaca." }
        var sample = 1
        while (max(bounds.outWidth, bounds.outHeight) / sample > 4096) sample *= 2
        val source = BitmapFactory.decodeByteArray(bytes, 0, bytes.size,
            BitmapFactory.Options().apply { inSampleSize = sample }) ?: error("Gambar tidak dapat dibaca.")
        var output: Bitmap? = null
        var rotated: Bitmap? = null
        try {
            val src = FloatArray(8) { i -> (points[i] * if (i % 2 == 0) source.width else source.height).toFloat() }
            fun distance(a: Int, b: Int) = hypot((src[a*2]-src[b*2]).toDouble(), (src[a*2+1]-src[b*2+1]).toDouble())
            val width = max(distance(0,1), distance(3,2)).roundToInt().coerceIn(16,4096)
            val height = max(distance(0,3), distance(1,2)).roundToInt().coerceIn(16,4096)
            val transform = Matrix()
            check(transform.setPolyToPoly(src, 0, floatArrayOf(0f,0f,width.toFloat(),0f,width.toFloat(),height.toFloat(),0f,height.toFloat()), 0,4))
            output = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            Canvas(output).apply {
                drawColor(Color.WHITE)
                drawBitmap(source, transform, Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG))
            }
            val turns = ((call.argument<Int>("rotation") ?: 0) % 4 + 4) % 4
            val finalImage = if (turns == 0) output else Bitmap.createBitmap(output,0,0,width,height,
                Matrix().apply { postRotate(turns * 90f) },true).also { rotated = it }
            return ByteArrayOutputStream().use { stream ->
                check(finalImage.compress(Bitmap.CompressFormat.JPEG, 94, stream))
                stream.toByteArray()
            }
        } finally {
            if (rotated !== output) rotated?.recycle()
            output?.recycle()
            source.recycle()
        }
    }

    private fun sharePacket(path: String) {
        val file = File(path).canonicalFile
        require(file.isFile && file.extension.lowercase() == "pdf" &&
            file.path.startsWith(activity.cacheDir.canonicalPath + File.separator)) { "PDF tidak tersedia." }
        val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.fileprovider", file)
        val intents = listOf("com.whatsapp", "com.whatsapp.w4b").mapNotNull { packageName ->
            val installed = try { activity.packageManager.getPackageInfo(packageName,0); true } catch (_: Exception) { false }
            if (!installed) null else Intent(Intent.ACTION_SEND).apply {
                type = "application/pdf"
                setPackage(packageName)
                putExtra(Intent.EXTRA_STREAM, uri)
                clipData = ClipData.newUri(activity.contentResolver, "Berkas dinas", uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                // Deliberately no jid, phone, or profile-admin recipient.
            }
        }
        check(intents.isNotEmpty()) { "WhatsApp belum terpasang. Pasang WhatsApp lalu bagikan kembali; hasil scan tetap tersimpan." }
        val intent = if (intents.size == 1) intents.first() else Intent.createChooser(intents.first(), "Bagikan via WhatsApp").apply {
            putExtra(Intent.EXTRA_INITIAL_INTENTS, intents.drop(1).toTypedArray())
        }
        activity.startActivity(intent)
    }

    fun dispose() { channel.setMethodCallHandler(null); worker.shutdown() }
}

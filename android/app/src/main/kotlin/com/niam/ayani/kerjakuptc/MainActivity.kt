package com.niam.ayani.kerjakuptc

import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "com.niam.ayani.kerjakuptc/whatsapp"
    private val backupChannelName = "com.niam.ayani.kerjakuptc/backup"
    private val backupPickRequestCode = 1201
    private val backupSaveRequestCode = 1202
    private var pendingBackupResult: MethodChannel.Result? = null
    private var pendingBackupBytes: ByteArray? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            if (call.method != "shareFilesToAdmin") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            try {
                val phone = call.argument<String>("phone").orEmpty()
                    .filter { it.isDigit() }
                val message = call.argument<String>("message").orEmpty()
                val filePaths = call.argument<List<String>>("filePaths").orEmpty()

                if (phone.isBlank()) {
                    result.error(
                        "INVALID_PHONE",
                        "Nomor WhatsApp admin tidak valid.",
                        null,
                    )
                    return@setMethodCallHandler
                }

                if (filePaths.isEmpty()) {
                    result.error(
                        "NO_FILES",
                        "Tidak ada file yang akan dibagikan.",
                        null,
                    )
                    return@setMethodCallHandler
                }

                shareFilesToWhatsApp(phone, message, filePaths)
                result.success(true)
            } catch (error: Exception) {
                result.error(
                    "WHATSAPP_SHARE_FAILED",
                    error.message ?: "Gagal membuka WhatsApp.",
                    null,
                )
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            backupChannelName,
        ).setMethodCallHandler { call, result ->
            if (pendingBackupResult != null) {
                result.error("PICKER_BUSY", "Pemilih berkas sedang terbuka.", null)
                return@setMethodCallHandler
            }
            when (call.method) {
                "pickBackup" -> {
                    pendingBackupResult = result
                    try {
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "application/json"
                        }
                        startActivityForResult(intent, backupPickRequestCode)
                    } catch (error: Exception) {
                        pendingBackupResult = null
                        result.error(
                            "BACKUP_PICKER_FAILED",
                            error.message ?: "Gagal membuka pemilih berkas.",
                            null,
                        )
                    }
                }
                "saveBackup" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes == null) {
                        result.error("BACKUP_EMPTY", "Berkas cadangan kosong.", null)
                        return@setMethodCallHandler
                    }
                    val fileName = call.argument<String>("fileName")
                        ?: "KerjaKu_PTC_backup.json"
                    pendingBackupBytes = bytes
                    pendingBackupResult = result
                    try {
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "application/json"
                            putExtra(Intent.EXTRA_TITLE, fileName)
                        }
                        startActivityForResult(intent, backupSaveRequestCode)
                    } catch (error: Exception) {
                        pendingBackupResult = null
                        pendingBackupBytes = null
                        result.error(
                            "BACKUP_SAVE_FAILED",
                            error.message ?: "Gagal membuka lokasi penyimpanan.",
                            null,
                        )
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    @Deprecated("Deprecated in Android, retained for Flutter activity result handling")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != backupPickRequestCode &&
            requestCode != backupSaveRequestCode
        ) return

        val result = pendingBackupResult ?: return
        pendingBackupResult = null
        if (resultCode != RESULT_OK || data?.data == null) {
            pendingBackupBytes = null
            result.success(if (requestCode == backupSaveRequestCode) false else null)
            return
        }

        try {
            if (requestCode == backupPickRequestCode) {
                val bytes = contentResolver.openInputStream(data.data!!)?.use { it.readBytes() }
                    ?: throw IllegalStateException("Berkas cadangan tidak dapat dibaca.")
                result.success(bytes)
            } else {
                val bytes = pendingBackupBytes
                    ?: throw IllegalStateException("Berkas cadangan kosong.")
                contentResolver.openOutputStream(data.data!!, "w")?.use {
                    it.write(bytes)
                } ?: throw IllegalStateException("Berkas cadangan tidak dapat disimpan.")
                result.success(true)
            }
        } catch (error: Exception) {
            result.error(
                "BACKUP_READ_FAILED",
                error.message ?: "Gagal membaca berkas cadangan.",
                null,
            )
        } finally {
            pendingBackupBytes = null
        }
    }

    private fun shareFilesToWhatsApp(
        phone: String,
        message: String,
        filePaths: List<String>,
    ) {
        val uris = ArrayList<Uri>()
        for (path in filePaths) {
            val file = File(path)
            if (!file.exists()) {
                throw IllegalArgumentException("File tidak ditemukan: $path")
            }
            uris.add(
                FileProvider.getUriForFile(
                    this,
                    "${applicationContext.packageName}.fileprovider",
                    file,
                ),
            )
        }

        val action = if (uris.size == 1) {
            Intent.ACTION_SEND
        } else {
            Intent.ACTION_SEND_MULTIPLE
        }

        val baseIntent = Intent(action).apply {
            type = "application/octet-stream"
            putExtra(Intent.EXTRA_TEXT, message)
            putExtra("jid", "$phone@s.whatsapp.net")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            clipData = ClipData.newUri(
                contentResolver,
                "Dokumen lembur",
                uris.first(),
            ).apply {
                for (uri in uris.drop(1)) {
                    addItem(ClipData.Item(uri))
                }
            }

            if (uris.size == 1) {
                putExtra(Intent.EXTRA_STREAM, uris.first())
            } else {
                putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
            }
        }

        val packages = listOf("com.whatsapp", "com.whatsapp.w4b")
        for (packageName in packages) {
            if (isPackageInstalled(packageName)) {
                val intent = Intent(baseIntent).apply {
                    setPackage(packageName)
                }
                for (uri in uris) {
                    grantUriPermission(
                        packageName,
                        uri,
                        Intent.FLAG_GRANT_READ_URI_PERMISSION,
                    )
                }
                try {
                    startActivity(intent)
                    return
                } catch (_: ActivityNotFoundException) {
                    // Coba WhatsApp Business atau panel berbagi di bawah.
                }
            }
        }

        try {
            startActivity(
                Intent.createChooser(baseIntent, "Kirim dokumen lembur"),
            )
        } catch (error: ActivityNotFoundException) {
            throw ActivityNotFoundException(
                "WhatsApp atau aplikasi berbagi tidak ditemukan.",
            )
        }
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (error: PackageManager.NameNotFoundException) {
            false
        }
    }
}

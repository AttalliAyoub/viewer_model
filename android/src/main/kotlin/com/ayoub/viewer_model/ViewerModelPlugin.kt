package com.ayoub.viewer_model

import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory


class ViewerModelPlugin : FlutterPlugin, PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        this.flutterPluginBinding = flutterPluginBinding
        flutterPluginBinding
        flutterPluginBinding
            .platformViewRegistry
            .registerViewFactory("com.ayoub.viewer_model", this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        // channel.setMethodCallHandler(null)
    }

    override fun create(context: Context?, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as Map<String?, Any?>?
        return NativeView(context, viewId, flutterPluginBinding, creationParams)
    }

}

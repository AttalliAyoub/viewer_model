package com.ayoub.viewer_model

import android.content.Context
import android.graphics.BitmapFactory
import android.graphics.Color
import android.util.Log
import android.view.MotionEvent
import android.view.View
import androidx.annotation.NonNull
import com.google.gson.Gson
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import org.rajawali3d.Object3D
import org.rajawali3d.lights.DirectionalLight
import org.rajawali3d.loader.ALoader
import org.rajawali3d.loader.LoaderOBJ
import org.rajawali3d.loader.async.IAsyncLoaderCallback
import org.rajawali3d.materials.Material
import org.rajawali3d.materials.methods.DiffuseMethod
import org.rajawali3d.materials.textures.ATexture
import org.rajawali3d.materials.textures.Texture
import org.rajawali3d.math.vector.Vector3
import org.rajawali3d.primitives.Sphere
import org.rajawali3d.renderer.Renderer
import org.rajawali3d.view.ISurface
import org.rajawali3d.view.SurfaceView
import java.io.File

internal class NativeView(
    context: Context,
    flutterPluginBinding: FlutterPlugin.FlutterPluginBinding,
    id: Int,
    private val creationParams: Map<String?, Any?>?
) :
    Renderer(context),
    PlatformView,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler
{
    // private val id: Int = id
    // private val flutterPluginBinding = flutterPluginBinding
    private val eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "event_viewer_model$id")
    private val channel = MethodChannel(flutterPluginBinding.binaryMessenger, "method_viewer_model$id")
    private val surfaceView = SurfaceView(context)
    private val gson = Gson()
    private var events: EventChannel.EventSink? = null
    private lateinit var mObject: Object3D
    private lateinit var mDirectionalLight: DirectionalLight

    override fun getView(): View {
        return surfaceView
    }

    init {
        channel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
        frameRate = 60.0
        surfaceView.setFrameRate(frameRate)
        surfaceView.renderMode = ISurface.RENDERMODE_WHEN_DIRTY
        surfaceView.setSurfaceRenderer(this)
        surfaceView.renderMode = ISurface.RENDERMODE_WHEN_DIRTY
        this.setAntiAliasingMode(ISurface.ANTI_ALIASING_CONFIG.COVERAGE)
    }

    override fun initScene() {
        mDirectionalLight = DirectionalLight(1.0, .2, -1.0)
        mDirectionalLight.setColor(1.0f, 1.0f, 1.0f)
        mDirectionalLight.power = 2f
        currentScene.addLight(mDirectionalLight)
        currentCamera.farPlane = 1000.0
        // currentCamera.nearPlane = 0.1
        currentCamera.z = 4.2
        loadFirstModel()
        events?.success(mapOf("event" to "initScene"))
    }

    override fun dispose() {
        channel.setMethodCallHandler(null)
    }

    override fun onOffsetsChanged(
        xOffset: Float,
        yOffset: Float,
        xOffsetStep: Float,
        yOffsetStep: Float,
        xPixelOffset: Int,
        yPixelOffset: Int
    ) {
        events?.success(mapOf(
            "event" to "OffsetsChanged",
            
        ))

    }

    override fun onTouchEvent(event: MotionEvent?) {
        if (event != null) {
            // event.classification;
            events?.success(mapOf(
                "event" to "touch",
                "data" to gson.toJson(event)
                    /*
                    "data" to mapOf(
                        "action" to event.action,
                        "actionButton" to event.actionButton,
                        "actionIndex" to event.actionIndex,
                        "actionMasked" to event.actionMasked,
                        "buttonState" to event.buttonState,
                        "downTime" to event.downTime,
                        "edgeFlags" to event.edgeFlags,
                        "flags" to event.flags,
                        "historySize" to event.historySize,
                        "metaState" to event.metaState,
                        "orientation" to event.orientation,
                        "pointerCount" to event.pointerCount,
                        "pressure" to event.pressure,
                        "rawX" to event.rawX,
                        "rawY" to event.rawY,
                        "size" to event.size,
                        "toolMajor" to event.toolMajor,
                        "toolMinor" to event.toolMinor,
                        "touchMajor" to event.touchMajor,
                        "touchMinor" to event.touchMinor,
                        "x" to event.x,
                        "xPrecision" to event.xPrecision,
                        "y" to event.y,
                        "yPrecision" to event.yPrecision,
                        "device" to mapOf(
                            "controllerNumber" to event.device.controllerNumber,
                            "controllerNumber" to event.device.id,
                            "controllerNumber" to event.device.keyboardType,
                            "controllerNumber" to event.device.productId,
                            "controllerNumber" to event.device.sources,
                            "controllerNumber" to event.device.vendorId,
                            "controllerNumber" to event.device.descriptor,
                            "controllerNumber" to event.device.descriptor,
                            "controllerNumber" to event.device.controllerNumber,
                            "controllerNumber" to event.device.controllerNumber,
                            "controllerNumber" to event.device.controllerNumber,
                            "controllerNumber" to event.device.controllerNumber,
                            "controllerNumber" to event.device.controllerNumber
                        ),
                        "deviceId" to event.deviceId,
                        "eventTime" to event.eventTime,
                        "source" to event.source
                    )
                    */
            ))
        }

    }

    /*
    override fun onRender(elapsedRealtime: Long, deltaTime: Double) {
        super.onRender(elapsedRealtime, deltaTime)
    }
     */

    private fun loadFirstModel() {
        val initialModel = creationParams?.get("initialModel") as Map<*, *>?
        if (initialModel?.isNotEmpty() == true) {
            val path = initialModel["path"]!! as String
            val texture =  initialModel["texture"] as String?
            val loader = LoaderOBJ(this, File(path))
            loadModel(loader, texture)
        }
    }


    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "loadModel" -> {
                val path = call.argument<String>("path")!!
                val texture = call.argument<String>("texture")
                val loader = LoaderOBJ(this, File(path))
                loadModel(loader, texture, result)
            }
            "loadEarth" -> {
                loadEarth()
                result.success(null)
            }
            "rotate" -> {
                val x = call.argument<Double>("x")!!
                val y = call.argument<Double>("y")!!
                val z = call.argument<Double>("z")!!
                mObject.rotX = x
                mObject.rotY = y
                mObject.rotZ = z
                result.success(null)
            }
            "moveCam" -> {
                val x = call.argument<Double>("x")!!
                val y = call.argument<Double>("y")!!
                val z = call.argument<Double>("z")!!
                currentCamera.position = Vector3(x, y, z)
                result.success(null)
            }
            "getRotation" -> {
                result.success(mObject.rotY)
            }
            else -> result.notImplemented()
        }
    }

    private fun loadModel(loader: ALoader, texture: String? = null, result: MethodChannel.Result? = null): ALoader {
        return super.loadModel(loader, object: IAsyncLoaderCallback {
            override fun onModelLoadComplete(loader: ALoader) {
                currentScene.clearChildren()
                mObject = (loader as LoaderOBJ).parsedObject
                // mObject.material = loadTexture(texture)
                mObject.position = Vector3.ZERO
                val box = mObject.boundingBox.max
                currentCamera.position = Vector3(0.0, box.y / 2, box.z * 8)
                currentScene.addChild(mObject)
                result?.success(null)
            }
            override fun onModelLoadFailed(loader: ALoader?) {
                result?.error("CAN_NOT_LOAD", "Model load failed", "")
            }
        }, loader.tag)
    }

    private fun loadTexture(path: String? = null): Material {
        val material = Material()
        material.enableLighting(true)
        material.diffuseMethod = DiffuseMethod.Lambert()
        material.color = Color.RED
        material.colorInfluence = 0f
        if (path != null) {
            val image = BitmapFactory.decodeStream(context.assets.open(path))
            val texture = Texture("path", image)
            try {
                material.addTexture(texture)
            } catch (error: ATexture.TextureException) {
                Log.d("BasicRenderer.initScene", error.toString())
            }
        }
        return material
    }

    private fun loadEarth() {
        currentScene.clearChildren()
        mObject = Sphere(1f, 24, 24)
        mObject.material = loadTexture()
        mObject.position = Vector3.ZERO
        currentScene.addChild(mObject)
        // events?.success(mapOf("event" to "loadEarth"))
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.events = events
    }

    override fun onCancel(arguments: Any?) {

    }

    override fun onInputConnectionLocked() {
        this.onPause()
    }

    override fun onInputConnectionUnlocked() {
        this.onResume()
    }
}
